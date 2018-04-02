#include "login_session_mgr.h"
#include "login_session.h"
#include "login_db_session.h"
#include "login_server.h"


login_session_mgr::login_session_mgr()
	: cur_db_session_(0)
	, first_connect_db_(0)
{
	register_message();
}

login_session_mgr::~login_session_mgr()
{
}

void login_session_mgr::close_all_session()
{
	net_work_holder::close_all_session();

	for (auto item : db_session_)
		item->close();
}

void login_session_mgr::release_all_session()
{
	net_work_holder::release_all_session();

	for (auto item : db_session_)
	{
		item->on_closed();
	}
	db_session_.clear();
}

bool login_session_mgr::tick()
{
	bool ret = net_work_holder::tick();

	for (auto item : db_session_)
	{
		if (!item->tick())
			ret = false;
	}

	if (first_connect_db_ == 1)
	{
		handler_mysql_connected();
		first_connect_db_ = 2;
	}
	return ret;
}

std::shared_ptr<virtual_session> login_session_mgr::create_session(boost::asio::ip::tcp::socket& socket)
{
	return std::static_pointer_cast<virtual_session>(std::make_shared<login_session>(socket));
}

std::shared_ptr<virtual_session> login_session_mgr::create_db_session(const std::string& ip, unsigned short port)
{
	auto session = std::make_shared<login_db_session>(network_server_->get_io_server_pool().get_io_service());
	session->set_ip_port(ip, port);
	return std::static_pointer_cast<virtual_session>(session);
}

