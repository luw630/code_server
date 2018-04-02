#pragma once

#include "base_lua_db_connection_pool.h"
#include "Singleton.h"
#include "public_msg.pb.h"

class db_mgr : public TSingleton<db_mgr>
{
protected:
	base_lua_db_connection_pool							db_connection_account_;
	base_lua_db_connection_pool							db_connection_game_;
	base_lua_db_connection_pool							db_connection_log_;
	base_lua_db_connection_pool							db_connection_recharge_;
public:
	db_mgr();
	virtual ~db_mgr();
	void run();
	void join();
	void stop();
	virtual bool tick();
	base_lua_db_connection_pool& get_db_connection_account() { return db_connection_account_; }
	base_lua_db_connection_pool& get_db_connection_game() { return db_connection_game_; }
    base_lua_db_connection_pool& get_db_connection_recharge() { return db_connection_recharge_; }
	base_lua_db_connection_pool& get_db_connection_log() { return db_connection_log_; }
};
