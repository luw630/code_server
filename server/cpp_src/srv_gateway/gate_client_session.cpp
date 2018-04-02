#include "gate_client_session.h"
#include "gate_login_session.h"
#include "gate_game_session.h"
#include "base_game_log.h"
#include "base_game_time_mgr.h"
#include "base_utils_helper.h"
#include "public_enum.pb.h"
#ifdef PLATFORM_LINUX
#include "../../depend/iconv/iconv.h"
#endif
#include "ip_mgr.h"
#include "../base_lib/base_asyn_task_mgr.h"
#include "../base_lib/base_http_request.h"
#include "gate_server.h"

gate_client_session::gate_client_session(boost::asio::ip::tcp::socket& sock)
	: virtual_session(sock)
	, port_(0)
	, guid_(0)
	, game_server_id_(0)
	, first_game_type_(0)
	, second_game_type_(0)
	, private_room_score_type_(0)
	, user_data_(0)
	, timeout_limit_(0)
	//, last_msg_time_(0)
	, last_sms_time_(0)
	, last_sms_req_time_(0)
	, is_send_login_(false)
{
	timeout_limit_ = static_cast<gateway_server*>(base_server::instance())->get_config().timeout_limit();
	sms_time_limit_ = static_cast<gateway_server*>(base_server::instance())->get_config().sms_time_limit();
}

gate_client_session::~gate_client_session()
{
}
void gate_client_session::on_closed()
{
	LOG_INFO("session disconnect ... <%s:%d>", real_ip_.c_str(), port_);

	if (!is_send_login_)
	{
		// ??????????????
		return;
	}

	S_Logout msg;
	msg.set_user_data(user_data_);

	if (guid_ == 0)
	{
		msg.set_session_id(get_id());
		msg.set_gate_id(static_cast<gateway_server*>(base_server::instance())->get_gate_id());
	}
	else
	{
		msg.set_guid(guid_);
	}
	if (!account_.empty())
	{
		msg.set_account(account_);
	}

	if (game_server_id_ == 0)
	{
		auto session = gate_session_mgr::instance()->get_login_session();
		if (session && session->is_connect())
		{
			session->send_pb(&msg);
		}
		else
		{
			LOG_WARN("login server disconnect");
		}
	}
	else // ????????????????????
	{
		auto session = gate_session_mgr::instance()->get_game_session(game_server_id_);
		if (session && session->is_connect())
		{
			session->send_pb(&msg);
		}
		else
		{
			LOG_WARN("game server[%d] disconnect", game_server_id_);
		}
	}

	GF_PlayerOut nmsg;
	nmsg.set_guid(guid_);
	gate_cfg_net_server::instance()->post_msg_to_cfg_pb(&nmsg);
	if (user_data_ == 0)
	{
		gate_session_mgr::instance()->remove_client_session(guid_, get_id());
	}
	user_data_ = 0;
}

bool gate_client_session::tick()
{
	if (socket_.is_open())
	{
		// ???
		if (last_msg_time_ == 0)
		{
			last_msg_time_ = base_game_time_mgr::instance()->get_second_time();
		}
		else if (base_game_time_mgr::instance()->get_second_time() - last_msg_time_ > timeout_limit_)
		{
			LOG_WARN("time out close socket, ip[%s] port[%d],session_id=%d", real_ip_.c_str(), port_, get_id());
			socket_.close();
			return true;
		}

		post();
		return true;
	}

	LOG_INFO("tick socket closed");
	on_closed();
	return false;
}

