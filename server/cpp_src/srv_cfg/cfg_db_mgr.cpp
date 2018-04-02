#include "cfg_db_mgr.h"
#include "cfg_server_cfg_mgr.h"
#include "cfg_server.h"

cfg_db_mgr::cfg_db_mgr()
{
}

cfg_db_mgr::~cfg_db_mgr()
{
}

void cfg_db_mgr::run()
{
	extern bool g_save_sql_to_log;
	{
		auto& cfg = cfg_server_cfg_mgr::instance()->get_config().config_db();

		db_connection_config_.set_host(cfg.host());
		db_connection_config_.set_user(cfg.user());
		db_connection_config_.set_password(cfg.password());
		db_connection_config_.set_database(cfg.database());
		db_connection_config_.set_save_sql_to_log(g_save_sql_to_log);
	}

	{
		auto& cfg = cfg_server_cfg_mgr::instance()->get_config().config_game();

		db_connection_game_.set_host(cfg.host());
		db_connection_game_.set_user(cfg.user());
		db_connection_game_.set_password(cfg.password());
		db_connection_game_.set_database(cfg.database());
		db_connection_game_.set_save_sql_to_log(g_save_sql_to_log);
	}

	
	//auto core_count = cfg_server::instance()->get_core_count();
	size_t core_count = 1;
	db_connection_config_.run(core_count);
	db_connection_game_.run(core_count);
}

void cfg_db_mgr::join()
{
	db_connection_config_.join();
	db_connection_game_.join();
}

void cfg_db_mgr::stop()
{
	db_connection_config_.stop();
	db_connection_game_.stop();
}

void cfg_db_mgr::tick()
{
	db_connection_config_.tick();
	db_connection_game_.tick();
}
