#pragma once

#include "base_redis_con.h"
#include "base_redis_query_result.h"
#ifdef PLATFORM_WINDOWS
#include <concurrent_queue.h>
#endif
#include "Singleton.h"

class base_redis_con_thread : public TSingleton<base_redis_con_thread>
{
private:
	void run();
	RedisConnection* get_connection(bool is_master);
	void close_connection();
	bool do_connect();
private:
	std::string										ip_;
	int												port_;
	int												dbnum_;
	struct redis_con_info
	{
	private:
		std::string ip;
		int port;
		std::shared_ptr<std::mutex> lock;
	public:
		RedisConnection	con;
		std::string master_name;
		int	dbnum;
		std::string password;

		redis_con_info()
		{
			lock = std::make_shared<std::mutex>();
		}
		void set_info(const std::string& ip_t, int port_t, const std::string& master_name_t, int dbnum_t, const std::string& password_t)
		{
			std::lock_guard<std::mutex> iplock(*lock);
			ip = ip_t;
			port = port_t;
			dbnum = dbnum_t;
			master_name = master_name_t;
			password = password_t;
		}
		bool connect()
		{
			do
			{
				std::lock_guard<std::mutex> iplock(*lock);
				if (ip.empty())
				{
					return false;
				}
			} while (0);

			close();
			return con.connect(ip, port, dbnum, password);
		}
		void close()
		{
			con.close();
		}
	};
	redis_con_info									connection_master_;
	std::vector<redis_con_info*>					connection_slaves_;
	std::vector<redis_con_info*>					sentinel_list_;

	std::thread										thread_;
	volatile bool									is_run_;
#ifdef PLATFORM_WINDOWS
	Concurrency::concurrent_queue<std::function<void(RedisConnection*)>> command_;
	Concurrency::concurrent_queue<bool> command_master_flag_;
	Concurrency::concurrent_queue<BaseRedisQueryResult*> query_result_;
#endif

#ifdef PLATFORM_LINUX
	std::recursive_mutex							mutex_;
	std::vector<std::function<void(RedisConnection*)>> command_;
	std::vector<bool> command_master_flag_;
	std::vector<BaseRedisQueryResult*>				query_result_;
#endif
public:

	base_redis_con_thread();

	~base_redis_con_thread();

	void set_ip(const std::string& ip)
	{
		ip_ = ip; 
	}

	void connect_sentinel();
	bool connnect_sentinel_thread();
	
	void add_sentinel(const std::string& ip, int	port, const std::string& master_name, int	dbnum, const std::string& password);
	void set_master_info(const std::string& ip, int	port, const std::string& master_name, int	dbnum, const std::string& password);
	void set_port(int port)
	{
		port_ = port;
	}
	void set_dbnum(int dbnum)
	{
		dbnum_ = dbnum;
	}

	void start();

	void join();

	void stop();

	bool tick();

	void command(const std::string& cmd, bool master_flag = true);
	
	void command_query(const std::function<void(RedisReply*)>& func, const std::string& cmd, bool master_flag = true);
	
	void command_query_lua(const char* func, int index, const char* cmd, bool master_flag = true);
	redisReply * command_do(const char* cmd, bool master_flag = true);

	void add_reply(const std::function<void(RedisReply*)>& cmd_func, const RedisReply& reply);
	void add_reply(const std::string& query_func, int index, const RedisReply& reply);
	void add_reply(const std::function<void()>& cmd_func);
	template<typename T>
	void add_reply(const std::function<void(T*)>& cmd_func, const T& reply)
	{
		auto qr = new RedisQueryPbResult<T>(cmd_func, reply);
#ifdef PLATFORM_WINDOWS
		query_result_.push(qr);
#endif
#ifdef PLATFORM_LINUX
		query_result_.push_back(qr);
#endif
	}

	void command_impl(const std::function<void(RedisConnection*)>& func, bool master_flag = true);


};
