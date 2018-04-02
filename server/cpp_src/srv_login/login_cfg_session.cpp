#include "login_cfg_session.h"
#include "base_game_log.h"
#include "public_enum.pb.h"
#include "login_server.h"
#include "login_cfg_net_server.h"

login_cfg_session::login_cfg_session(boost::asio::io_service& ioservice)
	: base_net_session(ioservice)
	, dispatcher_manager_(nullptr)
{
	dispatcher_manager_ = login_cfg_net_server::instance()->get_dispatcher_manager();
}

login_cfg_session::~login_cfg_session()
{
}
void login_cfg_session::on_closed()
{
	LOG_INFO("srv_login<-->srv_cfg disconnect ... <%s:%d>", ip_.c_str(), port_);

	base_net_session::on_closed();
}

bool login_cfg_session::handler_connect()
{
	LOG_INFO("srv_login<-->srv_cfg connect success ... <%s:%d>", ip_.c_str(), port_);
	
	if (!static_cast<login_server*>(base_server::instance())->get_init_config_server())
	{
		S_RequestServerConfig msg;
		msg.set_type(ServerSessionFromLogin);
		msg.set_server_id(static_cast<login_server*>(base_server::instance())->get_login_id());
		send_pb(&msg);
	}
	else
	{
		S_Connect msg;
		msg.set_type(ServerSessionFromLogin);
		msg.set_server_id(static_cast<login_server*>(base_server::instance())->get_login_id());
		send_pb(&msg);
	}

	return base_net_session::handler_connect();
}

void login_cfg_session::handler_connect_failed()
{
	LOG_INFO("srv_login<-->srv_cfg connect failed ... <%s:%d>", ip_.c_str(), port_);

	base_net_session::handler_connect_failed();
}



bool login_cfg_session::handler_msg_dispatch(MsgHeader* header)
{
	if (header->id == S_Heartbeat::ID)
	{
		return true;
	}

	auto dispatcher = dispatcher_manager_->query_dispatcher(header->id);
	if (nullptr == dispatcher)
	{
		LOG_ERR("msg[%d] not registered", header->id);
		return true;
	}

	return dispatcher->parse(this, header);
}

void login_cfg_session::on_S_ReplyServerConfig(S_ReplyServerConfig* msg)
{
	static_cast<login_server*>(base_server::instance())->on_loadConfigComplete(msg->login_config());
}

void login_cfg_session::on_S_NotifyDBServerStart(S_NotifyDBServerStart* msg)
{
	if (static_cast<login_server*>(base_server::instance())->on_NotifyDBServerStart(msg->db_id()))
	{
		S_RequestUpdateDBServerConfigByLogin request;
		request.set_db_id(msg->db_id());
		send_pb(&request);
	}
}

void login_cfg_session::on_S_ReplyUpdateDBServerConfigByLogin(S_ReplyUpdateDBServerConfigByLogin* msg)
{
	static_cast<login_server*>(base_server::instance())->on_UpdateDBConfigComplete(*msg);

	LOG_INFO("load config on_S_ReplyUpdateDBServerConfigByLogin\n");
}


void login_cfg_session::on_S_Maintain_switch(CS_QueryMaintain* msg)
{
	LOG_INFO("on_S_Maintain_switch  id = [%d],value=[%d]\n", msg->maintaintype(), msg->switchopen());
	int open_switch = msg->switchopen();

	static_cast<login_server*>(base_server::instance())->set_maintain_switch(open_switch);

}