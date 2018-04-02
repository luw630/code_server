-- texas房间
local pb = require "extern/lib/lib_pb"
require "game_script/virtual/virtual_room_mgr"
require "game_script/all_game/texas_table"
texas_room_mgr = virtual_room_mgr:new()  
-- 初始化房间
function texas_room_mgr:init(tb, chair_count, ready_mode, room_lua_cfg)
	virtual_room_mgr.init(self, tb, chair_count, ready_mode, room_lua_cfg)
end
-- 创建桌子
function texas_room_mgr:create_table()
	return texas_table:new()
end
-- 坐下处理
function texas_room_mgr:on_sit_down(player)
	local tb = self:get_user_table(player)
	-- if tb then
		-- print("========== texas_room_mgr:on_sit_down ============")
		-- local chat = {
		-- 	chat_content = player.account .. " sit down!",
		-- 	chat_guid = player.guid,
		-- 	chat_name = player.account,
		-- }
		-- tb:broadcast_msg_to_client("SC_ChatTable", chat)
	-- end
end
-- 快速坐下
function texas_room_mgr:auto_sit_down(player)
	print("========== texas_room_mgr:auto_sit_down ============")
	local result_, table_id_, chair_id_ = virtual_room_mgr.auto_sit_down(self, player)
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end
-- 坐下
function texas_room_mgr:sit_down(player, table_id_, chair_id_)
	local result_, table_id_, chair_id_ = virtual_room_mgr.sit_down(self, player, table_id_, chair_id_)
	
	print("========== texas_room_mgr:sit_down ============")
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end
-- 站起
function texas_room_mgr:stand_up(player)
	local tb = self:get_user_table(player)
	-- if tb then
	-- 	print("========== texas_room_mgr:stand_up ============")
	-- 	local chat = {
	-- 		chat_content = player.account .. " stand up!",
	-- 		chat_guid = player.guid,
	-- 		chat_name = player.account,
	-- 	}
	-- 	tb:broadcast_msg_to_client("SC_ChatTable", chat)
	-- end
	return virtual_room_mgr.stand_up(self, player)
end
-- 玩家掉线
function texas_room_mgr:player_offline(player)
	local room = self:find_room(player.room_id)
	if not room then
	print("is ready_mode off line   1")
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
	end
	local tb = room:find_table(player.table_id)
	if not tb then
		print("is ready_mode off line   2")
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
	end
	
		local chair = tb:get_player(player.chair_id)
	if not chair then
	print("is ready_mode off line   3")
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_CHAIR")
	end
	if chair.guid ~= player.guid then
	print("is ready_mode off line   4")
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OHTER_ON_CHAIR")
	end
	local tableid, chairid = player.table_id, player.chair_id
	if tb:player_stand_up(player, true) then
		local notify = {
			table_id = tableid,
			chair_id = chairid,
			guid = player.guid,
		}
		tb:foreach(function (p)
			p:on_notify_stand_up(notify)
		end)
		tb:check_start(true)
	print("is ready_mode off line   5")
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), false
	end
	local notify = {
		table_id = tableid,
		chair_id = chairid,
		guid = player.guid,
		is_offline = true,
	}
	tb:foreach_except(chairid, function (p)
		if not tb.isPlay then
			print("AAAAAAAAAA~~~~~~~~~~~!", tb.status)
			p:on_notify_stand_up(notify)
		end
	end)
	print("is ready_mode off line   0")
	return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), true
end
-- 站起并离开房间
function texas_room_mgr:stand_up_and_exit_room(player)
	print("texas_room_mgr:stand_up_and_exit_room=============================")
	if not player.room_id then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OUT_ROOM")
	end
	
	if not player.table_id then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
	end
	if not player.chair_id then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_CHAIR")
	end
	local room = self:find_room(player.room_idA)
	if not room then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
	end
	local tb = room:find_table(player.table_id)
	if not tb then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
	end
	local chair = tb:get_player(player.chair_id)
	if not chair then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_CHAIR")
	end
	if chair.guid ~= player.guid then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OHTER_ON_CHAIR")
	end
	local tableid = player.table_id
	local chairid = player.chair_id
	tb:player_stand_up(player, false)
	local notify = {
			table_id = tableid,
			chair_id = chairid,
			guid = player.guid,
		}
	tb:foreach(function (p)
		p:on_notify_stand_up(notify)
	end)
	
	tb:check_start(true)
	local roomid = player.room_id
	room:player_exit_room(player)
	print("=============================12")
	return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), roomid, tableid, chairid
end
function texas_room_mgr:on_stand_up()
	print("texas_room_mgr: on_stand_up() =============================")
end
function texas_room_mgr:change_table(player)
	print("texas_room_mgr: change_table() =============================")
	local tb = self:get_user_table(player)
	if tb then
		local room = self:find_room_by_player(player)
		if room then	
			local newTable, newChair, newTbID = self:get_suitable_table(room,player,true)
			if newTable then
				--离开当前桌子
				local result_, table_id_, chair_id_ = self:stand_up(player)
				player:on_stand_up(table_id_, chair_id_, result_)
				newTable:player_sit_down(player, newChair)
				--player.table_id = newTbID
				--player.chair_id = newChair
				room:player_enter_room(player, room.id)
				newTable:sit_on_chair(player, newChair)
				
				--check if useful
				--player:change_table(player.room_id, newTbID, newChair, pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), newTable)
				return
			end	
		else
			print(" ====== change_table  ====== not in room")
		end
	else
		print(" ====== change_table  ====== no find tb")
	end
	-- local l_player = player
	-- local chair = l_player.chair_id
	-- local guid = l_player.guid
	-- local tb = self:get_user_table(player)
	-- virtual_room_mgr:change_table(player)
	-- tb:player_stand_up(player, 0)
end
