#pragma once

#include "base_db_connection_pool.h"
#include "base_lua_mgr.h"


class DBQueryUpdateLuaResult : public BaseDBQueryResult
{
public:

	DBQueryUpdateLuaResult(const std::string& sql, const std::string& query_func, int index, int ret)
		: BaseDBQueryResult(sql)
		, query_func_(query_func)
		, index_(index)
		, ret_(ret)
	{
	}

	virtual ~DBQueryUpdateLuaResult()
	{

	}

	virtual void on_query_result()
	{
		lua_tinker::call<void>(base_lua_mgr::instance()->get_lua_state(), query_func_.c_str(), index_, ret_);
	}

private:
	std::string								query_func_;
	int										index_;
	int										ret_;
};

class DBQueryLuaResult : public BaseDBQueryResult
{
public:

	DBQueryLuaResult(const std::string& sql, const std::string& query_func, int index, bool success, const std::string& msg)
		: BaseDBQueryResult(sql)
		, query_func_(query_func)
		, index_(index)
		, success_(success)
		, message_(msg)
	{
	}

	virtual ~DBQueryLuaResult()
	{

	}

	virtual void on_query_result()
	{
		if (success_)
		{
			lua_tinker::call<void>(base_lua_mgr::instance()->get_lua_state(), query_func_.c_str(), index_, &message_);
		}
		else
		{
			lua_tinker::call<void>(base_lua_mgr::instance()->get_lua_state(), query_func_.c_str(), index_);
		}
	}

private:
	std::string								query_func_;
	int										index_;
	bool									success_;
	std::string								message_;
};

class base_lua_db_connection_pool : public db_connection_pool
{
public:
	base_lua_db_connection_pool();
	virtual ~base_lua_db_connection_pool();
	void execute_lua(const char* sql);
	void execute_update_lua(const char* func, int index, const char* sql);
	void execute_query_lua(const char* func, int index, bool more, const char* sql);
protected:
private:
};
