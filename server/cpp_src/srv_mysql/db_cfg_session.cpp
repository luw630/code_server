#include "db_cfg_session.h"
#include "base_game_log.h"
#include "public_enum.pb.h"
#include "db_server.h"
#include "db_cfg_net_server.h"

db_cfg_session::db_cfg_session(boost::asio::io_service& ioservice)
    : base_net_session(ioservice)
    , dispatcher_manager_(nullptr)
{
    dispatcher_manager_ = db_cfg_net_server::instance()->get_dispatcher_manager();
}

db_cfg_session::~db_cfg_session()
{
}
void insert_into_changemoney(FD_ChangMoneyDeal* msg)
{
	LOG_INFO("on_DF_ChangMoney  web[%d] gudi[%d] order_id[%d] type[%d]", msg->web_id(), msg->info().guid(), msg->info().order_id(), msg->info().type_id());
	int web_id = msg->web_id();
	AddMoneyInfo info;
	info.CopyFrom(msg->info());
	db_mgr::instance()->get_db_connection_recharge().execute_query_string([web_id, info](std::vector<std::string>* data) {
		if (data)
		{
			LOG_INFO("on_DF_ChangMoney  order[%d] is  deal", info.order_id());
			DF_Reply reply;
			reply.set_web_id(web_id);
			reply.set_result(6);
			db_cfg_net_server::instance()->post_msg_to_cfg_pb(&reply);
		}
		else
		{
			LOG_INFO("on_DF_ChangMoney  order[%d] is not deal", info.order_id());
			db_mgr::instance()->get_db_connection_recharge().execute_update([web_id, info](int ret) {
				DF_Reply reply;
				reply.set_web_id(web_id);
				if (ret > 0)
				{//插入成功
					LOG_INFO("on_DF_ChangMoney  order[%d] insert t_re_recharge  true", info.order_id());
					reply.set_result(6);
					if (info.type_id() == LOG_MONEY_OPT_TYPE_RECHARGE_MONEY)
					{
						db_mgr::instance()->get_db_connection_recharge().execute("UPDATE t_recharge_order SET `server_status` = '6' WHERE id = %d;", info.order_id());
					}
					else if (info.type_id() == LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE)
					{
						if (info.order_id() != -1)
						{//-1为非订单失败
							db_mgr::instance()->get_db_connection_recharge().execute("UPDATE t_cash SET `status_c` = '6' WHERE order_id = %d;", info.order_id());
						}
					}
				}
				else
				{//插入失败
					LOG_INFO("on_DF_ChangMoney  order[%d] insert t_re_recharge  false", info.order_id());
					reply.set_result(4);
				}
				if (web_id != -1)
				{
					LOG_INFO("on_DF_ChangMoney  order[%d] reply web[%d]", web_id);
					db_cfg_net_server::instance()->post_msg_to_cfg_pb(&reply);
				}
			}, "INSERT INTO t_re_recharge(`guid`,`money`,`type`,`order_id`,`created_at`)VALUES('%d', '%I64d', '%d', '%d', current_timestamp)", info.guid(), info.gold(), info.type_id(), info.order_id());
		}
	}, "select id, guid from t_re_recharge where type = '%d' and order_id = '%d';", info.type_id(), info.order_id());
}
bool db_cfg_session::handler_connect()
{
	LOG_INFO("srv_db<-->srv_cfg connect success ... <%s:%d>", ip_.c_str(), port_);

	if (!static_cast<db_server*>(base_server::instance())->get_init_config_server())
	{
		S_RequestServerConfig msg;
		msg.set_type(ServerSessionFromDB);
		msg.set_server_id(static_cast<db_server*>(base_server::instance())->get_db_id());
		send_pb(&msg);
	}
	else
	{
		S_Connect msg;
		msg.set_type(ServerSessionFromDB);
		msg.set_server_id(static_cast<db_server*>(base_server::instance())->get_db_id());
		send_pb(&msg);
	}

	return base_net_session::handler_connect();
}

void db_cfg_session::handler_connect_failed()
{
	LOG_INFO("srv_db<-->srv_cfg connect failed ... <%s:%d>", ip_.c_str(), port_);

	base_net_session::handler_connect_failed();
}