void login_session_mgr::set_network_server(base_net_server* network_server)
{
	net_work_holder::set_network_server(network_server);

	auto& cfg = static_cast<login_server*>(base_server::instance())->get_config();

	for (auto& attr : cfg.db_addr())
	{
		db_session_.push_back(create_db_session(attr.ip(), attr.port()));
	}
}
void login_session_mgr::register_message()
{
#define REG_GATE_DISPATCHER(Msg, Function) dispatcher_manager_gate_.register_dispatcher(new GateMsgDispatcher< Msg, login_session >(&login_session::Function));
#define REG_GAME_DISPATCHER(Msg, Function) dispatcher_manager_game_.register_dispatcher(new MsgDispatcher< Msg, login_session >(&login_session::Function));
#define REG_DB_DISPATCHER(Msg, Function) dispatcher_manager_db_.register_dispatcher(new MsgDispatcher< Msg, login_db_session >(&login_db_session::Function));
#define REG_WEB_DISPATCHER(Msg, Function) dispatcher_manager_web_.register_dispatcher(new MsgDispatcher< Msg, login_session >(&login_session::Function));

	dispatcher_manager_.register_dispatcher(new MsgDispatcher<S_Connect, login_session>(&login_session::on_s_connect));
	dispatcher_manager_gate_.register_dispatcher(new MsgDispatcher< S_Logout, login_session >(&login_session::on_s_logout));
	dispatcher_manager_gate_.register_dispatcher(new MsgDispatcher< L_KickClient, login_session >(&login_session::on_L_KickClient));
	dispatcher_manager_gate_.register_dispatcher(new MsgDispatcher< GL_NewNotice, login_session >(&login_session::on_gl_NewNotice));
	dispatcher_manager_gate_.register_dispatcher(new MsgDispatcher< CS_RequestSms, login_session >(&login_session::on_cs_request_sms));
	REG_GATE_DISPATCHER(CL_Login, on_cl_login);
	REG_GATE_DISPATCHER(CL_RegAccount, on_cl_reg_account);
	REG_GATE_DISPATCHER(CL_LoginBySms, on_cl_login_by_sms);
	REG_GATE_DISPATCHER(CS_ChatWorld, on_cs_chat_world);
	REG_GATE_DISPATCHER(GL_GetServerCfg, on_gl_get_server_cfg);
	REG_GATE_DISPATCHER(CL_GetInviterInfo, on_cl_get_server_cfg);

	REG_GAME_DISPATCHER(L_KickClient, on_L_KickClient);
	REG_GAME_DISPATCHER(S_UpdateGamePlayerCount, on_S_UpdateGamePlayerCount);
	REG_GAME_DISPATCHER(SS_ChangeGame, on_ss_change_game);
	REG_GAME_DISPATCHER(SL_ChangeGameResult, on_SL_ChangeGameResult);
	REG_GAME_DISPATCHER(SD_BankTransfer, handler_sd_bank_transfer);
	REG_GAME_DISPATCHER(S_BankTransferByGuid, handler_sd_bank_transfer_by_guid);
	REG_GAME_DISPATCHER(SC_ChatPrivate, on_sc_chat_private);
	REG_GAME_DISPATCHER(SL_WebGameServerInfo, on_sl_web_game_server_info);
	REG_GAME_DISPATCHER(SL_ChangeTax, on_sl_change_tax_reply);
	REG_GAME_DISPATCHER(SL_LuaCmdPlayerResult, on_SL_LuaCmdPlayerResult);
	REG_GAME_DISPATCHER(SL_CC_ChangeMoney, on_SL_AT_ChangeMoney);
	REG_GAME_DISPATCHER(SL_FreezeAccount, on_sl_FreezeAccount);
	REG_GAME_DISPATCHER(SL_AddMoney, on_SL_AddMoney);
	REG_GAME_DISPATCHER(LS_NewNotice, on_gl_broadcast_new_notice);
	REG_GAME_DISPATCHER(SL_LuaGameCmd, on_SL_LuaGameCmd);
	REG_GAME_DISPATCHER(WS_MaintainUpdate, on_gsMaintainSwitch);


	REG_DB_DISPATCHER(DL_VerifyAccountResult, on_dl_verify_account_result);
	REG_DB_DISPATCHER(DL_RegAccount, on_dl_reg_account);
	REG_DB_DISPATCHER(DL_RegAccount2, on_dl_reg_account2);
	REG_DB_DISPATCHER(DL_NewNotice, on_dl_NewNotice);
	REG_DB_DISPATCHER(DL_DelMessage, on_dl_DelMessage);
	REG_DB_DISPATCHER(DL_PhoneQuery, on_dl_reg_phone_query);
	REG_DB_DISPATCHER(DL_ServerConfig, on_dl_server_config);
	REG_DB_DISPATCHER(DL_DBGameConfigMgr, on_dl_server_config_mgr);
	REG_DB_DISPATCHER(LC_GetInviterInfo, on_dl_get_inviter_info);
	REG_DB_DISPATCHER(DL_LuaCmdPlayerResult, on_DL_LuaCmdPlayerResult);
	REG_DB_DISPATCHER(DL_CC_ChangeMoney, on_cc_ChangMoney);
	REG_DB_DISPATCHER(DL_DO_SQL, on_dl_doSql);
	REG_DB_DISPATCHER(DL_AlipayEdit, on_dl_AlipayEdit);


	REG_WEB_DISPATCHER(WL_RequestGameServerInfo, on_wl_request_game_server_info);
	REG_WEB_DISPATCHER(WL_GMMessage, on_wl_request_GMMessage);
	//    REG_WEB_DISPATCHER(WL_Recharge, on_wl_request_recharge);
	REG_WEB_DISPATCHER(WL_ChangeTax, on_wl_request_change_tax);
	REG_WEB_DISPATCHER(WL_ChangeMoney, on_wl_request_gm_change_money);
	REG_WEB_DISPATCHER(WL_LuaCmdPlayerResult, on_WL_LuaCmdPlayerResult);
	REG_WEB_DISPATCHER(WL_LuaGameCmd, on_WL_LuaGameCmd);
	REG_WEB_DISPATCHER(WL_BroadcastClientUpdate, on_wl_broadcast_gameserver_cmd);

#undef REG_GATE_DISPATCHER
#undef REG_GAME_DISPATCHER
#undef REG_DB_DISPATCHER
#undef REG_WEB_DISPATCHER

}
std::shared_ptr<virtual_session> login_session_mgr::get_gate_session(int server_id)
{
	for (auto item : gate_session_)
	{
		if (item->get_server_id() == server_id && item->is_connect())
			return item;
	}
	return std::shared_ptr<virtual_session>();
}

