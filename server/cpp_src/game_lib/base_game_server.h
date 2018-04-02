#pragma once

#include "god_include.h"
#include "base_server.h"
#include "game_session_mgr.h"
#include "base_game_lua_mgr.h"
#include "game_web_mgr.h"
#include "base_redis_con_thread.h"
#include "game_cfg_net_server.h"
#include "server.pb.h"

class base_game_server : public base_server
{
protected:
	int													game_id_;
	std::string											game_name_;
	bool												init_config_server_;
	bool												first_network_server_;
	std::unique_ptr<game_cfg_net_server>			config_server_;
	GameServerConfigInfo								game_config_;
	//GameServerConfigManager								cfg_manager_;

	std::unique_ptr<game_session_mgr>					sesssion_manager_;
	std::unique_ptr<base_net_server>						network_server_;
	std::unique_ptr<base_game_lua_mgr>			lua_manager_;
	std::unique_ptr<base_redis_con_thread>				redis_conn_;

#ifdef _DEBUG
	game_web_mgr										gm_manager_;
#endif

	bool												load_cfg_complete_;
public:

	base_game_server();
	~base_game_server();


	virtual bool init();
	virtual void run();
	virtual void stop();
	virtual void release();
	void on_gm_command(const char* cmd);
	virtual const wchar_t* dump_file_name();
	
	int get_game_id() { return game_id_; }
	void set_game_id(int gameid) { game_id_ = gameid; }
	const std::string& get_game_name() { return game_name_; }
	void set_game_name(const std::string& name) { game_name_ = name; }
	bool get_init_config_server() { return init_config_server_; }
	void on_loadConfigComplete(const GameServerConfigInfo& cfg);
	GameServerConfigInfo& get_config() { return game_config_; }

	bool on_NotifyLoginServerStart(int login_id);
	void on_UpdateLoginConfigComplete(const S_ReplyUpdateLoginServerConfigByGame& cfg);
	bool on_NotifyDBServerStart(int db_id);
	void on_UpdateDBConfigComplete(const S_ReplyUpdateDBServerConfigByGame& cfg);

protected:
	virtual void on_tick() {}

	virtual game_session_mgr* new_session_manager();
	virtual base_game_lua_mgr* new_lua_script_manager();
	void init_timer();

};
