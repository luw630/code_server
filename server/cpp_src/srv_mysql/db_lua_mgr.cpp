#include "db_lua_mgr.h"

db_lua_mgr::db_lua_mgr()
{
}

db_lua_mgr::~db_lua_mgr()
{
}

void bind_lua_redis(lua_State* L);
void bind_lua_db_connection_pool(lua_State* L);

void bind_lua_db_net_message(lua_State* L);
void bind_lua_db_manager(lua_State* L);

void db_lua_mgr::init()
{
	base_lua_mgr::init();

	bind_lua_redis(L);
	bind_lua_db_connection_pool(L);
	
	bind_lua_db_net_message(L);
	bind_lua_db_manager(L);
}
