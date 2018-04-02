#include "cfg_session.h"
#include "cfg_session_mgr.h"
#include "base_game_log.h"
#include "cfg_db_mgr.h"
#include "public_enum.pb.h"
#include "cfg_server.h"
#include "config.pb.h"
#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"


cfg_session::cfg_session(boost::asio::ip::tcp::socket& sock)
	: virtual_session(sock)
	, dispatcher_manager_(nullptr)
	, port_(0)
	, type_(0)
	, server_id_(0)
{
}

cfg_session::~cfg_session()
{
}

void cfg_session::on_WF_ChangeGameCfg(WF_ChangeGameCfg* msg)
{
    int WebID = get_id();
    int game_id = msg->id();
    cfg_db_mgr::instance()->get_db_connection_config().execute_query_vstring([WebID, game_id](std::vector<std::vector<std::string>>* data) {
            FS_ChangeGameCfg nmsg;
            nmsg.set_webid(WebID);
            bool bRet = true;
            if (data && !data->empty() && data->front().size() >= 3)
            {
                if (data->front().front() == "0")
                {
                    LOG_INFO("get_game_config[%d] failed", game_id);
                    return;
                }
				GameServerConfigInfo info;
				if (!google::protobuf::TextFormat::ParseFromString(data->front()[1], &info))
				{
					LOG_ERR("parse game_config[%d] failed", game_id);
					return;
				}

				std::string str = boost::str(boost::format("do return {{table_count=%1%, money_limit=%2%, cell_money=%3%, tax_open=%4%, tax_show=%5%, tax=%6%}} end")
					% info.table_count() % info.money_limit() % info.cell_money() % info.tax_open() % info.tax_show() % info.tax());

                nmsg.set_room_list(str);
                nmsg.set_room_lua_cfg(data->front()[2]);

                LOG_INFO("get_game_config[%d] ok", game_id);
				bRet = cfg_session_mgr::instance()->post_msg_to_game_pb(game_id, &nmsg);
            }
            else
            {
                LOG_ERR("load cfg from db error");
                bRet = false;
            }
            if (!bRet)
            {
                FW_ChangeGameCfg reply;
                reply.set_result(0);
                cfg_session_mgr::instance()->send2server_pb(nmsg.webid(), &reply);
            }

    }, "CALL get_game_config(%d);", game_id);
    
}
void cfg_session::on_WF_ChangeRobotCfg(WF_ChangeRobotCfg* msg)
{
	int WebID = get_id();
	int game_id = msg->game_id();
	std::string cfg_param = msg->cfg_param();

	FS_ChangeRobotCfg nmsg;
	nmsg.set_cfg_param(cfg_param);
	if (cfg_session_mgr::instance()->post_msg_to_game_pb(game_id, &nmsg))
	{
		FW_ChangeRobotCfg reply;
		reply.set_result(1);
		cfg_session_mgr::instance()->send2server_pb(WebID, &reply);
	}
	else
	{
		FW_ChangeRobotCfg reply;
		reply.set_result(0);
		cfg_session_mgr::instance()->send2server_pb(WebID, &reply);
	}
}
void cfg_session::on_S_Connect(S_Connect* msg)
{
	type_ = msg->type();
	server_id_ = msg->server_id();
	switch (type_)
	{
	case ServerSessionFromGate:
		cfg_session_mgr::instance()->add_gate_session(shared_from_this());
		LOG_INFO("connecting request ServerSessionFromGate");
		break;
	case ServerSessionFromLogin:
		cfg_session_mgr::instance()->add_login_session(shared_from_this());
		LOG_INFO("connecting request ServerSessionFromLogin");
		break;
	case ServerSessionFromDB:
		cfg_session_mgr::instance()->add_db_session(shared_from_this());
		LOG_INFO("connecting request ServerSessionFromDB");
		break;
	case ServerSessionFromGame:
		cfg_session_mgr::instance()->add_game_session(shared_from_this());
		LOG_INFO("connecting request ServerSessionFromGame");
		break;
	default:
		LOG_WARN("unknown connecting request %d", type_);
		break;
	}
}
void cfg_session::on_S_RequestServerConfig(S_RequestServerConfig* msg)
{
	type_ = msg->type();
	server_id_ = msg->server_id();

	switch (type_)
	{
	case ServerSessionFromGate:
		cfg_session_mgr::instance()->add_gate_session(shared_from_this());
		get_gate_config(get_id(), server_id_);
		get_client_channel_config(get_id(), server_id_);
		break;
	case ServerSessionFromLogin:
		cfg_session_mgr::instance()->add_login_session(shared_from_this());
		get_login_config(get_id(), server_id_);
		break;
	case ServerSessionFromDB:
		cfg_session_mgr::instance()->add_db_session(shared_from_this());
        get_db_config(get_id(), server_id_);
		break;
	case ServerSessionFromGame:
		cfg_session_mgr::instance()->add_game_session(shared_from_this());
		get_game_config(get_id(), server_id_);
		break;
	default:
		LOG_WARN("unknown connecting request %d", type_);
		break;
	}
}


