local pb = require "extern/lib/lib_pb"
require "game_script/handler_net"
local post_msg_to_client_pb = post_msg_to_client_pb
require "game_script/virtual/virtual_room"
require "game_script/virtual/virtual_table"
require "extern/lib/lib_table"
local def_first_game_type = def_first_game_type
virtual_room_mgr = virtual_room_mgr or {}
function virtual_room_mgr:new()  
    local o = {}  
    setmetatable(o, {__index = self})  
    return o 
end
function virtual_room_mgr:init(tb, chair_count, ready_mode, room_lua_cfg)
	self.time0_ = get_second_time()
	self.chair_count_ = chair_count
	self.ready_mode_ = ready_mode
	self.room_list_ = {}
	for i,v in ipairs(tb) do
		local r = self:create_room()
		r.id = i
		r:init(self, v.table_count, chair_count, ready_mode, v.money_limit, v.cell_money, v, room_lua_cfg)
		self.room_list_[i] = r
	end
end
function virtual_room_mgr:gm_update_cfg(tb, room_lua_cfg)
	local old_count = #self.room_list_
	for i,v in ipairs(tb) do
		if i <= old_count then
			self.room_list_[i]:gm_update_cfg(self,v.table_count, self.chair_count_, v.money_limit, v.cell_money, v, room_lua_cfg)
		else
			local r = self:create_room()
			r:init(self, v.table_count, self.chair_count_, self.ready_mode_, v.money_limit, v.cell_money, v, room_lua_cfg)
			self.room_list_[i] = r
		end
	end
end
function virtual_room_mgr:create_room()
	return virtual_room:new()
end
function virtual_room_mgr:create_table()
	return virtual_table:new()
end
function virtual_room_mgr:find_room(room_id)
	return self.room_list_[room_id]
end
function virtual_room_mgr:find_room_by_player(player)
	if not player.room_id then
		log_warning(string.format("guid[%d] not find in room", player.guid))
		return nil
	end
	local room = self:find_room(player.room_id)
	if not room then
		log_warning(string.format("room_id[%d] not find in room", player.room_id))
		return nil
	end
	return room
end
function virtual_room_mgr:get_user_table(player)
	local room = self:find_room_by_player(player)
	if room then
		return room:get_user_table(player)
	end
	log_warning(string.format("guid[%d] not find in room", player.guid))
	return nil
end
function virtual_room_mgr:foreach_by_player(func)
	for i,v in ipairs(self.room_list_) do
		v:foreach_by_player(func)
	end
end
function virtual_room_mgr:broadcast_msg_to_client_by_player(msg_name, pb)
	for i,v in ipairs(self.room_list_) do
		v:broadcast_msg_to_client_by_player(msg_name, pb)
	end
end
function virtual_room_mgr:get_table_players_status( player )
end
function virtual_room_mgr:enter_room_and_sit_down(player)
	if player.disable == 1 then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_FREEZEACCOUNT")
	end
	if player.room_id then
		log_error(string.format("player %d in room",player.guid))
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_ROOM")
	end
	if player.table_id or player.chair_id then
		log_error(string.format("player %d in tb",player.guid))
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_PLAYER_ON_CHAIR")
	end
	local ret = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
	for i,room in ipairs(self.room_list_) do
		if not player:check_room_limit(room:get_room_limit()) and room.cur_player_count_ < room.player_count_limit_ then
			ret = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
			local tb,k,j = self:get_suitable_table(room,player,false)
			if tb then
				if def_first_game_type == 8 then
					on_notify_php(player.guid)
				end
				room:player_enter_room(player, i)
				local notify = {
					table_id = j,
					pb_visual_info = {
					chair_id = k,
					guid = player.guid,
					account = player.account,
					nickname = player.nickname,
					level = player:get_level(),
					money = player:get_money(),
					header_icon = player:get_avatar(),
					ip_area = player.ip_area,
					is_ready = (tb.ready_list_ and tb.ready_list_[player.chair_id] or false)
					}
				}
				tb:foreach(function (p)
					p:on_notify_sit_down(notify)
				end)
				tb:player_sit_down(player, k)
				log_info(string.format("player %d enter_room_and_sit_down %d %d",player.guid,i,tb.table_id_))

				post_msg_to_mysql_pb("SD_Do_OneSql",{db_name = "log",
				sql = string.format("INSERT INTO t_log_player_game_record(`guid`,`game_id`,`channel_id`,`first_game_type`,`second_game_type`,`time`) VALUES(%d, %d, '%s', %d,%d,NOW())",
				player.guid,def_game_id,player.channel_id,def_first_game_type,def_second_game_type)})
				return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), i, j, k, tb
			end
		else
			log_error("error check_room_limit  room.cur_player_count_ < room.player_count_limit_  "  .. tostring(room.cur_player_count_) .. " " .. tostring(room.player_count_limit_))
		end
	end
	return ret
