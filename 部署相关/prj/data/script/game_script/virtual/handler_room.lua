local pb = require "extern/lib/lib_pb"
require "game_script/handler_net"
local post_msg_to_client_pb = post_msg_to_client_pb
require "game_script/virtual/virtual_player"
local virtual_player = virtual_player
local room_manager = g_room_mgr
local def_game_id = def_game_id
local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type
function handler_client_enter_room_and_sit_down(player, msg)
	local result_, room_id_, table_id_, chair_id_, tb = room_manager:enter_room_and_sit_down(player)
	log_info(string.format("enter_room_and_sit_down request : player %d, result_ %s ,room_id_ %s, table_id_ %s chair_id_ %s",
	player.guid,tostring(result_),tostring(room_id_),tostring(table_id_),tostring(chair_id_)))
	player:handler_enter_sit_down(room_id_, table_id_, chair_id_, result_, tb)
	room_manager:get_table_players_status(player)
end
function handler_client_stand_up_and_exit_room(player, msg)
	local result_, room_id_, table_id_, chair_id_ = room_manager:stand_up_and_exit_room(player)
	player:handler_stand_exit_room(room_id_, table_id_, chair_id_, result_)	
end
function handler_client_change_chair(player, msg)
	local result_, table_id_, chair_id_, tb = room_manager:change_chair(player)
	player:on_change_chair(table_id_, chair_id_, result_, tb)
end
function handler_client_enter_room(player, msg)
	local result_ = room_manager:enter_room(player, msg.room_id)
	player:on_enter_room(msg.room_id, result_)
end
function handler_client_exit_room(player, msg)
	local result_, room_id_ = room_manager:exit_room(player)
	player:on_exit_room(room_id_, result_)
end
function handler_client_auto_enter_room(player, msg)
	local result_, room_id_ = room_manager:auto_enter_room(player)
	player:on_enter_room(room_id_, result_)
end
function handler_client_auto_sit_down(player, msg)
	local result_, table_id_, chair_id_ = room_manager:auto_sit_down(player)
	player:on_sit_down(table_id_, chair_id_, result_)
	room_manager:get_table_players_status(player)
end
function handler_client_sit_down(player, msg)
	local result_, table_id_, chair_id_  = room_manager:sit_down(player, msg.table_id, msg.chair_id)
	player:on_sit_down(table_id_, chair_id_, result_)
	room_manager:get_table_players_status(player)
end
function handler_client_stand_up(player, msg)
	local result_, table_id_, chair_id_  = room_manager:stand_up(player)
	player:on_stand_up(table_id_, chair_id_, result_)
end
function handler_client_ready(player, msg)
	if player.disable == 1 then
		player:forced_exit();
		return
	end
	
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:ready(player)
	else
		log_error(string.format("player %d ready not in tb",player.guid))
	end
end
function handler_client_change_table(player,msg)
	room_manager:change_table(player)
end
function handler_client_exit(player,msg)
	room_manager:exit_server(player,true)
end
function handler_client_Trusteeship(player,msg)
	room_manager:CS_Trusteeship(player)
end
function handler_client_read_game_info(player)
	if player.is_offline and room_manager:isPlay(player) then
		local notify = {
			pb_gmMessage = {
				first_game_type = def_first_game_type,
				second_game_type = def_second_game_type,
				room_id = player.room_id,
				table_id = player.table_id,
				chair_id = player.chair_id,
			}
		}
		post_msg_to_client_pb(player,  "SC_ReadGameInfo", notify)
		room_manager:player_online(player)
		return
	end
	post_msg_to_client_pb(player,  "SC_ReadGameInfo", nil)	
end
function handler_client_reconnection_client_msg( player, msg )
	local tb = room_manager:get_user_table(player)
	if tb then
		tb:reconnection_client_msg(player)
	else
		post_msg_to_client_pb(player,  "SC_ReconnectionPlay", {find_table = false})
		log_error(string.format("guid[%d] stand up", player.guid))
	end
end
