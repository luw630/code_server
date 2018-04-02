#pragma once

#include "base_net_session.h"
#include "base_net_dispatcher.h"
#include "public_msg.pb.h"
#include "public_enum.pb.h"
#include "server.pb.h"

class db_cfg_session : public base_net_session
{
private:
	base_net_dispatcher_mgr*			dispatcher_manager_;
public:
    db_cfg_session(boost::asio::io_service& ioservice);
    virtual ~db_cfg_session();
	virtual bool handler_msg_dispatch(MsgHeader* header);
	virtual bool handler_connect();
	virtual void handler_connect_failed();
	virtual void on_closed();
    void on_S_ReplyServerConfig(S_ReplyServerConfig* msg);  
    void handler_fd_changemoney(FD_ChangMoney* msg);
    void handler_fd_changemoneydeal(FD_ChangMoneyDeal* msg);

};
