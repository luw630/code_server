#pragma once

#include "god_include.h"
#include "base_server.h"
#include "db_cfg_mgr.h"
#include "db_session_mgr.h"
#include "db_mgr.h"
#include "db_lua_mgr.h"
#include "base_gm_mgr.h"
#include "base_redis_con_thread.h"
#include "db_cfg_net_server.h"


class db_server : public base_server
{
private:
	void tick();
	std::unique_ptr<db_cfg_net_server>			    config_server_;
	db_cfg_mgr								cfg_manager_;
	int													db_id_;
	bool												init_config_server_;
	bool												first_network_server_;
	std::unique_ptr<db_session_mgr>					sesssion_manager_;
	std::unique_ptr<base_net_server>						network_server_;
	std::unique_ptr<db_mgr>							db_manager_;
	std::unique_ptr<db_lua_mgr>					lua_manager_;
	std::unique_ptr<base_redis_con_thread>				redis_conn_;

#ifdef _DEBUG
	web_mgr											gm_manager_;
#endif

	time_t												fortune_rank_time_;
	time_t												daily_earnings_time_;
	time_t												weekly_earnings_time_;
	int													monthly_earnings_year_mon_;
public:
	db_server();
	~db_server();
	virtual bool init();
	virtual void run();
	virtual void stop();
	virtual void release();
	virtual void on_gm_command(const char* cmd);
	virtual const char* main_lua_file();
	void update_rank_to_center();
	virtual bool LoadSeverConfig();
	bool get_init_config_server() { return init_config_server_; }
    void on_loadConfigComplete(const DBServerConfig& cfg);
    int get_db_id() { return db_id_; }
    void set_db_id(int dbid) { db_id_ = dbid; }

};