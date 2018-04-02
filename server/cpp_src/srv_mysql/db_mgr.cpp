#include "db_mgr.h"
#include "db_cfg_mgr.h"
#include "db_server.h"

db_mgr::db_mgr()
{
}

db_mgr::~db_mgr()
{
}


bool db_mgr::tick()
{
	bool ret = true;
	if (!db_connection_account_.tick())
	{
		ret = false;
	}
	if (!db_connection_game_.tick())
	{
		ret = false;
	}
	if (!db_connection_log_.tick())
	{
		ret = false;
	}
	if (!db_connection_recharge_.tick())
	{
		ret = false;
	}

	return ret;
}

void db_mgr::run()
{
	extern bool g_save_sql_to_log;
	

	{
		auto& cfg = db_cfg_mgr::instance()->get_config().login_db();

		db_connection_account_.set_host(cfg.host());
		db_connection_account_.set_user(cfg.user());
		db_connection_account_.set_password(cfg.password());
		db_connection_account_.set_database(cfg.database());
		db_connection_account_.set_save_sql_to_log(g_save_sql_to_log);
	}

	{
	auto& cfg = db_cfg_mgr::instance()->get_config().game_db();

	db_connection_game_.set_host(cfg.host());
	db_connection_game_.set_user(cfg.user());
	db_connection_game_.set_password(cfg.password());
	db_connection_game_.set_database(cfg.database());
	db_connection_game_.set_save_sql_to_log(g_save_sql_to_log);
}

	{
		auto& cfg = db_cfg_mgr::instance()->get_config().log_db();

		db_connection_log_.set_host(cfg.host());
		db_connection_log_.set_user(cfg.user());
		db_connection_log_.set_password(cfg.password());
		db_connection_log_.set_database(cfg.database());
		db_connection_log_.set_save_sql_to_log(g_save_sql_to_log);
	}

	{
		auto& cfg = db_cfg_mgr::instance()->get_config().recharge_db();

		db_connection_recharge_.set_host(cfg.host());
		db_connection_recharge_.set_user(cfg.user());
		db_connection_recharge_.set_password(cfg.password());
		db_connection_recharge_.set_database(cfg.database());
		db_connection_recharge_.set_save_sql_to_log(g_save_sql_to_log);
	}

	auto core_count = db_server::instance()->get_core_count();
	//core_count = 1;
	db_connection_account_.run(1);//用一个线程
	db_connection_game_.run(1);//用一个线程
	db_connection_log_.run(core_count);
	db_connection_recharge_.run(1);//用一个线程
}

void db_mgr::join()
{
	db_connection_account_.join();
	db_connection_game_.join();
	db_connection_log_.join();
	db_connection_recharge_.join();
}

void db_mgr::stop()
{
	db_connection_account_.stop();
	db_connection_game_.stop();
	db_connection_log_.stop();
	db_connection_recharge_.stop();
}

