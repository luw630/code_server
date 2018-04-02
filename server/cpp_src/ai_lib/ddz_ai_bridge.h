#pragma once
extern "C" {
#include"lua.hpp"
#include "lauxlib.h"
#include "lualib.h"
}
#define LUA_BUILD_AS_DLL
#include "..\base_lib\god_include.h"
#include "..\base_lib\lua_tinker.h"
#include "ddz_ai_logic.h"

extern lua_State* g_LuaState;
class ddz_ai_bridge
{
protected:
	WORD							m_wBankerUser;						
	WORD							m_wOutCardUser;					
	WORD							m_self_ChairID = 0;
	BYTE							m_cbTurnCardCount;					
	BYTE							m_cbTurnCardData[MAX_COUNT];		
	BYTE							m_landcards[3];						
	BYTE							m_cbHandCardData[MAX_COUNT];		
	BYTE							m_cbHandCardCount[GAME_PLAYER];		
	ddz_ai_logic					m_GameLogic;
public:
	ddz_ai_bridge();
	~ddz_ai_bridge();
public:
	virtual VOID Release() { delete this; }
	virtual VOID * QueryInterface(REFGUID Guid, DWORD dwQueryVer);
public:
	virtual bool Initialization();
	virtual bool RepositionSink();
	void set_self_ChairID(WORD self_ChairID){ m_self_ChairID = self_ChairID; };
public:
	bool UserOutCard(lua_tinker::table msg_back);
	bool OnEventGameMessage(const char* msg_name, lua_tinker::table msg, lua_tinker::table msg_back);
protected:
	bool OnSubGameStart(lua_tinker::table msg, lua_tinker::table msg_back);
	bool OnSubCallScore(lua_tinker::table msg, lua_tinker::table msg_back);
	bool OnSubBankerInfo(lua_tinker::table msg, lua_tinker::table msg_back);
	bool OnSubOutCard(lua_tinker::table msg, lua_tinker::table msg_back);
	bool OnSubPassCard(lua_tinker::table msg, lua_tinker::table msg_back);
	bool OnSubGameEnd(lua_tinker::table msg, lua_tinker::table msg_back);
};