end
function virtual_room_mgr:stand_up_and_exit_room(player)
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
	if tb:isPlay(player) then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_GAME")
	end
	local chair = tb:get_player(player.chair_id)
	if not chair then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_CHAIR")
	end
	if chair.guid ~= player.guid then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OHTER_ON_CHAIR")
	end
	local roomid = player.room_id
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
	room:player_exit_room(player)
	log_info(string.format("player %d exit_room %d",player.guid,roomid))
	return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), roomid, tableid, chairid
end
function virtual_room_mgr:create_private_room(player, chair_count, score_type, cell_money_)
	if player.room_id then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_ROOM")
	end
	if player.table_id or player.chair_id then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_PLAYER_ON_CHAIR")
	end
	local ret = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
	for i,room in ipairs(self.room_list_) do
		if room.cur_player_count_ < room.player_count_limit_ then
			ret = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
			local tb,k,j = self:get_private_table(room,player, chair_count, score_type, cell_money_)
			if tb then
				room:player_enter_room(player, i)
				local notify = {
					table_id = j,
					pb_visual_info = {
					chair_id = k,
					guid = player.guid,
					account = player.account,
					nickname = player.nickname,
					level = player:get_level(),
					money = player:get_money(),
					header_icon = player:get_avatar(),
					ip_area = player.ip_area,
					is_ready = (tb.ready_list_ and tb.ready_list_[player.chair_id] or false)
					}
				}
				tb:foreach(function (p)
					p:on_notify_sit_down(notify)
				end)
				tb:player_sit_down(player, k)
				return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), i, j, k, tb
			end
		end
	end
	return ret
end
function virtual_room_mgr:join_private_room(player, owner_guid, player)
	if player.room_id then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_ROOM")
	end
	if player.table_id or player.chair_id then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_PLAYER_ON_CHAIR")
	end
	local ret = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
	for i,room in ipairs(self.room_list_) do
		if room.cur_player_count_ < room.player_count_limit_ then
			ret = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
			local tb,k,j, is_full = self:get_join_private_table(room,owner_guid, player)
			if is_full then
				ret = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_PRIVATE_ROOM_FULL")
			end
			if tb then
				room:player_enter_room(player, i)
				local notify = {
					table_id = j,
					pb_visual_info = {
					chair_id = k,
					guid = player.guid,
					account = player.account,
					nickname = player.nickname,
					level = player:get_level(),
					money = player:get_money(),
					header_icon = player:get_avatar(),
					ip_area = player.ip_area,
					is_ready = (tb.ready_list_ and tb.ready_list_[player.chair_id] or false)
					}
				}
				tb:foreach(function (p)
					p:on_notify_sit_down(notify)
				end)
				tb:player_sit_down(player, k)
				return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), i, j, k, tb
			end
		end
	end
	return ret
end
function virtual_room_mgr:change_chair(player)
	if player.disable == 1 then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_FREEZEACCOUNT")
	end
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
	
	local room = self:find_room(player.room_id)
	if not room then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
	end
	local tableid = player.table_id
	local chairid = player.chair_id
	local targettb = nil
	local targetid = nil
	for i,v in ipairs(room:get_table_list()) do
		if i > tableid then
			for k,chair in ipairs(v:get_player_list()) do
				if chair == false then
					targettb = v
					targetid = k
				end
			end
		end
	end
	if targetid == nil then
		for i,v in ipairs(room:get_table_list()) do
			if i < tableid then
				for k,chair in ipairs(v:get_player_list()) do
					if chair == false then
						targettb = v
						targetid = k
					end
				end
			end
		end
	end
	if targetid == nil then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
	end
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
	local notify = {
		table_id = targettb.table_id_,
		pb_visual_info = {
			chair_id = targetid,
			guid = player.guid,
			account = player.account,
			nickname = player.nickname,
			level = player:get_level(),
			money = player:get_money(),
			header_icon = player:get_avatar(),
			ip_area = player.ip_area,
			is_ready = (tb.ready_list_ and tb.ready_list_[player.chair_id] or false)
		}
	}
	targettb:foreach(function (p)
		p:on_notify_sit_down(notify)
	end)
	targettb:player_sit_down(player, targetid)
	return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), targettb.table_id_, targetid, targettb
