#include "base_lua_mgr.h"
#include "base_lua_dispatcher.h"
#include "xn_test_mgr.h"

static void reg_perf_dispatcher(const char* msg, unsigned short msgid, const char* func, const char* callback, bool show_log)
{
	xn_test_mgr::instance()->get_dispatcher_manager()->register_dispatcher(new LuaMsgDispatcher(msg, msgid, func, callback), show_log);
}

static void send2server(int client_id, unsigned short msgid, std::string pb)
{
	auto session = xn_test_mgr::instance()->get_session(client_id);
	if (session)
	{
		session->send_spb(msgid, pb);
	}
	else
	{
		LOG_WARN("perf[%d] session disconnect", client_id);
	}
}

void bind_lua_net_message(lua_State* L)
{
	lua_tinker::def(L, "reg_perf_dispatcher", reg_perf_dispatcher);
	lua_tinker::def(L, "send2server", send2server);
}
