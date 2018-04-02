#pragma once

#include "god_include.h"

class base_io_service_pool
	: public boost::noncopyable
{
public:
	explicit base_io_service_pool(size_t pool_size);
	void start();
	void join();
	void stop();
	boost::asio::io_service& get_io_service();
private:
	typedef std::shared_ptr<boost::asio::io_service> io_service_sptr;
	typedef std::shared_ptr<boost::asio::io_service::work> work_sptr;
	typedef std::shared_ptr<std::thread> thread_sptr;
	void run(io_service_sptr ioservice);
	void c_run(boost::asio::io_service* ioservice);
	void seh_run(boost::asio::io_service* ioservice);
	std::mutex								mutex_;
	std::vector<io_service_sptr>			io_services_;
	std::vector<work_sptr>					work_;
	std::vector<thread_sptr>				threads_;
	size_t									next_io_service_;
	volatile bool							brun_;
};
