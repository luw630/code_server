#include "stdafx.h"

#include "db_server.h"
#include <google/protobuf/text_format.h>
#include <boost/algorithm/string.hpp>

#include "base_db_connection.h"
#include "base_db_connection_pool.h"
#include "public_enum.pb.h"
#include "public_msg.pb.h"
#include "server.pb.h"

#ifdef PLATFORM_WINDOWS

#include "minidump.h"
int __stdcall seh_filter(unsigned int code, struct _EXCEPTION_POINTERS *ep)
{
	time_t t = time(nullptr);
	tm tm_;
	localtime_s(&tm_, &t);

	WCHAR buf[MAX_PATH] = { 0 };
	wsprintf(buf, L"srv_mysql_%d-%02d-%02d_%02d-%02d-%02d.dmp", tm_.tm_year + 1900, tm_.tm_mon + 1, tm_.tm_mday, tm_.tm_hour, tm_.tm_min, tm_.tm_sec);

	CreateMiniDump(ep, buf);

	return EXCEPTION_EXECUTE_HANDLER;
}

#endif

db_server::db_server()
	: fortune_rank_time_(0)
	, daily_earnings_time_(0)
	, weekly_earnings_time_(0)
	, monthly_earnings_year_mon_(0)
    , db_id_(1)
    , init_config_server_(false)
    , first_network_server_(true)
{
}

db_server::~db_server()
{
}


void db_server::on_loadConfigComplete(const DBServerConfig& ncfg)
{
	if (init_config_server_)
		return;

    auto & mycfg = cfg_manager_.get_config();
    mycfg.CopyFrom(ncfg);

	db_manager_ = std::move(std::unique_ptr<db_mgr>(new db_mgr));

	sesssion_manager_ = std::move(std::unique_ptr<db_session_mgr>(new db_session_mgr));
	network_server_ = std::move(std::unique_ptr<base_net_server>(new base_net_server(cfg_manager_.get_config().port(), get_core_count(), sesssion_manager_.get())));
	
	lua_manager_ = std::move(std::unique_ptr<db_lua_mgr>(new db_lua_mgr));
	lua_manager_->init();
	lua_manager_->dofile("../data/script/mysql_db/entry.lua");

	redis_conn_ = std::move(std::unique_ptr<base_redis_con_thread>(new base_redis_con_thread));
	{
		auto& cfg_sentinel = cfg_manager_.get_config().def_sentinel();
		if (cfg_sentinel.size() > 0)
		{
			for (auto& sentinel : cfg_sentinel)
			{
				redis_conn_->add_sentinel(sentinel.ip(), sentinel.port(), sentinel.master_name(), sentinel.dbnum(), sentinel.password());
			}
			redis_conn_->connect_sentinel();
		}
		else
		{
			auto& cfg = cfg_manager_.get_config().def_redis();
			if (cfg.has_ip())
			{
				std::string master_name_tmp;
				redis_conn_->set_master_info(cfg.ip(), cfg.port(), master_name_tmp, cfg.dbnum(), cfg.password());
			}
		}
	}
	redis_conn_->start();

    init_config_server_ = true;
}
bool db_server::init()
{
	if (!base_server::init())
		return false;
	base_game_log::instance()->set_log_print(common_config_.log_print_open());
	std::string filename = "../game_logs/%dƒÍ%02d‘¬%02d»’ srv_mysql_" + boost::lexical_cast<std::string>(get_db_id()) + ".txt";
	base_game_log::instance()->init(filename);

	config_server_ = std::move(std::unique_ptr<db_cfg_net_server>(new db_cfg_net_server));
	config_server_->create_cfg_session(common_config_.config_addr().ip(), common_config_.config_addr().port());
	config_server_->run();

	return true;
}
bool  db_server::LoadSeverConfig()
{
    return true;
}