void db_cfg_session::on_closed()
{
	LOG_INFO("srv_db<-->srv_cfg disconnect ... <%s:%d>", ip_.c_str(), port_);

	base_net_session::on_closed();
}

void db_cfg_session::handler_fd_changemoneydeal(FD_ChangMoneyDeal* msg)
{
	insert_into_changemoney(msg);
}
bool db_cfg_session::handler_msg_dispatch(MsgHeader* header)
{
	if (header->id == S_Heartbeat::ID)
	{
		return true;
	}

    auto dispatcher = dispatcher_manager_->query_dispatcher(header->id);
    if (nullptr == dispatcher)
    {
        LOG_ERR("opcode：%d not registered", header->id);
        return true;
    }

    return dispatcher->parse(this, header);
}



void db_cfg_session::on_S_ReplyServerConfig(S_ReplyServerConfig* msg)
{
	static_cast<db_server*>(base_server::instance())->on_loadConfigComplete(msg->db_config());
}
void db_cfg_session::handler_fd_changemoney(FD_ChangMoney* msg)
{
    int order_id = msg->order_id();
    int web_id = msg->web_id();
    int type_id = msg->type_id();
    if (msg->type_id() == LOG_MONEY_OPT_TYPE_RECHARGE_MONEY)
    {
        db_mgr::instance()->get_db_connection_recharge().execute_query<Recharge>([type_id, web_id, order_id](Recharge* data) {
            if (data && (data->pay_status() != 2) && (data->server_status() == 0))
            {
                DF_ChangMoney reply;
                reply.set_web_id(web_id);
                AddMoneyInfo * info = reply.mutable_info();
                info->set_guid(data->guid());
                info->set_type_id(type_id);
                info->set_gold(data->exchange_gold());
                info->set_order_id(order_id);
                db_cfg_net_server::instance()->post_msg_to_cfg_pb(&reply);

				LOG_INFO("handler_fd_changemoney_01......order_id[%d]  web[%d]", order_id, web_id);
            }
            else
            {
                DF_Reply reply;
                reply.set_web_id(web_id);
                reply.set_result(2);
                db_cfg_net_server::instance()->post_msg_to_cfg_pb(&reply);
				LOG_INFO("handler_fd_changemoney_02......order_id[%d]  web[%d]", order_id, web_id);
            }
        }, nullptr, "SELECT guid, id, exchange_gold, pay_status,server_status FROM t_recharge_order WHERE id='%d';", order_id);
    }
    else if (msg->type_id() == LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE)
    {
        int del = msg->other_oper();
        db_mgr::instance()->get_db_connection_recharge().execute_query<CashFalse>([type_id, web_id, order_id, del](CashFalse* data) {
            if (data && (data->status() != 1) && (data->status() != 0) && (data->status() != 4) && (data->status_c() == 0))
            {
                DF_ChangMoney reply;
                reply.set_web_id(web_id);
                AddMoneyInfo * info = reply.mutable_info();
                info->set_guid(data->guid());
                info->set_type_id(type_id);
                info->set_gold(data->coins());
                info->set_order_id(order_id);
                db_cfg_net_server::instance()->post_msg_to_cfg_pb(&reply);
                int guid = data->guid();
                if (del){
                    db_mgr::instance()->get_db_connection_account().execute("UPDATE t_account SET `alipay_account_y` = NULL, alipay_name_y = NULL, alipay_account = NULL, alipay_name = NULL  WHERE guid = %d;", guid);
                }
				LOG_INFO("handler_fd_changemoney_03......order_id[%d]  web[%d]", order_id, web_id);
            }
            else
            {
                DF_Reply reply;
                reply.set_web_id(web_id);
                reply.set_result(2);
                db_cfg_net_server::instance()->post_msg_to_cfg_pb(&reply);
				LOG_INFO("handler_fd_changemoney_04......order_id[%d]  web[%d]", order_id, web_id);
            }
        }, nullptr, "SELECT guid, order_id, coins, status, status_c FROM t_cash WHERE order_id='%d';", order_id);
    }
    else
    {
		LOG_INFO("handler_fd_changemoney_05......order_id[%d]  web[%d]", order_id, web_id);
    }
}


