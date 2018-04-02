#pragma once

#include "god_include.h"
#include "base_game_server.h"
#include "game_session_mgr.h"

class game_server : public base_game_server
{
public:

	game_server();
	~game_server();
	virtual const wchar_t* dump_file_name();
	virtual const char* main_lua_file();
private:
};