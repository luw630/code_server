#pragma once

#include "base_lua_db_connection_pool.h"
#include "Singleton.h"
#include "public_msg.pb.h"

class cfg_db_mgr : public TSingleton<cfg_db_mgr>
{
protected:
	base_lua_db_connection_pool							db_connection_config_;
	base_lua_db_connection_pool							db_connection_game_;
public:
	cfg_db_mgr();
	virtual ~cfg_db_mgr();
	void run();
	void join();
	void stop();
	virtual void tick();
	base_lua_db_connection_pool& get_db_connection_config() { return db_connection_config_; }
	base_lua_db_connection_pool& get_db_connection_game() { return db_connection_game_; }
};
