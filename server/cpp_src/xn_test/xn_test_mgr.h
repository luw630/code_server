#pragma once

#include "perinclude.h"
#include "Singleton.h"
#include "base_windows_console.h"
#include "base_game_time_mgr.h"
#include "base_game_log.h"
#include "game_client_session.h"
#include "xn_test_lua_mgr.h"


class xn_test_mgr : public TSingleton < xn_test_mgr >
{
public:
	xn_test_mgr();

	virtual ~xn_test_mgr();

	virtual void startup();

	virtual bool init();
	virtual void run();
	virtual void stop();
	virtual void release();

	std::shared_ptr<NetworkSession> get_session(int client_id);
	NetworkDispatcherManager* get_dispatcher_manager() { return &dispatcher_manager_; }

protected:
	std::shared_ptr<NetworkSession> create_client_session(int client_id, const std::string& ip, unsigned short port);

protected:
#ifdef _DEBUG
	WindowsConsole									windows_console_;
#endif // _DEBUG
	std::unique_ptr<GameTimeManager>				game_time_;
	std::unique_ptr<GameLog>						game_log_;

	std::thread										thread_;
	volatile bool									is_run_;

	boost::asio::io_service							ioservice_;
	std::shared_ptr<boost::asio::io_service::work>	work_;
	std::thread										thread_net_;
	std::vector<std::shared_ptr<NetworkSession>>	session_;
	NetworkDispatcherManager						dispatcher_manager_;

	std::unique_ptr<xn_test_lua_mgr>		lua_manager_;
};
