#include "base_lua_mgr.h"
#include "db_mgr.h"
#include "db_cfg_mgr.h"
#include "base_utils_helper.h"

static base_lua_db_connection_pool* get_account_db()
{
	return &db_mgr::instance()->get_db_connection_account();
}

static base_lua_db_connection_pool* get_game_db()
{
	return &db_mgr::instance()->get_db_connection_game();
}

static base_lua_db_connection_pool* get_log_db()
{
	return &db_mgr::instance()->get_db_connection_log();
}

static base_lua_db_connection_pool* get_recharge_db()
{
    return &db_mgr::instance()->get_db_connection_recharge();
}

static const char* get_sd_cash_money_addr()
{
	if (db_cfg_mgr::instance())
		return db_cfg_mgr::instance()->get_config().cash_money_addr().c_str();
	else
		return "";
}

static int32_t get_init_money()
{
	if (db_cfg_mgr::instance())
	{
		return db_cfg_mgr::instance()->get_config().init_money();
	}
	
	return 0;
}

static const char* get_php_interface_addr()
{
    if (db_cfg_mgr::instance())
        return db_cfg_mgr::instance()->get_config().php_interface_addr().c_str();
    else
        return "";
}
static const char* get_php_sign_key()
{
    if (db_cfg_mgr::instance())
        return db_cfg_mgr::instance()->get_config().php_sign_key().c_str();
    else
        return "";
}

static std::string get_to_md5(std::string str)
{
	return crypto_manager::md5(str);
}

void bind_lua_db_manager(lua_State* L)
{
	lua_tinker::def(L, "get_account_db", get_account_db);
	lua_tinker::def(L, "get_game_db", get_game_db);
    lua_tinker::def(L, "get_log_db", get_log_db);
	lua_tinker::def(L, "get_recharge_db", get_recharge_db);
	lua_tinker::def(L, "get_init_money", get_init_money);
    lua_tinker::def(L, "get_php_interface_addr", get_php_interface_addr);
    lua_tinker::def(L, "get_php_sign_key", get_php_sign_key);
    lua_tinker::def(L, "get_to_md5", get_to_md5);
	lua_tinker::def(L, "get_sd_cash_money_addr", get_sd_cash_money_addr);
}
