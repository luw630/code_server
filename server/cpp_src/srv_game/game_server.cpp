
#include "stdafx.h"

#include "game_server.h"
#include <google/protobuf/text_format.h>

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG

game_server::game_server()
{
}

game_server::~game_server()
{
}

const wchar_t* game_server::dump_file_name()
{
	return L"srv_game_%d-%02d-%02d_%02d-%02d-%02d.dmp";
}

const char* game_server::main_lua_file()
{
	return "../data/script/game_script/entry.lua";
}


//////////////////////////////////////////////////////////////////////////

int main(int argc, char* argv[])
{
#ifdef PLATFORM_WINDOWS
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

#ifndef _DEBUG
	DeleteMenu(GetSystemMenu(GetConsoleWindow(), FALSE), SC_CLOSE, MF_BYCOMMAND);
	DrawMenuBar(GetConsoleWindow());
#endif

	extern bool g_is_game_server;
	g_is_game_server = true;

	std::string game_name = "game";
	std::string title = "srv_game";

	game_server theServer;
	if (argc > 1)
	{
		if (argc > 2)
		{
			game_name = argv[2];
			if (game_name == "da_ting")
			{
				game_name = "lobby";
			}
			else if (game_name == "pu_yu")
			{
				game_name = "fishing";
			}
			else if (game_name == "dou_di_zhu")
			{
				game_name = "land";
			}
			else if (game_name == "zha_jing_hua")
			{
				game_name = "zhajinhua";
			}
			else if (game_name == "bai_ren_niu_niu")
			{
				game_name = "ox";
			}
			else if (game_name == "qiang_zhuang_niu_niu")
			{
				game_name = "banker_ox";
			}
			else if (game_name == "san_gong")
			{
				game_name = "sangong";
			}
			
			theServer.set_game_name(game_name);
		}
		theServer.set_game_id(atoi(argv[1]));
	
		title = str(boost::format("srv_game_%s_%03d") % game_name % theServer.get_game_id());
	}

	/*for (int i = 1; i < argc; i++)
	{
		if (strcmp(argv[i], "-db") == 0)
			theServer.set_using_db_config(true);
		else
			GameServerConfigManager::instance()->set_cfg_file_name(argv[i]);
	}*/
	
	//std::string title = GameServerConfigManager::instance()->get_title();
	theServer.set_print_filename(title);
	theServer.set_msg_flow_log_filename(title);

	//if (theServer.get_using_db_config())
	//	title += "-db";

#ifdef PLATFORM_WINDOWS
	SetConsoleTitleA(title.c_str());
#endif

	theServer.startup();

#ifdef _DEBUG
	system("pause");
#endif // _DEBUG

	return 0;
}
