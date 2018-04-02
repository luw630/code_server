#pragma once

#include "base_net_server.h"
#include "base_net_dispatcher.h"
#include "Singleton.h"

class game_session;
class game_db_session;

class game_session_mgr : public net_work_holder, public TSingleton < game_session_mgr >
{
protected:
	base_net_dispatcher_mgr			dispatcher_manager_;
	base_net_dispatcher_mgr			dispatcher_manager_login_;
	base_net_dispatcher_mgr			dispatcher_manager_gate_;
	base_net_dispatcher_mgr			dispatcher_manager_db_;
	std::vector<std::shared_ptr<virtual_session>> login_session_;
	std::vector<std::shared_ptr<virtual_session>> db_session_;
	std::vector<std::shared_ptr<virtual_session>> db_session_game_only_;
	std::vector<std::shared_ptr<virtual_session>> gate_session_;
	size_t								cur_login_session_;
	size_t								cur_db_session_;
	size_t								cur_db_session_game_only_;
	int									first_connect_db_;
public:
	game_session_mgr();
	virtual ~game_session_mgr();
	void register_message();
	virtual void close_all_session();
	virtual void release_all_session();
	virtual bool tick();
	virtual std::shared_ptr<virtual_session> create_session(boost::asio::ip::tcp::socket& socket);
	virtual std::shared_ptr<virtual_session> create_login_session(const std::string& ip, unsigned short port);
	virtual std::shared_ptr<virtual_session> create_db_session(const std::string& ip, unsigned short port);
	virtual void set_network_server(base_net_server* network_server);
	base_net_dispatcher_mgr* get_dispatcher_manager() { return &dispatcher_manager_; }
	base_net_dispatcher_mgr* get_dispatcher_manager_login() { return &dispatcher_manager_login_; }
	base_net_dispatcher_mgr* get_dispatcher_manager_gate() { return &dispatcher_manager_gate_; }
	base_net_dispatcher_mgr* get_dispatcher_manager_db() { return &dispatcher_manager_db_; }
	std::shared_ptr<virtual_session> get_db_session();
	std::shared_ptr<virtual_session> get_db_session_game_only();
	std::shared_ptr<virtual_session> get_login_session();
    std::shared_ptr<virtual_session> get_login_session(int login_id);
	void add_login_session(std::shared_ptr<virtual_session> session);
	void del_login_session(std::shared_ptr<virtual_session> session);
	std::shared_ptr<virtual_session> get_gate_session(int server_id);
	void add_gate_session(std::shared_ptr<virtual_session> session);
	void del_gate_session(std::shared_ptr<virtual_session> session);
	template<typename T> void post_msg_to_login_pb(T* pb)
	{
		auto session = get_login_session();
		if (session && session->is_connect())
		{
			session->send_pb(pb);
		}
		else
		{
			LOG_WARN("login server disconnect");
		}
	}
	template<typename T> void post_msg_to_client_pb(int guid, int gate_id, T* pb)
	{
		auto session = get_gate_session(gate_id);
		if (session && session->is_connect())
		{
			session->send_xc_pb(guid, pb);
		}
		else
		{
			LOG_WARN("gate server[%d] disconnect", gate_id);
		}
	}

	void broadcast_player_count(int count, int ly_android_online_count, int ly_ios_online_count);
	void set_first_connect_db();
	virtual void handler_mysql_connected();
	void Add_Login_Server_Session(const std::string& ip, int port);
	void Add_DB_Server_Session(const std::string& ip, int port);
};
