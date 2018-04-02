#include "gate_game_session.h"
#include "gate_client_session.h"
#include "base_game_log.h"
#include "public_enum.pb.h"
#include "gate_server.h"

gate_game_session::gate_game_session(boost::asio::io_service& ioservice)
	: base_net_session(ioservice)
    , server_id_(0)
{
}

gate_game_session::~gate_game_session()
{
}

bool gate_game_session::handler_connect()
{
	LOG_INFO("srv_gateway<-->srv_game connect ... <%s:%d>", ip_.c_str(), port_);

	S_Connect msg;
	msg.set_type(ServerSessionFromGate);
	msg.set_server_id(static_cast<gateway_server*>(base_server::instance())->get_gate_id());
	send_pb(&msg);

	return base_net_session::handler_connect();
}

void gate_game_session::handler_connect_failed()
{
	LOG_INFO("srv_gateway<-->srv_game connect failed ... <%s:%d>", ip_.c_str(), port_);

	base_net_session::handler_connect_failed();
}

bool gate_game_session::handler_msg_dispatch(MsgHeader* header)
{
	if (header->id == S_Heartbeat::ID)
	{
		return true;
	}

	if (header->id == S_Connect::ID)
	{
		try
		{
			S_Connect msg;
			if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
			{
				LOG_ERR("ParseFromArray failed, id=%d", header->id);
				return false;
			}
			
			server_id_ = msg.server_id();
			LOG_INFO("S_Connect  game_id=%d", server_id_);
			gate_session_mgr::instance()->add_game_id(server_id_);

			GC_GameServerCfg notify;
			for (auto& item : static_cast<gateway_server*>(base_server::instance())->get_gamecfg().pb_cfg())
			{
				if (gate_session_mgr::instance()->in_open_game_list(item.game_id()))
				{
					notify.add_pb_cfg()->CopyFrom(item);
				}
			}

			gate_session_mgr::instance()->broadcast_client(&notify);
		}
		catch (const std::exception& e)
		{
			LOG_ERR("pb error:%s", e.what());
			return false;
		}
	}
	else
	{
		GateMsgHeader* h = static_cast<GateMsgHeader*>(header);

		if (h->id == LC_Login::ID)
		{
			// 登录成功通知消息
			try
			{
				LC_Login msg;
				if (!msg.ParseFromArray(h + 1, h->len - sizeof(GateMsgHeader)))
				{
					LOG_ERR("ParseFromArray failed, id=%d", header->id);
					return false;
				}

				auto s = gate_session_mgr::instance()->find_by_id(h->guid);
				if (s)
				{
					auto session = static_cast<gate_client_session*>(s.get());

					session->set_guid(msg.guid());
					if (msg.game_id() != 0)
					{
						session->set_game_server_id(msg.game_id());
					}
					else
					{
						LOG_WARN("game_id=0");
					}
					if (msg.is_guest())
					{
						session->set_account(msg.account());
					}
					gate_session_mgr::instance()->add_client_session(s);

					session->send_xc(h);
					session->set_login(true);

					
                    if (msg.result() == LOGIN_RESULT_SUCCESS)
                    {
                        GF_PlayerIn nmsg;
                        nmsg.set_guid(msg.guid());
                        gate_cfg_net_server::instance()->post_msg_to_cfg_pb(&nmsg);
                    }
				}
				else
				{
					LOG_ERR("login err guid:%d", msg.guid());
				}
			}
			catch (const std::exception& e)
			{
				LOG_ERR("pb error:%s", e.what());
				return false;
			}
		}
        else
		{
			if (h->len > 10240)
			{
				LOG_ERR("msg guid [%d] id [%d] len [%d] too long", h->guid, header->id, h->len);
			}
			auto s = gate_session_mgr::instance()->get_client_session(h->guid);
			if (!s)
			{
				LOG_WARN("msg[%d] guid[%d] not find", h->id, h->guid);
				return true;
			}

			auto session = static_cast<gate_client_session*>(s.get());

			if (header->id == SC_EnterRoomAndSitDown::ID)
			{
				try
				{
					SC_EnterRoomAndSitDown msg;
					if (!msg.ParseFromArray(h + 1, h->len - sizeof(GateMsgHeader)))
					{
						LOG_ERR("ParseFromArray failed, id=%d", header->id);
						return false;
					}

					if (msg.game_id() != 0)
					{
						session->set_game_server_id(msg.game_id());
						session->set_first_game_type(msg.first_game_type());
						session->set_second_game_type(msg.second_game_type());
						session->set_private_room_score_type(msg.private_room_score_type());
					}
					else
					{
						LOG_WARN("game_id=0");
					}
				}
				catch (const std::exception& e)
				{
					LOG_ERR("pb error:%s", e.what());
					return false;
				}
			}
			else if (header->id == SC_PlayerReconnection::ID)
			{
				try
				{
					SC_PlayerReconnection msg;
					if (!msg.ParseFromArray(h + 1, h->len - sizeof(GateMsgHeader)))
					{
						LOG_ERR("ParseFromArray failed, id=%d", header->id);
						return false;
					}

					if (msg.game_id() != 0)
					{
						session->set_game_server_id(msg.game_id());
					}
					else
					{
						LOG_WARN("game_id=0");
					}
				}
				catch (const std::exception& e)
				{
					LOG_ERR("pb error:%s", e.what());
					return false;
				}
			}
			else if (header->id == SC_ChangeTable::ID)
			{
				try
				{
					SC_ChangeTable msg;
					if (!msg.ParseFromArray(h + 1, h->len - sizeof(GateMsgHeader)))
					{
						LOG_ERR("ParseFromArray failed, id=%d", header->id);
						return false;
					}

					if (msg.game_id() != 0)
					{
						session->set_game_server_id(msg.game_id());
					}
					else
					{
						LOG_WARN("game_id=0");
					}
				}
				catch (const std::exception& e)
				{
					LOG_ERR("pb error:%s", e.what());
					return false;
				}
			}

			session->send_xc(h);
		}
	}
	return true;
}



void gate_game_session::on_closed()
{
	LOG_INFO("srv_gateway<-->srv_game close ... <%s:%d>", ip_.c_str(), port_);

	gate_session_mgr::instance()->remove_game_id(server_id_);

    // 断线处理
	for (auto& item : static_cast<gateway_server*>(base_server::instance())->get_gamecfg().pb_cfg())
    {
        if (item.game_id() == server_id_)
		{
			GC_GameServerCfg notify;
			for (auto& item : static_cast<gateway_server*>(base_server::instance())->get_gamecfg().pb_cfg())
			{
				if (gate_session_mgr::instance()->in_open_game_list(item.game_id()))
				{
					notify.add_pb_cfg()->CopyFrom(item);
				}
			}

			gate_session_mgr::instance()->broadcast_client(&notify);

			break;
        }
    }
	base_net_session::on_closed();
}
