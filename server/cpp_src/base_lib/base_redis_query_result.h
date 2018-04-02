#pragma once
#include "god_include.h"
#include "base_redis_con.h"
#include "base_lua_mgr.h"


class BaseRedisQueryResult
{
public:
	BaseRedisQueryResult() {}
	virtual ~BaseRedisQueryResult() {}
	virtual void on_command_result() = 0;
};

class RedisQueryResult : public BaseRedisQueryResult
{
public:
	RedisQueryResult(const std::function<void(RedisReply*)>& cmd_func, const RedisReply& reply)
		: cmd_func_(cmd_func)
		, reply_(reply)
	{
	}
	virtual ~RedisQueryResult()
	{
	}
	virtual void on_command_result()
	{
		cmd_func_(&reply_);
	}
private:
	std::function<void(RedisReply*)>		cmd_func_;
	RedisReply								reply_;
};

class RedisQueryLuaResult : public BaseRedisQueryResult
{
public:
	RedisQueryLuaResult(const std::string& query_func, int index, const RedisReply& reply)
		: cmd_func_(query_func)
		, index_(index)
		, reply_(reply)
	{
	}
	virtual ~RedisQueryLuaResult()
	{
	}
	virtual void on_command_result()
	{
		lua_tinker::call<void>(base_lua_mgr::instance()->get_lua_state(), cmd_func_.c_str(), index_, &reply_);
	}
private:
	std::string								cmd_func_;
	int										index_;
	RedisReply								reply_;
};

class RedisQueryNullResult : public BaseRedisQueryResult
{
public:
	RedisQueryNullResult(const std::function<void()>& cmd_func)
		: cmd_func_(cmd_func)
	{
	}
	virtual ~RedisQueryNullResult()
	{

	}
	virtual void on_command_result()
	{
		cmd_func_();
	}
private:
	std::function<void()>					cmd_func_;
};

template<typename T>
class RedisQueryPbResult : public BaseRedisQueryResult
{
public:
	RedisQueryPbResult(const std::function<void(T*)>& cmd_func, const T& reply)
		: cmd_func_(cmd_func)
		, reply_(reply)
	{
	}
	virtual ~RedisQueryPbResult()
	{

	}
	virtual void on_command_result()
	{
		cmd_func_(&reply_);
	}
private:
	std::function<void(T*)>					cmd_func_;
	T										reply_;
};