bool gate_client_session::handler_msg_dispatch(MsgHeader* header)
{
	last_msg_time_ = base_game_time_mgr::instance()->get_second_time();

	switch (header->id)
	{
	case C_RequestPublicKey::ID:
		if (!on_C_RequestPublicKey(header))
			return false;
		break;
	case CL_RegAccount::ID:
		if (!on_CL_RegAccount(header))
			return false;
		break;
	case CL_Login::ID:
		if (!on_CL_Login(header))
			return false;
		break;
	case CL_LoginBySms::ID:
		if (!on_CL_LoginBySms(header))
			return false;
		break;
	case CS_RequestSms::ID:
		if (!on_CS_RequestSms(header))
			return false;
		break;
	case CG_GameServerCfg::ID:
		if (!on_CG_GameServerCfg(header))
			return false;
		break;
	case CL_GetInviterInfo::ID:
		if (!on_CL_GetInviterInfo(header))
			return false;
		break;
	case CS_SetNickname::ID:
		if (!on_CS_SetNickname(header))
			return false;
		break;
	case CS_ResetAccount::ID:
		if (!on_CS_ResetAccount(header))
			return false;
		break;
	case CS_SetPassword::ID:
		if (!on_CS_SetPassword(header))
			return false;
		break;
	case CS_SetPasswordBySms::ID:
		if (!on_CS_SetPasswordBySms(header))
			return false;
		break;
	case CS_BankSetPassword::ID:
		if (!on_CS_BankSetPassword(header))
			return false;
		break;
	case CS_BankChangePassword::ID:
		if (!on_CS_BankChangePassword(header))
			return false;
		break;
	case CS_BankLogin::ID:
		if (!on_CS_BankLogin(header))
			return false;
		break;
	case CS_ChatWorld::ID:
	{
		auto session = gate_session_mgr::instance()->get_login_session();
		if (session && session->is_connect())
		{
			session->send_cx(get_guid(), header);
		}
		else
		{
			LOG_WARN("login server disconnect");
		}
	}
		break;
    case CS_HEARTBEAT::ID:
	{
		if (m_islogin && game_server_id_ != 0)
		{
			auto s = gate_session_mgr::instance()->get_game_session(game_server_id_);
			if (s)
			{
				gate_game_session* session = static_cast<gate_game_session*>(s.get());
				if (session->is_connected())
				{
					SC_HEARTBEAT msg;
					msg.set_severtime(base_game_time_mgr::instance()->get_second_time());
					send_pb(&msg);
				}
				else
				{
					LOG_WARN("game_id=%d connect state error:%d", game_server_id_, session->get_connect_state());
				}
			}
			else
			{
				LOG_WARN("game_id=%d not connect", game_server_id_);
			}
		}
		else
		{
			SC_HEARTBEAT msg;
			msg.set_severtime(base_game_time_mgr::instance()->get_second_time());
			send_pb(&msg);
		}
	}
	break;
	default:
	{
		if (game_server_id_ == 0)
		{
			LOG_WARN("game_id == 0");
			return false;
		}

		auto session = gate_session_mgr::instance()->get_game_session(game_server_id_);
		if (session && session->is_connect())
		{
			session->send_cx(get_guid(), header);
		}
		else
		{
			LOG_WARN("game server[%d] disconnect", game_server_id_);
		}
	}
		break;
	}

	return true;
}

bool gate_client_session::handler_accept()
{
	port_ = get_remote_ip_port(ip_);
	LOG_INFO("accept session ... <%s:%d>", ip_.c_str(), port_);

	// GC_GameServerCfg
	/*GC_GameServerCfg notify;
	for (auto& item : static_cast<GateServer*>(base_server::instance())->get_gamecfg().pb_cfg())
	{
		if (gate_session_mgr::instance()->in_open_game_list(item.game_id()))
		{
			notify.add_pb_cfg()->CopyFrom(item);
		}
	}*/
	/*for (auto& item : gate_cfg_mgr::instance()->get_gameserver_config().pb_cfg())
	{
		if (gate_session_mgr::instance()->in_open_game_list(item.game_id()))
		{
			//notify.add_pb_cfg()->CopyFrom(item);
			auto p = notify.add_pb_cfg();
			p->set_game_id(item.game_id());
			p->set_second_game_type(item.second_game_type());
			p->set_first_game_type(item.first_game_type());
			p->set_game_name(item.game_name());
			if (item.pb_room_list_size() > 0)
			{
				auto room_list_info = item.pb_room_list(0);
				p->set_table_count(room_list_info.table_count());
				p->set_money_limit(room_list_info.money_limit());
				p->set_cell_money(room_list_info.cell_money());
				p->set_tax(room_list_info.tax());
			}
		}
	}*/
	
	/*send_pb(&notify);
	
	// C_PublicKey
	std::string public_key;
	crypto_manager::rsa_key(public_key, private_key_);

	C_PublicKey msg;
	msg.set_public_key(crypto_manager::to_hex(public_key));
	send_pb(&msg);*/

	return true;
}

std::string get_real_ip(const std::string& change_ip)
{
	std::string real_ip("113.125.40.36");//"山东省济南市"
	try
	{
		if (!change_ip.empty())
		{
			std::vector<std::string> ip_littel;
			boost::split(ip_littel, change_ip, boost::is_any_of("-"));
			if (ip_littel.size() == 4 && ip_littel[0].size() == 12 && 
				ip_littel[1].size() == 12 && ip_littel[2].size() == 12 && ip_littel[3].size() == 12)
			{
				std::string x_3_str = ip_littel[0].substr(3, 3);
				int x_3 = atoi(x_3_str.c_str());
				std::string x_2_str = ip_littel[1].substr(3, 3);
				int x_2 = atoi(x_2_str.c_str());
				std::string x_4_str = ip_littel[2].substr(3, 3);
				int x_4 = atoi(x_4_str.c_str());
				std::string x_1_str = ip_littel[3].substr(3, 3);
				int x_1 = atoi(x_1_str.c_str());
				
				std::string ip_3_str = ip_littel[0].substr(6, 3);
				int ip_3 = atoi(ip_3_str.c_str()) - x_1;
				std::string ip_2_str = ip_littel[1].substr(6, 3);
				int ip_2 = atoi(ip_2_str.c_str()) - x_2;
				std::string ip_4_str = ip_littel[2].substr(6, 3);
				int ip_4 = atoi(ip_4_str.c_str()) - x_3;
				std::string ip_1_str = ip_littel[3].substr(6, 3);
				int ip_1 = atoi(ip_1_str.c_str()) - x_4;
				
				if ((x_4 > x_3 && x_3 > x_2 && x_2 > x_1) && (ip_1 >= 0 && ip_1 <= 255) && (ip_2 >= 0 && ip_2 <= 255)
					&& (ip_3 >= 0 && ip_3 <= 255) && (ip_4 >= 0 && ip_4 <= 255))
				{
					char buff[128] = {0};
					sprintf(buff, "%d.%d.%d.%d", ip_1, ip_2, ip_3, ip_4);
					real_ip.clear();
					real_ip.append(buff);
				}
				else
				{
					LOG_ERR("get_real_ip error");
					LOG_ERR(change_ip.c_str());
				}
			}
		}
	}
	catch (...)
	{
		LOG_ERR("get_real_ip EXP");
		LOG_ERR(change_ip.c_str());
	}
	return real_ip;
}

