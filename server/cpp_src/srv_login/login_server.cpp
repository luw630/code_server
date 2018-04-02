#include "stdafx.h"
#include "login_server.h"
#include <google/protobuf/text_format.h>

#ifdef PLATFORM_WINDOWS

#include "minidump.h"
int __stdcall seh_filter(unsigned int code, struct _EXCEPTION_POINTERS *ep)
{
	time_t t = time(nullptr);
	tm tm_;
	localtime_s(&tm_, &t);

	WCHAR buf[MAX_PATH] = { 0 };
	wsprintf(buf, L"srv_login_%d-%02d-%02d_%02d-%02d-%02d.dmp", tm_.tm_year + 1900, tm_.tm_mon + 1, tm_.tm_mday, tm_.tm_hour, tm_.tm_min, tm_.tm_sec);

	CreateMiniDump(ep, buf);

	return EXCEPTION_EXECUTE_HANDLER;
}

#endif

login_server::login_server()
	: login_id_(1)
	, init_config_server_(false)
	, first_network_server_(true)
{
}

login_server::~login_server()
{
}

bool login_server::init()
{	
	if (!base_server::init())
		return false;

	base_game_log::instance()->set_log_print(common_config_.log_print_open());

	std::string filename = "../game_logs/%d年%02d月%02d日 srv_login_" + boost::lexical_cast<std::string>(get_login_id()) + ".txt";
	base_game_log::instance()->init(filename.c_str());

	config_server_ = std::move(std::unique_ptr<login_cfg_net_server>(new login_cfg_net_server));
	config_server_->create_cfg_session(common_config_.config_addr().ip(), common_config_.config_addr().port());

	config_server_->run();

	return true;
}

void login_server::on_loadConfigComplete(const LoginServerConfigInfo& cfg)
{
	if (init_config_server_)
		return;

	login_config_.CopyFrom(cfg);

	web_gm_manager_ = std::move(std::unique_ptr<web_server_mgr>(new web_server_mgr));
	sesssion_manager_ = std::move(std::unique_ptr<login_session_mgr>(new login_session_mgr));
	network_server_ = std::move(std::unique_ptr<base_net_server>(new base_net_server(login_config_.port(), get_core_count(), sesssion_manager_.get())));

	redis_conn_ = std::move(std::unique_ptr<base_redis_con_thread>(new base_redis_con_thread));
	{
		auto& cfg_sentinel = login_config_.def_sentinel();
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
			auto& cfg = login_config_.def_redis();
			if (cfg.has_ip())
			{
				std::string master_name_tmp;
				redis_conn_->set_master_info(cfg.ip(), cfg.port(), master_name_tmp, cfg.dbnum(), cfg.password());
			}
		}
	}
	redis_conn_->start();

	init_config_server_ = true;
	init_timer();
}
void login_server::init_timer()
{
	//每日凌晨
	class game_server_daily_timer : public game_timer
	{
	public:
		game_server_daily_timer(float deley) : game_timer(deley){}
	
	protected:
		virtual void on_time(float delta) {
			login_session_mgr::instance()->clear_online_info();

			auto ss_task = new game_server_daily_timer(24 * 60 * 60);
			base_game_time_mgr::instance()->add_timer(ss_task);
		}
	};

	const tm* tp_tm = base_game_time_mgr::instance()->get_tm();
	int left_sec = 24 * 60 * 60 - tp_tm->tm_hour * 3600 - tp_tm->tm_min * 60 - tp_tm->tm_sec;

	auto ss_task = new game_server_daily_timer(left_sec);
	base_game_time_mgr::instance()->add_timer(ss_task);
}



void login_server::run()
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
					first_network_server_ = false;
					t = GetTickCount();
					if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
					{
						LOG_WARN("timeout 1 start net:%d", t - t0);
						t0 = t;
					}
				}

				game_time_->tick();
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("timeout 2 timer:%d", t - t0);
					t0 = t;
				}

				if (!sesssion_manager_->tick())
				{
					b_sleep = false;
				}
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("timeout 3 session:%d", t - t0);
					t0 = t;
				}

				if (!redis_conn_->tick())
				{
					b_sleep = false;
				}
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("timeout 4 redis:%d", t - t0);
					t0 = t;
				}

				print_statistics();
				print_msg_flow();
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("timeout 5 :%d", t - t0);
					t0 = t;
				}
			}

			if (config_server_)
				config_server_->tick();
			t = GetTickCount();
			if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
			{
				LOG_WARN("timeout 6 cfg:%d", t - t0);
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
			network_server_->stop();
			redis_conn_->stop();

			network_server_->join();
			redis_conn_->join();

			sesssion_manager_->release_all_session();
		}

		if (config_server_)
		{
			config_server_->stop();
			config_server_->join();
		}
	}
#ifdef PLATFORM_WINDOWS
	__except (seh_filter(GetExceptionCode(), GetExceptionInformation()))
	{
		printf("seh exception\n");
	}
#endif
}

void login_server::stop()
{
	if (is_run_ && init_config_server_)
		sesssion_manager_->close_all_session();

	base_server::stop();
}

void login_server::release()
{
	network_server_.reset();
	sesssion_manager_.reset();
	redis_conn_.reset();

	config_server_.reset();

	base_server::release();
}

bool login_server::on_NotifyDBServerStart(int db_id)
{
	for (const auto& item : login_config_.db_addr())
	{
		if (item.server_id() == db_id)
		{
			return false;
		}
	}

	return true;
}

void login_server::on_UpdateDBConfigComplete(const S_ReplyUpdateDBServerConfigByLogin& cfg)
{
	auto addr = login_config_.add_db_addr();
	addr->set_ip(cfg.ip());
	addr->set_port(cfg.port());
	addr->set_server_id(cfg.db_id());

	login_session_mgr::instance()->Add_DB_Server_Session(cfg.ip(), cfg.port());
}


int main(int argc, char* argv[])
{
#ifdef PLATFORM_WINDOWS
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

#ifndef _DEBUG
	DeleteMenu(GetSystemMenu(GetConsoleWindow(), FALSE), SC_CLOSE, MF_BYCOMMAND);
	DrawMenuBar(GetConsoleWindow());
#endif

	std::string title = "srv_login";

	login_server theServer;
	if (argc > 1)
	{
		theServer.set_login_id(atoi(argv[1]));
		title = str(boost::format("srv_login_%02d") % theServer.get_login_id());
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
