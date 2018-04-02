#include "stdafx.h"
#include "client_socket_proto.h"
#include "web_request_dispatch.h"
#include <string>  
#include <fstream>
#include "web_cfg.h"
#include <boost/algorithm/string.hpp>

web_cfg g_cfg;
std::string s_http_key;
std::vector<std::string> s_http_addr_list;
#define BUF_MAX 1024 * 16
static char _buf[BUF_MAX];
#define NO_HOST_LIMIT "NO_HOST_LIMIT"
void php_post_handler(struct evhttp_request *req, void *arg)
{
	bool pass = false;
	for (auto item : s_http_addr_list)
	{
		if (strcmp(item.c_str(), NO_HOST_LIMIT) == 0
			|| strcmp(item.c_str(), req->remote_host) == 0)
		{
			pass = true;
			break;
		}
	}
	if (!pass)
	{
		printf("Unkown Request Host: %s\n", req->remote_host);
		return;
	}
	
	
	std::string out;
	size_t post_size = EVBUFFER_LENGTH(req->input_buffer);
	if (post_size > 0)
	{
		size_t copy_len = post_size > BUF_MAX ? BUF_MAX : post_size;
		memcpy(_buf, EVBUFFER_DATA(req->input_buffer), copy_len);
		out.assign(_buf, copy_len);
	}
	auto p = evhttp_find_header(req->input_headers, "Content-Type");
	if (nullptr == p)
	{
		printf("Host %s Request without Content-Type\n", req->remote_host);
		return;
	}
	else
	{
		printf("Host %s Request: %s\n", req->remote_host, p);
	}
	rapidjson::Document document;
	document.Parse(out.c_str());
	std::string strType = p;
	if (strType == "info")
	{
		http_game_server_info(out);
	}
    else if (strType == "GMCommand"){
        http_gm_command(document, out);
    }
    else if (strType == "recharge")
    {
        http_recharge(document, out);
    }
	else if (strType == "cash_false")
	{
		http_cash_false(document, out);
	}
    else if (strType == "changetax")
    {
        http_change_tax(document, out);
    }
	else if (strType == "robot_cfg_change")
	{
		http_change_robot_cfg(document, out);
	}
    else if (strType == "update-game-cfg")
    {
        http_change_game_cfg(document, out);
    }
	else if (strType == "lua")
	{
		http_change_money(document, out);
	}
	else if (strType == "broadcast-client-update-info")
	{
		http_broadcast_client_update(document, out);
	}
	else if (strType == "cmd-player-result")
	{
		http_lua_cmd_player_res(document, out);
	}
	else if (strType == "lua-game-cmd")
	{
		http_lua_game_cmd(document, out);
	}
	else if (strType == "Maintain-switch")
	{
		http_lua_cmd_query_maintain(document, out);
	}
	else if (strType == "save-players-info-to-mysql")
	{
		http_save_players_info_to_mysql(document, out);
	}

	struct evbuffer *pe = evbuffer_new();

	evbuffer_add(pe, out.data(), out.size());
	evhttp_send_reply(req, HTTP_OK, "OK", pe);
	evbuffer_free(pe);
}

void get_http_key(std::string& out)
{
    client_socket_proto sock;
    auto attr = g_cfg.get_cfg_attr();
    sock.connect(attr.first.c_str(), attr.second, false);

    WF_GetCfg msg;
    sock.send_pb(&msg);
    sock.Flush();

    volatile bool flag = true;
    DWORD cur_time = GetTickCount();
    while (flag && GetTickCount() - cur_time < 20000)
    {
        if (sock.recv_msg<FW_GetCfg>([&flag, &out](FW_GetCfg* msg) {
            out = msg->php_sign().c_str();
            flag = false;
            return true;
        }))
        {
            Sleep(1);
        }
    }

    sock.Destroy();
}
int main(int argc, char* argv[])
{
#ifndef _DEBUG
	DeleteMenu(GetSystemMenu(GetConsoleWindow(), FALSE), SC_CLOSE, MF_BYCOMMAND);
	DrawMenuBar(GetConsoleWindow());
#endif
#ifdef PLATFORM_WINDOWS
	SetConsoleTitleA("srv_web");
#endif
#ifdef WIN32
	WSADATA wsaData;
	if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0)
	{
		return -1;
	}
#endif
	if (!g_cfg.load())
	{
		return -1;
	}
	s_http_addr_list.clear();
	if (argc > 1)
	{
		boost::split(s_http_addr_list, argv[1], boost::is_any_of("#"));
	}
	else
	{
		s_http_addr_list.push_back(NO_HOST_LIMIT);
	}
    s_http_key = "";
	struct event_base * base = event_base_new();
	struct evhttp * http_server = evhttp_new(base);
	if (!http_server)
	{
		return -1;
	}

	int ret = evhttp_bind_socket(http_server, g_cfg.get_http_addr().c_str(), g_cfg.get_http_port());
	if (ret != 0)
	{
		return -1;
	}
	evhttp_set_gencb(http_server, php_post_handler, NULL);
    while (s_http_key == "")
    {
		get_http_key(s_http_key);
        if (s_http_key == "")
        {
            Sleep(1000);
        }
    }

	printf("server is start ! \n");
	event_base_dispatch(base);
	evhttp_free(http_server);
	WSACleanup();
	return 0;
}

