require "game_script/handler_net"
require "game_script/virtual/virtual_player"
local pb = require "extern/lib/lib_pb"
local post_msg_to_client_pb = post_msg_to_client_pb
local virtual_player = virtual_player
local room_manager = g_room_mgr

function handler_sangong_getbanker(player, msg)
	local tb = room_manager:get_user_table(player)
	if not tb then
		log_error("handler_sangong_getbanker  tb is nil,player is " .. player.guid)
		return
	end

	if tb and (tb.cur_state_FSM == ETableState.TABLE_STATE_GETBANKER or 
	tb.cur_state_FSM == ETableState.TABLE_STATE_WAITBANKER) then
		log_info(string.format("cur_turn_banker is %d ,player is %d",tb.cur_turn_banker,player.chair_id))
	 	if tb.cur_turn_banker == player.chair_id then
			tb:player_getbanker(player, msg)
		else
			log_info("tb handler_sangong_getbanker error "..player.guid)
		end
	else
		log_info(string.format("guid[%d] bets error,status=%d", player.guid,tb.cur_state_FSM))
	end
end


function handler_sangong_bets(player, msg)
	local tb = room_manager:get_user_table(player)
	if not tb then
		log_error("handler_sangong_bets  tb is nil,player is " .. player.guid)
		return
	end
	--log_info("test .................. handler_sangong_bets tb.cur_state_FSM "..tb.cur_state_FSM)
	if tb and (tb.cur_state_FSM == ETableState.TABLE_STATE_BET or 
	tb.cur_state_FSM == ETableState.TABLE_STATE_WAITBET) then
	 	if tb and tb.cur_turn_banker == player.chair_id then
	 		--log_info("player tb:player_bet")
			tb:player_bet(player,msg)
		else
			log_info("tb handler_sangong_bets error "..player.guid)
		end
	else
		log_info(string.format("guid[%d] bets error,status=%d", player.guid,tb.cur_state_FSM))
	end
end

client_handler_reg("CS_SanGong_AskBanker", "handler_sangong_getbanker")
client_handler_reg("CS_SanGong_AskBet", "handler_sangong_bets")