end

function virtual_room_mgr:auto_enter_room(player)
	if player.disable == 1 then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_FREEZEACCOUNT")
	end
	if player.room_id then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_ROOM")
	end
	for i,room in ipairs(self.room_list_) do
		if not player:check_room_limit(room:get_room_limit()) and room.cur_player_count_ < room.player_count_limit_ then
			local notify = {
				room_id = i,
				guid = player.guid,
			}
			room:foreach_by_player(function (p)
				p:on_notify_enter_room(notify)
			end)
			room:player_enter_room(player, i)
			return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), i
		end
	end
	return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
end

function virtual_room_mgr:enter_room(player, room_id_)
	if player.disable == 1 then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_FREEZEACCOUNT")
	end
	if player.room_id then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_ROOM")
	end
	local room = self:find_room(room_id_)
	if not room then
		log_error(string.format("player %d,enter_room not find %d",player.guid,room_id_))
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
	end
	if player:check_room_limit(room:get_room_limit()) then
		return GAME_SERVER_RESULT_ROOM_LIMIT
	end

	local notify = {
		room_id = room_id_,
		guid = player.guid,
	}
	room:foreach_by_player(function (p)
		p:on_notify_enter_room(notify)
	end)
	room:player_enter_room(player, room_id_)
	log_info(string.format("player %d enter_room %d",player.guid,room_id_))
	return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
end
function virtual_room_mgr:CS_Trusteeship(player)
	local room = self:find_room(player.room_id)
	if not room then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
	end
	local tb = room:find_table(player.table_id)
	if not tb then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
	end
	tb:setTrusteeship(player,true)
end
function virtual_room_mgr:exit_room(player)
	if not player.room_id then
		log_info(string.format("player %d exit_room err01",player.guid))
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OUT_ROOM")
	end
	
	local roomid = player.room_id
	local room = self:find_room(roomid)
	if not room then
		log_info(string.format("player %d exit_room err02",player.guid))
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
	end
	room:player_exit_room(player)
	
	local notify = {
			room_id = roomid,
			guid = player.guid,
		}
	room:foreach_by_player(function (p)
		if p then
			p:on_notify_exit_room(notify)
		end
	end)
	return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), roomid
end
function virtual_room_mgr:player_offline(player)
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
	log_info(string.format("player %d offline ,table %d",player.guid,player.table_id))
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
		p:on_notify_stand_up(notify)
	end)
	return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), true
end
function virtual_room_mgr:isPlay(player)
	if player.room_id and player.table_id and player.chair_id then
		local room = self:find_room(player.room_id)
		if not room then
			return false
		end
		local tb = room:find_table(player.table_id)
		if not tb then
			return false
		end
		return tb:isPlay(player)
	end
	return false
end
function virtual_room_mgr:can_bank_action(player)
	if player.room_id and player.table_id and player.chair_id then
		local room = self:find_room(player.room_id)
		if not room then
			return true
		end
		local tb = room:find_table(player.table_id)
		if not tb then
			return true
		end
		return false
	end
	return true
