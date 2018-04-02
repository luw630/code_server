#pragma once

#include "base_net_server.h"
#include "base_net_dispatcher.h"
#include "Singleton.h"
#include "server.pb.h"
#include "cfg_session.h"

class cfg_session;
class cfg_session_mgr : public net_work_holder, public TSingleton < cfg_session_mgr >
{
protected:
	base_net_dispatcher_mgr			dispatcher_manager_;
	std::vector<std::shared_ptr<virtual_session>> gate_session_;
	std::vector<std::shared_ptr<virtual_session>> game_session_;
	std::vector<std::shared_ptr<virtual_session>> login_session_;
	std::vector<std::shared_ptr<virtual_session>> db_session_;
	DBGameConfigMgr                     dbgamer_config;
	std::string                         m_sPhpString;
	std::unordered_map<int, int>        m_mpPlayer_Gate;


public:
	cfg_session_mgr();
	virtual ~cfg_session_mgr();
	void register_server_message();
	virtual std::shared_ptr<virtual_session> create_session(boost::asio::ip::tcp::socket& socket);
	base_net_dispatcher_mgr* get_dispatcher_manager() { return &dispatcher_manager_; }
	
	template<typename T> void send2server_pb(int session_id, T* pb)
	{
		auto session = find_by_id(session_id);
		if (session && session->is_connect())
		{
			session->send_pb(pb);
		}
		else
		{
			LOG_WARN("login server[%d] disconnect", session_id);
		}
    }

	template<typename T> bool send2gate_pb(int gate_id, T* pb)
	{
		auto session = get_gate_session(gate_id);
		if (session && session->is_connect())
		{
			session->send_pb(pb);
		}
		else
		{
			LOG_WARN("gate server[%d] disconnect", gate_id);
			return false;
		}
		return true;
	}

	template<typename T> int broadcast2gate_pb(T* pb)
	{
		for (auto session : gate_session_)
		{
			if (session && session->is_connect())
			{
				session->send_pb(pb);
			}
			else
			{
				LOG_WARN("gate server disconnect");
			}
		}
		return (int)gate_session_.size();
	}

	template<typename T> bool post_msg_to_game_pb(int game_id, T* pb)
	{
		auto session = get_game_session(game_id);
		if (session && session->is_connect())
		{
			session->send_pb(pb);
		}
		else
		{
			LOG_WARN("game server[%d] disconnect", game_id);
			return false;
		}
		return true;
	}

	template<typename T> int broadcast2game_pb(T* pb)
	{
		for (auto session : game_session_)
		{
			session->send_pb(pb);
		}
		return (int)game_session_.size();
	}

	template<typename T> int broadcast2login_pb(T* pb)
	{
		for (auto session : login_session_)
		{
			session->send_pb(pb);
		}
		return (int)login_session_.size();
    }
	template<typename T> bool post_msg_to_mysql_pb(T* pb)
    {
		for (auto session : db_session_)
		{
			if (session && session->is_connect())
			{
				session->send_pb(pb);
				return true;
			}
		}
		LOG_ERR("post_msg_to_mysql_pb failed, non  connnect");
		return false;
    }
    std::string GetPHPSign() { return m_sPhpString; }
    void SetPHPSign(std::string str) { m_sPhpString = str; }
    DBGameConfigMgr  &GetServerCfg(){ return dbgamer_config; }
	std::shared_ptr<virtual_session> get_gate_session(int server_id);
	void add_gate_session(std::shared_ptr<virtual_session> session);
	void del_gate_session(std::shared_ptr<virtual_session> session);
	std::shared_ptr<virtual_session> get_game_session(int server_id);
	void add_game_session(std::shared_ptr<virtual_session> session);
	void del_game_session(std::shared_ptr<virtual_session> session);
	std::shared_ptr<virtual_session> get_login_session(int server_id);
	void add_login_session(std::shared_ptr<virtual_session> session);
	void del_login_session(std::shared_ptr<virtual_session> session);
	std::shared_ptr<virtual_session> get_db_session(int server_id);
	void add_db_session(std::shared_ptr<virtual_session> session);
	void del_db_session(std::shared_ptr<virtual_session> session);

    void SetPlayer_Gate(int guid, int gate_id);
    int GetPlayer_Gate(int guid);
    void ErasePlayer_Gate(int guid);

};