void login_session_mgr::add_gate_session(std::shared_ptr<virtual_session> session)
{
	gate_session_.push_back(session);

	//send_open_game_list(session);
}

void login_session_mgr::del_gate_session(std::shared_ptr<virtual_session> session)
{
	for (auto it = gate_session_.begin(); it != gate_session_.end(); ++it)
	{
		if (*it == session)
		{
			gate_session_.erase(it);

			//send_open_game_list(session);
			break;
		}
	}
}

std::shared_ptr<virtual_session> login_session_mgr::get_game_session(int server_id)
{
	for (auto item : game_session_)
	{
		if (item->get_server_id() == server_id)
			return item;
	}
	return std::shared_ptr<virtual_session>();
}

void login_session_mgr::add_game_session(std::shared_ptr<virtual_session> session)
{
	game_session_.push_back(session);
}

void login_session_mgr::del_game_session(std::shared_ptr<virtual_session> session)
{
	for (auto it = game_session_.begin(); it != game_session_.end(); ++it)
	{
		if (*it == session)
		{
			game_session_.erase(it);
			break;
		}
	}
}

std::shared_ptr<virtual_session> login_session_mgr::get_db_session()
{
	if (db_session_.empty())
		return std::shared_ptr<virtual_session>();

	int check_time = 0;
	while (check_time != db_session_.size())
	{
		if (cur_db_session_ >= db_session_.size())
			cur_db_session_ = 0;
		std::shared_ptr<virtual_session> cur_session = db_session_[cur_db_session_];
		if (cur_session->is_connect())
		{
			cur_db_session_++;
			return cur_session;
		}
		else
		{
			cur_db_session_++;
			check_time++;
		}
	}
	return std::shared_ptr<virtual_session>();
}

void login_session_mgr::add_game_server_info(int game_id, int first_game_type, int second_game_type, bool default_lobby, int player_limit)
{
	RegGameServerInfo info;
	info.first_game_type = first_game_type;
	info.second_game_type = second_game_type;
	info.default_lobby = default_lobby;
	info.player_limit = player_limit;
	info.cur_player_count = 0;
	std::lock_guard<std::recursive_mutex> lock(mutex_reg_game_server_info_);
	reg_game_server_info_[game_id] = info;

	//broadcast_open_game_list();
}

void login_session_mgr::remove_game_server_info(int game_id)
{
	std::lock_guard<std::recursive_mutex> lock(mutex_reg_game_server_info_);
	reg_game_server_info_.erase(game_id);

	//broadcast_open_game_list();
}

bool login_session_mgr::has_game_server_info(int game_id)
{
	std::lock_guard<std::recursive_mutex> lock(mutex_reg_game_server_info_);
	return reg_game_server_info_.find(game_id) != reg_game_server_info_.end();
}

