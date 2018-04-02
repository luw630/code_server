#pragma once

#include "base_net_session.h"
#include "base_net_dispatcher.h"
#include "public_msg.pb.h"
#include "server.pb.h"


class gate_cfg_session : public base_net_session
{
private:
	base_net_dispatcher_mgr*			dispatcher_manager_;
public:

	gate_cfg_session(boost::asio::io_service& ioservice);

	virtual ~gate_cfg_session();

	virtual bool handler_msg_dispatch(MsgHeader* header);

	virtual bool handler_connect();

	
	virtual void handler_connect_failed();

	
	virtual void on_closed();

public:


	void on_S_ReplyServerConfig(S_ReplyServerConfig* msg);

	void on_S_NotifyGameServerStart(S_NotifyGameServerStart* msg);

	void on_S_ReplyUpdateGameServerConfig(S_ReplyUpdateGameServerConfig* msg);


	void on_S_NotifyLoginServerStart(S_NotifyLoginServerStart* msg);

	void on_S_ReplyUpdateLoginServerConfigByGate(S_ReplyUpdateLoginServerConfigByGate* msg);

    void on_FG_GameServerCfg(FG_GameServerCfg * msg);

    void on_FS_ChangMoneyDeal(FS_ChangMoneyDeal * msg);

	void on_SS_JoinPrivateRoom(SS_JoinPrivateRoom* msg);

	void on_FG_ClientChannelInfo(FG_ClientChannelInfo* msg);
	

};
