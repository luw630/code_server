#include "gate_cfg_session.h"
#include "base_game_log.h"
#include "public_enum.pb.h"
#include "gate_server.h"
#include "gate_cfg_net_server.h"
#include "gate_client_session.h"

bool gate_cfg_session::handler_connect()
{
	LOG_INFO("srv_gate<-->srv_cfg connect success ... <%s:%d>", ip_.c_str(), port_);
	gate_session_mgr::instance()->SendOnLine();
	if (!static_cast<gateway_server*>(base_server::instance())->get_init_config_server())
	{
		S_RequestServerConfig msg;
		msg.set_type(ServerSessionFromGate);
		msg.set_server_id(static_cast<gateway_server*>(base_server::instance())->get_gate_id());
		send_pb(&msg);
	}
	else
	{
		S_Connect msg;
		msg.set_type(ServerSessionFromGate);
		msg.set_server_id(static_cast<gateway_server*>(base_server::instance())->get_gate_id());
		send_pb(&msg);
	}

	return base_net_session::handler_connect();
}

void gate_cfg_session::handler_connect_failed()
{
	LOG_INFO("srv_gate<-->srv_cfg connect failed ... <%s:%d>", ip_.c_str(), port_);

	base_net_session::handler_connect_failed();
}

void gate_cfg_session::on_closed()
{
	LOG_INFO("srv_gate<-->srv_cfg disconnect ... <%s:%d>", ip_.c_str(), port_);

	base_net_session::on_closed();
}
gate_cfg_session::gate_cfg_session(boost::asio::io_service& ioservice)
	: base_net_session(ioservice)
	, dispatcher_manager_(nullptr)
{
	dispatcher_manager_ = gate_cfg_net_server::instance()->get_dispatcher_manager();
}

gate_cfg_session::~gate_cfg_session()
{
}

bool gate_cfg_session::handler_msg_dispatch(MsgHeader* header)
{
	if (header->id == S_Heartbeat::ID)
	{
		return true;
	}

	auto dispatcher = dispatcher_manager_->query_dispatcher(header->id);
	if (nullptr == dispatcher)
	{
		LOG_ERR("opcode£º%d not registered", header->id);
		return true;
	}

	return dispatcher->parse(this, header);
}



void gate_cfg_session::on_FS_ChangMoneyDeal(FS_ChangMoneyDeal * msg)
{
    LOG_INFO("on_FS_ChangMoneyDeal  web[%d] gudi[%d] order_id[%d] type[%d]", msg->web_id(), msg->info().guid(), msg->info().order_id(), msg->info().type_id());
    FS_ChangMoneyDeal nmsg;
    nmsg.set_web_id(msg->web_id());
    AddMoneyInfo *info = nmsg.mutable_info();
    info->CopyFrom(msg->info());
    int Server_ID = gate_session_mgr::instance()->find_gameid_by_guid(msg->info().guid());
    if (Server_ID == -1)
    {
        LOG_INFO("on_FS_ChangMoneyDeal  %d no find", msg->info().guid());
        gate_cfg_net_server::instance()->post_msg_to_cfg_pb(&nmsg);
    }
    else
    {
        auto session = gate_session_mgr::instance()->get_game_session(Server_ID);
        if (session && session->is_connect())
        {
            LOG_INFO("on_FS_ChangMoneyDeal  %d  find session %d", msg->info().guid(), Server_ID);
            session->send_pb(&nmsg);
        }
        else
        {
            LOG_INFO("on_FS_ChangMoneyDeal  %d no find session %d", msg->info().guid(), Server_ID);
            gate_cfg_net_server::instance()->post_msg_to_cfg_pb(&nmsg);
        }
    }
}

void gate_cfg_session::on_SS_JoinPrivateRoom(SS_JoinPrivateRoom* msg)
{
	auto s = gate_session_mgr::instance()->get_client_session(msg->owner_guid() / 100);
	if (s)
	{
		auto session = static_cast<gate_client_session*>(s.get());
		msg->set_owner_game_id(session->get_game_server_id());
		msg->set_first_game_type(session->get_first_game_type());
		msg->set_second_game_type(session->get_second_game_type());
		msg->set_private_room_score_type(session->get_private_room_score_type());
	}
	
	auto session = gate_session_mgr::instance()->get_game_session(msg->game_id());
	if (session && session->is_connect())
	{
		session->send_pb(msg);
	}
}
void gate_cfg_session::on_FG_ClientChannelInfo(FG_ClientChannelInfo* msg)
{
	gate_session_mgr::instance()->set_ClientChannelInfo(msg);
}

void gate_cfg_session::on_FG_GameServerCfg(FG_GameServerCfg * msg)
{
    GC_GameServerCfg notify;
	for (auto& item : static_cast<gateway_server*>(base_server::instance())->get_gamecfg().pb_cfg())
    {
        if (item.game_id() == msg->pb_cfg().game_id())
        {
            auto dbcfg = const_cast<GameClientRoomListCfg *>(&(item));
            dbcfg->CopyFrom(msg->pb_cfg());
        }
        if (gate_session_mgr::instance()->in_open_game_list(item.game_id()))
        {
            notify.add_pb_cfg()->CopyFrom(item);
        }
    }

    gate_session_mgr::instance()->broadcast_client(&notify);
}
void gate_cfg_session::on_S_ReplyServerConfig(S_ReplyServerConfig* msg)
{
	static_cast<gateway_server*>(base_server::instance())->on_loadConfigComplete(*msg);
}

void gate_cfg_session::on_S_NotifyGameServerStart(S_NotifyGameServerStart* msg)
{
	if (static_cast<gateway_server*>(base_server::instance())->on_NotifyGameServerStart(msg->game_id()))
	{
		S_RequestUpdateGameServerConfig request;
		request.set_game_id(msg->game_id());
		send_pb(&request);
	}
}

void gate_cfg_session::on_S_ReplyUpdateGameServerConfig(S_ReplyUpdateGameServerConfig* msg)
{
	static_cast<gateway_server*>(base_server::instance())->on_UpdateConfigComplete(*msg);

}

void gate_cfg_session::on_S_NotifyLoginServerStart(S_NotifyLoginServerStart* msg)
{
	if (static_cast<gateway_server*>(base_server::instance())->on_NotifyLoginServerStart(msg->login_id()))
	{
		S_RequestUpdateLoginServerConfigByGate request;
		request.set_login_id(msg->login_id());
		send_pb(&request);
	}
}

void gate_cfg_session::on_S_ReplyUpdateLoginServerConfigByGate(S_ReplyUpdateLoginServerConfigByGate* msg)
{
	static_cast<gateway_server*>(base_server::instance())->on_UpdateLoginConfigComplete(*msg);

}
