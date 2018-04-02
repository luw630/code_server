#include "cfg_session_mgr.h"
#include "cfg_session.h"




cfg_session_mgr::cfg_session_mgr()
{
	register_server_message();
    m_sPhpString = "";
    m_mpPlayer_Gate.clear();
}

cfg_session_mgr::~cfg_session_mgr()
{
}

std::shared_ptr<virtual_session> cfg_session_mgr::get_gate_session(int server_id)
{
	for (auto item : gate_session_)
	{
		if (item->get_server_id() == server_id && item->is_connect())
			return item;
	}
	return std::shared_ptr<virtual_session>();
}

void cfg_session_mgr::add_gate_session(std::shared_ptr<virtual_session> session)
{
	gate_session_.push_back(session);
}

void cfg_session_mgr::del_gate_session(std::shared_ptr<virtual_session> session)
{
	for (auto it = gate_session_.begin(); it != gate_session_.end(); ++it)
	{
		if (*it == session)
		{
			gate_session_.erase(it);
			break;
		}
	}
}

std::shared_ptr<virtual_session> cfg_session_mgr::get_game_session(int server_id)
{
	for (auto item : game_session_)
	{
		if (item->get_server_id() == server_id)
			return item;
	}
	return std::shared_ptr<virtual_session>();
}

void cfg_session_mgr::add_game_session(std::shared_ptr<virtual_session> session)
{
	game_session_.push_back(session);
}

void cfg_session_mgr::del_game_session(std::shared_ptr<virtual_session> session)
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

std::shared_ptr<virtual_session> cfg_session_mgr::get_login_session(int server_id)
{
	for (auto item : login_session_)
	{
		if (item->get_server_id() == server_id && item->is_connect())
			return item;
	}
	return std::shared_ptr<virtual_session>();
}

void cfg_session_mgr::add_login_session(std::shared_ptr<virtual_session> session)
{
	login_session_.push_back(session);
}

void cfg_session_mgr::register_server_message()
{
#define REG_SERVER_DISPATCHER(Msg, Function) dispatcher_manager_.register_dispatcher(new MsgDispatcher< Msg, cfg_session >(&cfg_session::Function));
	REG_SERVER_DISPATCHER(S_Connect, on_S_Connect);
	REG_SERVER_DISPATCHER(S_RequestServerConfig, on_S_RequestServerConfig);
	REG_SERVER_DISPATCHER(S_RequestUpdateGameServerConfig, on_S_RequestUpdateGameServerConfig);
	REG_SERVER_DISPATCHER(S_RequestUpdateLoginServerConfigByGate, on_S_RequestUpdateLoginServerConfigByGate);
	REG_SERVER_DISPATCHER(S_RequestUpdateLoginServerConfigByGame, on_S_RequestUpdateLoginServerConfigByGame);
	REG_SERVER_DISPATCHER(S_RequestUpdateDBServerConfigByGame, on_S_RequestUpdateDBServerConfigByGame);
	REG_SERVER_DISPATCHER(S_RequestUpdateDBServerConfigByLogin, on_S_RequestUpdateDBServerConfigByLogin);
	REG_SERVER_DISPATCHER(WF_ChangeGameCfg, on_WF_ChangeGameCfg);
	REG_SERVER_DISPATCHER(WF_ChangeRobotCfg, on_WF_ChangeRobotCfg);
	REG_SERVER_DISPATCHER(WF_GetCfg, on_WF_GetCfg);
	REG_SERVER_DISPATCHER(SF_ChangeGameCfg, on_SF_ChangeGameCfg);
	REG_SERVER_DISPATCHER(WS_MaintainUpdate, on_ReadMaintainSwitch);
	REG_SERVER_DISPATCHER(GF_PlayerIn, on_GF_PlayerIn);
	REG_SERVER_DISPATCHER(GF_PlayerOut, on_GF_PlayerOut);
	REG_SERVER_DISPATCHER(WF_Recharge, on_WF_Recharge);
	REG_SERVER_DISPATCHER(WF_Cash_false, on_WF_Cash_false);
	REG_SERVER_DISPATCHER(DF_Reply, on_DF_Reply);
	REG_SERVER_DISPATCHER(DF_ChangMoney, on_DF_ChangMoney);
	REG_SERVER_DISPATCHER(FS_ChangMoneyDeal, on_FS_ChangMoneyDeal);
	REG_SERVER_DISPATCHER(SS_JoinPrivateRoom, on_SS_JoinPrivateRoom);

	REG_SERVER_DISPATCHER(GF_SavePlayerInfo, on_GF_SavePlayerInfo);
	REG_SERVER_DISPATCHER(GF_GetPlayerInfo, on_GF_GetPlayerInfo);
	REG_SERVER_DISPATCHER(DF_SavePlayerInfo, on_DF_SavePlayerInfo);
	REG_SERVER_DISPATCHER(DF_GetPlayerInfo, on_DF_GetPlayerInfo);
	REG_SERVER_DISPATCHER(WF_SavePlayersInfoToMySQL, on_WF_SavePlayersInfoToMySQL);
	

#undef REG_SERVER_DISPATCHER
}

std::shared_ptr<virtual_session> cfg_session_mgr::create_session(boost::asio::ip::tcp::socket& socket)
{
	return std::static_pointer_cast<virtual_session>(std::make_shared<cfg_session>(socket));
}

void cfg_session_mgr::del_login_session(std::shared_ptr<virtual_session> session)
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

std::shared_ptr<virtual_session> cfg_session_mgr::get_db_session(int server_id)
{
	for (auto item : db_session_)
	{
		if (item->get_server_id() == server_id)
			return item;
	}
	return std::shared_ptr<virtual_session>();
}

void cfg_session_mgr::add_db_session(std::shared_ptr<virtual_session> session)
{
	db_session_.push_back(session);
}

void cfg_session_mgr::del_db_session(std::shared_ptr<virtual_session> session)
{
	for (auto it = db_session_.begin(); it != db_session_.end(); ++it)
	{
		if (*it == session)
		{
			db_session_.erase(it);
			break;
		}
	}
}

void cfg_session_mgr::SetPlayer_Gate(int guid, int gate_id)
{
    if (gate_id >= 0)
    {
        m_mpPlayer_Gate[guid] = gate_id;
    }
    else
    {
        LOG_INFO("SetPlayer_Gate error... gate_id %d", gate_id);
    }
}

int cfg_session_mgr::GetPlayer_Gate(int guid)
{
	auto iter = m_mpPlayer_Gate.find(guid);
	if (iter != m_mpPlayer_Gate.end())
	{
		return iter->second;
	}
	else
	{
		return -1;
	}
}

void cfg_session_mgr::ErasePlayer_Gate(int guid)
{
	m_mpPlayer_Gate.erase(guid);
}