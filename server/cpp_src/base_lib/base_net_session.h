#pragma once

#include "base_net_server_session.h"
#include <atomic>

class base_net_session : public virtual_session
{
protected:
	boost::asio::ip::tcp::resolver		resolver_;
	enum CONNECT_STATE
	{
		CONNECT_STATE_INVALID,
		CONNECT_STATE_DISCONNECT,
		CONNECT_STATE_CONNECTING,
		CONNECT_STATE_CONNECTED,
	};
	std::atomic<int32_t>				connect_state_;
	long long							wait_tick_;

	std::string							ip_;
	unsigned short						port_;

	time_t								last_heartbeat_;
public:

	
	base_net_session(boost::asio::io_service& ioservice);

	
	virtual ~base_net_session();

	
	virtual bool connect(const char* ip, unsigned short port);

	virtual bool handler_connect();

	virtual void handler_connect_failed();

	virtual void on_closed();

	
	virtual bool tick();

	
	void set_ip_port(const std::string& ip, unsigned short port);

	bool is_connected() { return connect_state_ == CONNECT_STATE_CONNECTED; }

	int get_connect_state() { return connect_state_; }
protected:
	void connect_impl(boost::asio::ip::tcp::resolver::iterator it);

};
