#pragma once

#include "base_net_session.h"
#include "base_net_dispatcher.h"
#include "public_msg.pb.h"
#include "server.pb.h"
#include "gate_session_mgr.h"


class gate_login_session : public base_net_session
{
public:

	
	gate_login_session(boost::asio::io_service& ioservice);

	
	virtual ~gate_login_session();

	virtual bool handler_msg_dispatch(MsgHeader* header);

	
	virtual bool handler_connect();

	
	virtual void handler_connect_failed();

	
	virtual void on_closed();

    void RetWebCode(int retCode,int retid);
};
