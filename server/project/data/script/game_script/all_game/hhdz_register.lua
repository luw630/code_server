require "game_script/handler_net"
require "game_script/virtual/virtual_player"
local pb = require "extern/lib/lib_pb"
local virtual_player = virtual_player
local room_manager = g_room_mgr
local post_msg_to_client_pb = post_msg_to_client_pb


function handler_hhdz_PlayerBetMsg( player, msg )
	local tb = room_manager:get_user_table(player)
	if tb and tb.table_status == HONGHEITABLESTATE.TABLE_WAIT_BETS then
		tb:player_bet(player,msg.playerbet,msg.playerbettype)
	end
end


function handler_hhdz_BetStandardMsg( player, msg )
	local tb = room_manager:get_user_table(player)
	if tb then
		post_msg_to_client_pb(player,"SC_HongHeiBetStandard",{playerbets=tb.bet_base})
		tb:statistics_rank(player)
	end
end


client_handler_reg("CS_HongHeiPlayerBet", "handler_hhdz_PlayerBetMsg") 
client_handler_reg("CS_HongHeiBetStandard", "handler_hhdz_BetStandardMsg") 
