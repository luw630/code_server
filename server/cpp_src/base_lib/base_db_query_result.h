#pragma once

#include "god_include.h"
#include <google/protobuf/text_format.h>
#include "base_game_log.h"



class BaseDBQueryResult
{
public:


	BaseDBQueryResult(const std::string& sql) : sql_(sql) {}

	
	virtual ~BaseDBQueryResult() {}

	
	virtual void on_query_result() = 0;

	const char* get_sql() { return sql_.c_str(); }
private:
	std::string							sql_;
};

template<typename T>
class DBQueryResult : public BaseDBQueryResult
{
public:


	DBQueryResult(const std::string& sql, const std::function<void(T*)>& query_func, bool success)
		: BaseDBQueryResult(sql)
		, query_func_(query_func)
		, success_(success)
	{
	}

	
	virtual ~DBQueryResult()
	{

	}

	
	virtual void on_query_result()
	{
		if (success_)
		{
			query_func_(&msg_);
		}
		else
		{
			query_func_(nullptr);
		}
	}

	void parseMessage(const std::string& message_)
	{
		if (success_ && !google::protobuf::TextFormat::ParseFromString(message_, &msg_))
		{
			LOG_ERR("query error:%s", message_.c_str());
		}
	}

private:
	
	std::function<void(T*)>					query_func_;

	bool									success_;

	T										msg_;
};

class DBQueryUpdateResult : public BaseDBQueryResult
{
public:

	
	DBQueryUpdateResult(const std::string& sql, const std::function<void(int)>& query_func, int ret)
		: BaseDBQueryResult(sql)
		, query_func_(query_func)
		, ret_(ret)
	{
	}

	
	virtual ~DBQueryUpdateResult()
	{

	}

	
	virtual void on_query_result()
	{
		query_func_(ret_);
	}

private:
	std::function<void(int)>				query_func_;
	int										ret_;
};


class DBQueryUpdateTryResult : public BaseDBQueryResult
{
public:

	
	DBQueryUpdateTryResult(const std::string& sql, const std::function<void(int, int)>& query_func, int ret, int err)
		: BaseDBQueryResult(sql)
		, query_func_(query_func)
		, ret_(ret)
		, err_(err)
	{
	}

	
	virtual ~DBQueryUpdateTryResult()
	{

	}

	
	virtual void on_query_result()
	{
		query_func_(ret_, err_);
	}

private:
	std::function<void(int, int)>			query_func_;
	int										ret_;
	int										err_;
};

class DBQueryStringResult : public BaseDBQueryResult
{
public:


	DBQueryStringResult(const std::string& sql, const std::function<void(std::vector<std::string>*)>& query_func, bool success, const std::vector<std::string>& msg)
		: BaseDBQueryResult(sql)
		, query_func_(query_func)
		, success_(success)
		, message_(msg)
	{
	}

	
	virtual ~DBQueryStringResult()
	{

	}

	
	virtual void on_query_result()
	{
		if (success_)
		{
			query_func_(&message_);
		}
		else
		{
			query_func_(nullptr);
		}
	}

private:
	
	std::function<void(std::vector<std::string>*)> query_func_;
	
	bool									success_;
	
	std::vector<std::string>				message_;
};


class DBQueryVStringResult : public BaseDBQueryResult
{
public:

	
	DBQueryVStringResult(const std::string& sql, const std::function<void(std::vector<std::vector<std::string>>*)>& query_func, bool success, const std::vector<std::vector<std::string>>& msg)
		: BaseDBQueryResult(sql)
		, query_func_(query_func)
		, success_(success)
		, message_(msg)
	{
	}

	
	virtual ~DBQueryVStringResult()
	{

	}

	
	virtual void on_query_result()
	{
		if (success_)
		{
			query_func_(&message_);
		}
		else
		{
			query_func_(nullptr);
		}
	}

private:
	
	std::function<void(std::vector<std::vector<std::string>>*)> query_func_;

	bool									success_;

	std::vector<std::vector<std::string>>	message_;
};