void login_session_mgr::update_game_server_player_count(int game_id, S_UpdateGamePlayerCount* msg)
{
	int count = msg->cur_player_count();
	int a_count = msg->cur_android_count();
	int i_count = msg->cur_ios_count();
	if (count < 0 || a_count < 0 || i_count < 0)
	{
		LOG_ERR("update_game_server_player_count ERROR£¬ game %d count %d %d %d", game_id, count, a_count, i_count);
		return;
	}
	bool is_new_top_count = false;
	std::lock_guard<std::recursive_mutex> lock(mutex_reg_game_server_info_);
	auto it = reg_game_server_info_.find(game_id);
	if (it != reg_game_server_info_.end())
	{
		if (count > it->second.cur_player_count)
		{
			is_new_top_count = true;
		}
		it->second.cur_player_count = count;
		it->second.cur_player_ios = i_count;
		it->second.cur_player_android = a_count;
	}

	int	t_top_player_android = 0;
	int t_top_player_ios = 0;
	for (auto it = reg_game_server_info_.begin(); it != reg_game_server_info_.end(); it++)
	{
		t_top_player_android = t_top_player_android + it->second.cur_player_android;
		t_top_player_ios = t_top_player_ios + it->second.cur_player_ios;
	}

	if (t_top_player_android > top_player_android) top_player_android = t_top_player_android;
	if (t_top_player_ios > top_player_ios) top_player_ios = t_top_player_ios;

	if (is_new_top_count)
	{
		int count_all = 0;
		for (auto it = reg_game_server_info_.begin(); it != reg_game_server_info_.end(); it++)
		{
			count_all = count_all + it->second.cur_player_count;
		}
		SD_Do_OneSql msg;
		msg.set_db_name("log");
		char buff[1024] = { 0 };
		sprintf(buff, "INSERT INTO t_log_player_count_top(`player_count_top`,`time`,`ex_info`) VALUES(%d, NOW(), '%s')", count_all,"");
		msg.set_sql(buff);

		post_msg_to_mysql_pb(&msg);
	}
}
int login_session_mgr::get_game_server_player_count(int fg_id, int sg_id)
{
	std::lock_guard<std::recursive_mutex> lock(mutex_reg_game_server_info_);
	for (auto it = reg_game_server_info_.begin(); it != reg_game_server_info_.end(); it++)
	{
		if (it->second.first_game_type == fg_id && it->second.second_game_type == sg_id)
		{
			return it->second.cur_player_count;
		}
	}
	return 0;
}
int login_session_mgr::get_ios_online_top()
{
	return top_player_ios;
}
int login_session_mgr::get_android_online_top()
{
	return top_player_android;
}
void login_session_mgr::clear_online_info()
{
	LOG_INFO("clear_online_info: ios top %d  android top %d", top_player_ios, top_player_android);
	top_player_ios = 0;
	top_player_android = 0;
}

int login_session_mgr::find_a_default_lobby()
{
	int game_id = 0;
	std::lock_guard<std::recursive_mutex> lock(mutex_reg_game_server_info_);
	for (auto& item : reg_game_server_info_)
	{
		if (item.second.default_lobby && item.second.cur_player_count < item.second.player_limit)
		{
			game_id = item.first;
			break;
		}
	}

	return game_id;
}

void login_session_mgr::print_game_server_info()
{
	std::stringstream ss;
	ss << "print_game_server_info:";
	std::lock_guard<std::recursive_mutex> lock(mutex_reg_game_server_info_);
	for (auto& item : reg_game_server_info_)
	{
		ss << "(" << item.first << "," << item.second.default_lobby << ")";
	}
	LOG_WARN(ss.str().c_str());

}

int login_session_mgr::find_a_game_id(int first_game_type, int second_game_type)
{
	int game_id = 0;
	std::lock_guard<std::recursive_mutex> lock(mutex_reg_game_server_info_);
	for (auto& item : reg_game_server_info_)
	{
		if (item.second.first_game_type == first_game_type && item.second.second_game_type == second_game_type && item.second.cur_player_count < item.second.player_limit)
		{
			game_id = item.first;
			break;
		}
	}

	return game_id;
}

void login_session_mgr::set_first_connect_db()
{
	if (first_connect_db_ == 0)
	{
		first_connect_db_ = 1;
	}
}

bool login_session_mgr::is_first_connect_db()
{
	return first_connect_db_ > 0;
}

void login_session_mgr::handler_mysql_connected()
{
}

void login_session_mgr::Add_DB_Server_Session(const std::string& ip, int port)
{
	db_session_.push_back(create_db_session(ip, port));
}
