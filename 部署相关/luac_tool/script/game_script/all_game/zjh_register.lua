require "game_script/handler_net"
require "game_script/virtual/virtual_player"
local pb = require "extern/lib/lib_pb"
local post_msg_to_client_pb = post_msg_to_client_pb
local virtual_player = virtual_player
local room_manager = g_room_mgr

function handler_zjh_compare_card(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		if msg.compare_chair_id then
			tb:compare_card(player, msg.compare_chair_id)
		end
	end
end
function handler_zjh_get_player_status(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
			tb:get_play_Status(player)
	else
		post_msg_to_client_pb(player, "SC_Gamefinish",{
			money = player.pb_base_info.money
		})
	end
end
function handler_zjh_get_sit_down(player, msg)

	local tb = room_manager:get_user_table(player)
	if tb then
			tb:get_sit_down(player)
	end
end
function handler_zjh_add_score(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		if type(msg) == "table" and msg.score then
			tb:add_score(player, msg.score)
		end
	end
end
function handler_zjh_give_up(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:give_up(player)
	end
end
function handler_zjh_look_card(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:look_card(player)
	end
end
function handler_zjh_prv_cfg_set(player, msg)	
	local tb = room_manager:get_user_table(player)
	if tb then
			tb:set_prv_cfg(player, msg)
	end
end
function handler_zjh_prv_cfg_get(player, msg)	
	local tb = room_manager:get_user_table(player)
	if tb then
			tb:get_prv_cfg(player)
	end
end
function handler_zjh_game_data(player, msg)	
	local tb = room_manager:get_user_table(player)
	if tb then
			tb:get_game_data(player)
	end
end
function handler_zjh_tab_tiren(player, msg)	
	local tb = room_manager:get_user_table(player)
	if tb then
			tb:tab_tiren(player, msg)
	end
end
function handler_zjh_tab_vote(player, msg)	
	local tb = room_manager:get_user_table(player)
	if tb then
			tb:tab_vote(player, msg)
	end
end

client_handler_reg("CS_ZhaJinHuaAddScore", "handler_zjh_add_score")
client_handler_reg("CS_ZhaJinHuaGiveUp", "handler_zjh_give_up")
client_handler_reg("CS_ZhaJinHuaLookCard", "handler_zjh_look_card")
client_handler_reg("CS_ZhaJinHuaCompareCard", "handler_zjh_compare_card")
client_handler_reg("CS_ZhaJinHuaGetPlayerStatus", "handler_zjh_get_player_status")
client_handler_reg("CS_ZhaJinHuaGetSitDown", "handler_zjh_get_sit_down")
client_handler_reg("CS_ZhaJinHuaPrivateCFG_Set", "handler_zjh_prv_cfg_set")
client_handler_reg("CS_ZhaJinHuaPrivateCFG_Get", "handler_zjh_prv_cfg_get")
client_handler_reg("CS_ZhaJinHuaGameData", "handler_zjh_game_data")
client_handler_reg("CS_ZhaJinHuaTabTiren", "handler_zjh_tab_tiren")
client_handler_reg("CS_ZhaJinHuaTabVote", "handler_zjh_tab_vote")
