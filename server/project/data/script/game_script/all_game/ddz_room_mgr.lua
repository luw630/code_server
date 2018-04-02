local pb = require "extern/lib/lib_pb"
require "game_script/virtual/virtual_room_mgr"
require "game_script/all_game/ddz_table"
require "extern/lib/lib_redis"
local redis_command = redis_command
local redis_cmd_query = redis_cmd_query
local redis_cmd_do = redis_cmd_do
local get_second_time = get_second_time
local x = 1
local LAND_STATUS_FREE = 1
ddz_room_mgr = virtual_room_mgr:new()
function ddz_room_mgr:init(tb, chair_count, ready_mode, room_lua_cfg)
	virtual_room_mgr.init(self, tb, chair_count, ready_mode, room_lua_cfg)
end
function ddz_room_mgr:create_table()
	return ddz_table:new()
end
function ddz_room_mgr:on_sit_down(player)
	local tb = self:get_user_table(player)
	if tb then
		local chat = {
			chat_content = player.account .. " sit down!",
			chat_guid = player.guid,
			chat_name = player.account,
		}
		tb:broadcast_msg_to_client("SC_ChatTable", chat)
	end
end
function ddz_room_mgr:auto_sit_down(player)
	local result_, table_id_, chair_id_ = virtual_room_mgr.auto_sit_down(self, player)
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end
function ddz_room_mgr:get_table_players_status( player )
	virtual_room_mgr:get_table_players_status( player )
	if not player.room_id then
		return nil
	end
	local room = self.room_list_[player.room_id]
	if not room then
		return nil
	end	
	local tb = room:find_table(player.table_id)
	if not tb then
		return nil
	end
	for i,p in ipairs(tb:get_player_list()) do
		if p then
			if tb.ready_list_[p.chair_id] then
				local notify = {
					ready_chair_id = p.chair_id,
					is_ready = true,
					}
				post_msg_to_client_pb(player, "SC_Ready", notify)
			end
		end
	end
end
function ddz_room_mgr:sit_down(player, table_id_, chair_id_)
	local result_, table_id_, chair_id_ = virtual_room_mgr.sit_down(self, player, table_id_, chair_id_)
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	return result_
end
function ddz_room_mgr:stand_up(player)
	local tb = self:get_user_table(player)
	if tb then
		local chat = {
		chat_content = player.account .. " stand up!",
			chat_guid = player.guid,
			chat_name = player.account,
		}
		tb:broadcast_msg_to_client("SC_ChatTable", chat)
	end
	return virtual_room_mgr.stand_up(self, player)
end
