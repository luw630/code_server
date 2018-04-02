#pragma once

#include "base_net_dispatcher.h"
#include "base_lua_mgr.h"

class base_lua_msg_dispatcher : public base_net_dispatcher
{
public:
	base_lua_msg_dispatcher(const std::string& msg, unsigned short msgid, const std::string& func, const std::string& callback)
		: msg_(msg)
		, msgid_(msgid)
		, func_(func)
		, callback_(callback)
	{
	}

	virtual ~base_lua_msg_dispatcher()
	{

	}

	virtual unsigned short get_msg_id()
	{
		return msgid_;
	}

	virtual bool parse(virtual_session* session, MsgHeader* header)
	{
		std::string str;
		if (header->len > sizeof(MsgHeader))
		{
			str.assign(reinterpret_cast<char*>(header + 1), header->len - sizeof(MsgHeader));
		}

		lua_tinker::call<void>(base_lua_mgr::instance()->get_lua_state(), callback_.c_str(), session->get_server_id(), func_.c_str(), msg_.c_str(), &str);
		
		return true;
	}

protected:
	std::string msg_;
	unsigned short msgid_;
	std::string func_;
	std::string callback_;
};

class LuaGateMsgDispatcher : public base_lua_msg_dispatcher
{
public:
	LuaGateMsgDispatcher(const std::string& msg, unsigned short msgid, const std::string& func, const std::string& callback)
		: base_lua_msg_dispatcher(msg, msgid, func, callback)
	{
	}

	virtual ~LuaGateMsgDispatcher()
	{

	}

	virtual bool parse(virtual_session* session, MsgHeader* header)
	{
		GateMsgHeader* h = reinterpret_cast<GateMsgHeader*>(header);

		std::string str;
		if (header->len > sizeof(GateMsgHeader))
		{
			str.assign(reinterpret_cast<char*>(h + 1), h->len - sizeof(GateMsgHeader));
		}

		lua_tinker::call<void>(base_lua_mgr::instance()->get_lua_state(), callback_.c_str(), h->guid, func_.c_str(), msg_.c_str(), &str);

		return true;
	}
};
