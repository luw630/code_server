#pragma once

#include "god_include.h"
#include "base_server.h"
#include "login_session_mgr.h"
#include "base_redis_con_thread.h"
#include "login_cfg_net_server.h"
#include "server.pb.h"
#include "web_server_mgr.h"

class login_server : public base_server
{
private:
	int													login_id_;
	bool												init_config_server_;
	bool												first_network_server_;
	std::unique_ptr<login_cfg_net_server>			config_server_;
	LoginServerConfigInfo								login_config_;
	std::unique_ptr<login_session_mgr>				sesssion_manager_;
	std::unique_ptr<base_net_server>						network_server_;
	std::unique_ptr<base_redis_con_thread>				redis_conn_;
	int													maintain_switch;
	std::unique_ptr<web_server_mgr>						web_gm_manager_;
public:
	login_server();
	~login_server();
	int get_login_id() {
		return login_id_;
	}
	void set_login_id(int loginid) {
		login_id_ = loginid;
	}
	bool get_init_config_server() {
		return init_config_server_;
	}
	void on_loadConfigComplete(const LoginServerConfigInfo& cfg);
	LoginServerConfigInfo& get_config() {
		return login_config_;
	}
	bool on_NotifyDBServerStart(int db_id);
	void on_UpdateDBConfigComplete(const S_ReplyUpdateDBServerConfigByLogin& cfg);
	void set_maintain_switch(int open_switch) {
		maintain_switch = open_switch;
	};
	int get_maintain_switch() {
		return maintain_switch;
	};
	virtual bool init();
	virtual void run();
	virtual void stop();
	virtual void release();
	void init_timer();
};