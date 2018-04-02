#pragma once

#include "base_net_session.h"
#include "base_net_dispatcher.h"
#include "public_msg.pb.h"
#include "server.pb.h"
#include "game_session_mgr.h"

class game_login_session : public base_net_session
{
private:
	base_net_dispatcher_mgr*			dispatcher_manager_;


public:

	game_login_session(boost::asio::io_service& ioservice);
	virtual ~game_login_session();
	virtual bool handler_msg_dispatch(MsgHeader* header);
	virtual bool handler_connect();
	virtual void handler_connect_failed();
	virtual void on_closed();

public:
	void on_wl_request_game_server_info(WL_RequestGameServerInfo* msg);
	void on_wl_request_php_gm_cmd_change_money(LS_ChangeMoney * msg);
	void on_wl_broadcast_gameserver_gmcommand(WL_BroadcastClientUpdate * msg);
	void on_wl_request_LS_LuaCmdPlayerResult(LS_LuaCmdPlayerResult* msg);

};
