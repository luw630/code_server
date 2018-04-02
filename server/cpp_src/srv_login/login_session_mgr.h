#pragma once

#include "base_net_server.h"
#include "base_net_dispatcher.h"
#include "Singleton.h"

class login_session;
class login_db_session;

class login_session_mgr : public net_work_holder, public TSingleton < login_session_mgr >
{
protected:
	base_net_dispatcher_mgr			dispatcher_manager_;
	base_net_dispatcher_mgr			dispatcher_manager_gate_;
	base_net_dispatcher_mgr			dispatcher_manager_game_;
	base_net_dispatcher_mgr			dispatcher_manager_db_;
	base_net_dispatcher_mgr			dispatcher_manager_web_;
	std::vector<std::shared_ptr<virtual_session>> gate_session_;
	std::vector<std::shared_ptr<virtual_session>> game_session_;
	std::vector<std::shared_ptr<virtual_session>> db_session_;
	size_t								cur_db_session_;
	int									first_connect_db_;
	struct RegGameServerInfo
	{
		int first_game_type;
		int second_game_type;
		bool default_lobby;
		int player_limit;
		int cur_player_count;
		int cur_player_ios = 0;
		int cur_player_android = 0;
	};
	std::map<int, RegGameServerInfo>	reg_game_server_info_;
	int	top_player_ios = 0;
	int	top_player_android = 0;
	std::recursive_mutex				mutex_reg_game_server_info_;
public:
	login_session_mgr();
	virtual ~login_session_mgr();
	base_net_dispatcher_mgr* get_dispatcher_manager() { return &dispatcher_manager_; }
	base_net_dispatcher_mgr* get_dispatcher_manager_gate() { return &dispatcher_manager_gate_; }
	base_net_dispatcher_mgr* get_dispatcher_manager_game() { return &dispatcher_manager_game_; }
	base_net_dispatcher_mgr* get_dispatcher_manager_db() { return &dispatcher_manager_db_; }
	base_net_dispatcher_mgr* get_dispatcher_manager_web() { return &dispatcher_manager_web_; }
	std::shared_ptr<virtual_session> get_gate_session(int server_id);
	void add_gate_session(std::shared_ptr<virtual_session> session);
	void del_gate_session(std::shared_ptr<virtual_session> session);
	std::shared_ptr<virtual_session> get_game_session(int server_id);
	void add_game_session(std::shared_ptr<virtual_session> session);
	void del_game_session(std::shared_ptr<virtual_session> session);
	std::shared_ptr<virtual_session> get_db_session();
	void register_message();
	virtual void close_all_session();
	virtual void release_all_session();
	virtual bool tick();
	virtual std::shared_ptr<virtual_session> create_session(boost::asio::ip::tcp::socket& socket);
	virtual std::shared_ptr<virtual_session> create_db_session(const std::string& ip, unsigned short port);
	virtual void set_network_server(base_net_server* network_server);
	template<typename T> void post_msg_to_mysql_pb(T* pb)
	{
		auto session = get_db_session();
		if (session && session->is_connect())
		{
			session->send_pb(pb);
		}
		else
		{
			LOG_WARN("db server disconnect");
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
    template<typename T> bool sendgate_All( T* pb)
    {
        for (auto item : gate_session_)
        {
            if (item)
            {
                return item->send_pb(pb);
            }
            else
            {
                LOG_WARN("gate server[%d] disconnect", item->get_server_id());
            }
        }
        return false;
    }
	template<typename T> bool send2gate_pb(int gate_id, T* pb)
	{
		auto session = get_gate_session(gate_id);
		if (session && session->is_connect())
		{
			return session->send_pb(pb);
		}
		else
		{
			LOG_WARN("gate server[%d] disconnect", gate_id);
		}
		return false;
	}
	template<typename T> int broadcast2gate_pb(T* pb)
	{
		for (auto session : gate_session_)
		{
			session->send_pb(pb);
		}
		return (int)gate_session_.size();
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
	template<typename T> int broadcast2game_pb(T* pb)
	{
		for (auto session : game_session_)
		{
			session->send_pb(pb);
		}
		return (int)game_session_.size();
	}
	template<typename T> void send2web_pb(int id, T* pb)
	{
		auto session = find_by_id(id);
		if (session && session->is_connect())
		{
			session->send_pb(pb);
		}
		else
		{
			LOG_WARN("web server[%d] disconnect", id);
		}
	}

	void add_game_server_info(int game_id, int first_game_type, int second_game_type, bool default_lobby, int player_limit);
	void remove_game_server_info(int game_id);
	bool has_game_server_info(int game_id);
	void update_game_server_player_count(int game_id, class S_UpdateGamePlayerCount* msg);
	int get_game_server_player_count(int fg_id, int sg_id);
	int get_ios_online_top();
	int get_android_online_top();
	void clear_online_info();
	int find_a_default_lobby();
	void print_game_server_info();
	int find_a_game_id(int first_game_type, int second_game_type);
	void set_first_connect_db();
	bool is_first_connect_db();
	virtual void handler_mysql_connected();
	void Add_DB_Server_Session(const std::string& ip, int port);

};
