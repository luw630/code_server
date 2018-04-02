#include "gate_login_session.h"
#include "gate_client_session.h"
#include "base_game_log.h"
#include "public_enum.pb.h"
#include "gate_server.h"

gate_login_session::gate_login_session(boost::asio::io_service& ioservice)
	: base_net_session(ioservice)
{
}

gate_login_session::~gate_login_session()
{
}

bool gate_login_session::handler_connect()
{
	LOG_INFO("srv_gateway<-->srv_login connect ... <%s:%d>", ip_.c_str(), port_);

	S_Connect msg;
	msg.set_type(ServerSessionFromGate);
	msg.set_server_id(static_cast<gateway_server*>(base_server::instance())->get_gate_id());
	send_pb(&msg);

	return base_net_session::handler_connect();
}

void gate_login_session::handler_connect_failed()
{
	LOG_INFO("srv_gateway<-->srv_login connect failed ... <%s:%d>", ip_.c_str(), port_);

	base_net_session::handler_connect_failed();
}

void gate_login_session::on_closed()
{
	LOG_INFO("srv_gateway<-->srv_login close ... <%s:%d>", ip_.c_str(), port_);

	base_net_session::on_closed();
}

bool gate_login_session::handler_msg_dispatch(MsgHeader* header)
{
	if (header->id == S_Heartbeat::ID)
	{
		return true;
	}

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

				if (msg.result() == LOGIN_RESULT_SUCCESS)
				{
					session->set_guid(msg.guid());
					if (msg.game_id() != 0)
					{
						session->set_game_server_id(msg.game_id());
					}
					else
					{
						LOG_WARN("game_id=0");
					}
					gate_session_mgr::instance()->add_client_session(s);
					session->set_login(true);
				}
				else
				{
					session->reset_is_send_login();
				}
				session->send_xc(h);

				LOG_INFO("login account=%s session_id=%d ret=%d, guid=%d ok", session->get_account().c_str(), session->get_id(), msg.result(), msg.guid());
			}
			else
			{
				LOG_ERR("login err ret=%d, guid=%d", msg.result(), msg.guid());
			}
		}
		catch (const std::exception& e)
		{
			LOG_ERR("pb error:%s", e.what());
			return false;
		}
	}
	else if (h->id == S_ConnectDB::ID)
	{
		gate_session_mgr::instance()->set_first_connect_db();
	}
	/*else if (h->id == LG_OpenGameList::ID)
	{
		LG_OpenGameList msg;
		if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
		{
			LOG_ERR("ParseFromArray failed, id=%d", header->id);
			return false;
		}

		gate_session_mgr::instance()->set_open_game_list(&msg);
	}*/
	else if (h->id == LG_KickClient::ID)
	{
		try
		{
			LG_KickClient msg;
			if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
			{
				LOG_ERR("ParseFromArray failed, id=%d", header->id);
				return false;
			}

			do
			{
				auto s = gate_session_mgr::instance()->find_by_id(msg.session_id());
				if (s)
				{
					auto session = static_cast<gate_client_session*>(s.get());
					if (session->get_account() == msg.reply_account())
					{
						session->set_user_data(msg.user_data());

						LOG_WARN("player[%s] online!!session_id=%d,game_id=%d", msg.reply_account().c_str(), msg.session_id(), session->get_game_server_id());

						// 如果在线改为踢玩家
						//session->close();

						SC_KickClient kick_msg;
						kick_msg.set_result(msg.user_data());
						session->send_pb(&kick_msg);
						session->set_close_after_send(true);

						class delay_close_session_timer : public game_timer
						{
						public:
							delay_close_session_timer() : game_timer(1.5){}
							std::shared_ptr<virtual_session> m_session;
						protected:
							virtual void on_time(float delta) {
								try
								{
									if (m_session) m_session->close();
								}
								catch (...)
								{
									LOG_ERR("delay_close_session_timer EXCPTION ...");
								}
							}
						};
						auto ss_task = new delay_close_session_timer();
						ss_task->m_session = s;
						base_game_time_mgr::instance()->add_timer(ss_task);
						break;
					}
				}

				L_KickClient notify;
				notify.set_reply_account(msg.reply_account());
				notify.set_user_data(msg.user_data());
				send_pb(&notify);
			} while (false);
		}
		catch (const std::exception& e)
		{
			LOG_ERR("pb error:%s", e.what());
			return false;
		}
	}
	else if (h->id == LG_PhoneQuery::ID)
	{
		try
		{
			LG_PhoneQuery msg;
			if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
			{
				LOG_ERR("ParseFromArray failed, id=%d", header->id);
				return false;
			}
			int sid = msg.gate_session_id();
			auto s = gate_session_mgr::instance()->find_by_id(sid);
			if (s && msg.ret() == 1)
			{
				auto session = static_cast<gate_client_session*>(s.get());
				session->do_get_sms_http(msg.phone());
			}
			else if (s)
			{
				auto session = static_cast<gate_client_session*>(s.get());
				SC_RequestSms notify;
				notify.set_result(LOGIN_RESULT_TEL_USED);
				session->send_pb(&notify);
			}
		}
		catch (const std::exception& e)
		{
			LOG_ERR("pb error:%s", e.what());
			return false;
		}
	}
	else if (h->id == SC_RequestSms::ID)
	{
		// 登录成功通知消息
		auto s = gate_session_mgr::instance()->find_by_id(h->guid);
		if (s)
		{
			auto session = static_cast<gate_client_session*>(s.get());

			try
			{
				SC_RequestSms msg;
				if (!msg.ParseFromArray(h + 1, h->len - sizeof(GateMsgHeader)))
				{
					LOG_ERR("ParseFromArray failed, id=%d", header->id);
					return false;
				}

				if (msg.result() == LOGIN_RESULT_SUCCESS)
				{
					session->set_sms(msg.tel(), msg.sms_no());
				}

				session->send_xc(h);
			}
			catch (const std::exception& e)
			{
				LOG_ERR("pb error:%s", e.what());
				return false;
			}
		}
	}
    else if (h->id == DL_ServerConfig::ID)
    {
		try
		{
			DL_ServerConfig msg;
			if (!msg.ParseFromArray(header + 1, h->len - sizeof(MsgHeader)))
			{
				LOG_ERR("ParseFromArray failed, id=%d", header->id);
				return false;
			}
			static_cast<gateway_server*>(base_server::instance())->reload_gameserver_config(msg);
		}
		catch (const std::exception& e)
		{
			LOG_ERR("pb error:%s", e.what());
			return false;
		}
    }
    else if (h->id == LG_DBGameConfigMgr::ID)
    {
		try
		{
			LG_DBGameConfigMgr msg;
			if (!msg.ParseFromArray(header + 1, h->len - sizeof(MsgHeader)))
			{
				LOG_ERR("ParseFromArray failed, id=%d", header->id);
				return false;
			}
			static_cast<gateway_server*>(base_server::instance())->reload_gameserver_config_DB(msg);
		}
		catch (const std::exception& e)
		{
			LOG_ERR("pb error:%s", e.what());
			return false;
		}
    }
    else if (h->id == LG_NewNotice::ID){
		try
		{
			LG_NewNotice msg;
			if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
			{
				RetWebCode(GMmessageRetCode::GMmessageRetCode_MsgGateDataError, msg.retid());
				LOG_ERR("ParseFromArray failed, id=%d", header->id);
				return false;
			}
			auto s = gate_session_mgr::instance()->get_client_session(msg.guid());
			//得到玩家session
			if (s)
			{
				//通知玩家
				SC_NewMsgData notify;
				Msg_DataInfo * msgdata = notify.add_pb_msg_data();
				msgdata->set_id(msg.id());
				msgdata->set_start_time(msg.start_time());
				msgdata->set_end_time(msg.end_time());
				msgdata->set_msg_type(msg.msg_type());
				msgdata->set_is_read(1);
				msgdata->set_content(msg.content());
				//s->send_spb(SC_NewMsgData::ID, notify.SerializeAsString());
				s->send_pb(&notify);

				RetWebCode(GMmessageRetCode::GMmessageRetCode_Success, msg.retid());
				LOG_INFO("LG_NewNotice proc success session :[%d]", s->get_id());
			}
			else {
				RetWebCode(GMmessageRetCode::GMmessageRetCode_Msgnofindsession, msg.retid());
				LOG_ERR("no find guid :[%d]", msg.guid());
			}
		}
		catch (const std::exception& e)
		{
			LOG_ERR("pb error:%s", e.what());
			return false;
		}
    }
    else if (h->id == LG_DelNotice::ID){
		try
		{
			LG_DelNotice msg;
			if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
			{
				RetWebCode(GMmessageRetCode::GMmessageRetCode_MsgGateDataError, msg.retid());
				LOG_ERR("ParseFromArray failed, id=%d", header->id);
				return false;
			}
			auto s = gate_session_mgr::instance()->get_client_session(msg.guid());
			//得到玩家session
			if (s)
			{
				//通知玩家
				SC_DeletMsg notify;
				notify.set_msg_id(msg.msg_id());
				notify.set_msg_type(msg.msg_type());
				s->send_pb(&notify);
				RetWebCode(GMmessageRetCode::GMmessageRetCode_Success, msg.retid());
				LOG_INFO("LG_NewNotice proc success session :[%d]", s->get_id());
			}
			else {
				RetWebCode(GMmessageRetCode::GMmessageRetCode_Msgnofindsession, msg.retid());
				LOG_ERR("no find guid :[%d]", msg.guid());
			}
		}
		catch (const std::exception& e)
		{
			LOG_ERR("pb error:%s", e.what());
			return false;
		}
    }
    else if (h->id == LG_FeedBackUpdate::ID){
		try
		{
			LG_FeedBackUpdate msg;
			if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
			{
				RetWebCode(GMmessageRetCode::GMmessageRetCode_FBGateDataError, msg.retid());
				LOG_ERR("ParseFromArray failed, id=%d", header->id);
				return false;
			}
			auto s = gate_session_mgr::instance()->get_client_session(msg.guid());
			if (s)
			{
				//通知玩家
				SC_FeedBackUpDate notify;
				notify.set_type(msg.type());
				notify.set_updatetime(msg.updatetime());
				notify.set_feedbackid(msg.feedbackid());
				s->send_pb(&notify);
				RetWebCode(GMmessageRetCode::GMmessageRetCode_Success, msg.retid());
				LOG_INFO("LG_NewNotice proc success session :[%d]", s->get_id());
			}
			else {
				RetWebCode(GMmessageRetCode::GMmessageRetCode_Msgnofindsession, msg.retid());
				LOG_ERR("no find guid :[%d]", msg.guid());
			}
		}
		catch (const std::exception& e)
		{
			LOG_ERR("pb error:%s", e.what());
			return false;
		}
    }
    else if (h->id == LG_AddNewGameServer::ID){
		try
		{
			LG_AddNewGameServer msg;
			if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
			{
				RetWebCode(GMmessageRetCode::GMmessageRetCode_MsgGateDataError, msg.retid());
				LOG_ERR("ParseFromArray failed, id=%d", header->id);
				return false;
			}
			gate_session_mgr::instance()->Add_Game_Server_Session(msg.ip(), msg.port());
		}
		catch (const std::exception& e)
		{
			LOG_ERR("pb error:%s", e.what());
			return false;
		}
    }
	else
	{
		auto s = gate_session_mgr::instance()->get_client_session(h->guid);
		if (s)
		{
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

					if (msg.has_game_id())
						session->set_game_server_id(msg.game_id());
					if (session->get_game_server_id() == 0)
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
void gate_login_session::RetWebCode(int retCode, int retid){
    GL_NewNotice notify;
    notify.set_result(retCode);
    notify.set_retid(retid);
    send_pb(&notify);
}