end
function virtual_room_mgr:player_online(player)
	if player.room_id and player.table_id and player.chair_id then
		local room = self:find_room(player.room_id)
		if not room then
			return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
		end
		player:on_enter_room(player.room_id, pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"))
		local tb = room:find_table(player.table_id)
		if not tb then
			return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
		end
		
		local chair = tb:get_player(player.chair_id)
		if not chair then
			return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_CHAIR")
		end
		if chair.guid ~= player.guid then
			player.table_id = nil
			player.chair_id = nil
			return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OHTER_ON_CHAIR")
		end
		player.is_offline = nil
		local notify = {
			table_id = player.table_id,
			pb_visual_info = {
				chair_id = player.chair_id,
				guid = player.guid,
				account = player.account,
				nickname = player.nickname,
				level = player:get_level(),
				money = player:get_money(),
				header_icon = player:get_avatar(),				
				ip_area = player.ip_area,
				is_ready = (tb.ready_list_ and tb.ready_list_[player.chair_id] or false)
			},
			is_onfline = true,
		}

		tb:foreach_except(player.chair_id, function (p)
			p:on_notify_sit_down(notify)
		end)
		tb:reconnect(player)
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
	end
end
function virtual_room_mgr:exit_server(player)
	if player.room_id and player.table_id and player.chair_id then
		local result_, is_offline_ = self:player_offline(player)
		if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
			if is_offline_ then
				return true
			end
			self:exit_room(player)
		end
	end
	return false
end
function virtual_room_mgr:auto_sit_down(player)
	if player.disable == 1 then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_FREEZEACCOUNT")
	end
	if not player.room_id then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OUT_ROOM")
	end
	
	local room = self:find_room(player.room_id)
	if not room then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
	end
	for i,tb in ipairs(room:get_table_list()) do
		for j,chair in ipairs(tb:get_player_list()) do
			if chair == false then
				return self:sit_down(player, i, j)
			end
		end
	end
	return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
end
function virtual_room_mgr:sit_down(player, table_id_, chair_id_)
	if player.disable == 1 then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_FREEZEACCOUNT")
	end
	if not player.room_id then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OUT_ROOM")
	end
	
	if player.table_id or player.chair_id then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_PLAYER_ON_CHAIR")
	end
	
	local room = self:find_room(player.room_id)
	if not room then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
	end
	
	local tb = room:find_table(table_id_)
	if not tb then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
	end
	
	local chair = tb:get_player(chair_id_)
	if chair then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER")
	elseif chair == nil then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_CHAIR")
	end
	
	local notify = {
		table_id = table_id_,
		pb_visual_info = {
			chair_id = chair_id_,
			guid = player.guid,
			account = player.account,
			nickname = player.nickname,
			level = player:get_level(),
			money = player:get_money(),
			header_icon = player:get_avatar(),			
			ip_area = player.ip_area,
			is_ready = (tb.ready_list_ and tb.ready_list_[player.chair_id] or false)
		},
	}
	tb:foreach(function (p)
		p:on_notify_sit_down(notify)
	end)
	tb:player_sit_down(player, chair_id_)
	log_info(string.format("player %d sit_down tb %d chair %d",player.guid,tb.table_id_,chair_id_))
	return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), table_id_, chair_id_
end
function virtual_room_mgr:stand_up(player)
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
	log_info(string.format("player %d stand_up tb %d chair %d",player.guid,tableid,chairid))
	return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), tableid, chairid
end
function virtual_room_mgr:find_android_pos(room_id)
	local room = self:find_room(room_id)
	if not room then
		return nil
	end
	local isplayer = false
	local tableid, chairid
	for i,tb in ipairs(room:get_table_list()) do
		for j,chair in ipairs(tb:get_player_list()) do
			if chair == true then
				if isplayer then
					return i, j
				else
					isplayer = true
					tableid = i
					chairid = j
				end
			elseif chair.is_player then
				if tableid and chairid then
					return tableid, chairid
				end
				isplayer = true
			end
		end
	end
	return nil
end
function virtual_room_mgr:tick()
	for i,v in ipairs(self.room_list_) do
		for _,tb in ipairs(v:get_table_list()) do
			tb:tick()
		end
	end
end
function virtual_room_mgr:get_private_table(room,player, chair_count, score_type, cell_money_)
	local suitable_table = nil
	local chair_id = nil
	local table_id = nil
	for j,tb in ipairs(room:get_table_list()) do
		if 0 == tb:get_player_count() then
			for k,chair in ipairs(tb:get_player_list()) do
				if chair == false then
					suitable_table = tb
					chair_id = k
					table_id = j
					tb.private_room = true
					tb.private_room_chair_count = chair_count
					tb.private_room_score_type = score_type
					tb.private_room_cell_money = cell_money_
					tb.private_room_owner_guid = player.guid
					tb.private_room_owner_chair_id = k
					tb.private_room_id = player.guid*100+def_first_game_type		-- 私人房间号暂时先用创建的guid+firsttype
					tb:private_init()
					return suitable_table,chair_id,table_id
				end
			end
		end
	end	
	return suitable_table,chair_id,table_id
