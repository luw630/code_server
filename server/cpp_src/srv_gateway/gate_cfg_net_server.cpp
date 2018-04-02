#include "gate_cfg_net_server.h"
#include "base_game_log.h"
#include "gate_cfg_session.h"


gate_cfg_net_server::gate_cfg_net_server()
{
	register_login2config_message();
}

gate_cfg_net_server::~gate_cfg_net_server()
{
}


void gate_cfg_net_server::join()
{
	thread_.join();
}

void gate_cfg_net_server::stop()
{
	if (cfg_session_)
		cfg_session_->close();
	work_ptr_.reset();
	io_service_.stop();
}

void gate_cfg_net_server::tick()
{
	if (cfg_session_)
		cfg_session_->tick();
}
void gate_cfg_net_server::register_login2config_message()
{
#define REG_CONFIG_DISPATCHER(Msg, Function) dispatcher_manager_.register_dispatcher(new MsgDispatcher< Msg, gate_cfg_session >(&gate_cfg_session::Function));
	REG_CONFIG_DISPATCHER(S_ReplyServerConfig, on_S_ReplyServerConfig);
	REG_CONFIG_DISPATCHER(S_NotifyGameServerStart, on_S_NotifyGameServerStart);
	REG_CONFIG_DISPATCHER(S_ReplyUpdateGameServerConfig, on_S_ReplyUpdateGameServerConfig);
	REG_CONFIG_DISPATCHER(S_NotifyLoginServerStart, on_S_NotifyLoginServerStart);
	REG_CONFIG_DISPATCHER(S_ReplyUpdateLoginServerConfigByGate, on_S_ReplyUpdateLoginServerConfigByGate);
	REG_CONFIG_DISPATCHER(FG_GameServerCfg, on_FG_GameServerCfg);
	REG_CONFIG_DISPATCHER(FS_ChangMoneyDeal, on_FS_ChangMoneyDeal);
	REG_CONFIG_DISPATCHER(SS_JoinPrivateRoom, on_SS_JoinPrivateRoom);
	REG_CONFIG_DISPATCHER(FG_ClientChannelInfo, on_FG_ClientChannelInfo);
#undef REG_CONFIG_DISPATCHER
}

void gate_cfg_net_server::create_cfg_session(const std::string& ip, unsigned short port)
{
	auto session = std::make_shared<gate_cfg_session>(io_service_);
	session->set_ip_port(ip, port);
	cfg_session_ = std::static_pointer_cast<base_net_session>(session);
}

void gate_cfg_net_server::run()
{
	work_ptr_ = std::move(std::unique_ptr<boost::asio::io_service::work>(new boost::asio::io_service::work(io_service_)));

	thread_ = std::thread([this]() {
		try
		{
			io_service_.run();
		}
		catch (const std::exception& e)
		{
			LOG_ERR(e.what());
		}
	});
}