bool gate_client_session::on_C_RequestPublicKey(MsgHeader* header)
{
	try
	{
		C_RequestPublicKey msg_RequestPublicKey;
		if (!msg_RequestPublicKey.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
		{
			LOG_ERR("ParseFromArray failed, id=%d", header->id);
			return false;
		}
		
		channel_id_.assign(msg_RequestPublicKey.channel_id());
		version_.assign(msg_RequestPublicKey.version());
		real_ip_.assign(get_real_ip(msg_RequestPublicKey.re_ip()));
		android_uid_ = msg_RequestPublicKey.android_uid(); //渠道ID
		android_pid_ = msg_RequestPublicKey.android_pid(); //渠道父ID
		std::string public_key;
		static_cast<gateway_server*>(base_server::instance())->get_rsa_key(public_key, private_key_);

		C_PublicKey msg;
		msg.set_public_key(crypto_manager::to_hex(public_key));
		send_pb(&msg);
		LOG_INFO("channel_id_ %s, version_ %s, real_ip_ %s, android_uid_ %d, android_pid_ %d", channel_id_.c_str(), version_.c_str(),
			real_ip_.c_str(), android_uid_, android_pid_);

		return true;
	}
	catch (const std::exception& e)
	{
		LOG_ERR("request publicKey error:%s", e.what());
		return false;
	}
}
bool open_for_channel(std::string & channel,int game_id)
{
	std::vector<ClientChannelInfo>& ClientChannelInfo_list_ = gate_session_mgr::instance()->get_ClientChannelInfo();
	for (auto item : ClientChannelInfo_list_)
	{
		if (item.channel() == "open_for_all_channel")
		{
			if (!item.open_server_list().empty())
			{
				return true;
			}
		}
	}
	for (auto item : ClientChannelInfo_list_)
	{
		if (item.channel() == channel)
		{
			for (int id : item.open_server_list())
			{
				if (game_id == id)
				{
					return true;
				}
			}
			return false;
		}
	}
	return true;
}
bool gate_client_session::on_CG_GameServerCfg(MsgHeader* header)
{
	GC_GameServerCfg notify;
	for (auto& item : static_cast<gateway_server*>(base_server::instance())->get_gamecfg().pb_cfg())
	{
		if (open_for_channel(channel_id_, item.game_id()) && gate_session_mgr::instance()->in_open_game_list(item.game_id()))
		{
			notify.add_pb_cfg()->CopyFrom(item);
		}
	}

	send_pb(&notify);

	return true;
}

bool gate_client_session::on_CL_GetInviterInfo(MsgHeader* header)
{
	try
	{
		CL_GetInviterInfo msg;
		if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
		{
			LOG_ERR("ParseFromArray failed, id=%d", header->id);
			return false;
		}
		if (!msg.has_invite_code())
		{
			LOG_ERR("no invite_code, id=%d", header->id);
			return false;
		}
		msg.set_guid(guid_);
		gate_session_mgr::instance()->post_msg_to_login_pb(get_id(), &msg);
	}
	catch (const std::exception& e)
	{
		LOG_ERR("pb error:%s", e.what());
		return false;
	}
	return true;
}
bool gate_client_session::on_CL_RegAccount(MsgHeader* header)
{
	if (is_send_login_)
	{
		LOG_WARN("send login repeated");
		return true;
	}
	try
	{
		CL_RegAccount msg;
		if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
		{
			LOG_ERR("ParseFromArray failed, id=%d", header->id);
			return false;
		}

		if (!msg.has_phone())
		{
			LOG_ERR("no phone, id=%d", header->id);
			return false;
		}

		if (msg.has_password())
		{
			std::string password = crypto_manager::rsa_decrypt(private_key_, crypto_manager::from_hex(msg.password()));
			if (!check_string(password))
			{
				LOG_ERR("password error %s", msg.password().c_str());
				return false;
			}

			msg.set_password(password);
		}

		// ???????
		if (msg.has_account())
		{
			if (!check_string(msg.account()))
			{
				LOG_ERR("no account, id=%d", header->id);
				return false;
			}

			account_ = msg.account();
		}

		std::string ip = real_ip_;
		//get_remote_ip_port(ip);
		msg.set_ip(ip);
		LOG_INFO("set_ip = %s", msg.ip().c_str());
		msg.set_ip_area(ip_mgr::instance()->get_ip_area_str(ip));
		LOG_INFO("set_ip_area = %s", msg.ip_area().c_str());
		msg.set_android_uid(android_uid_);
		msg.set_android_pid(android_pid_);
		//gate_session_mgr::instance()->post_msg_to_login_pb(get_id(), &msg);
		gate_session_mgr::instance()->add_CL_RegAccount(get_id(), msg);

		is_send_login_ = true;
	}
	catch (const std::exception& e)
	{
		LOG_ERR("pb error:%s", e.what());
		return false;
	}
	return true;
}

bool gate_client_session::on_CL_Login(MsgHeader* header)
{
	if (is_send_login_)
	{
		LOG_WARN("send login repeated");
		return true;
	}
	try
	{
		CL_Login msg;
		if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
		{
			LOG_ERR("ParseFromArray failed, id=%d", header->id);
			return false;
		}

		if (!msg.has_account() || !check_string(msg.account()))
		{
			LOG_ERR("no account, id=%d", header->id);
			return false;
		}

		if (gate_session_mgr::instance()->check_login_quque_account(msg.account()))
		{
			LC_Login reply;
			reply.set_result(LOGIN_RESULT_LOGIN_QUQUE);
			send_pb(&reply);
			return true;
		}

		if (msg.has_password())
		{
			std::string password = crypto_manager::rsa_decrypt(private_key_, crypto_manager::from_hex(msg.password()));
			if (!check_string(password))
			{
				LOG_ERR("password error %s", msg.password().c_str());

				LC_Login reply;
				reply.set_result(LOGIN_RESULT_ACCOUNT_PASSWORD_ERR);
				send_pb(&reply);
				return true;
			}

			msg.set_password(password);
		}
		else
		{
			LOG_ERR("no password, id=%d", header->id);
			return false;
		}

		std::string ip = real_ip_;
		//get_remote_ip_port(ip);
		msg.set_ip(ip);
		LOG_INFO("set_ip = %s", msg.ip().c_str());
		// ???????
		account_ = msg.account();
		msg.set_ip_area(ip_mgr::instance()->get_ip_area_str(ip));
		LOG_INFO("set_ip_area = %s", msg.ip_area().c_str());
		// ?????????guid????????????
		//gate_session_mgr::instance()->post_msg_to_login_pb(get_id(), &msg);
		gate_session_mgr::instance()->add_CL_Login(get_id(), msg);

		is_send_login_ = true;
	}
	catch (const std::exception& e)
	{
		LOG_ERR("pb error:%s", e.what());
		return false;
	}
	return true;
}

bool gate_client_session::on_CL_LoginBySms(MsgHeader* header)
{
	if (is_send_login_)
	{
		LOG_WARN("send login repeated");
		return true;
	}
	try
	{
		CL_LoginBySms msg;
		if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
		{
			LOG_ERR("ParseFromArray failed, id=%d", header->id);
			return false;
		}

		if (!msg.has_account() || !check_string(msg.account()))
		{
			LOG_ERR("no account, id=%d", header->id);
			return false;
		}

		if (gate_session_mgr::instance()->check_login_quque_account(msg.account()))
		{
			LC_Login reply;
			reply.set_result(LOGIN_RESULT_LOGIN_QUQUE);
			send_pb(&reply);
			return true;
		}

		if (msg.account() != tel_.c_str() || sms_no_.empty() || msg.sms_no() != sms_no_)
		{
			LC_Login reply;
			reply.set_result(LOGIN_RESULT_SMS_FAILED);
			send_pb(&reply);
		}
		else
		{
			clear_sms();
			std::string ip = real_ip_;
			//get_remote_ip_port(ip);
			msg.set_ip(ip);
			LOG_INFO("set_ip = %s", msg.ip().c_str());
			// ???????
			account_ = msg.account();
			msg.set_ip_area(ip_mgr::instance()->get_ip_area_str(ip));
			//gate_session_mgr::instance()->post_msg_to_login_pb(get_id(), &msg);
			gate_session_mgr::instance()->add_CL_LoginBySms(get_id(), msg);

			is_send_login_ = true;
		}
	}
	catch (const std::exception& e)
	{
		LOG_ERR("pb error:%s", e.what());
		return false;
	}

	return true;
}
#ifdef _DEBUG
#define MSG_DEBUG_MODE
#endif
void gate_client_session::do_get_sms_http(const std::string& phone)
{
	class get_sms_task : public AsynTask
	{
	public:
		void execute_task_handler()
		{
			m_code_ret.clear();
			std::string code_err;
			std::string split("--------------------------675526169953038878040223");
			if (AsioHttpPost_AllMsg(gate_session_mgr::instance()->get_net_server()->get_io_server_pool().get_io_service(),
				static_cast<gateway_server*>(base_server::instance())->get_config().sms_url(), m_msg, m_code_ret, code_err, split))
			{

			}
		};
		void finish_task_handler()
		{
			SC_RequestSms notify;
#ifdef MSG_DEBUG_MODE
			notify.set_result(LOGIN_RESULT_SUCCESS);
			notify.set_tel(m_tel);
			if (m_gate_client_session)
			{
				gate_client_session* p = dynamic_cast<gate_client_session*>(m_gate_client_session.get());
				if (p) p->set_sms(m_tel, m_sms_no);
			}
#else
			if (m_code_ret.empty())
			{
				notify.set_result(LOGIN_RESULT_SMS_FAILED);
				LOG_ERR("SC_RequestSms failed, code_ret empty,phone=%s", m_tel.c_str());
			}
			else
			{
				if (m_code_ret.find("\"status\":\"1\"") != std::string::npos)
				{
					notify.set_result(LOGIN_RESULT_SUCCESS);
					notify.set_tel(m_tel);
					if (m_gate_client_session)
					{
						gate_client_session* p = dynamic_cast<gate_client_session*>(m_gate_client_session.get());
						if (p) p->set_sms(m_tel, m_sms_no);
					}
				}
				else
				{
					notify.set_result(LOGIN_RESULT_SMS_FAILED);
					LOG_ERR("SC_RequestSmsfailed, code_ret=%s,phone=%s", m_code_ret.c_str(), m_tel.c_str());
				}
			}
#endif			
			if (m_gate_client_session)
			{
				m_gate_client_session->send_pb(&notify);
			}
		};

		std::string m_msg;
		std::string m_tel;
		std::string m_sms_no;
		std::string m_code_ret;
		std::shared_ptr<virtual_session> m_gate_client_session;
	};
	std::string sms_sign_key_ = static_cast<gateway_server*>(base_server::instance())->get_config().sms_sign_key();
	
	std::shared_ptr<get_sms_task> sms_task = std::make_shared<get_sms_task>();
	int r = rand() % 1000 + (rand() % 1000) * 1000;
	sms_task->m_gate_client_session = shared_from_this();
	sms_task->m_tel = phone;
#ifdef MSG_DEBUG_MODE
	sms_task->m_sms_no = "123456";
#else
	sms_task->m_sms_no = str(boost::format("%06d") % r);
#endif
	
	std::string sing_src;
	sing_src.append("phone=").append(phone).append("&").append("code=").append(sms_task->m_sms_no).append(sms_sign_key_);
	std::string sing = crypto_manager::md5(sing_src);

	sms_task->m_msg.clear();
	sms_task->m_msg.append("----------------------------675526169953038878040223\r\n")
		.append("Content-Disposition: form-data; name=\"phone\"")
		.append("\r\n\r\n")
		.append(sms_task->m_tel)
		.append("\r\n")
		.append("----------------------------675526169953038878040223\r\n")
		.append("Content-Disposition: form-data; name=\"code\"")
		.append("\r\n\r\n")
		.append(sms_task->m_sms_no)
		.append("\r\n")
		.append("----------------------------675526169953038878040223\r\n")
		.append("Content-Disposition: form-data; name=\"sign\"")
		.append("\r\n\r\n")
		.append(sing)
		.append("\r\n")
		.append("----------------------------675526169953038878040223--\r\n");

	base_asyn_task_mgr::instance()->add_task(sms_task);

	last_sms_req_time_ = base_game_time_mgr::instance()->get_second_time();
}
bool gate_client_session::on_CS_RequestSms(MsgHeader* header)
{
	if (base_game_time_mgr::instance()->get_second_time() - last_sms_time_ < sms_time_limit_)
	{
		SC_RequestSms notify;
		notify.set_result(LOGIN_RESULT_SMS_REPEATED);
		send_pb(&notify);
	}
	else
	{
		if (base_game_time_mgr::instance()->get_second_time() - last_sms_req_time_ < 2)
		{
			LOG_ERR("client  request msg too fast...");
			return true;
		}
		try
		{
			CS_RequestSms msg;
			if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
			{
				LOG_ERR("ParseFromArray failed, id=%d", header->id);
				return false;
			}
			if (!msg.has_tel())
			{
				SC_RequestSms notify;
				notify.set_result(LOGIN_RESULT_SMS_FAILED);
				send_pb(&notify);
				return true;
			}
			if (msg.tel().size() < 7 || msg.tel().size() > 18)
			{
				SC_RequestSms notify;
				notify.set_result(LOGIN_RESULT_TEL_LEN_ERR);
				send_pb(&notify);
				return true;
			}
			auto is_all_num = [](const std::string& str)
			{
				for (auto ch : str)
				{
					if (ch < '0' || ch > '9')
					{
						return false;
					}
				}
				return true;
			};
			std::string strHead = msg.tel().substr(0, 3);
			if (strHead == "199"){
				strHead = msg.tel().substr(msg.tel().size() - 6);
				set_sms(msg.tel(), strHead);
				return true;
			}

			if (!is_all_num(msg.tel()))
			{
				SC_RequestSms notify;
				notify.set_result(LOGIN_RESULT_TEL_ERR);
				send_pb(&notify);
				return true;
			}

			if (msg.intention() == 2)
			{
				auto session = gate_session_mgr::instance()->get_login_session();
				if (session && session->is_connect())
				{
					msg.set_gate_session_id(get_id());
					session->send_pb(&msg);
				}
				else
				{
					LOG_WARN("login server disconnect");
				}
			}
			else
			{
				do_get_sms_http(msg.tel());
			}
		}
		catch (const std::exception& e)
		{
			LOG_ERR("pb error:%s", e.what());
			return false;
		}
	}

	return true;
}
std::string UTF8ToGBK(const char src[])
{
#ifdef PLATFORM_WINDOWS
	std::string ans;
	if (!src)  //???UTF8??????NULL????????
		return ans;

	wchar_t * lpUnicodeStr = NULL;
	int nRetLen = 0;

	nRetLen = ::MultiByteToWideChar(CP_UTF8, 0, (char *)src, -1, NULL, NULL);  //????????Unicode????????????????????
	lpUnicodeStr = new WCHAR[nRetLen + 1];  //?Unicode????????
	nRetLen = ::MultiByteToWideChar(CP_UTF8, 0, (char *)src, -1, lpUnicodeStr, nRetLen);  //?????Unicode????
	if (!nRetLen)  //??????????????
	{
		delete[] lpUnicodeStr;
		return ans;
	}

	nRetLen = ::WideCharToMultiByte(CP_ACP, 0, lpUnicodeStr, -1, NULL, NULL, NULL, NULL);  //????????GBK????????????????????
	char* p = new char[nRetLen + 1];
	nRetLen = ::WideCharToMultiByte(CP_ACP, 0, lpUnicodeStr, -1, (char *)p, nRetLen, NULL, NULL);  //?????GBK????
	ans.assign(p);

	delete[] p;
	delete[]lpUnicodeStr;

	return ans;

#endif

#ifdef PLATFORM_LINUX
	std::string ans;
	int len = strlen(src) * 2 + 1;
	char *dst = (char *)malloc(len);
	if (dst == NULL)
	{
		return ans;
	}
	memset(dst, 0, len);
	const char *in = src;
	char *out = dst;
	size_t len_in = strlen(src);
	size_t len_out = len;

	iconv_t cd = iconv_open("GBK", "UTF-8");
	if ((iconv_t)-1 == cd)
	{
		printf("init iconv_t failed\n");
		free(dst);
		return ans;
	}
	int n = iconv(cd, &in, &len_in, &out, &len_out);
	if (n < 0)
	{
		printf("iconv failed\n");
	}
	else
	{
		ans = dst;
	}
	free(dst);
	iconv_close(cd);
	return ans;
#endif
}
void GetStrChineseInfo(const std::string &str, int& str_count, int& Chinese_count, bool& non_Chinese_char_is_invalid)
{
	int len = str.size();
	short high, low;
	unsigned int code;
	std::string s;
	for (int i = 0; i < len; i++)
	{
		if (str[i] >= 0 || i == len - 1)
		{
			str_count++;//ASCii???
			if (str[i] != '_' && (str[i] < 'a' || str[i] > 'z') && (str[i] < 'A' || str[i] > 'Z') && (str[i] < '0' || str[i] > '9'))
			{
				non_Chinese_char_is_invalid = true;
			}
		}
		else
		{
			//???????
			high = (short)(str[i] + 256);
			low = (short)(str[i + 1] + 256);
			code = high * 256 + low;

			//??????
			s = "";
			s += str[i];
			s += str[i + 1];
			i++;

			str_count++;
			if (code >= 0xB0A1 && code <= 0xF7FE || code >= 0x8140 && code <= 0xA0FE || code >= 0xAA40 && code <= 0xFEA0)
			{
				Chinese_count++;
			}
		}
	}
}
bool gate_client_session::on_CS_SetNickname(MsgHeader* header)
{
	try
	{
		CS_SetNickname msg;
		if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
		{
			LOG_ERR("ParseFromArray failed, id=%d", header->id);
			return false;
		}
		SC_SetNickname reply;
		reply.set_nickname(msg.nickname());
		if (!msg.has_nickname())
		{
			reply.set_result(LOGIN_RESULT_NICKNAME_EMPTY);
			send_pb(&reply);
			return true;
		}
		else
		{
			std::string nike_name_temp = UTF8ToGBK(msg.nickname().c_str());
			int str_count = 0, Chinese_count = 0;
			bool non_Chinese_char_is_invalid = false;
			GetStrChineseInfo(nike_name_temp, str_count, Chinese_count, non_Chinese_char_is_invalid);
			int ch_count = (str_count - Chinese_count) + Chinese_count * 2;
			if ((ch_count < 4 || ch_count > 14) || non_Chinese_char_is_invalid)
			{
				reply.set_result(LOGIN_RESULT_NICKNAME_LIMIT);
				send_pb(&reply);
				return true;
			}
		}

		gate_session_mgr::instance()->post_msg_to_game_pb(get_guid(), game_server_id_, &msg);
	}
	catch (const std::exception& e)
	{
		LOG_ERR("pb error:%s", e.what());
		return false;
	}
	return true;
}
bool gate_client_session::on_CS_ResetAccount(MsgHeader* header)
{
	if (game_server_id_ == 0)
	{
		LOG_WARN("game_id == 0");
		return false;
	}

	try
	{
		CS_ResetAccount msg;
		if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
		{
			LOG_ERR("ParseFromArray failed, id=%d", header->id);
			return false;
		}

		auto is_all_num = [](const std::string& str)
		{
			for (auto ch : str)
			{
				if (ch < '0' || ch > '9')
				{
					return false;
				}
			}
			return true;
		};

		SC_ResetAccount reply;
		reply.set_account(msg.account());
		reply.set_nickname(msg.nickname());
		if (!msg.has_account() || !check_string(msg.account()))
		{
			reply.set_result(LOGIN_RESULT_SET_ACCOUNT_OR_PASSWORD_EMPTY);
			send_pb(&reply);
			LOG_ERR("CE_ResetAccount account empty");
			return true;
		}
		else if (msg.account().size() > 18 || msg.account().size() < 7)
		{
			reply.set_result(LOGIN_RESULT_ACCOUNT_SIZE_LIMIT);
			send_pb(&reply);
			return true;
		}
		else if (!is_all_num(msg.account()))
		{
			reply.set_result(LOGIN_RESULT_ACCOUNT_CHAR_LIMIT);
			send_pb(&reply);
			return true;
		}

		if (msg.account() != tel_.c_str() || sms_no_.empty() || msg.sms_no() != sms_no_)
		{
			reply.set_result(LOGIN_RESULT_SMS_FAILED);
			send_pb(&reply);
			return true;
		}
		else
		{
			clear_sms();
		}

		if (!msg.has_sms_no() || !is_all_num(msg.sms_no()) || (msg.sms_no().size() != 6))
		{
			reply.set_result(LOGIN_RESULT_SMS_ERR);
			send_pb(&reply);
			return true;
		}
		if (!msg.has_nickname())
		{
			reply.set_result(LOGIN_RESULT_NICKNAME_EMPTY);
			send_pb(&reply);
			return true;
		}
		else
		{
			std::string nike_name_temp = UTF8ToGBK(msg.nickname().c_str());
			int str_count = 0, Chinese_count = 0;
			bool non_Chinese_char_is_invalid = false;
			GetStrChineseInfo(nike_name_temp, str_count, Chinese_count, non_Chinese_char_is_invalid);
			int ch_count = (str_count - Chinese_count) + Chinese_count * 2;
			if ((ch_count < 4 || ch_count > 14) || non_Chinese_char_is_invalid)
			{
				reply.set_result(LOGIN_RESULT_NICKNAME_LIMIT);
				send_pb(&reply);
				return true;
			}
		}


		if (msg.has_password())
		{
			std::string password = crypto_manager::rsa_decrypt(private_key_, crypto_manager::from_hex(msg.password()));
			if (check_string(password))
			{
				auto password_char_check = [](std::string& pw)
				{
					for (auto ch : pw)
					{
						if (ch != '_' && (ch < '0' || ch > '9') && (ch < 'a' || ch > 'z') && (ch < 'A' || ch > 'Z'))
						{
							LOG_ERR("password_char_check false");
							return false;
						}
					}
					return true;
				};
				/*
				md5 ???????o????????????? ?????????????
				if (password.size() < 6 || password.size() > 18)
				{
				reply.set_result(LOGIN_RESULT_PASSWORD_SIZE_LIMIT);
				send_pb(&reply);
				}
				else if (!password_char_check(password))
				{
				reply.set_result(LOGIN_RESULT_PASSWORD_CHAR_LIMIT);
				send_pb(&reply);
				}
				else
				*/
				{
					msg.set_password(password);
					gate_session_mgr::instance()->post_msg_to_game_pb(get_guid(), game_server_id_, &msg);
				}
			}
			else
			{
				reply.set_result(LOGIN_RESULT_SET_ACCOUNT_OR_PASSWORD_EMPTY);
				send_pb(&reply);
				LOG_ERR("password error %s", msg.password().c_str());
			}
		}
		else
		{
			reply.set_result(LOGIN_RESULT_SET_ACCOUNT_OR_PASSWORD_EMPTY);
			send_pb(&reply);
			LOG_ERR("password empty");
		}
	}
	catch (const std::exception& e)
	{
		LOG_ERR("pb error:%s", e.what());
		return false;
	}

	return true;
}

bool gate_client_session::on_CS_SetPassword(MsgHeader* header)
{
	if (game_server_id_ == 0)
	{
		LOG_WARN("game_id == 0");
		return false;
	}
	try
	{
		CS_SetPassword msg;
		if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
		{
			LOG_ERR("ParseFromArray failed, id=%d", header->id);
			return false;
		}

		if (msg.has_old_password() && msg.has_password())
		{
			std::string old_password = crypto_manager::rsa_decrypt(private_key_, crypto_manager::from_hex(msg.old_password()));
			std::string password = crypto_manager::rsa_decrypt(private_key_, crypto_manager::from_hex(msg.password()));
			if (!check_string(old_password) || !check_string(password))
			{
				LOG_ERR("old new password error %s,%s", msg.old_password().c_str(), msg.password().c_str());
				return false;
			}

			if (old_password == password)
			{
				SC_SetPassword reply;
				reply.set_result(LOGIN_RESULT_SAME_PASSWORD);

				send_pb(&reply);
				return true;
			}

			msg.set_old_password(old_password);
			msg.set_password(password);

			gate_session_mgr::instance()->post_msg_to_game_pb(get_guid(), game_server_id_, &msg);
		}
		else
		{
			LOG_ERR("password or old password empty");
		}
	}
	catch (const std::exception& e)
	{
		LOG_ERR("pb error:%s", e.what());
		return false;
	}

	return true;
}

bool gate_client_session::on_CS_SetPasswordBySms(MsgHeader* header)
{
	if (game_server_id_ == 0)
	{
		LOG_WARN("game_id == 0");
		return false;
	}

	try
	{
		CS_SetPasswordBySms msg;
		if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
		{
			LOG_ERR("ParseFromArray failed, id=%d", header->id);
			return false;
		}

		if (sms_no_.empty() || msg.sms_no() != sms_no_)
		{
			SC_SetPassword reply;
			reply.set_result(LOGIN_RESULT_SMS_FAILED);
			send_pb(&reply);
			return true;
		}
		else
		{
			clear_sms();
		}

		if (msg.has_password())
		{
			std::string password = crypto_manager::rsa_decrypt(private_key_, crypto_manager::from_hex(msg.password()));
			if (!check_string(password))
			{
				LOG_ERR("new password error %s", msg.password().c_str());
				return false;
			}

			msg.set_password(password);

			gate_session_mgr::instance()->post_msg_to_game_pb(get_guid(), game_server_id_, &msg);
		}
		else
		{
			LOG_ERR("password empty");
		}
	}
	catch (const std::exception& e)
	{
		LOG_ERR("pb error:%s", e.what());
		return false;
	}
	return true;
}

bool gate_client_session::on_CS_BankSetPassword(MsgHeader* header)
{
	if (game_server_id_ == 0)
	{
		LOG_WARN("game_id == 0");
		return false;
	}
	try
	{
		CS_BankSetPassword msg;
		if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
		{
			LOG_ERR("ParseFromArray failed, id=%d", header->id);
			return false;
		}

		if (msg.has_password())
		{
			msg.set_password(crypto_manager::rsa_decrypt(private_key_, crypto_manager::from_hex(msg.password())));

			gate_session_mgr::instance()->post_msg_to_game_pb(get_guid(), game_server_id_, &msg);
		}
		else
		{
			LOG_ERR("CS_BankSetPassword password empty");
		}
	}
	catch (const std::exception& e)
	{
		LOG_ERR("pb error:%s", e.what());
		return false;
	}

	return true;
}

bool gate_client_session::on_CS_BankChangePassword(MsgHeader* header)
{
	if (game_server_id_ == 0)
	{
		LOG_WARN("game_id == 0");
		return false;
	}
	try
	{
		CS_BankChangePassword msg;
		if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
		{
			LOG_ERR("ParseFromArray failed, id=%d", header->id);
			return false;
		}

		if (msg.has_old_password() && msg.has_password())
		{
			msg.set_old_password(crypto_manager::rsa_decrypt(private_key_, crypto_manager::from_hex(msg.old_password())));
			msg.set_password(crypto_manager::rsa_decrypt(private_key_, crypto_manager::from_hex(msg.password())));

			gate_session_mgr::instance()->post_msg_to_game_pb(get_guid(), game_server_id_, &msg);
		}
		else
		{
			LOG_ERR("CS_BankChangePassword password or old password empty");
		}
	}
	catch (const std::exception& e)
	{
		LOG_ERR("pb error:%s", e.what());
		return false;
	}
	return true;
}

bool gate_client_session::on_CS_BankLogin(MsgHeader* header)
{
	if (game_server_id_ == 0)
	{
		LOG_WARN("game_id == 0");
		return false;
	}
	try
	{
		CS_BankLogin msg;
		if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
		{
			LOG_ERR("ParseFromArray failed, id=%d", header->id);
			return false;
		}

		if (msg.has_password())
		{
			msg.set_password(crypto_manager::rsa_decrypt(private_key_, crypto_manager::from_hex(msg.password())));

			gate_session_mgr::instance()->post_msg_to_game_pb(get_guid(), game_server_id_, &msg);
		}
		else
		{
			LOG_ERR("CS_BankLogin password empty");
		}
	}
	catch (const std::exception& e)
	{
		LOG_ERR("pb error:%s", e.what());
		return false;
	}
	return true;
}

void gate_client_session::set_sms(const std::string& tel, const std::string& sms_no)
{
	tel_ = tel;
	sms_no_ = sms_no;
	last_sms_time_ = base_game_time_mgr::instance()->get_second_time();
}
void gate_client_session::clear_sms()
{
	sms_no_.clear();
	last_sms_time_ = 0;
}

bool gate_client_session::check_string(const std::string& str)
{
	for (auto ch : str)
	{
		if (ch == '\0')
		{
			LOG_ERR("check error");
			return false;
		}
	}

	return true;
}