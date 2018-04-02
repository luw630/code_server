require "game_script/handler_net"
require "game_script/virtual/virtual_player"
local pb = require "extern/lib/lib_pb"
local post_msg_to_client_pb = post_msg_to_client_pb
local virtual_player = virtual_player
local room_manager = g_room_mgr

function handler_point21_bet(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:do_bet(player, msg)
	end
end

function handler_point21_get_card(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:get_card(player, msg)
	end
end

function handler_point21_call_double(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:call_double(player, msg)
	end
end

function handler_point21_stop(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:do_stop(player, msg)
	end
end

function handler_point21_split(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:do_split(player, msg)
	end
end

function handler_point21_insurance(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:do_insurance(player, msg)
	end
end

function handler_point21_surrender(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:do_surrender(player, msg)
	end
end

client_handler_reg("CS_Point21_Bet", "handler_point21_bet")
client_handler_reg("CS_Point21_GetCard", "handler_point21_get_card")
client_handler_reg("CS_Point21_CallDouble", "handler_point21_call_double")
client_handler_reg("CS_Point21_Stop", "handler_point21_stop")
client_handler_reg("CS_Point21_Split", "handler_point21_split")
client_handler_reg("CS_Point21_Insurance", "handler_point21_insurance")
client_handler_reg("CS_Point21_Surrender", "handler_point21_surrender")







