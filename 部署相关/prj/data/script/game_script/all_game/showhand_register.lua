require "game_script/handler_net"
require "game_script/virtual/virtual_player"
local pb = require "extern/lib/lib_pb"
local post_msg_to_client_pb = post_msg_to_client_pb
local virtual_player = virtual_player
local room_manager = g_room_mgr

function handler_showhand_add_score(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:add_score(player, msg)
	end
end

function handler_showhand_give_up(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:give_up(player,msg)
	end
end
function handler_showhand_pass(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:pass(player,msg)
	end
end

function handler_showhand_give_up_eixt(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:give_up_eixt(player,msg)
	end
end
function handler_showhand_vote_result(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb and msg then
		tb:vote_result(player,msg)
	end
end


client_handler_reg("CS_ShowHandAddScore", "handler_showhand_add_score")
client_handler_reg("CS_ShowHandGiveUp", "handler_showhand_give_up")
client_handler_reg("CS_ShowHandPass", "handler_showhand_pass")
client_handler_reg("CS_ShowHandGiveUpEixt", "handler_showhand_give_up_eixt")
client_handler_reg("CS_ShowHandMyVoteResult", "handler_showhand_vote_result")

