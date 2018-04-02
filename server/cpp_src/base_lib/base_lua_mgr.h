#pragma once

#include "god_include.h"
#include "Singleton.h"
#include "lua_tinker_ex.h"

class base_lua_mgr : public TSingleton<base_lua_mgr>
{
public:
	base_lua_mgr();
	virtual ~base_lua_mgr();
	virtual void init();
	void dofile(const char* filename);
	lua_State* get_lua_state() { return L; }
protected:
	void add_loader();
protected:
	lua_State* L;
};