void db_server::run()
{
#ifdef PLATFORM_WINDOWS
	__try
#endif
	{
		while (is_run_)
		{
			DWORD t0 = GetTickCount();
			DWORD t;
			bool b_sleep = true;
            if (init_config_server_)
            {
                if (first_network_server_)
                {
                    network_server_->run();
					t = GetTickCount();
					if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
					{
						LOG_WARN("timeout 1 start net:%d", t - t0);
						t0 = t;
					}

                    // db
                    db_manager_->run();
					t = GetTickCount();
					if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
					{
						LOG_WARN("timeout 2 start db:%d", t - t0);
						t0 = t;
					}
                    first_network_server_ = false;
                }
                game_time_->tick();
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("timeout 3 timer:%d", t - t0);
					t0 = t;
				}

				if (!sesssion_manager_->tick())
				{
					b_sleep = false;
				}
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("timeout 4 session:%d", t - t0);
					t0 = t;
				}

				if (!db_manager_->tick())
				{
					b_sleep = false;
				}
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("timeout 5 db:%d", t - t0);
					t0 = t;
				}

				if (!redis_conn_->tick())
				{
					b_sleep = false;
				}
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("timeout 6 redis:%d", t - t0);
					t0 = t;
				}

                tick();
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("timeout 7 tick:%d", t - t0);
					t0 = t;
				}

#ifdef _DEBUG
                gm_manager_.exe_gm_command();
#endif
            }
            if (config_server_)
				config_server_->tick();
			t = GetTickCount();
			if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
			{
				LOG_WARN("timeout 8 cfg:%d", t - t0);
				t0 = t;
			}

			print_statistics();
			print_msg_flow();
			t = GetTickCount();
			if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
			{
				LOG_WARN("timeout 9 :%d", t - t0);
				t0 = t;
			}
#ifdef PLATFORM_WINDOWS
			// linux todo
			if (b_sleep)
				Sleep(1);
#endif
		}
        if (init_config_server_)
        {
            db_manager_->stop();


            network_server_->stop();
            redis_conn_->stop();

            network_server_->join();
            redis_conn_->join();
        }
        if (config_server_)
        {
            config_server_->stop();
            config_server_->join();
        }

		sesssion_manager_->release_all_session();

		db_manager_->join();
	}
#ifdef PLATFORM_WINDOWS
	__except (seh_filter(GetExceptionCode(), GetExceptionInformation()))
	{
		printf("seh exception\n");
	}
#endif
}

void db_server::stop()
{
	if (is_run_)
	{
        if (init_config_server_)
        {
            sesssion_manager_->close_all_session();
        }
	}

	base_server::stop();
}

void db_server::release()
{
	network_server_.reset();
	sesssion_manager_.reset();
	db_manager_.reset();
	lua_manager_.reset();
    redis_conn_.reset();
    config_server_.reset();

	base_server::release();
}

void db_server::on_gm_command(const char* cmd)
{
#ifdef _DEBUG
	std::vector<std::string> vc;
	std::string str = boost::trim_copy(std::string(cmd));
	boost::split(vc, str, boost::is_any_of(" \t"), boost::token_compress_on);

	if (!vc.empty())
		gm_manager_.gm_command(vc);
#endif
}

const char* db_server::main_lua_file()
{
	return "../script/mysql_db/entry.lua";
}

static void update_fortune_rank()
{
	/*db_mgr::instance()->get_db_connection_game().execute_query<RankList>([](RankList* data) {
		DE_UpdateRank reply;
		reply.set_rank_type(RANK_TYPE_FORTUNE);
		if (data)
		{
			reply.mutable_pb_rank()->CopyFrom(data->pb_rank_list());
		}

		db_session_mgr::instance()->send2center_pb(&reply);

	}, "pb_rank_list", "CALL get_fortune_rank();");*/
}

static void update_daily_earnings_rank()
{
	/*db_mgr::instance()->get_db_connection_game().execute_query<RankList>([](RankList* data) {
		DE_UpdateRank reply;
		reply.set_rank_type(RANK_TYPE_DAILY_EARNINGS);
		if (data)
		{
			reply.mutable_pb_rank()->CopyFrom(data->pb_rank_list());
		}

		db_session_mgr::instance()->send2center_pb(&reply);

	}, "pb_rank_list", "CALL get_daily_earnings_rank();");*/
}

