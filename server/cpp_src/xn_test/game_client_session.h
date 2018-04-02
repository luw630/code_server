#pragma once

#include "base_net_session.h"
#include "base_net_dispatcher.h"
#include "common_msg_define.pb.h"

class game_client_session : public NetworkConnectSession
{
public:
	game_client_session(boost::asio::io_service& ioservice);

	virtual ~game_client_session();

	virtual bool on_dispatch(MsgHeader* header);
	
	virtual bool on_connect();

	virtual void on_connect_failed();

	virtual void on_closed();

	virtual bool tick();

	/**********************************************************************************************//**
	 * \brief	得到服务器id.
	 *
	 * \return	The server identifier.
	 **************************************************************************************************/

	virtual int get_server_id() { return server_id_; }

	/**********************************************************************************************//**
	 * \brief	设置服务器id.
	 *
	 * \param	server_id	Identifier for the server.
	 **************************************************************************************************/

	void set_server_id(int server_id) { server_id_ = server_id; }

	void set_deta(time_t deta) { deta_ = deta; }
private:
	int									server_id_;
	NetworkDispatcherManager*			dispatcher_manager_;

	time_t								deta_;
	time_t								oldtime_;
};
