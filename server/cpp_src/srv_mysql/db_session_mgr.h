#pragma once

#include "base_net_server.h"
#include "base_net_dispatcher.h"
#include "Singleton.h"
#include "server.pb.h"

class db_session;
class db_session_mgr : public net_work_holder, public TSingleton < db_session_mgr >
{
protected:
	base_net_dispatcher_mgr			dispatcher_manager_;
	base_net_dispatcher_mgr			dispatcher_manager_login_;
	base_net_dispatcher_mgr			dispatcher_manager_game_;
	DBGameConfigMgr                     dbgamer_config;
	std::vector<std::shared_ptr<virtual_session>> login_session_;
	std::vector<std::shared_ptr<virtual_session>> game_session_;
	std::unordered_map<std::string, time_t> verify_account_list_;
public:
	db_session_mgr();
	virtual ~db_session_mgr();
	void register_message();
	
	void add_verify_account(const std::string& account);
	void remove_verify_account(const std::string& account);
	bool find_verify_account(const std::string& account);
	virtual std::shared_ptr<virtual_session> create_session(boost::asio::ip::tcp::socket& socket);
	base_net_dispatcher_mgr* get_dispatcher_manager() { return &dispatcher_manager_; }
	base_net_dispatcher_mgr* get_dispatcher_manager_login() { return &dispatcher_manager_login_; }
	base_net_dispatcher_mgr* get_dispatcher_manager_game() { return &dispatcher_manager_game_; }
	std::shared_ptr<virtual_session> get_login_session(int login_id);
	void add_login_session(std::shared_ptr<virtual_session> session);
	void del_login_session(std::shared_ptr<virtual_session> session);
	std::shared_ptr<virtual_session> get_game_session(int server_id);
	void add_game_session(std::shared_ptr<virtual_session> session);
	void del_game_session(std::shared_ptr<virtual_session> session);
	DBGameConfigMgr  &GetServerCfg(){
		return dbgamer_config;
	}
	template<typename T> void post_msg_to_login_pb(int login_id, T* pb)
	{
		auto session = get_login_session(login_id);
		if (session && session->is_connect())
		{
			session->send_pb(pb);
		}
		else
		{
			LOG_WARN("login server[%d] disconnect", login_id);
		}
	}
	template<typename T> int broadcast2login_pb(T* pb)
	{
        for (auto session : login_session_)
		{
			session->send_pb(pb);
		}
        return (int)login_session_.size();
	}
	template<typename T> void post_msg_to_game_pb(int game_id, T* pb)
	{
		auto session = get_game_session(game_id);
		if (session && session->is_connect())
		{
			session->send_pb(pb);
		}
		else
		{
			LOG_WARN("game server[%d] disconnect", game_id);
		}
	}
};