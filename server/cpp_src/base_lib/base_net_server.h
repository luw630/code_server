#pragma once

#include "god_include.h"
#include "base_net_server_session.h"
#include "base_io_service_pool.h"

class base_net_server;


class net_work_holder
{
public:

	virtual std::shared_ptr<virtual_session> alloc(boost::asio::ip::tcp::socket& socket);

	virtual std::shared_ptr<virtual_session> create_session(boost::asio::ip::tcp::socket& socket) = 0;

	virtual void set_network_server(base_net_server* network_server);


	std::shared_ptr<virtual_session> find_by_id(int id);
	std::shared_ptr<virtual_session> find_by_server_id(int server_id);

	base_net_server*	  get_net_server() {
		return network_server_;
	}

	net_work_holder();


	virtual ~net_work_holder();



	virtual void close_all_session();


	virtual void release_all_session();



	virtual bool tick();




protected:
	base_net_server*						network_server_;

	std::recursive_mutex				mutex_;
	std::unordered_map<int, std::shared_ptr<virtual_session>> session_;
};

class base_net_server
{
private:

	void do_accept();

	base_io_service_pool				io_service_pool_;

	boost::asio::ip::tcp::acceptor		acceptor_;
	boost::asio::ip::tcp::socket		socket_;
	net_work_holder*					allocator_;

	base_net_server(const base_net_server&) = delete;
	base_net_server& operator =(const base_net_server&) = delete;
public:

	base_net_server(unsigned short port, size_t threadCount, net_work_holder* pAllocator);

	
	~base_net_server();

	
	void run();

	
	void join();

	
	void stop();

	base_io_service_pool& get_io_server_pool() { return io_service_pool_; }


};
