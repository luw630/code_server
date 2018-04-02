#pragma once

#include "base_net_server_session.h"
#include "base_net_dispatcher.h"
#include "public_msg.pb.h"
#include "server.pb.h"

class game_session : public virtual_session
{
private:
	base_net_dispatcher_mgr*			dispatcher_manager_;
	std::string							ip_;
	unsigned short						port_;
	int									type_;
	int									server_id_;
public:
	game_session(boost::asio::ip::tcp::socket& sock);
	virtual ~game_session();
	virtual bool handler_msg_dispatch(MsgHeader* header);
	virtual bool handler_accept();
	virtual void on_closed();
	virtual int get_server_id() { return server_id_; }
	void set_server_id(int server_id) { server_id_ = server_id; }
	void on_s_connect(S_Connect* msg);
	void on_s_logout(S_Logout* msg);
};