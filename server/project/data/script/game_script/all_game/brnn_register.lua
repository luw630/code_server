require "game_script/handler_net"
require "game_script/virtual/virtual_player"
local pb = require "extern/lib/lib_pb"
local virtual_player = virtual_player
local room_manager = g_room_mgr
local post_msg_to_client_pb = post_msg_to_client_pb

function handler_brnn_top(player,msg)
	room_manager:get_top_info(player)
end
function handler_brnn_PlayerConnectionOxMsg( player, msg )
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:client_connection_brnn(player)
	end
end
function handler_brnn_PlayerLeaveGame(player,msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:playerLeaveOxGame(player)
	end
end
function handler_brnn_GetBetCfg(player,msg)
	local betcf={}
	betcf=many_ox_room_config[def_second_game_type].Ox_basic_chip
	post_msg_to_client_pb(player, "SC_OxGetBetCfg",betcf)

end
function handler_brnn_ask_banker(player,msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:applyforbanker(player)
	end
end
function handler_brnn_cancel_banker(player,msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:leaveforbanker(player)
	end
end
function handler_brnn_curbanker_leave(player,msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:leave_cur_banker(player)
	end
end
function handler_brnn_call_banker(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:call_banker(player, msg.call_banker)
	end
end
function handler_brnn_open_cards(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:open_cards(player)
	end
end
function handler_brnn_add_score(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb and  tb.status == 2 and type(msg)== "table" then
		tb:add_score(player,msg.score_area,msg.score)
	end
end
function handler_brnn_record(player,msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		--tb:send_ox_record(player)
	end
end


client_handler_reg("CS_OxApplyForBanker", "handler_brnn_ask_banker") 
client_handler_reg("CS_OxLeaveForBanker", "handler_brnn_cancel_banker") 
client_handler_reg("CS_OxCurBankerLeave", "handler_brnn_curbanker_leave")
client_handler_reg("CS_OxCallBanker", "handler_brnn_call_banker")
client_handler_reg("CS_OxAddScore", "handler_brnn_add_score")
client_handler_reg("CS_OxOpenCards", "handler_brnn_open_cards")
client_handler_reg("CS_OxRecord","handler_brnn_record")
client_handler_reg("CS_OxTop","handler_brnn_top")
client_handler_reg("CS_OxPlayerConnectGame","handler_brnn_PlayerConnectionOxMsg")
client_handler_reg("CS_OxLeaveGame","handler_brnn_PlayerLeaveGame")
client_handler_reg("CS_OxGetBetCfg","handler_brnn_GetBetCfg")
