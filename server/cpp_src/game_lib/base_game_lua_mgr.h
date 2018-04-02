#pragma once

#include "base_lua_mgr.h"

class base_game_lua_mgr : public base_lua_mgr
{
public:
	base_game_lua_mgr();

	virtual ~base_game_lua_mgr();

	virtual void init();

protected:
private:
};
