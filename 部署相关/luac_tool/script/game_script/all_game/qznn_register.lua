require "game_script/handler_net"
require "game_script/virtual/virtual_player"
local pb = require "extern/lib/lib_pb"
local post_msg_to_client_pb = post_msg_to_client_pb
local virtual_player = virtual_player
local room_manager = g_room_mgr

function handler_qznn_contend(player, msg)
	local tb = room_manager:get_user_table(player)
	if msg == false then
		msg = {}
		msg.ratio = -1
	end

	if next(msg) == nil then
		msg = {}
		msg.ratio = -1
	end
	
	if tb then
		local retCode = tb:banker_contend(player, msg.ratio)
	end
end

function handler_qznn_bet(player, msg)
	local tb = room_manager:get_user_table(player)
	if msg == false then
		msg = {}
		msg.bet_money = -1
	end

	if next(msg) == nil then
		msg = {}
		msg.bet_money = 10
	end

	if msg.bet_money < 0 and msg.bet_money ~= -1 then
		log_error("handler_qznn_bet error  " .. tostring(player.guid))
		log_error("handler_qznn_bet error  " .. tostring(msg.bet_money))
		return
	end
	
	if tb then
		local retCode = tb:banker_bet(player, msg.bet_money)
	end
end

function handler_qznn_guess(player)
	local tb = room_manager:get_user_table(player)
	if tb then
		local retCode = tb:banker_guess_cards(player)
	end
end
function handler_qznn_enter(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:sit_on_chair(player, player.chair_id)
	end
end

function handler_qznn_reEnter(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:check_reEnter(player, player.chair_id)
	else
		local result_, room_id_, table_id_, chair_id_, newTable = room_manager:enter_room_and_sit_down(player)
		if newTable then
			newTable:check_reEnter(player, player.chair_id)
		end
	end
end

function handler_qznn_leave(player,msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:player_leave(player)
	end
end


client_handler_reg("CS_BankerEnter","handler_qznn_enter")
client_handler_reg("CS_BankerNextGame","handler_qznn_reEnter")
client_handler_reg("CS_BankerLeave","handler_qznn_leave")
client_handler_reg("CS_BankerContend","handler_qznn_contend")
client_handler_reg("CS_BankerPlayerBet","handler_qznn_bet")
client_handler_reg("CS_BankerPlayerGuessCards","handler_qznn_guess")


