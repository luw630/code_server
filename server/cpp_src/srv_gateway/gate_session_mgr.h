#pragma once

#include "base_net_server.h"
#include "base_net_dispatcher.h"
#include "Singleton.h"
#include "public_msg.pb.h"
#include "server.pb.h"
#include "public_msg.pb.h"

class gate_client_session;
class gate_login_session;
class gate_game_session;
class GateCenterSession;


class gate_session_mgr : public net_work_holder, public TSingleton < gate_session_mgr >
{
protected:
	std::unordered_map<int, std::shared_ptr<virtual_session>>	client_session_;
	std::vector<std::shared_ptr<virtual_session>>				login_session_;
	std::vector<std::shared_ptr<virtual_session>>				game_session_;
	size_t														cur_login_session_;
	std::set<int>												open_game_list_;
	int															first_connect_db_;
	std::deque<CL_LoginAll>										login_quque_;
	time_t														login_quque_time_;
	std::unordered_set<std::string>								login_quque_account_;
	std::vector<ClientChannelInfo>								ClientChannelInfo_list_;
public:

	
	gate_session_mgr();

	
	virtual ~gate_session_mgr();

	
	virtual void close_all_session();

	
	virtual void release_all_session();

	
	virtual bool tick();

	
	virtual std::shared_ptr<virtual_session> create_session(boost::asio::ip::tcp::socket& socket);

	
	virtual std::shared_ptr<virtual_session> create_login_session(const std::string& ip, unsigned short port);

	
	virtual std::shared_ptr<virtual_session> create_game_session(const std::string& ip, unsigned short port);

	
	virtual void set_network_server(base_net_server* network_server);

	
	std::shared_ptr<virtual_session> get_client_session(int guid);

	
	void add_client_session(std::shared_ptr<virtual_session> session);

	
	void remove_client_session(int guid, int session_id);

	
	std::shared_ptr<virtual_session> get_login_session();

	
	std::shared_ptr<virtual_session> get_game_session(int game_id);

	
	template<typename T> void post_msg_to_login_pb(int guid, T* pb)
	{
		auto session = get_login_session();
		if (session && session->is_connect())
		{
			session->send_xc_pb(guid, pb);
		}
		else
		{
			LOG_WARN("login server disconnect");
		}
	}

	
	template<typename T> void post_msg_to_game_pb(int guid, int game_id, T* pb)
	{
		auto session = get_game_session(game_id);
		if (session && session->is_connect())
		{
			session->send_xc_pb(guid, pb);
		}
		else
		{
			LOG_WARN("game server[%d] disconnect", game_id);
		}
	}

    
    template<typename T> void broadcast_client(T* pb)
    {
        for (auto& player : client_session_)
        {
			player.second->send_pb(pb);
        }
    }
    void SendOnLine();

	void set_first_connect_db();

	virtual void handler_mysql_connected();

	bool in_open_game_list(int id);
	void add_game_id(int game_id);
	void remove_game_id(int game_id);
    void Add_Game_Server_Session(std::string ip, int port);
	void Add_Login_Server_Session(const std::string& ip, int port);
    int find_gameid_by_guid(int guid);

	void add_CL_RegAccount(int gate_id, const CL_RegAccount& msg);
	void add_CL_Login(int gate_id, const CL_Login& msg);
	void add_CL_LoginBySms(int gate_id, const CL_LoginBySms& msg);
	void on_login_quque();
	bool check_login_quque_account(const std::string& account);
	void set_ClientChannelInfo(FG_ClientChannelInfo* msg){
		auto p_info = msg->mutable_info();
		ClientChannelInfo_list_.clear();
		
		for (int i = 0; i<p_info->size(); i++)
		{
			ClientChannelInfo_list_.push_back((*p_info)[i]);
		}
	};
	std::vector<ClientChannelInfo>& get_ClientChannelInfo(){
		return ClientChannelInfo_list_;
	};
};
