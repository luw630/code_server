local pb = require "extern/lib/lib_pb"
require "game_script/virtual/virtual_room_mgr"
require "game_script/all_game/qznn_table"
qznn_room_mgr = virtual_room_mgr:new()
function qznn_room_mgr:change_table(player)
	local tb = self:get_user_table(player)
	if tb then
		local room = self:find_room_by_player(player)
		if room then	
			local newTable, newChair, newTbID = self:get_suitable_table(room,player,true)
			if newTable then
				local result_, table_id_, chair_id_ = self:stand_up(player)
				player:on_stand_up(table_id_, chair_id_, result_)
				newTable:player_sit_down(player, newChair)
				room:player_enter_room(player, room.id)
				newTable:sit_on_chair(player, newChair)
				return
			end	
		else
		end
	else
	end
end
function qznn_room_mgr:init(tb, chair_count, ready_mode, room_lua_cfg)
	virtual_room_mgr.init(self, tb, chair_count,ready_mode,room_lua_cfg)
end
function qznn_room_mgr:create_table()
	return qznn_table:new()
end
function qznn_room_mgr:on_sit_down(player)
	local tb = self:get_user_table(player)

end
function qznn_room_mgr:auto_sit_down(player)
	local result_, table_id_, chair_id_ = virtual_room_mgr.auto_sit_down(self, player)
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	return result_
end
function qznn_room_mgr:sit_down(player, table_id_, chair_id_)
	local result_, table_id_, chair_id_ = virtual_room_mgr.sit_down(self, player, table_id_, chair_id_)
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	return result_
end

function qznn_room_mgr:stand_up(player)
	local tb = self:get_user_table(player)
	return virtual_room_mgr.stand_up(self, player)
end
function qznn_room_mgr:player_offline(player)
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
			p:on_notify_stand_up(notify)
		end
	end)
	return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), true
end

function qznn_room_mgr:stand_up_and_exit_room(player)
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
	return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), roomid, tableid, chairid
end
