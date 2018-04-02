#include "db_cfg_net_server.h"
#include "base_game_log.h"
#include "db_cfg_session.h"



db_cfg_net_server::db_cfg_net_server()
{
    register_db2config_message();
}

db_cfg_net_server::~db_cfg_net_server()
{
}

void db_cfg_net_server::create_cfg_session(const std::string& ip, unsigned short port)
{
    auto session = std::make_shared<db_cfg_session>(io_service_);
    session->set_ip_port(ip, port);
    cfg_session_ = std::static_pointer_cast<base_net_session>(session);
}

void db_cfg_net_server::run()
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

void db_cfg_net_server::join()
{
    thread_.join();
}

void db_cfg_net_server::stop()
{
    if (cfg_session_)
        cfg_session_->close();
    work_ptr_.reset();
    io_service_.stop();
}

void db_cfg_net_server::tick()
{
    if (cfg_session_)
        cfg_session_->tick();
}
void db_cfg_net_server::register_db2config_message()
{
#define REG_CONFIG_DISPATCHER(Msg, Function) dispatcher_manager_.register_dispatcher(new MsgDispatcher< Msg, db_cfg_session >(&db_cfg_session::Function));
	REG_CONFIG_DISPATCHER(S_ReplyServerConfig, on_S_ReplyServerConfig);
	REG_CONFIG_DISPATCHER(FD_ChangMoney, handler_fd_changemoney);
	REG_CONFIG_DISPATCHER(FD_ChangMoneyDeal, handler_fd_changemoneydeal);
#undef REG_CONFIG_DISPATCHER

}