static void update_weekly_earnings_rank()
{
	/*db_mgr::instance()->get_db_connection_game().execute_query<RankList>([](RankList* data) {
		DE_UpdateRank reply;
		reply.set_rank_type(RANK_TYPE_WEEKLY_EARNINGS);
		if (data)
		{
			reply.mutable_pb_rank()->CopyFrom(data->pb_rank_list());
		}

		db_session_mgr::instance()->send2center_pb(&reply);

	}, "pb_rank_list", "CALL get_weekly_earnings_rank();");*/
}

static void update_monthly_earnings_rank()
{
	/*db_mgr::instance()->get_db_connection_game().execute_query<RankList>([](RankList* data) {
		DE_UpdateRank reply;
		reply.set_rank_type(RANK_TYPE_MONTHLY_EARNINGS);
		if (data)
		{
			reply.mutable_pb_rank()->CopyFrom(data->pb_rank_list());
		}

		db_session_mgr::instance()->send2center_pb(&reply);

	}, "pb_rank_list", "CALL get_monthly_earnings_rank();");*/
}

void db_server::update_rank_to_center()
{
	update_fortune_rank();
	update_daily_earnings_rank();
	update_weekly_earnings_rank();
	update_monthly_earnings_rank();
}

void db_server::tick()
{
	if (fortune_rank_time_ != 0)
	{
		if (base_game_time_mgr::instance()->to_days() != base_game_time_mgr::instance()->to_days(fortune_rank_time_))
		{
			update_fortune_rank();
			fortune_rank_time_ = base_game_time_mgr::instance()->get_second_time();
		}
	}
	else
	{
		fortune_rank_time_ = base_game_time_mgr::instance()->get_second_time();
	}

	if (daily_earnings_time_ != 0 )
	{
		if (base_game_time_mgr::instance()->to_days() != base_game_time_mgr::instance()->to_days(daily_earnings_time_))
		{
			update_daily_earnings_rank();
			daily_earnings_time_ = base_game_time_mgr::instance()->get_second_time();
		}
	}
	else
	{
		daily_earnings_time_ = base_game_time_mgr::instance()->get_second_time();
	}

	if (weekly_earnings_time_ != 0)
	{
		if (base_game_time_mgr::instance()->to_weeks() != base_game_time_mgr::instance()->to_weeks(weekly_earnings_time_))
		{
			update_weekly_earnings_rank();
			weekly_earnings_time_ = base_game_time_mgr::instance()->get_second_time();
		}
	}
	else
	{
		weekly_earnings_time_ = base_game_time_mgr::instance()->get_second_time();
	}

	auto tm = base_game_time_mgr::instance()->get_tm();
	int year_mon = tm->tm_year * 100 + tm->tm_mon;
	if (monthly_earnings_year_mon_ != 0)
	{
		if (monthly_earnings_year_mon_ != year_mon)
		{
			update_monthly_earnings_rank();
			monthly_earnings_year_mon_ = year_mon;
		}
	}
	else
	{
		monthly_earnings_year_mon_ = year_mon;
	}
}

extern bool g_save_sql_to_log = false;
//////////////////////////////////////////////////////////////////////////
int main(int argc, char* argv[])
{
#ifdef PLATFORM_WINDOWS
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

#ifndef _DEBUG
	DeleteMenu(GetSystemMenu(GetConsoleWindow(), FALSE), SC_CLOSE, MF_BYCOMMAND);
	DrawMenuBar(GetConsoleWindow());
#endif

    std::string title = "srv_mysql";

	db_server theServer;
    if (argc > 1)
    {
        theServer.set_db_id(atoi(argv[1]));
        title = str(boost::format("srv_mysql_%02d") % theServer.get_db_id());
    }
	if (argc > 2 && strcmp(argv[2], "save_sql_to_log") == 0)
	{
		g_save_sql_to_log = true;
	}
	theServer.set_print_filename(title);
	theServer.set_msg_flow_log_filename(title);

#ifdef PLATFORM_WINDOWS
	SetConsoleTitleA(title.c_str());
#endif

	theServer.startup();

#ifdef _DEBUG
	system("pause");
#endif // _DEBUG

	return 0;
}
