#pragma once

#include "god_include.h"
#include <hiredis.h>
#include "redis.pb.h"


extern "C" {
#include"lua.hpp"
#include "lauxlib.h"
#include "lualib.h"
}


class RedisReply
{
public:
	RedisReply(redisReply* r);
	void copy(redisReply* r);
	~RedisReply();

	bool is_nil() { return type_ == REDIS_REPLY_NIL; }
	bool is_error() { return type_ == REDIS_REPLY_ERROR; }
	bool is_status() { return type_ == REDIS_REPLY_STATUS; }
	bool is_string() { return type_ == REDIS_REPLY_STRING; }
	bool is_integer() { return type_ == REDIS_REPLY_INTEGER; }
	bool is_array() { return type_ == REDIS_REPLY_ARRAY; }

	long long get_integer() { return integer_; }
	const char* get_string() { return string_.c_str(); }

	int size_element() { return (int)element_.size(); }
	RedisReply* get_element(int index);

private:
	int								type_;
	long long						integer_;
	std::string						string_;
	std::vector<RedisReply>			element_;
};

class base_redis_con_thread;

class RedisConnection
{
private:
	redisContext*					context_;
	redisReply*						reply_;

	std::string						host_;
	int								port_;
	int								dbnum_;
	std::string						password_;

	bool							is_sentinel_;

	base_redis_con_thread*			redis_thrd_;
	bool							using_sentinel_;

	RedisConnection(RedisConnection&) = delete;
	RedisConnection& operator =(RedisConnection&) = delete;
public:
	RedisConnection();

	~RedisConnection();

	void close();

	void free_reply();

	bool connect(const std::string& host, int port, int dbnum, const std::string& password);

	void command(const std::string& cmd);

	redisReply *get_replyT();
	RedisReply get_reply();

	void set_is_sentinel() { is_sentinel_ = true; }
	void set_redis_thr(base_redis_con_thread* thrd);

public:
	bool get_player_login_info(const std::string& account, PlayerLoginInfo* info = nullptr);

	bool get_player_login_info_temp(const std::string& account, PlayerLoginInfo* info = nullptr);

	int get_gameid_by_guid(int guid);

	bool get_player_login_info_guid(int guid, PlayerLoginInfo* info = nullptr);

	bool connect_impl();

};
