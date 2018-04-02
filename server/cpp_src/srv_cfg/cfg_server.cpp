
#include "stdafx.h"

#include "cfg_server.h"
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
	wsprintf(buf, L"srv_cfg_%d-%02d-%02d_%02d-%02d-%02d.dmp", tm_.tm_year + 1900, tm_.tm_mon + 1, tm_.tm_mday, tm_.tm_hour, tm_.tm_min, tm_.tm_sec);

	CreateMiniDump(ep, buf);

	return EXCEPTION_EXECUTE_HANDLER;
}

#endif

cfg_server::cfg_server()
{
}

cfg_server::~cfg_server()
{
}

bool cfg_server::init()
{
	if (!base_server::init())
		return false;

	base_game_log::instance()->init("../game_logs/%dÄê%02dÔÂ%02dÈÕ srv_cfg.txt");

	if (!cfg_manager_.load_config())
		return false;

	base_game_log::instance()->set_log_print(cfg_manager_.get_config().log_print_open());

	db_manager_ = std::move(std::unique_ptr<cfg_db_mgr>(new cfg_db_mgr));

	sesssion_manager_ = std::move(std::unique_ptr<cfg_session_mgr>(new cfg_session_mgr));
	network_server_ = std::move(std::unique_ptr<base_net_server>(new base_net_server(cfg_manager_.get_config().port(), get_core_count(), sesssion_manager_.get())));
	
	return true;
}

bool  cfg_server::LoadSeverConfig()
{
    cfg_db_mgr::instance()->get_db_connection_config().execute_query_vstring([this](std::vector<std::vector<std::string>>* data) {
        if (data)
        {

            DBGameConfigMgr &dbgamer_config = cfg_session_mgr::instance()->GetServerCfg();
            dbgamer_config.clear_pb_cfg();
            for (auto& item : *data)
            {
                auto dbcfg = dbgamer_config.add_pb_cfg();
                dbcfg->set_cfg_name(item[0]);
                dbcfg->set_is_open(boost::lexical_cast<int>(item[1]));
                dbcfg->set_using_login_validatebox(boost::lexical_cast<int>(item[2]));
                dbcfg->set_ip(item[3]);
                dbcfg->set_port(boost::lexical_cast<int>(item[4]));
                dbcfg->set_game_id(boost::lexical_cast<int>(item[5]));
                dbcfg->set_first_game_type(boost::lexical_cast<int>(item[6]));
                dbcfg->set_second_game_type(boost::lexical_cast<int>(item[7]));
                dbcfg->set_game_name(item[8]);
                dbcfg->set_game_log(item[9]);
                dbcfg->set_default_lobby(boost::lexical_cast<int>(item[10]));
                dbcfg->set_player_limit(boost::lexical_cast<int>(item[11]));
                dbcfg->set_data_path(item[12]);
                dbcfg->set_room_list(item[13]);
                dbcfg->set_room_lua_cfg(item[14]);
            }
        }
        else
        {
            LOG_ERR("load cfg from db error");
        }
    }, "SELECT * FROM t_game_server_cfg;");
    return true;
}

void cfg_server::init_timer()
{
	class updata_black_player_to_gameserver_timer : public game_timer
	{
	public:
		updata_black_player_to_gameserver_timer(float deley) : game_timer(deley){}
	protected:
		virtual void on_time(float delta) {

			cfg_db_mgr::instance()->get_db_connection_game().execute_query_vstring([](std::vector<std::vector<std::string>>* data) {
				if (data)
				{
					std::vector<int>  black_list;
					for (auto& item : *data)
					{
						black_list.push_back(boost::lexical_cast<int>(item[0]));
					}
					std::vector<std::string>  game_list;
					for (auto& item : *data)
					{
						game_list.push_back(boost::lexical_cast<std::string>(item[1]));
					}

					FS_Black_List msg;
					auto ttt = msg.mutable_black_list();
					for (auto& item : black_list)
					{	
						//ttt->Add(item);
						msg.add_black_list(item);
					}
					
					auto glist = msg.mutable_game_list();
					for (auto& item : game_list)
					{
						msg.add_game_list(item);
					}

					cfg_session_mgr::instance()->broadcast2game_pb(&msg);
				}
				else
				{
					FS_Black_List msg;
					cfg_session_mgr::instance()->broadcast2game_pb(&msg);
				}
			}, "SELECT guid,game_name FROM t_game_blacklist;");

			auto ss_task = new updata_black_player_to_gameserver_timer(60);
			base_game_time_mgr::instance()->add_timer(ss_task);
		}
	};
	auto ss_task = new updata_black_player_to_gameserver_timer(15);
	base_game_time_mgr::instance()->add_timer(ss_task);

	/*
	class load_playerinfo_timer : public game_timer
	{
	public:
		load_playerinfo_timer(float deley) : game_timer(deley){}
	protected:
		virtual void on_time(float delta) {

			cfg_db_mgr::instance()->get_db_connection_game().execute_query_vstring([](std::vector<std::vector<std::string>>* data) {
				int player_count = 0;
				if (data)
				{
					for (auto& item : *data)
					{
						player_count = player_count + 1;
						PlayerInfoInMemery tmp;
						tmp.set_guid(boost::lexical_cast<int>(item[0]));
						tmp.set_money(boost::lexical_cast<int>(item[1]));
						tmp.set_bank(boost::lexical_cast<int>(item[2]));
						(static_cast<cfg_server*>(base_server::instance()))->set_player_info_in_memery(tmp);
					}
				}
				LOG_INFO("------------------cfg load player count %d ----------------",player_count);
				LOG_INFO("\n------------------you can start other server now ----------------\n------------------you can start other server now ----------------\n------------------you can start other server now ----------------");
			}, "SELECT guid,money,bank FROM t_player;");
		}
	};
	auto load_task = new load_playerinfo_timer(3);
	base_game_time_mgr::instance()->add_timer(load_task);
	LOG_INFO("------------------do not start other server now ----------------");
	LOG_INFO("------------------do not start other server now ----------------");
	LOG_INFO("------------------do not start other server now ----------------");
	LOG_INFO("------------------do not start other server now ----------------");
	*/
}

