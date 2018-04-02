
#include "stdafx.h"
#include "gate_server.h"
#include "base_utils_helper.h"
#include <algorithm>
#include <strstream>
#include "./base_http_request.h"



gateway_server::gateway_server()
	: gate_id_(1)
	, init_config_server_(false)
	, first_network_server_(true)
	, rsa_keys_index_(0)
	, rsa_keys_time_(0)
{
}

gateway_server::~gateway_server()
{
}


bool gateway_server::on_NotifyGameServerStart(int game_id)
{
	for (const auto& item : gameserver_cfg_.pb_cfg())
	{
		if (item.game_id() == game_id)
		{
			return false;
		}
	}

	// 没有找到，说明新加了服务器
	return true;
}

void gateway_server::on_UpdateLoginConfigComplete(const S_ReplyUpdateLoginServerConfigByGate& cfg)
{
	auto addr = gate_config_.add_login_addr();
	addr->set_ip(cfg.ip());
	addr->set_port(cfg.port());
	addr->set_server_id(cfg.login_id());

	gate_session_mgr::instance()->Add_Login_Server_Session(cfg.ip(), cfg.port());
}

bool gateway_server::on_NotifyLoginServerStart(int login_id)
{
	for (const auto& item : gate_config_.login_addr())
	{
		if (item.server_id() == login_id)
		{
			return false;
		}
	}

	// 没有找到，说明新加了服务器
	return true;
}

#ifdef PLATFORM_WINDOWS

#include "minidump.h"
int __stdcall seh_filter(unsigned int code, struct _EXCEPTION_POINTERS *ep)
{
	time_t t = time(nullptr);
	tm tm_;
	localtime_s(&tm_, &t);

	WCHAR buf[MAX_PATH] = { 0 };
	wsprintf(buf, L"srv_gateway_%d-%02d-%02d_%02d-%02d-%02d.dmp", tm_.tm_year + 1900, tm_.tm_mon + 1, tm_.tm_mday, tm_.tm_hour, tm_.tm_min, tm_.tm_sec);

	CreateMiniDump(ep, buf);

	return EXCEPTION_EXECUTE_HANDLER;
}

#endif

bool gateway_server::init()
{
	if (!base_server::init())
		return false;

	base_game_log::instance()->set_log_print(common_config_.log_print_open());

	std::string filename = "../game_logs/%d年%02d月%02d日 srv_gateway_" + boost::lexical_cast<std::string>(get_gate_id()) + ".txt";
	base_game_log::instance()->init(filename.c_str());

	sesssion_manager_ = std::move(std::unique_ptr<gate_session_mgr>(new gate_session_mgr));
	ip_manager_ = std::move(std::unique_ptr<ip_mgr>(new ip_mgr));
	ip_manager_->parse_file();

	// 从网络读取配置
	config_server_ = std::move(std::unique_ptr<gate_cfg_net_server>(new gate_cfg_net_server));
	config_server_->create_cfg_session(common_config_.config_addr().ip(), common_config_.config_addr().port());

	config_server_->run();

	asyn_task_manager_ = std::move(std::unique_ptr<base_asyn_task_mgr>(new base_asyn_task_mgr));



	return true;
}

void gateway_server::on_loadConfigComplete(const S_ReplyServerConfig& cfg)
{
	if (init_config_server_)
		return;

	gate_config_.CopyFrom(cfg.gate_config());
	gameserver_cfg_.mutable_pb_cfg()->CopyFrom(cfg.client_room_cfg());



	network_server_ = std::move(std::unique_ptr<base_net_server>(new base_net_server(gate_config_.port(), get_core_count(), sesssion_manager_.get())));

	init_config_server_ = true;
}

void gateway_server::on_UpdateConfigComplete(const S_ReplyUpdateGameServerConfig& cfg)
{
	gameserver_cfg_.mutable_pb_cfg()->CopyFrom(cfg.client_room_cfg());
	gate_session_mgr::instance()->Add_Game_Server_Session(cfg.ip(), cfg.port());
}
void gateway_server::run()
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
				// 启动网络线程
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


				// 消息统计
				print_statistics();
				print_msg_flow();
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("timeout 4 print_statistics:%d", t - t0);
					t0 = t;
				}

				asyn_task_manager_->tick();
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("timeout 5 asyn_task_manager:%d", t - t0);
					t0 = t;
				}
			}

			if (config_server_)
				config_server_->tick();
			t = GetTickCount();
			if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
			{
				LOG_WARN("timeout 6 config_server:%d", t - t0);
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
			network_server_->join();
			sesssion_manager_->release_all_session();
			asyn_task_manager_->stop();
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

void gateway_server::stop()
{
	if (is_run_ && init_config_server_)
		sesssion_manager_->close_all_session();

	base_server::stop();
}

void gateway_server::release()
{
	network_server_.reset();
	sesssion_manager_.reset();

	config_server_.reset();

	base_server::release();
}

void gateway_server::reload_gameserver_config(DL_ServerConfig & cfg)
{
    //cfg_manager_.load_gameserver_config_pb(cfg);
}


void gateway_server::reload_gameserver_config_DB(LG_DBGameConfigMgr & cfg)
{
    //cfg_manager_.load_gameserver_config_pb(cfg);
}

void gateway_server::get_rsa_key(std::string& public_key, std::string& private_key)
{
	if (rsa_keys_.empty() || base_game_time_mgr::instance()->get_second_time() - rsa_keys_time_ >= 3600)
	{
		rsa_keys_.clear();
		for (int i = 0; i < 10; i++)
		{
			crypto_manager::rsa_key(public_key, private_key);
			rsa_keys_.push_back(std::make_pair(public_key, private_key));
		}
		rsa_keys_index_ = 0;
		rsa_keys_time_ = base_game_time_mgr::instance()->get_second_time();
		return;
	}

	++rsa_keys_index_;
	if (rsa_keys_index_ >= rsa_keys_.size())
		rsa_keys_index_ = 0;
	auto& p = rsa_keys_[rsa_keys_index_];
	public_key = p.first;
	private_key = p.second;
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

	std::string title = "srv_gateway";
	
	gateway_server theServer;
	if (argc > 1)
	{
		theServer.set_gate_id(atoi(argv[1]));
		title = str(boost::format("srv_gateway_%02d") % theServer.get_gate_id());
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

