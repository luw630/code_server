
require "game_script/handler_net"
require "game_script/virtual/virtual_player"
local pb = require "extern/lib/lib_pb"
local post_msg_to_client_pb = post_msg_to_client_pb
local virtual_player = virtual_player
local room_manager = g_room_mgr
 
function handler_texas_action(player, msg)
	local tb = room_manager:get_user_table(player)
	if msg == false then
		msg = {}
		msg.action = ACT_CHECK
		msg.bet_money = 0
	end

	if next(msg) == nil then
		msg = {}
		msg.action = ACT_CHECK
		msg.bet_money = 0
	end
	
	if tb then
		local retCode = tb:player_action(player, tb, msg.action, msg.bet_money)
		if retCode ~= CS_ERR_OK then
			post_msg_to_client_pb(player,"SC_TexasError", {error=retCode})
		end
	end
	--t:broadcast_msg_to_client("SC_TexasU^serAction", ret) 
end


--获取坐下玩家
function handler_texas_sit_down(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:sit_on_chair(player, player.chair_id)
		--tb:player_sit_down(player, player.chair_id)
	end
end

--亮牌
function handler_texas_show_cards(player, msg)
	if msg == false or next(msg) == nil then
		return
	end
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:set_show_cards(player,msg.show_cards)
	end
end

-- 玩家离开游戏
function handler_texas_leave(player,msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:player_leave(player)
	end
end

client_handler_reg("CS_TexasUserAction","handler_texas_action")
client_handler_reg("CS_TexasEnterTable", "handler_texas_sit_down")
client_handler_reg("CS_TexasLeaveTable", "handler_texas_leave")
client_handler_reg("CS_TexasShowCards", "handler_texas_show_cards")