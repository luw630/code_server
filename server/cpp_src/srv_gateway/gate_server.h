#pragma once

#include "god_include.h"
#include "base_server.h"
#include "gate_session_mgr.h"
#include "ip_mgr.h"
#include "../base_lib/base_asyn_task_mgr.h"
#include "gate_cfg_net_server.h"


class gateway_server : public base_server
{
private:
	int													gate_id_;
	bool												init_config_server_;
	bool												first_network_server_;
	std::unique_ptr<gate_cfg_net_server>			config_server_;
	GateServerConfigInfo								gate_config_;
	GC_GameServerCfg									gameserver_cfg_;
	//gate_cfg_mgr								cfg_manager_;


	std::unique_ptr<gate_session_mgr>					sesssion_manager_;
	std::unique_ptr<base_net_server>						network_server_;

	std::unique_ptr<ip_mgr>						ip_manager_;
	std::unique_ptr<base_asyn_task_mgr>						asyn_task_manager_;

	bool												using_db_config_;

	std::vector<std::pair<std::string, std::string>>	rsa_keys_;
	size_t												rsa_keys_index_;
	time_t												rsa_keys_time_;
public:

	
	gateway_server();

	
	~gateway_server();

	
	virtual bool init();


	virtual void run();

	

	virtual void stop();

	
	virtual void release();
	

    void reload_gameserver_config(DL_ServerConfig & cfg);
    void reload_gameserver_config_DB(LG_DBGameConfigMgr & cfg);

	int get_gate_id() { return gate_id_; }
	void set_gate_id(int gateid) { gate_id_ = gateid; }
	bool get_init_config_server() { return init_config_server_; }
	void on_loadConfigComplete(const S_ReplyServerConfig& cfg);
	void on_UpdateConfigComplete(const S_ReplyUpdateGameServerConfig& cfg);
	bool on_NotifyGameServerStart(int game_id);
	void on_UpdateLoginConfigComplete(const S_ReplyUpdateLoginServerConfigByGate& cfg);
	bool on_NotifyLoginServerStart(int login_id);
	GateServerConfigInfo& get_config() { return gate_config_; }
	GC_GameServerCfg& get_gamecfg() { return gameserver_cfg_; }

	void get_rsa_key(std::string& public_key, std::string& private_key);


};
