#include <stdio.h>
#include <string>
#include<iostream>  
#include <iostream>  
#include <thread>
#include <math.h>
#include<cmath>
#include <boost/asio.hpp>    
#include <boost/bind.hpp>  
#include <google/protobuf/text_format.h>
extern "C" {
#include"lua.hpp"
#include "lauxlib.h"
#include "lualib.h"
}
#define LUA_BUILD_AS_DLL
#include "ddz_ai_bridge.h"

#ifdef WIN32
BOOL WINAPI DllMain(HINSTANCE hinstDLL, uint32_t fdwReason, LPVOID lpReserved)
{
	switch (fdwReason)
	{
	case DLL_PROCESS_ATTACH:
		break;

	case DLL_THREAD_ATTACH:
		break;

	case DLL_THREAD_DETACH:
		break;

	case DLL_PROCESS_DETACH:
		break;
	}
	return TRUE;
}
#endif
class ddz_robot_module
{
public:
	static ddz_robot_module* GetInstance(lua_State* L = nullptr){ if (!sInstance){ sInstance = new ddz_robot_module(L); } return sInstance;}
	static void Destroy(){ delete sInstance; sInstance = nullptr; }
private:
	ddz_robot_module(lua_State* L){
		lua_tinker::class_add<ddz_ai_bridge>(L, "cpp_robot");
		lua_tinker::class_con<ddz_ai_bridge>(L, lua_tinker::constructor<ddz_ai_bridge>);
		lua_tinker::class_def<ddz_ai_bridge>(L, "Initialization", &ddz_ai_bridge::Initialization);
		lua_tinker::class_def<ddz_ai_bridge>(L, "set_self_ChairID", &ddz_ai_bridge::set_self_ChairID);
		lua_tinker::class_def<ddz_ai_bridge>(L, "OnEventGameMessage", &ddz_ai_bridge::OnEventGameMessage);
	}

	~ddz_robot_module(){}
	static ddz_robot_module* sInstance;
};
ddz_robot_module* ddz_robot_module::sInstance = nullptr;
extern lua_State* g_LuaState = nullptr;
extern "C" __declspec(dllexport) int luaopen_ailib(lua_State* L)
{
	printf("load ailib  finish ...\n");
	g_LuaState = L;
	ddz_robot_module::GetInstance(L);
	return 1;
}