bool cfg_session::handler_msg_dispatch(MsgHeader* header)
{
	if (virtual_session::handler_msg_dispatch(header))
	{
		return true;
	}

	if (nullptr == dispatcher_manager_)
	{
		LOG_ERR("dispatcher manager is null");
		return false;
	}

	auto dispatcher = dispatcher_manager_->query_dispatcher(header->id);
	if (nullptr == dispatcher)
	{
		LOG_ERR("msg[%d] not registered", header->id);
		return true;
	}

	return dispatcher->parse(this, header);
}

bool cfg_session::handler_accept()
{
	port_ = get_remote_ip_port(ip_);
	LOG_INFO("accept session ... <%s:%d>", ip_.c_str(), port_);

	dispatcher_manager_ = cfg_session_mgr::instance()->get_dispatcher_manager();

	return true;
}

void cfg_session::on_closed()
{
	switch (type_)
	{
	case ServerSessionFromGate:
		cfg_db_mgr::instance()->get_db_connection_config().execute("UPDATE t_gate_server_cfg SET is_start = 0 WHERE gate_id = %d;", server_id_);
		cfg_session_mgr::instance()->del_gate_session(shared_from_this());
		LOG_INFO("gateway session disconnect ... <%s:%d>", ip_.c_str(), port_);
		break;
	case ServerSessionFromLogin:
		cfg_db_mgr::instance()->get_db_connection_config().execute("UPDATE t_login_server_cfg SET is_start = 0 WHERE login_id = %d;", server_id_);
		cfg_session_mgr::instance()->del_login_session(shared_from_this());
		LOG_INFO("Login session disconnect ... <%s:%d>", ip_.c_str(), port_);
		break;
	case ServerSessionFromDB:
		cfg_db_mgr::instance()->get_db_connection_config().execute("UPDATE t_db_server_cfg SET is_start = 0 WHERE id = %d;", server_id_);
		cfg_session_mgr::instance()->del_db_session(shared_from_this());
		LOG_INFO("DB session disconnect ... <%s:%d>", ip_.c_str(), port_);
		break;
	case ServerSessionFromGame:
		cfg_db_mgr::instance()->get_db_connection_config().execute("UPDATE t_game_server_cfg SET is_start = 0 WHERE game_id = %d;", server_id_);
		cfg_session_mgr::instance()->del_game_session(shared_from_this());
		LOG_INFO("Game session disconnect ... <%s:%d>", ip_.c_str(), port_);
		break;
	default:
		LOG_INFO("other session disconnect ... <%s:%d>", ip_.c_str(), port_);
		break;
	}
}

void cfg_session::on_SF_ChangeGameCfg(SF_ChangeGameCfg* msg)
{
	FW_ChangeGameCfg reply;
	reply.set_result(msg->result());
	cfg_session_mgr::instance()->send2server_pb(msg->webid(), &reply);
	FG_GameServerCfg nmsg;
	GameClientRoomListCfg * cfg = nmsg.mutable_pb_cfg();
	cfg->CopyFrom(msg->pb_cfg());
	cfg_session_mgr::instance()->broadcast2gate_pb(&nmsg);
}
void cfg_session::on_WF_GetCfg(WF_GetCfg* msg)
{
	FW_GetCfg reply;
	reply.set_php_sign(cfg_session_mgr::instance()->GetPHPSign().c_str());
	cfg_session_mgr::instance()->send2server_pb(get_id(), &reply);
}

