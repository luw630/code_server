#include "db_session_mgr.h"
#include "db_session.h"
#include "base_game_time_mgr.h"



db_session_mgr::db_session_mgr()
{
	register_message();
}

db_session_mgr::~db_session_mgr()
{
}

std::shared_ptr<virtual_session> db_session_mgr::create_session(boost::asio::ip::tcp::socket& socket)
{
	return std::static_pointer_cast<virtual_session>(std::make_shared<db_session>(socket));
}

std::shared_ptr<virtual_session> db_session_mgr::get_login_session(int login_id)
{
	for (auto item : login_session_)
	{
		if (item->get_server_id() == login_id && item->is_connect())
			return item;
	}
	return std::shared_ptr<virtual_session>();
}

void db_session_mgr::add_login_session(std::shared_ptr<virtual_session> session)
{
	login_session_.push_back(session);
}

void db_session_mgr::del_login_session(std::shared_ptr<virtual_session> session)
{
	for (auto it = login_session_.begin(); it != login_session_.end(); ++it)
	{
		if (*it == session)
		{
			login_session_.erase(it);
			break;
		}
	}
}

std::shared_ptr<virtual_session> db_session_mgr::get_game_session(int server_id)
{
	for (auto item : game_session_)
	{
		if (item->get_server_id() == server_id)
			return item;
	}
	return std::shared_ptr<virtual_session>();
}

void db_session_mgr::add_game_session(std::shared_ptr<virtual_session> session)
{
	game_session_.push_back(session);
}

void db_session_mgr::del_game_session(std::shared_ptr<virtual_session> session)
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
void db_session_mgr::register_message()
{

#define REG_LOGIN_DISPATCHER(Msg, Function) dispatcher_manager_login_.register_dispatcher(new MsgDispatcher< Msg, db_session >(&db_session::Function));
#define REG_GAME_DISPATCHER(Msg, Function) dispatcher_manager_game_.register_dispatcher(new MsgDispatcher< Msg, db_session >(&db_session::Function));

	dispatcher_manager_.register_dispatcher(new MsgDispatcher<S_Connect, db_session>(&db_session::on_s_connect));

	REG_LOGIN_DISPATCHER(LD_VerifyAccount, handler_ld_verify_account);
	REG_LOGIN_DISPATCHER(LD_RegAccount, handler_ld_reg_account);
	REG_LOGIN_DISPATCHER(LD_SmsLogin, handler_ld_sms_login);
	//    REG_LOGIN_DISPATCHER(LD_Recharge, handler_ld_recharge);
	//    REG_LOGIN_DISPATCHER(LD_RechargeReply, handler_ld_recharge_reply);
	//    REG_LOGIN_DISPATCHER(LD_RechargeDeal, handler_ld_recharge_deal);
	REG_LOGIN_DISPATCHER(LD_PhoneQuery, handler_ld_phone_query);
	REG_LOGIN_DISPATCHER(LD_OfflineChangeMoney, handler_ld_offlinechangemoney_query);
	REG_LOGIN_DISPATCHER(LD_GetServerCfg, handler_ld_get_server_cfg);
	REG_LOGIN_DISPATCHER(CL_GetInviterInfo, handler_ld_get_inviter_info);
	REG_LOGIN_DISPATCHER(LD_LuaCmdPlayerResult, handler_ld_LuaCmdPlayerResult);
	REG_LOGIN_DISPATCHER(LD_AddMoney, handler_ld_re_add_player_money);

	REG_GAME_DISPATCHER(SD_ResetAccount, handler_sd_reset_account);
	REG_GAME_DISPATCHER(SD_SetPassword, handler_sd_set_password);
	REG_GAME_DISPATCHER(SD_SetPasswordBySms, handler_sd_set_password_by_sms);
	REG_GAME_DISPATCHER(SD_SetNickname, handler_sd_set_nickname);
	REG_GAME_DISPATCHER(SD_UpdateEarnings, handler_sd_update_earnings);
	REG_GAME_DISPATCHER(SD_BandAlipay, handler_sd_band_alipay);
	REG_GAME_DISPATCHER(SD_ServerConfig, handler_sd_server_cfg);
	REG_GAME_DISPATCHER(SD_ChangMoneyReply, handler_sd_changemoney);
	REG_GAME_DISPATCHER(FD_ChangMoneyDeal, handler_fd_changemoney);

	REG_GAME_DISPATCHER(SD_BindBankCard, handler_sd_band_bank_card);
	REG_GAME_DISPATCHER(SD_GetBankCardInfo, handler_sd_get_band_bank_info);

	

#undef REG_LOGIN_DISPATCHER
#undef REG_GAME_DISPATCHER
}
void db_session_mgr::add_verify_account(const std::string& account)
{
	verify_account_list_[account] = base_game_time_mgr::instance()->get_second_time();
}

void db_session_mgr::remove_verify_account(const std::string& account)
{
	verify_account_list_.erase(account);
}

bool db_session_mgr::find_verify_account(const std::string& account)
{
	auto it = verify_account_list_.find(account);
	if (it == verify_account_list_.end())
	{
		return false;
	}

	if (base_game_time_mgr::instance()->get_second_time() - it->second >= 10)
	{
		verify_account_list_.erase(it);
		return false;
	}
	return true;
}