require "game_script/handler_net"
require "game_script/virtual/virtual_player"
local pb = require "extern/lib/lib_pb"
local post_msg_to_client_pb = post_msg_to_client_pb
local virtual_player = virtual_player
local room_manager = g_room_mgr

function handler_ddz_getconfig(player,msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:land_getconfig(player)
	end
end
function handler_ddz_tab_tiren(player, msg)	
	local tb = room_manager:get_user_table(player)
	if tb then
			tb:tab_tiren(player, msg)
	end
end
function handler_ddz_vote(player, msg)	
	local tb = room_manager:get_user_table(player)
	if tb then
			tb:tab_vote(player, msg)
	end
end
function handler_ddz_tablevoteinfo(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
			tb:tab_getvoteinfo(player, msg)
	end
end
function handler_ddz_call_score(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb and player.chair_id == tb.cur_turn then
		tb:call_score(player, msg.call_score - 1)
	end
end
function handler_ddz_call_double(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:call_double(player, msg.is_double == 2)
	end
end
function handler_ddz_out_card(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		newCards = {}
		if msg and msg.cards then
			local i = 0
			for _,card in ipairs(msg.cards) do
				table.insert(newCards, card - 1)
			end
		end		
		tb:out_card(player, newCards)
	end
end
function handler_ddz_pass_card(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:pass_card(player)
	end
end
function  handler_ddzTrusteeship(  player, msg )
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:setTrusteeship(player,false)
	end
end
function handler_ddz_configchange(player,msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		local configlist={}
		table.insert(configlist, msg.nallowDouble)
		table.insert(configlist, msg.nlimitbeishu)
		table.insert(configlist, msg.nallowYiXiaoBoda)
		tb:land_configchange(player, configlist)
	end
end

client_handler_reg("CS_LandCallScore", "handler_ddz_call_score")
client_handler_reg("CS_LandOutCard", "handler_ddz_out_card")
client_handler_reg("CS_LandPassCard", "handler_ddz_pass_card")
client_handler_reg("CS_LandTrusteeship","handler_ddzTrusteeship")
client_handler_reg("CS_LandCallDouble","handler_ddz_call_double")
client_handler_reg("CS_SetPrivateConfigChange","handler_ddz_configchange")
client_handler_reg("CS_GetPrivateConfig","handler_ddz_getconfig")
client_handler_reg("CS_TabTiren", "handler_ddz_tab_tiren")
client_handler_reg("CS_TabVote", "handler_ddz_vote")
client_handler_reg("CS_GetTabVoteArray", "handler_ddz_tablevoteinfo")
