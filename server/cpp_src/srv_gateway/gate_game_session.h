#pragma once

#include "base_net_session.h"
#include "base_net_dispatcher.h"
#include "public_msg.pb.h"
#include "server.pb.h"
#include "gate_session_mgr.h"
#include "base_game_time_mgr.h"

class gate_game_session : public base_net_session
{
private:
	int									    server_id_;
public:
	gate_game_session(boost::asio::io_service& ioservice);
	virtual ~gate_game_session();
	virtual bool handler_msg_dispatch(MsgHeader* header);
	virtual bool handler_connect();
	virtual void handler_connect_failed();
	virtual void on_closed();
	virtual int get_server_id() { return server_id_; }
	void set_server_id(int server_id) { server_id_ = server_id; }
};
