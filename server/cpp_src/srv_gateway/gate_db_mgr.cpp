#include "gate_db_mgr.h"
#include "gate_cfg_mgr.h"
#if 0
gate_db_mgr::gate_db_mgr()
{
}

gate_db_mgr::~gate_db_mgr()
{
}

void gate_db_mgr::run()
{
	{
		auto& cfg = gate_cfg_mgr::instance()->get_config().config_db();

		db_connection_config_.set_host(cfg.host());
		db_connection_config_.set_user(cfg.user());
		db_connection_config_.set_password(cfg.password());
		db_connection_config_.set_database(cfg.database());
	}

	db_connection_config_.run(1);
}

void gate_db_mgr::join()
{
	db_connection_config_.join();
}

void gate_db_mgr::stop()
{
	db_connection_config_.stop();
}

void gate_db_mgr::tick()
{
	db_connection_config_.tick();
}
#endif
