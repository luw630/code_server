#pragma once

#include "base_net_session.h"
#include "base_net_dispatcher.h"
#include "public_msg.pb.h"
#include "server.pb.h"
#include "game_session_mgr.h"

class game_db_session : public base_net_session
{
private:
	base_net_dispatcher_mgr*			dispatcher_manager_;
public:
	game_db_session(boost::asio::io_service& ioservice);
	virtual ~game_db_session();
	virtual bool handler_msg_dispatch(MsgHeader* header);
	virtual bool handler_connect();
	virtual void handler_connect_failed();
	virtual void on_closed();

};
