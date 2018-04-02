-- 梭哈房间
local pb = require "extern/lib/lib_pb"
require "game_script/virtual/virtual_room_mgr"
require "game_script/all_game/showhand_table"
showhand_room_mgr = virtual_room_mgr:new()
-- 初始化房间
function showhand_room_mgr:init(tb, chair_count, ready_mode,room_lua_cfg)
	virtual_room_mgr.init(self, tb, chair_count, ready_mode,room_lua_cfg)
end
-- 创建桌子
function showhand_room_mgr:create_table()
	return showhand_table:new()
end
-- 坐下处理
function showhand_room_mgr:on_sit_down(player)
	local tb = self:get_user_table(player)
	if tb then
		local chat = {
			chat_content = player.account .. " sit down!",
			chat_guid = player.guid,
			chat_name = player.account,
		}
		--tb:broadcast_msg_to_client("SC_ChatTable", chat)
	end
end
-- 快速坐下
function showhand_room_mgr:auto_sit_down(player)
	print "test showhand auto sit down ....................."
	local result_, table_id_, chair_id_ = virtual_room_mgr.auto_sit_down(self, player)
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	return result_
end
-- 坐下
function showhand_room_mgr:sit_down(player, table_id_, chair_id_)
	print "test showhand sit down ....................."
	local result_, table_id_, chair_id_ = virtual_room_mgr.sit_down(self, player, table_id_, chair_id_)
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	return result_
end
-- 站起
function showhand_room_mgr:stand_up(player)
	print "test showhand stand up ....................."
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
-- 玩家掉线
function showhand_room_mgr:player_offline(player)
	local ret,b = virtual_room_mgr.player_offline(self,player)
	local tb = self:get_user_table(player)
	if tb then
		tb:notify_offline(player)
	end
	return ret,b
end
function showhand_room_mgr:stand_up_and_exit_room(player)
	if not player.room_id then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OUT_ROOM")
	end
	if not player.table_id then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
	end
	if not player.chair_id then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_CHAIR")
	end
	local room = self:find_room(player.room_id)
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
	
	if tb:isPlay() then
		if tb.private_room then
			tb:vote_for_exit(player)
		end
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_GAME")
	end
	if tb.private_room and tb.private_room_owner_guid == player.guid then
		tb:destroy_private_room(b)
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
	return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), roomid, tableid, chairid
end
