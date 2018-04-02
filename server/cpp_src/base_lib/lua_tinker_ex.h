#pragma once

#include "god_include.h"
extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
};
#include "lua_tinker.h"

namespace lua_tinker
{
	template<>	void push(lua_State *L, std::string ret);

	template<>	void push(lua_State *L, std::string* ret);
	template<>	void push(lua_State *L, const std::string* ret);

	template<>	std::string read(lua_State *L, int index);
}
