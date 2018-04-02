#pragma once

#include "god_include.h"
#include "base_net_server_session.h"
#include "base_game_log.h"


class base_net_dispatcher
{
public:
	base_net_dispatcher() {}

	virtual ~base_net_dispatcher() {}
	virtual unsigned short get_msg_id() = 0;
	virtual bool parse(virtual_session* session, MsgHeader* header) = 0;
};


template<typename T, typename Session>
class MsgDispatcher : public base_net_dispatcher
{
public:
	typedef void (Session::* DispatchFunction)(T*);

	MsgDispatcher(DispatchFunction func)
		: func_(func)
	{
	}

	virtual ~MsgDispatcher()
	{

	}

	virtual unsigned short get_msg_id()
	{
		return T::ID;
	}

	virtual bool parse(virtual_session* session, MsgHeader* header)
	{
		try
		{
			T msg;
			if (!msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeader)))
			{
				LOG_ERR("ParseFromArray failed, id=%d", header->id);
				return false;
			}

			(static_cast<Session*>(session)->*func_)(&msg);
		}
		catch (const std::exception& e)
		{
			LOG_ERR("pb error:%s", e.what());
			return false;
		}
		return true;
	}

private:
	DispatchFunction func_;
};

template<typename T, typename Session>
class GateMsgDispatcher : public base_net_dispatcher
{
public:
	typedef void (Session::* DispatchFunction)(int, T*);

	GateMsgDispatcher(DispatchFunction func)
		: func_(func)
	{
	}

	virtual ~GateMsgDispatcher()
	{

	}

	virtual unsigned short get_msg_id()
	{
		return T::ID;
	}

	virtual bool parse(virtual_session* session, MsgHeader* header)
	{
		GateMsgHeader* h = reinterpret_cast<GateMsgHeader*>(header);
		
		try
		{
			T msg;
			if (!msg.ParseFromArray(h + 1, h->len - sizeof(GateMsgHeader)))
			{
				LOG_ERR("ParseFromArray failed, id=%d", header->id);
				return false;
			}

			(static_cast<Session*>(session)->*func_)(h->guid, &msg);
		}
		catch (const std::exception& e)
		{
			LOG_ERR("pb error:%s", e.what());
			return false;
		}
		return true;
	}

private:
	DispatchFunction func_;
};


class base_net_dispatcher_mgr
{
private:
	std::unordered_map<unsigned short, base_net_dispatcher*> dispatcher_;
public:


	base_net_dispatcher_mgr();


	~base_net_dispatcher_mgr();

	void register_dispatcher(base_net_dispatcher* dispatcher, bool show_log = true);


	base_net_dispatcher* query_dispatcher(unsigned short id);


};
