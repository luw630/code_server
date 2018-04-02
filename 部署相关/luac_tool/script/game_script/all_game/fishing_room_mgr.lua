-- 捕鱼房间
local pb = require "extern/lib/lib_pb"
require "game_script/virtual/virtual_room_mgr"
require "game_script/all_game/fishing_table"
require "game_script/all_game/fishing_robot"
fishing_room_mgr = class("fishing_room_mgr",virtual_room_mgr)
function fishing_room_mgr:ctor( ... )
	self.android_players = {}
end
-- 初始化房间
function fishing_room_mgr:init(tb, chair_count, ready_mode,room_lua_cfg)
	fishing_room_mgr.super.init(self,tb, chair_count, ready_mode,room_lua_cfg)
end
function fishing_room_mgr:create_table()
	return fishing_table:new()
end
-- 快速坐下
function fishing_room_mgr:auto_sit_down(player)
	local result_, table_id_, chair_id_ = fishing_room_mgr.super.auto_sit_down(self, player)
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		--第一个人进来，开始游戏
		local tb = self.super.get_user_table(self,player)
		if #tb.player_list_ == 1 then
	    	tb.cpp_table:OnEventGameStart()
	    end
		return result_, table_id_, chair_id_
	end
	
	return result_
end
function fishing_room_mgr:get_suitable_table(room,player,bool_change_table)
	local suitable_player_count = -1
	local suitable_table = nil
	local chair_id = nil
	local table_id = nil
	for j,tb in ipairs(room:get_table_list()) do
		if suitable_table == nil or (suitable_table ~= nil and suitable_table:get_player_count() < tb:get_player_count()) then
			for k,chair in ipairs(tb:get_player_list()) do
				if (bool_change_table and player.table_id ~= tb.table_id_) or (not bool_change_table) then
					if chair == false and tb:canEnter(player) then
						local tmp_player_count = tb:get_player_count()	
						if suitable_player_count < tmp_player_count then
							suitable_player_count = tmp_player_count	
							suitable_table = tb
							chair_id = k
							table_id = j
							break
						end
					end
				end
			end
		end
		
		if tb:get_player_count() > 0 then
			--log_warning(string.format("table pcount %d, table_id is %d",tb:get_player_count(),j))
		end
	end	
	
	return suitable_table,chair_id,table_id
end
function fishing_room_mgr:player_offline(player)
	return fishing_room_mgr.super.player_offline(self,player)
end
local last_tick_time = os.clock()
-- 心跳
function fishing_room_mgr:tick()
	if os.clock() - last_tick_time > 0.03 then
		last_tick_time = os.clock()
		self.super.tick(self)
		-- for _,v in pairs(g_android_players) do
		-- 	v:tick()
		-- end
	end
end

