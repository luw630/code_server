#pragma once

#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"
#include <iostream>
#include <string>

#include "stdarg.h" 
#define endStr "JudgeParamEnd"
#define judgeJsonMember(ABC,...)  judgeJsonMemberT(ABC,__VA_ARGS__,endStr)

void http_game_server_info(std::string& out);
void http_gm_command(rapidjson::Document& document, std::string& out);
void http_recharge(rapidjson::Document& document, std::string& out);
void http_cash_false(rapidjson::Document& document, std::string& out);
void http_change_tax(rapidjson::Document& document, std::string& out);
void http_change_robot_cfg(rapidjson::Document& document, std::string& out);
void http_change_game_cfg(rapidjson::Document& document, std::string& out);
void http_change_money(rapidjson::Document& document, std::string& out);
void http_broadcast_client_update(rapidjson::Document& document, std::string& out);
void http_lua_cmd_player_res(rapidjson::Document& document, std::string& out);
void http_lua_game_cmd(rapidjson::Document& document, std::string& out);
void http_lua_cmd_query_maintain(rapidjson::Document& document, std::string& out);
void http_save_players_info_to_mysql(rapidjson::Document& document, std::string& out);