void cfg_server::begin_save_players_info_to_mysql()
{
	player_info_in_memery_tmp_ = player_info_in_memery_;
	save_players_info_to_mysql();
}
void cfg_server::save_players_info_to_mysql()
{
	if (!player_info_in_memery_tmp_.empty())
	{
		auto iter = player_info_in_memery_tmp_.begin();
		int money = iter->second.money();
		int bank = iter->second.bank();
		int guid = iter->second.guid();
		cfg_db_mgr::instance()->get_db_connection_game().execute_update([this,money,bank,guid](int ret){
			auto itertmp = player_info_in_memery_tmp_.find(guid);
			if (itertmp != player_info_in_memery_tmp_.end())
			{
				LOG_INFO("save guid %d money %d bank %d .........",itertmp->second.guid(),itertmp->second.money(),itertmp->second.bank());
				printf("saving ...\n");
				player_info_in_memery_tmp_.erase(itertmp);
			}
			save_players_info_to_mysql();
		},"update t_player set money = %d,bank = %d where guid=%d;",
		money,bank,guid);
	}
	else
	{
		LOG_INFO("save_players_info_to_mysql finish .........");
		printf("save_players_info_to_mysql finish .........\n");
	}
}

void cfg_server::run()
{
#ifdef PLATFORM_WINDOWS
	__try
#endif
	{
		db_manager_->run();

		network_server_->run();

		init_timer();
		while (is_run_)
		{
			DWORD t0 = GetTickCount();
			DWORD t;
			bool b_sleep = true;
			game_time_->tick();

			if (!sesssion_manager_->tick())
			{
				b_sleep = false;
			}
			t = GetTickCount();
			if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
			{
				LOG_WARN("timeout 1 session net:%d", t - t0);
				t0 = t;
			}

			db_manager_->tick();
			t = GetTickCount();
			if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
			{
				LOG_WARN("timeout 2 db net:%d", t - t0);
				t0 = t;
			}

			tick();
			t = GetTickCount();
			if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
			{
				LOG_WARN("timeout 3 tick net:%d", t - t0);
				t0 = t;
			}

#ifdef _DEBUG
			gm_manager_.exe_gm_command();
#endif

			print_statistics();
			print_msg_flow();

			t = GetTickCount();
			if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
			{
				LOG_WARN("timeout 4 net:%d", t - t0);
				t0 = t;
			}
#ifdef PLATFORM_WINDOWS
			if (b_sleep)
				Sleep(1);
#endif
		}

		db_manager_->stop();


		network_server_->stop();

		network_server_->join();

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

void cfg_server::stop()
{
	if (is_run_)
	{
		sesssion_manager_->close_all_session();
	}

	base_server::stop();
}

void cfg_server::release()
{
	network_server_.reset();
	sesssion_manager_.reset();
	db_manager_.reset();

	base_server::release();
}

void cfg_server::on_gm_command(const char* cmd)
{
#ifdef _DEBUG
	std::vector<std::string> vc;
	std::string str = boost::trim_copy(std::string(cmd));
	boost::split(vc, str, boost::is_any_of(" \t"), boost::token_compress_on);

	if (!vc.empty())
		gm_manager_.gm_command(vc);
#endif
}

void cfg_server::tick()
{
}

extern bool g_save_sql_to_log = false;

int main(int argc, char* argv[])
{
#ifdef PLATFORM_WINDOWS
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif
#ifndef _DEBUG
	DeleteMenu(GetSystemMenu(GetConsoleWindow(), FALSE), SC_CLOSE, MF_BYCOMMAND);
	DrawMenuBar(GetConsoleWindow());
#endif

	cfg_server theServer;
	//if (argc > 1)
	//	cfg_server_cfg_mgr::instance()->set_cfg_file_name(argv[1]);
	if (argc > 1 && strcmp(argv[1],"save_sql_to_log") == 0)
	{
		g_save_sql_to_log = true;
	}
	theServer.set_print_filename("srv_cfg");
	theServer.set_msg_flow_log_filename("srv_cfg");
#ifdef PLATFORM_WINDOWS
	SetConsoleTitleA("srv_cfg");
#endif
	theServer.startup();

#ifdef _DEBUG
	system("pause");
#endif // _DEBUG

	return 0;
}
