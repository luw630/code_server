#pragma once

#include "base_net_session.h"
#include "base_net_dispatcher.h"
#include "public_msg.pb.h"
#include "server.pb.h"


class game_cfg_session : public base_net_session
{

private:
	base_net_dispatcher_mgr*			dispatcher_manager_;
public:

	
	game_cfg_session(boost::asio::io_service& ioservice);

	
	virtual ~game_cfg_session();

	
	virtual bool handler_msg_dispatch(MsgHeader* header);

	
	virtual bool handler_connect();

	
	virtual void handler_connect_failed();

	
	virtual void on_closed();

public:

	
	void on_S_ReplyServerConfig(S_ReplyServerConfig* msg);

	void on_S_NotifyLoginServerStart(S_NotifyLoginServerStart* msg);

	void on_S_ReplyUpdateLoginServerConfigByGame(S_ReplyUpdateLoginServerConfigByGame* msg);

	void on_S_NotifyDBServerStart(S_NotifyDBServerStart* msg);

	void on_S_ReplyUpdateDBServerConfigByGame(S_ReplyUpdateDBServerConfigByGame* msg);

};