end
function virtual_room_mgr:get_join_private_table(room,owner_guid, player)
	local suitable_table = nil
	local chair_id = nil
	local table_id = nil
	local is_full = false
	for j,tb in ipairs(room:get_table_list()) do
		if tb.private_room and tb.private_room_id == owner_guid then
			local tb_count = tb:get_player_count()
			if 0 == tb_count then
				tb.private_room = false
			else
				if tb_count >= tb.private_room_chair_count then
					is_full = true
					break
				end
				for k,chair in ipairs(tb:get_player_list()) do
					if chair == false then
						if tb:canEnter(player) then
							suitable_table = tb
							chair_id = k
							table_id = j
						else
						end
						break
					end
				end
				break
			end
		end
	end	
	return suitable_table,chair_id,table_id, is_full
end
function virtual_room_mgr:get_suitable_table(room,player,bool_change_table)
	local player_count = -1
	local suitable_table = nil
	local chair_id = nil
	local table_id = nil
	for j,tb in ipairs(room:get_table_list()) do
		if tb.private_room and 0 == tb:get_player_count() then
			tb.private_room = false
		end
		if (not tb.private_room) and (suitable_table == nil or (suitable_table ~= nil and suitable_table:get_player_count() < tb:get_player_count())) then
			for k,chair in ipairs(tb:get_player_list()) do
				if (bool_change_table and player.table_id ~= tb.table_id_) or (not bool_change_table) then
					if chair == false and tb:canEnter(player) then
						local tmp_player_count = tb:get_player_count()	
						if player_count < tmp_player_count then
							player_count = tmp_player_count	
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
		end
	end	
	
	return suitable_table,chair_id,table_id
end
function virtual_room_mgr:change_table(player)
	log_info(string.format("change table player %d ",player.guid))
	if player.disable == 1 then
		return pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_FREEZEACCOUNT")
	end
	local tb = self:get_user_table(player)
	if tb then
		if def_game_id > 20 and def_game_id < 30 then  --斗地主农民不换桌,地主强制换桌
			--if player.first_land ~=nil and player.first_land == 1 and not(player.is_android) then
			if player.first_land ~=nil then
				if player.first_land == 1 then
					player.first_land = 0
				elseif player.first_land == 0 then
					tb:ready(player)
					return
				end
			else
				player.first_land = 0
				tb:ready(player)
				return
			end
		end


		local room = self:find_room_by_player(player)
		if room then	
			local tb,k,j = self:get_suitable_table(room,player,true)
			if tb then
				--if def_game_id  
				local result_, table_id_, chair_id_  = self:stand_up(player)
				player:on_stand_up(table_id_, chair_id_, result_)
				local notify = {
					table_id = j,
					pb_visual_info = {
					chair_id = k,
					guid = player.guid,
					account = player.account,
					nickname = player.nickname,
					level = player:get_level(),
					money = player:get_money(),
					header_icon = player:get_avatar(),
					ip_area = player.ip_area,
					is_ready = (tb.ready_list_ and tb.ready_list_[player.chair_id] or false)
					}
				}
					
				tb:foreach(function (p)
					p:on_notify_sit_down(notify)
				end)
				tb:player_sit_down(player,k)
				player:change_table(player.room_id, j, k, pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"), tb)
				self:get_table_players_status(player)
				log_info(string.format("change table suc player %d, tb %d",player.guid,tb.table_id_))
				return
			end	
		else
		end
	else
	end
end
function virtual_room_mgr:change_tax(tax, tax_show, tax_open)
	tax_ = tax * 0.01
	for i , v in pairs (self.room_list_) do		
		print (tax_, tax_show, tax_open)
		v.tax_show_ = tax_show 
		v.tax_open_ = tax_open 
		v.tax_ = tax_
	end
end
