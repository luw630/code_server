#pragma once

#include "base_net_session.h"
#include "base_net_dispatcher.h"
#include "public_msg.pb.h"
#include "server.pb.h"

class login_cfg_session : public base_net_session
{
private:
	base_net_dispatcher_mgr*			dispatcher_manager_;
public:
	login_cfg_session(boost::asio::io_service& ioservice);
	virtual ~login_cfg_session();
	virtual bool handler_msg_dispatch(MsgHeader* header);
	virtual bool handler_connect();
	virtual void handler_connect_failed();
	virtual void on_closed();
	void on_S_ReplyServerConfig(S_ReplyServerConfig* msg);
	void on_S_NotifyDBServerStart(S_NotifyDBServerStart* msg);
	void on_S_ReplyUpdateDBServerConfigByLogin(S_ReplyUpdateDBServerConfigByLogin* msg);
	void on_S_Maintain_switch(CS_QueryMaintain* msg);
};
