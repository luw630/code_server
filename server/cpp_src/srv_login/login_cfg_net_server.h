#pragma once

#include "god_include.h"
#include "base_net_session.h"
#include "base_net_dispatcher.h"

class login_cfg_net_server : public TSingleton < login_cfg_net_server >
{
private:
	boost::asio::io_service					io_service_;
	std::unique_ptr<boost::asio::io_service::work> work_ptr_;
	std::thread								thread_;
	std::shared_ptr<virtual_session>			cfg_session_;
	base_net_dispatcher_mgr				dispatcher_manager_;
public:
	login_cfg_net_server();
	~login_cfg_net_server();
	void register_login2config_message();
	void create_cfg_session(const std::string& ip, unsigned short port);
	base_net_dispatcher_mgr* get_dispatcher_manager() { return &dispatcher_manager_; }
	void run();
	void join();
	void stop();
	void tick();
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
};
