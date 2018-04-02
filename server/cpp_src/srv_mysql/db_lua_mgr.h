#pragma once

#include "base_lua_mgr.h"

class db_lua_mgr : public base_lua_mgr
{
public:
	db_lua_mgr();
	virtual ~db_lua_mgr();
	virtual void init();
};
