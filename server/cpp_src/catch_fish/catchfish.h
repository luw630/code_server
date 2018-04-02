#pragma once
#include <stdio.h>
#include <string>
#include<iostream>  
using namespace std;
#include <math.h>
#include<cmath>
extern "C" {
#include"lua.hpp"
#include "lauxlib.h"
#include "lualib.h"
}
#define LUA_BUILD_AS_DLL
#include "common.h"
#include "catch_fish_logic.h"
#include "MyObjectFactory.h"
#include "MyComponentFactory.h"
#include "EffectFactory.h"
#include "EffectManager.h"
#include "BufferFactory.h"
#include "BufferManager.h"
#include "base_game_time_mgr.h"
#include "lua_tinker_ex.h"
#include "Earnings.h"
#include <boost/asio.hpp>    
#include <boost/bind.hpp>  
#include <iostream>  
#include <google/protobuf/text_format.h>

using namespace lua_tinker;

int Init(lua_State *L);
class catchfish_dll
{
public:
	static catchfish_dll* GetInstance(lua_State* L = nullptr){
		if (!sInstance){
			sInstance = new catchfish_dll(L);
		}

		return sInstance;
	}

	static void Destroy(){
		sLuaState = nullptr;
		delete sInstance;
		sInstance = nullptr;
	}

private:
	catchfish_dll(lua_State* L){
		sLuaState = L;
		Init(L);
		catch_fish_logic::LoadConfig();
	}

	~catchfish_dll(){

	}
	static catchfish_dll* sInstance;
public:
	static lua_State* sLuaState;
};