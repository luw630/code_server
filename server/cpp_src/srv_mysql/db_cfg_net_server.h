#pragma once

#include "god_include.h"
#include "base_net_session.h"
#include "base_net_dispatcher.h"

class db_cfg_net_server : public TSingleton < db_cfg_net_server >
{
private:
	boost::asio::io_service					io_service_;
	std::unique_ptr<boost::asio::io_service::work> work_ptr_;
	std::thread								thread_;
	std::shared_ptr<virtual_session>			cfg_session_;
	base_net_dispatcher_mgr				dispatcher_manager_;
public:
    db_cfg_net_server();
    ~db_cfg_net_server();
    void register_db2config_message();
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
    template<typename T> void post_msg_to_cfg_pb(T* pb)
    {
		if (cfg_session_ && cfg_session_->is_connect())
        {
            cfg_session_->send_pb(pb);
        }
        else
        {
            LOG_WARN("cfg server disconnect");
        }
    }
	void post_msg_to_cfg_spb(unsigned short msgid, std::string& spb)
    {
		if (cfg_session_ && cfg_session_->is_connect())
        {
            cfg_session_->send_spb(msgid,spb);
        }
        else
        {
            LOG_WARN("cfg server disconnect");
        }
    }

};