void cfg_session::on_S_RequestUpdateGameServerConfig(S_RequestUpdateGameServerConfig* msg)
{
	update_gate_config(get_id(), server_id_, msg->game_id());
}

void cfg_session::on_S_RequestUpdateLoginServerConfigByGate(S_RequestUpdateLoginServerConfigByGate* msg)
{
	update_gate_login_config(get_id(), server_id_, msg->login_id());
}

void cfg_session::on_S_RequestUpdateLoginServerConfigByGame(S_RequestUpdateLoginServerConfigByGame* msg)
{
	update_game_login_config(get_id(), server_id_, msg->login_id());
}

void cfg_session::on_S_RequestUpdateDBServerConfigByGame(S_RequestUpdateDBServerConfigByGame* msg)
{
	update_game_db_config(get_id(), server_id_, msg->db_id());
}

void cfg_session::on_S_RequestUpdateDBServerConfigByLogin(S_RequestUpdateDBServerConfigByLogin* msg)
{
	update_login_db_config(get_id(), server_id_, msg->db_id());
}


void cfg_session::get_login_config(int session_id, int login_id)
{
	cfg_db_mgr::instance()->get_db_connection_config().execute_query_vstring([session_id, login_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 2)
		{
			if (data->front().front() == "0")
			{
				LOG_INFO("get_login_config[%d] failed", login_id);
				return;
			}

			LoginServerConfigInfo info;
			if (!google::protobuf::TextFormat::ParseFromString(data->front()[1], &info))
			{
				LOG_ERR("parse login_config[%d] failed", login_id);
				return;
			}

			S_ReplyServerConfig reply;
			reply.set_type(ServerSessionFromLogin);
			reply.set_server_id(login_id);
			reply.mutable_login_config()->CopyFrom(info);

			cfg_session_mgr::instance()->send2server_pb(session_id, &reply);

			S_NotifyLoginServerStart notify;
			notify.set_login_id(login_id);

			// 通知game
			cfg_session_mgr::instance()->broadcast2game_pb(&notify);
			// 通知gate
			cfg_session_mgr::instance()->broadcast2gate_pb(&notify);

		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL get_login_config(%d);", login_id);
	//2017-04-25 by rocky add
	on_RequestMaintainSwitchConfig(session_id,login_id,3);//请求登录维护开关
}

void cfg_session::get_game_config(int session_id, int game_id)
{
	cfg_db_mgr::instance()->get_db_connection_config().execute_query_vstring([session_id, game_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 3)
		{
			if (data->front().front() == "0")
			{
				LOG_INFO("get_game_config[%d] failed", game_id);
				return;
			}

			GameServerConfigInfo info;
			if (!google::protobuf::TextFormat::ParseFromString(data->front()[1], &info))
			{
				LOG_ERR("parse game_config[%d] failed", game_id);
				return;
			}

			info.set_room_lua_cfg(data->front()[2]);

			S_ReplyServerConfig reply;
			reply.set_type(ServerSessionFromGame);
			reply.set_server_id(game_id);
			reply.mutable_game_config()->CopyFrom(info);

			cfg_session_mgr::instance()->send2server_pb(session_id, &reply);

			// 通知gate
			S_NotifyGameServerStart notify;
			notify.set_game_id(game_id);
			cfg_session_mgr::instance()->broadcast2gate_pb(&notify);

			// 通知私人房间配置信息
			cfg_db_mgr::instance()->get_db_connection_config().execute_query_vstring([session_id](std::vector<std::vector<std::string>>* data) {
				if (data)
				{
					S_ReplyPrivateRoomConfig reply;
					for (auto& item : *data)
					{
						auto p = reply.mutable_info_list()->add_info();
						p->set_game_id(boost::lexical_cast<int>(item[0]));
						p->set_first_game_type(boost::lexical_cast<int>(item[1]));
						p->set_room_lua_cfg(item[2]);
					}

					cfg_session_mgr::instance()->send2server_pb(session_id, &reply);

				}
			}, "SELECT game_id, first_game_type, room_lua_cfg FROM t_game_server_cfg WHERE second_game_type = 99 AND is_open = 1;");

		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL get_game_config(%d);", game_id);

	on_RequestMaintainSwitchConfig(session_id,game_id,1);//请求提现维护开关
	on_RequestMaintainSwitchConfig(session_id, game_id,2);//请求游戏维护开关
}

void cfg_session::get_client_channel_config(int session_id, int gate_id)
{
	cfg_db_mgr::instance()->get_db_connection_config().execute_query_vstring([session_id, gate_id](std::vector<std::vector<std::string>>* data) {
		if (data)
		{
			FG_ClientChannelInfo reply;
			for (auto& item : *data)
			{
				auto p = reply.mutable_info()->Add();
				
				p->set_channel(item[0]);

				std::vector<std::string> v;
				boost::split(v, item[1], boost::is_any_of(","));
				for (auto iii : v)
				{
					if (!iii.empty())
						p->mutable_open_server_list()->Add(boost::lexical_cast<int>(iii.c_str()));
				}				
			}
			cfg_session_mgr::instance()->send2server_pb(session_id, &reply);

		}
		else
		{
			LOG_INFO("load client_channel_config from db NULL");
		}
	}, "SELECT channel,server_list FROM t_client_channel_cfg;");
}
void cfg_session::get_gate_config(int session_id, int gate_id)
{
	cfg_db_mgr::instance()->get_db_connection_config().execute_query_vstring([session_id, gate_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 2)
		{
			if (data->front().front() == "0")
			{
				LOG_INFO("get_gate_config[%d] failed", gate_id);
				return;
			}

			GateServerConfigInfo info;
			if (!google::protobuf::TextFormat::ParseFromString(data->front()[1], &info))
			{
				LOG_ERR("parse gate_config[%d] failed", gate_id);
				return;
			}

			cfg_db_mgr::instance()->get_db_connection_config().execute_query_vstring([session_id, gate_id, info](std::vector<std::vector<std::string>>* data) {
				if (data)
				{
					S_ReplyServerConfig reply;
					for (auto& item : *data)
					{
						auto p = reply.add_client_room_cfg();
						p->set_game_id(boost::lexical_cast<int>(item[0]));
						p->set_game_name(item[1]);
						p->set_first_game_type(boost::lexical_cast<int>(item[2]));
						p->set_second_game_type(boost::lexical_cast<int>(item[3]));
						p->set_table_count(boost::lexical_cast<int>(item[4]));
						p->set_money_limit(boost::lexical_cast<int>(item[5]));
						p->set_cell_money(boost::lexical_cast<int>(item[6]));
						p->set_tax(boost::lexical_cast<int>(item[7]));
						p->set_room_lua_cfg(item[8]);
					}

					reply.set_type(ServerSessionFromGate);
					reply.set_server_id(gate_id);
					reply.mutable_gate_config()->CopyFrom(info);

					cfg_session_mgr::instance()->send2server_pb(session_id, &reply);

				}
				else
				{
					LOG_ERR("reload cfg from db error");
				}
			}, "SELECT game_id, game_name, first_game_type, second_game_type, table_count, money_limit, cell_money, tax, room_lua_cfg FROM t_game_server_cfg WHERE is_open = 1;");
		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL get_gate_config(%d);", gate_id);
}

void cfg_session::get_db_config(int session_id, int db_id)
{
	cfg_db_mgr::instance()->get_db_connection_config().execute_query_vstring([session_id, db_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 2)
		{
			if (data->front().front() == "0")
			{
				LOG_INFO("get_db_config[%d] failed", db_id);
				return;
			}

			DBServerConfig info;
			if (!google::protobuf::TextFormat::ParseFromString(data->front()[1], &info))
			{
				LOG_ERR("parse db_config[%d] failed", db_id);
				return;
			}

			S_ReplyServerConfig reply;
			reply.set_type(ServerSessionFromLogin);
			reply.set_server_id(db_id);
			reply.mutable_db_config()->CopyFrom(info);

            cfg_session_mgr::instance()->SetPHPSign(info.php_sign_key().c_str());
			cfg_session_mgr::instance()->send2server_pb(session_id, &reply);

			S_NotifyDBServerStart notify;
			notify.set_db_id(db_id);

			// 通知game
			cfg_session_mgr::instance()->broadcast2game_pb(&notify);
			// 通知login
			cfg_session_mgr::instance()->broadcast2login_pb(&notify);

			LOG_INFO("get_db_config[%d] ok", db_id);
		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL get_db_config(%d);", db_id);

}

void cfg_session::update_gate_config(int session_id, int gate_id, int game_id)
{
	cfg_db_mgr::instance()->get_db_connection_config().execute_query_vstring([session_id, gate_id, game_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 2)
		{
			std::string ip = data->front()[0];
			int port = boost::lexical_cast<int>(data->front()[1]);

			cfg_db_mgr::instance()->get_db_connection_config().execute_query_vstring([session_id, gate_id, game_id, ip, port](std::vector<std::vector<std::string>>* data) {
				if (data)
				{
					S_ReplyUpdateGameServerConfig reply;
					for (auto& item : *data)
					{
						auto p = reply.add_client_room_cfg();
						p->set_game_id(boost::lexical_cast<int>(item[0]));
						p->set_game_name(item[1]);
						p->set_first_game_type(boost::lexical_cast<int>(item[2]));
						p->set_second_game_type(boost::lexical_cast<int>(item[3]));

						rapidjson::Document document;
						document.Parse(item[4].c_str());
						p->set_table_count(document[0]["table_count"].GetInt());
						p->set_money_limit(document[0]["money_limit"].GetInt());
						p->set_cell_money(document[0]["cell_money"].GetInt());
						p->set_tax(document[0]["tax"].GetInt());

					}

					reply.set_server_id(gate_id);
					reply.set_game_id(game_id);
					reply.set_ip(ip);
					reply.set_port(port);

					cfg_session_mgr::instance()->send2server_pb(session_id, &reply);

					LOG_INFO("update_gate_config[%d] ok", gate_id);
				}
				else
				{
					LOG_ERR("update_gate_config reload cfg from db error");
				}
			}, "SELECT game_id, game_name, first_game_type, second_game_type, room_list FROM t_game_server_cfg WHERE is_open = 1;");
		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL update_gate_config(%d,%d);", gate_id, game_id);
}

void cfg_session::update_gate_login_config(int session_id, int gate_id, int login_id)
{
	cfg_db_mgr::instance()->get_db_connection_config().execute_query_vstring([session_id, gate_id, login_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 2)
		{
			std::string ip = data->front()[0];
			int port = boost::lexical_cast<int>(data->front()[1]);

			S_ReplyUpdateLoginServerConfigByGate reply;
			
			reply.set_server_id(gate_id);
			reply.set_login_id(login_id);
			reply.set_ip(ip);
			reply.set_port(port);

			cfg_session_mgr::instance()->send2server_pb(session_id, &reply);

			LOG_INFO("update_gate_login_config[%d] ok", gate_id);
		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL update_gate_login_config(%d,%d);", gate_id, login_id);
}

void cfg_session::update_game_login_config(int session_id, int game_id, int login_id)
{
	cfg_db_mgr::instance()->get_db_connection_config().execute_query_vstring([session_id, game_id, login_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 2)
		{
			std::string ip = data->front()[0];
			int port = boost::lexical_cast<int>(data->front()[1]);

			S_ReplyUpdateLoginServerConfigByGame reply;

			reply.set_server_id(game_id);
			reply.set_login_id(login_id);
			reply.set_ip(ip);
			reply.set_port(port);

			cfg_session_mgr::instance()->send2server_pb(session_id, &reply);

			LOG_INFO("update_game_login_config[%d] ok", game_id);
		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL update_game_login_config(%d,%d);", game_id, login_id);
}

void cfg_session::update_game_db_config(int session_id, int game_id, int db_id)
{
	cfg_db_mgr::instance()->get_db_connection_config().execute_query_vstring([session_id, game_id, db_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 2)
		{
			std::string ip = data->front()[0];
			int port = boost::lexical_cast<int>(data->front()[1]);

			S_ReplyUpdateDBServerConfigByGame reply;

			reply.set_server_id(game_id);
			reply.set_db_id(db_id);
			reply.set_ip(ip);
			reply.set_port(port);

			cfg_session_mgr::instance()->send2server_pb(session_id, &reply);

			LOG_INFO("update_game_db_config[%d] ok", game_id);
		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL update_game_db_config(%d,%d);", game_id, db_id);
}

void cfg_session::update_login_db_config(int session_id, int login_id, int db_id)
{
	cfg_db_mgr::instance()->get_db_connection_config().execute_query_vstring([session_id, login_id, db_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 2)
		{
			std::string ip = data->front()[0];
			int port = boost::lexical_cast<int>(data->front()[1]);

			S_ReplyUpdateDBServerConfigByLogin reply;

			reply.set_server_id(login_id);
			reply.set_db_id(db_id);
			reply.set_ip(ip);
			reply.set_port(port);

			cfg_session_mgr::instance()->send2server_pb(session_id, &reply);

			LOG_INFO("update_login_db_config[%d] ok", login_id);
		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL update_login_db_config(%d,%d);", login_id, db_id);
}
void cfg_session::on_GF_PlayerOut(GF_PlayerOut* msg)
{
    cfg_session_mgr::instance()->ErasePlayer_Gate(msg->guid());
}
void cfg_session::on_GF_PlayerIn(GF_PlayerIn* msg)
{
    cfg_session_mgr::instance()->SetPlayer_Gate(msg->guid(), server_id_);
}
void cfg_session::on_GF_SavePlayerInfo(GF_SavePlayerInfo* msg)
{
	switch (type_)
	{
	case ServerSessionFromGame:
		{
			LOG_INFO("game server %d:%d, set player %d money %d bank %d", server_id_,port_,msg->info().guid(),msg->info().money(),msg->info().bank());
			(static_cast<cfg_server*>(base_server::instance()))->set_player_info_in_memery(msg->info());
		}
		break;
	default:
		LOG_WARN("unknown connecting request GF_SavePlayerInfo %d", type_);
		break;
	}    
}
void cfg_session::on_GF_GetPlayerInfo(GF_GetPlayerInfo* msg)
{
	switch (type_)
	{
	case ServerSessionFromGame:
		{
			auto info = (static_cast<cfg_server*>(base_server::instance()))->get_player_info_in_memery(msg->guid());
			FG_GetPlayerInfo tmp;
			auto tinfo = tmp.mutable_info();
			tinfo->CopyFrom(info);
			send_pb(&tmp);
		}
		break;
	default:
		LOG_WARN("unknown connecting request GF_GetPlayerInfo %d", type_);
		break;
	}  
}

void cfg_session::on_DF_SavePlayerInfo(DF_SavePlayerInfo* msg)
{
	switch (type_)
	{
	case ServerSessionFromDB:
		{
			LOG_INFO("db server %d:%d, set player %d money %d bank %d", server_id_,port_,msg->info().guid(),msg->info().money(),msg->info().bank());
			(static_cast<cfg_server*>(base_server::instance()))->set_player_info_in_memery(msg->info());
		}
		break;
	default:
		LOG_WARN("unknown connecting request GF_SavePlayerInfo %d", type_);
		break;
	}    
}
void cfg_session::on_DF_GetPlayerInfo(DF_GetPlayerInfo* msg)
{
	switch (type_)
	{
	case ServerSessionFromDB:
		{
			auto info = (static_cast<cfg_server*>(base_server::instance()))->get_player_info_in_memery(msg->guid());
			FD_GetPlayerInfo tmp;
			tmp.set_guid(msg->guid());
			tmp.set_account(msg->account());
			tmp.set_nickname(msg->nickname());
			tmp.set_gameid(msg->gameid());
			auto tinfo = tmp.mutable_info();
			tinfo->CopyFrom(info);
			send_pb(&tmp);
		}
		break;
	default:
		LOG_WARN("unknown connecting request GF_GetPlayerInfo %d", type_);
		break;
	}  
}
void cfg_session::on_WF_SavePlayersInfoToMySQL(WF_SavePlayersInfoToMySQL* msg)
{
	(static_cast<cfg_server*>(base_server::instance()))->begin_save_players_info_to_mysql();
	FW_SavePlayersInfoToMySQL tmp;
	tmp.set_suc(true);
	send_pb(&tmp);
}
//维护开关
void cfg_session::on_ReadMaintainSwitch(WS_MaintainUpdate* msg)
{
	int webid = get_id();
	int id = msg->id_index();
	int game_type = msg->first_game_type();
	std::string  strtemp = "";
	if (id == 1)//提现
	{
		strtemp = "cash_switch";
	}
	else if (id == 2)//游戏
	{
		strtemp = "game_switch";
		game_type = -1000;
	}
	else if (id == 3)//登录
	{
		strtemp = "login_switch";
	}
	else if (id == 4)//支付宝提现开关
	{
		strtemp = "cash_ali_switch";
	}
	else if (id == 5)//银行卡提现开关
	{
		strtemp = "cash_bank_switch";
	}
	else
	{
		LOG_ERR("unknown key[%d],return", id);
		SW_MaintainResult reply;
		reply.set_result(2);
		cfg_session_mgr::instance()->send2server_pb(webid, &reply);
	}

	cfg_db_mgr::instance()->get_db_connection_config().execute_query_string([webid, id, strtemp, game_type](std::vector<std::string>* data) {
		if (data && !data->empty())
		{
			CS_QueryMaintain queryinfo;
			
			int value_ = boost::lexical_cast<int>(data->front());//1维护中,0正常
			LOG_INFO("--------maintain-----------key = [%d][%s],value_ = %d\n", id, strtemp.c_str(), value_);
			queryinfo.set_maintaintype(id);
			queryinfo.set_switchopen(value_);
			queryinfo.set_first_game_type(game_type);
			if (id == 3)
			{	
				cfg_session_mgr::instance()->broadcast2login_pb(&queryinfo);
			}
			else
			{
				cfg_session_mgr::instance()->broadcast2game_pb(&queryinfo);
			}	
			SW_MaintainResult reply;
			reply.set_result(1);
			cfg_session_mgr::instance()->send2server_pb(webid, &reply);
			LOG_INFO("on_ReadMaintainSwitch ok...");
		}
		else   
		{
			LOG_ERR("ReadMaintainSwitch error");
			SW_MaintainResult reply;
			reply.set_result(2);
			cfg_session_mgr::instance()->send2server_pb(webid, &reply);
		}
	}, "select value from t_globle_int_cfg where `key` = '%s' ;", strtemp.c_str());
}

void cfg_session::on_WF_Cash_false(WF_Cash_false *msg)
{
    LOG_INFO("on_WF_Cash_false......order_id[%d]  web[%d]", msg->order_id(), get_id());
    FD_ChangMoney notify;
    notify.set_web_id(get_id());
    notify.set_order_id(msg->order_id());
	notify.set_type_id(LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE);
	notify.set_other_oper(msg->reason());
    bool ret = cfg_session_mgr::instance()->post_msg_to_mysql_pb(&notify);
	if (!ret)
	{
		LOG_ERR("on_WF_Cash_false  MYSQL  disconnect ......order_id[%d]  web[%d]", msg->order_id(), get_id());
	}
}
void cfg_session::on_WF_Recharge(WF_Recharge *msg)
{
	LOG_INFO("on_WF_Recharge......order_id[%d]  web[%d]", msg->order_id(), get_id());
	FD_ChangMoney notify;
	notify.set_web_id(get_id());
	notify.set_order_id(msg->order_id());
	notify.set_type_id(LOG_MONEY_OPT_TYPE_RECHARGE_MONEY);
	bool ret = cfg_session_mgr::instance()->post_msg_to_mysql_pb(&notify);
	if (!ret)
	{
		LOG_ERR("on_WF_Recharge  MYSQL  disconnect ......order_id[%d]  web[%d]", msg->order_id(), get_id());
	}
}
void cfg_session::on_DF_Reply(DF_Reply *msg)
{
    FW_Result reply;
    LOG_INFO("on_DF_Reply...... web[%d] reply[%d]", msg->web_id(), msg->result());
    reply.set_result(msg->result());
    cfg_session_mgr::instance()->send2server_pb(msg->web_id(), &reply);
}
void cfg_session::on_DF_ChangMoney(DF_ChangMoney *msg)
{
    int Gate_id = cfg_session_mgr::instance()->GetPlayer_Gate(msg->info().guid());
    LOG_INFO("on_DF_ChangMoney  web[%d] gudi[%d] order_id[%d] type[%d]", msg->web_id(), msg->info().guid(), msg->info().order_id(), msg->info().type_id());
    if (Gate_id == -1)
    {
        LOG_INFO("on_DF_ChangMoney  %d no online", msg->info().guid());
        //玩家不在线
        FD_ChangMoneyDeal nmsg;
        AddMoneyInfo * info = nmsg.mutable_info();
        info->CopyFrom(msg->info());
        nmsg.set_web_id(msg->web_id());

		bool ret = cfg_session_mgr::instance()->post_msg_to_mysql_pb(&nmsg);
		if (!ret)
		{
			LOG_ERR("on_DF_ChangMoney  Gate_id == -1  MYSQL  disconnect ,web[%d] gudi[%d] order_id[%d] type[%d]", 
				msg->web_id(), msg->info().guid(), msg->info().order_id(), msg->info().type_id());
		}
    }
    else
    {
        LOG_INFO("on_DF_ChangMoney  %d  online", msg->info().guid());
        FS_ChangMoneyDeal nmsg;
        AddMoneyInfo * info = nmsg.mutable_info();
        info->CopyFrom(msg->info());
        nmsg.set_web_id(msg->web_id());
		cfg_session_mgr::instance()->send2gate_pb(Gate_id, &nmsg);
    }
}
void cfg_session::on_FS_ChangMoneyDeal(FS_ChangMoneyDeal *msg)
{
    LOG_INFO("on_FS_ChangMoneyDeal  web[%d] gudi[%d] order_id[%d] type[%d]", msg->web_id(), msg->info().guid(), msg->info().order_id(), msg->info().type_id());
    FD_ChangMoneyDeal nmsg;
    AddMoneyInfo * info = nmsg.mutable_info();
    info->CopyFrom(msg->info());
    nmsg.set_web_id(msg->web_id());
	bool ret = cfg_session_mgr::instance()->post_msg_to_mysql_pb(&nmsg);
	if (!ret)
	{
		LOG_ERR("MYSQL  disconnect on_FS_ChangMoneyDeal  web[%d] gudi[%d] order_id[%d] type[%d]",
			msg->web_id(), msg->info().guid(), msg->info().order_id(), msg->info().type_id());
	}
}

void cfg_session::on_SS_JoinPrivateRoom(SS_JoinPrivateRoom* msg)
{
	int gateid = cfg_session_mgr::instance()->GetPlayer_Gate(msg->owner_guid() / 100);
	if (gateid == -1)
	{
		//玩家不在线
		send_pb(msg);
	}
	else
	{
		cfg_session_mgr::instance()->send2gate_pb(gateid, msg);
	}
}

//LoginServer和GameServer启动时找cfg_server请求维护开关初始值
void cfg_session::on_RequestMaintainSwitchConfig(int session_id,int game_id,int id_index)
{
	int id = id_index;
	std::string  strtemp = "";
	if (id == 1)//提现
	{
		strtemp = "cash_switch";
	}
	else if (id == 2)//游戏
	{
		strtemp = "game_switch";
	}
	else if (id == 3)//登录
	{
		strtemp = "login_switch";
	}
	else
	{
		LOG_ERR("unknown key[%d],return", id);
		return;
	}

	cfg_db_mgr::instance()->get_db_connection_config().execute_query_string([session_id,game_id, id, strtemp](std::vector<std::string>* data) {
		if (data && !data->empty())
		{
			CS_QueryMaintain queryinfo;
			int value_ = 0;
			value_ = boost::lexical_cast<int>(data->front());//value=0维护状态,等于1正常
			queryinfo.set_maintaintype(id);
			queryinfo.set_switchopen(value_);
			if (id == 3)
			{
				//cfg_session_mgr::instance()->broadcast2login_pb(&queryinfo);
				cfg_session_mgr::instance()->send2server_pb(session_id,&queryinfo);
			}
			else
			{
				//cfg_session_mgr::instance()->broadcast2game_pb(&queryinfo);
				cfg_session_mgr::instance()->post_msg_to_game_pb(game_id, &queryinfo);
			}
			
		}
		else
		{
			LOG_ERR("requestMaintainSwitchConfig error..");
			return;
		}
	}, "select value from t_globle_int_cfg where `key` = '%s' ;", strtemp.c_str());
	return;
}
