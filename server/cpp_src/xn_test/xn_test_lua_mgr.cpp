#include "xn_test_lua_mgr.h"

xn_test_lua_mgr::xn_test_lua_mgr()
{
}

xn_test_lua_mgr::~xn_test_lua_mgr()
{
}

void bind_lua_crypto_message(lua_State* L);
void bind_lua_net_message(lua_State* L);

void xn_test_lua_mgr::init()
{
	LuaScriptManager::init();

	bind_lua_crypto_message(L);
	bind_lua_net_message(L);
}
