local pb = require "extern/lib/lib_pb"
require "game_script/virtual/virtual_room_mgr"
require "game_script/all_game/longhu_table"
local OX_STATUS_FREE = 1
local OX_GET_TOP_DIS = 10
local TOP_MAX_NUM =300
longhu_room_mgr = virtual_room_mgr:new()
function longhu_room_mgr:get_top_info(player)
	if get_second_time() > (OX_GET_TOP_DIS + self.last_get_top_time) then
		self.count_all_player =0
		self.top_info = {}
		local playerinfo = {}
		for i,room in ipairs(self.room_list_) do
			self.count_all_player = self.count_all_player + room.cur_player_count_
			for j,player in pairs(room.room_player_list_) do
				table.insert(playerinfo,{guid = player.guid,head_id = 10001,nickname =player.nickname,money =player.base_info.money})
			end
		end
		table.sort(playerinfo, function (a, b)
			if a.money == b.money then
				return a.guid < b.guid
			else
				return a.money > b.money
			end
		end)
		for i=1,TOP_MAX_NUM do
			local p = playerinfo[i]
			if p == nil then
				break
			end
			self.top_info[i] = p  
		end
		self.last_get_top_time = get_second_time()
	end
	local msg = { count_all = self.count_all_player, pb_player_top_info =self.top_info}
	post_msg_to_client_pb(player,"SC_OxTop",msg)
end
function longhu_room_mgr:auto_sit_down(player)
	local result_, table_id_, chair_id_ = virtual_room_mgr.auto_sit_down(self, player)
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end
function longhu_room_mgr:sit_down(player, table_id_, chair_id_)
	local result_, table_id_, chair_id_ = virtual_room_mgr.sit_down(self, player, table_id_, chair_id_)
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	return result_
end
function longhu_room_mgr:stand_up(player)
	local tb = self:get_user_table(player)
	if tb then
		local chat = {
		chat_content = player.account .. " stand up!",
			chat_guid = player.guid,
			chat_name = player.account,
		}
		--tb:broadcast_msg_to_client("SC_ChatTable", chat)
	end
	return virtual_room_mgr.stand_up(self, player)
end
function longhu_room_mgr:init(tb, chair_count, ready_mode, room_lua_cfg)
	virtual_room_mgr.init(self, tb, chair_count,ready_mode,room_lua_cfg)
	self.last_get_top_time =0
	self.count_all_player =0
	self.top_info = {}
end
function longhu_room_mgr:create_table()
	return longhu_table:new()
end
function longhu_room_mgr:on_sit_down(player)
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
function longhu_room_mgr:player_offline(player)
	local ret,b = virtual_room_mgr.player_offline(self,player)
	local tb = self:get_user_table(player)
	if tb then
		tb:notify_offline(player)
	end
	return ret,b
end

