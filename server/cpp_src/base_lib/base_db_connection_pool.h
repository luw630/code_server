#pragma once

#include "god_include.h"
#include <boost/thread/tss.hpp>
#include <google/protobuf/text_format.h>
#include "base_db_connection.h"
#include "base_db_query_result.h"


class db_connection_pool
{
protected:
	std::string										host_;
	std::string										user_;
	std::string										password_;
	std::string										database_;
	volatile bool									save_sql_to_log_;

	boost::asio::io_service							io_service_;
	std::shared_ptr<boost::asio::io_service::work>	work_;
	std::vector<std::shared_ptr<std::thread>>		thread_;
	std::mutex										mutex_;

	volatile bool									is_run_;

	boost::thread_specific_ptr<base_db_connection>		con_ptr_;

	std::recursive_mutex							mutex_query_result_;
	std::deque<BaseDBQueryResult*>					query_result_;
	db_connection_pool(const db_connection_pool&) = delete;
	db_connection_pool& operator =(const db_connection_pool&) = delete;
public:

	db_connection_pool();

	virtual ~db_connection_pool();

	void run(size_t thread_count);

	void join();

	void stop();

	virtual bool tick();

	void execute(const char* fmt, ...);

	void execute(const google::protobuf::Message& message, const char* fmt, ...);

	void execute_update(const std::function<void(int)>& func, const char* fmt, ...);

	void execute_update(const std::function<void(int)>& func, const google::protobuf::Message& message, const char* fmt, ...);

	void execute_try(const std::function<void(int)>& func, const char* fmt, ...);

	void execute_update_try(const std::function<void(int, int)>& func, const char* fmt, ...);

	void execute_query_string(const std::function<void(std::vector<std::string>*)>& func, const char* fmt, ...);
	
	void execute_query_vstring(const std::function<void(std::vector<std::vector<std::string>>*)>& func, const char* fmt, ...);

	template<typename T> void execute_query(const std::function<void(T*)>& func, const char* name, const char* fmt, ...)
	{
		char str[4096] = { 0 };

		va_list arg;
		va_start(arg, fmt);
#ifdef PLATFORM_WINDOWS
		_vsnprintf_s(str, 4095, fmt, arg);
#else
		vsnprintf(str, 4095, fmt, arg);
#endif
		va_end(arg);

		std::string sql = str;

		std::string strname;
		if (name)
			strname = name;

		io_service_.post([=] {
			base_db_connection* con = get_db_connection();
			
			std::string str;
			bool ret = con->execute_query(str, sql, strname);

			auto p = new DBQueryResult<T>(sql, func, ret);
			p->parseMessage(str);

			std::lock_guard<std::recursive_mutex> lock(mutex_query_result_);
			query_result_.push_back(p);
		});
	}

	template<typename T> void execute_query_filter(const std::function<void(T*)>& func, const char* name, 
		const std::function<bool(const std::string&)>& filter_func, const char* fmt, ...)
	{
		char str[4096] = { 0 };

		va_list arg;
		va_start(arg, fmt);
#ifdef PLATFORM_WINDOWS
		_vsnprintf_s(str, 4095, fmt, arg);
#else
		vsnprintf(str, 4095, fmt, arg);
#endif
		va_end(arg);

		std::string sql = str;

		std::string strname;
		if (name)
			strname = name;

		io_service_.post([=] {
			base_db_connection* con = get_db_connection();

			std::string str;
			bool ret = con->execute_query_filter(str, sql, strname, filter_func);

			auto p = new DBQueryResult<T>(sql, func, ret);
			p->parseMessage(str);

			std::lock_guard<std::recursive_mutex> lock(mutex_query_result_);
			query_result_.push_back(p);
		});
	}

	void set_host(const std::string& host)
	{
		host_  = host; 
	}

	void set_user(const std::string& user)
	{
		user_ = user;
	}
	void set_password(const std::string& password)
	{
		password_ = password;
	}

	void set_database(const std::string& database)
	{
		database_ = database;
	}
	void set_save_sql_to_log(bool b_val);

protected:
	base_db_connection* get_db_connection();
	void run_thread();


};

