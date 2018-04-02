local pb = require "extern/lib/lib_pb"
require "game_script/handler_net"
local get_msg_id_str = get_msg_id_str
local def_game_id = def_game_id
local def_game_name = def_game_name
require "extern/lib/lib_table"
virtual_table = {}
function virtual_table:new()  
    local o = {}  
    setmetatable(o, {__index = self})
	
    return o 
end

function virtual_table:get_now_game_id()
	local guid = string.format([[%03d%03d%04d%s%07d]], def_game_id, self.room_.id, self.table_id_, self.ID_date_,self.table_gameid)
	return guid
end

function virtual_table:next_game()
	self.ID_date_ = os.date("%y%m%d%H%M")
	self.table_gameid = self.table_gameid + 1
end
function virtual_table:startsaveInfo()
	for _,v in ipairs(self.player_list_) do
		if v then 
			v:IncPlayTimes()
			v:SetPlayerIpContrl(self.player_list_)
		end
	end
end
function virtual_table:canEnter(player)
	return true
end

function virtual_table:init(room, table_id, chair_count)
	self.table_gameid = 1
	self.room_ = room
	self.table_id_ = table_id
	self.def_game_name = def_game_name
	self.def_game_id = def_game_id
	self.player_list_ = {}
	self.player_guid_list_ = {}
	self.ID_date_ = os.date("%y%m%d%H%M")
	self.configid_ = room.configid_
	self.tax_show_ = room.tax_show_ 
	self.tax_open_ = room.tax_open_ 
	self.tax_ = room.tax_ 
	self.room_limit_ = room.room_limit_ 
	self.cell_score_ = room.cell_score_ 
	for i = 1, chair_count do
		self.player_list_[i] = false
	end
	if room:get_ready_mode() ~= pb.get_ev("GAME_READY_MODE", "GAME_READY_MODE_NONE") then
		self.ready_list_ = {}
		for i = 1, chair_count do
			self.ready_list_[i] = false
		end
	end
	self.notify_msg = {}
	if self.tax_show_ == 1 then 
		self.notify_msg.flag = 3
	else
		self.notify_msg.flag = 4
	end	
end
function virtual_table:isPlay( ... )
	return false
end
function virtual_table:load_lua_cfg( ... )
	return false
end
function virtual_table:get_player(chair_id)
	if not chair_id then
		return nil
	end
	return self.player_list_[chair_id]
end

function virtual_table:set_player(chair_id, player)
	self.player_list_[chair_id] = player
	if player then
		self.player_guid_list_[chair_id] = player.guid
	else
		self.player_guid_list_[chair_id] = false
	end
end

function virtual_table:get_player_list()
	return self.player_list_
end
function virtual_table:has_real_player()
	for k,chair in pairs(self.player_list_) do
		if chair and (not chair.is_android) then
			return true
		end
	end
	return false
end
function virtual_table:has_robot_player()
	for k,chair in pairs(self.player_list_) do
		if chair and (chair.is_android) then
			return true
		end
	end
	return false
end
function virtual_table:get_real_player_count()
	local count = 0
	for k,chair in pairs(self.player_list_) do
		if chair and (not chair.is_android) then
			count = count + 1
		end
	end
	return count
end

function virtual_table:get_player_count()
	local count = 0
	for k,chair in pairs(self.player_list_) do
		if chair then
			count = count + 1
		end
	end
	return count
end

function virtual_table:foreach(func)
	for i, p in pairs(self.player_list_) do
		if p then
			func(p)
		end
	end
end
function virtual_table:foreach_except(except, func)
	for i, p in pairs(self.player_list_) do
		if p and i ~= except then 
			func(p)
		end
	end
end
function  virtual_table:write_game_log_to_mysql(s_playid,s_playType,s_log,s_starttime,s_endtime)
	local nMsg = {
		playid = s_playid,
		type = s_playType,
		log = s_log,
		starttime = s_starttime,
		endtime = s_endtime,
	}
	post_msg_to_mysql_pb("SL_Log_Game",nMsg)
end
function virtual_table:user_log_money(player,s_type,s_old_money,s_tax,s_change_money,s_id)
	local nMsg = {
		guid = player.guid,
		type = s_type,
		gameid = self.def_game_id or def_game_id,
		game_name = self.def_game_name or def_game_name,
		phone_type = player.phone_type,
		old_money = s_old_money,
		new_money = player.pb_base_info.money,
		tax = s_tax,
		change_money = s_change_money,
		ip = player.ip,
		id = s_id,
		channel_id = player.create_channel_id,
	}
	post_msg_to_mysql_pb("SL_Log_Money",nMsg)
	post_msg_to_client_pb(player,"SC_Gamefinish",{
		money = player.pb_base_info.money
	})
end
function virtual_table:user_log_money_user_nil(guid, phone_type,money, ip, s_type,s_old_money,s_tax,s_change_money,s_id,channel_id)
	local nMsg = {
		guid = guid,
		type = s_type,
		gameid = self.def_game_id or def_game_id,
		game_name = self.def_game_name or def_game_name,
		phone_type = phone_type,
		old_money = s_old_money,
		new_money = money,
		tax = s_tax,
		change_money = s_change_money,
		ip = ip,
		id = s_id,
		channel_id = channel_id,
	}
	post_msg_to_mysql_pb("SL_Log_Money",nMsg)
end

function virtual_table:user_log_money_robot(robot,banker_flag,winorlose,old_money,tax,money_change,table_id)
	local nMsg = {
		guid = robot.guid,
		isbanker = banker_flag,
		winorlose = winorlose,
		gameid = self.def_game_id,
		game_name = self.def_game_name,
		old_money = old_money,
		new_money = robot.money,
		tax = tax,
		money_change = money_change,
		id = table_id,
	}
	post_msg_to_mysql_pb("SL_Log_Robot_Money",nMsg)
end

function virtual_table:tax_channel_invite(channel_id_p,guid_p,guid_invite_p,tax_p)
	if true then
		return
	end
	
	if tax_p == 0 or guid_invite_p == nil or guid_invite_p == 0 then
		return
	end
	local cfg = channel_invite_cfg(channel_id_p)
	if cfg and cfg.is_invite_open == 1 then
		local nMsg = {
			channel_id = channel_id_p,
			guid = guid_p,
			guid_invite = guid_invite_p,
			val = math.floor(tax_p*cfg.tax_rate/100)
		}
		post_msg_to_mysql_pb("SL_Channel_Invite_Tax",nMsg)
	end
end


function virtual_table:broadcast_msg_to_client(msg_name, pb)
	local id, msg = get_msg_id_str(msg_name, pb)
	for i, p in pairs(self.player_list_) do
		if not p or p.noready == true then
		else
			if p.online and p.in_game then
				post_msg_to_client_pb_str(p, id, msg)
			else
				if p.is_player == false then
				else
				end
			end
		end
	end
end
function virtual_table:broadcast_msg_to_client_except(except, msg_name, pb)
	local id, msg = get_msg_id_str(msg_name, pb)
	for i, p in ipairs(self.player_list_) do
		if p and i ~= except then
			post_msg_to_client_pb_str(p, id, msg)
		end
	end
end

function virtual_table:player_sit_down(player, chair_id_)
	player.table_id = self.table_id_
	player.chair_id = chair_id_
	self.player_list_[chair_id_] = player

	if player.is_player then
		for i, p in ipairs(self.player_list_) do
			if p == false then
				player:on_notify_android_sit_down(player.room_id, self.table_id_, i)
			end
		end
	end
end
function virtual_table:player_sit_down_finished(player)
	return
end

function virtual_table:playeroffline(player)
	player.in_game = false
end
function virtual_table:player_stand_up(player, is_offline)
	if self:check_cancel_ready(player, is_offline) then
		local chairid = player.chair_id
		self.player_list_[chairid] = false
		player.table_id = nil
		player.chair_id = nil
		if self.room_:get_ready_mode() ~= pb.get_ev("GAME_READY_MODE", "GAME_READY_MODE_NONE") then
			if self.ready_list_[chairid] then
				self.ready_list_[chairid] = false
				local notify = {
					ready_chair_id = chairid,
					is_ready = false,
				}
				self:broadcast_msg_to_client("SC_Ready", notify)
			end
		end
		log_info(string.format("player %d stand up table %d",player.guid,self.table_id_))
		return true
	end
	if is_offline then
		player.is_offline = true
	end
	return false
end
function virtual_table:setTrusteeship(player)
end

function virtual_table:ready(player)
	if player.disable == 1 then
		player:forced_exit()
		return
	end
	if not self:check_ready(player) then
		return
	end
	if not player.room_id then
		log_warning(string.format("guid[%d] not find in room", player.guid))
		return
	end
	if not player.table_id then
		log_warning(string.format("guid[%d] not find in table", player.guid))
		return
	end
	if not player.chair_id then
		log_warning(string.format("guid[%d] not find in chair_id", player.guid))
		return
	end
	local ready_mode = self.room_:get_ready_mode()
	if ready_mode == pb.get_ev("GAME_READY_MODE", "GAME_READY_MODE_NONE") then
		return
	end
	if self.ready_list_[player.chair_id] ~= false then
		return
	end
	self.ready_list_[player.chair_id] = true
	
	if def_game_name ~= "zhajinhua" and def_game_name ~= "showhand" and def_game_name ~= "point21" 
		and def_game_name ~= "sangong" then
		self:foreach(function(p)
			if p.is_android and (not self.ready_list_[p.chair_id]) then
					self.ready_list_[p.chair_id] = true
				local notify = {
					ready_chair_id = p.chair_id,
					is_ready = true,
					}
				self:broadcast_msg_to_client("SC_Ready", notify)
			end
		end)
	end
	player.Dropped = false
	local notify = {
		ready_chair_id = player.chair_id,
		is_ready = true,
		}
	self:broadcast_msg_to_client("SC_Ready", notify)
	self:check_start(false)
end
function virtual_table:reconnection_client_msg(player)
	player.Dropped = false
	player.online = true
	player.in_game = true
end
function virtual_table:check_ready(player)
	return true
end

function virtual_table:check_cancel_ready(player, is_offline)
	if is_offline then
		player.Dropped = true
	end
	return self.room_:get_ready_mode() ~= pb.get_ev("GAME_READY_MODE", "GAME_READY_MODE_NONE")
end

function virtual_table:check_start(part)
	local ready_mode = self.room_:get_ready_mode()
	if ready_mode == pb.get_ev("GAME_READY_MODE", "GAME_READY_MODE_PART") then
		local n = 0
		for i, v in ipairs(self.player_list_) do
			if v then
				if self.ready_list_[i] then
					n = n+1
				else
					return
				end
			end
		end
		if n >= 2 then
			self:start(n)
		end
	end
	if part then
		return
	end
	if ready_mode == pb.get_ev("GAME_READY_MODE", "GAME_READY_MODE_ALL") then
		local n =0
		for i,v in ipairs(self.ready_list_) do
			if not v then
				return
			end
			n = n +1
		end
		self:start(n)
	end
end
function virtual_table:send_playerinfo(player)
	return true  
end

function virtual_table:start(player_count)
	local bRet = false
	if self.configid_ ~= self.room_.configid_ then 
		self.tax_show_ = self.room_.tax_show_ 
		self.tax_open_ = self.room_.tax_open_ 
		self.tax_ = self.room_.tax_ 
		self.room_limit_ = self.room_.room_limit_ 
		self.cell_score_ = self.room_.cell_score_ 
		if self.tax_show_ == 1 then 
			self.notify_msg.flag = 3
		else
			self.notify_msg.flag = 4
		end	
		self.configid_ = self.room_.configid_ 
		bRet = true	
	
		if self.room_.lua_cfg_ ~= nil then
			self:load_lua_cfg()
		end
	end
	self:broadcast_msg_to_client("SC_ShowTax", self.notify_msg)
	return bRet
end

function virtual_table:check_game_maintain()
	local iRet = false
	if ly_game_switch == 1 then
		for i,v in pairs (self.player_list_) do
			if  v and v.is_player == true and v.vip ~= 100 then 
				post_msg_to_client_pb(v, "SC_GameMaintain", {
				result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_MAINTAIN"),
				first_game_type = def_first_game_type,
				second_game_type = 0,
				})
				v:forced_exit()
			end
		end
		iRet = true
	end
	return iRet
end

function virtual_table:onNotifyReadyPlayerMaintain(player)
	local iRet = false
	if ly_game_switch == 1 and player.vip ~= 100 then
		post_msg_to_client_pb(player, "SC_GameMaintain", {
		result = GAME_SERVER_RESULT_MAINTAIN,
		first_game_type = def_first_game_type,
		second_game_type = def_second_game_type,
		})
		player:forced_exit()
		iRet = true
	end
	return iRet
end

function virtual_table:reconnect(player)
	log_info(string.format("player %d reconnect to table %d",player.guid,self.table_id_))
end

function virtual_table:clear_ready()
	for i,v in ipairs(self.ready_list_) do
		self.ready_list_[i] = false
	end
end

function virtual_table:tick()
end
function virtual_table:private_init()
end
function virtual_table:destroy_private_room(b)
	if self.private_room then
		if b then
			local player = virtual_player:find(self.private_room_owner_guid)
			if player  then
				player:change_money(self.open_private_room_cost, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CREATE_PRIVATE_ROOM"))
			end
		end
		post_msg_to_mysql_pb("SD_FilishPrivateRoomLog", {
			room_id = self.private_room_id,
			room_state = (b and 11 or 10),
			})
		self.private_room = false
	end
end

function virtual_table:update_player_last_recharge_game_total(player,guid)
	if not guid then
		if (not player) or player.is_android or (not player.guid) or (0 == player.guid) then
			return
		end
	end
	post_msg_to_mysql_pb("SD_Do_OneSql",{db_name = "game",
	sql = string.format("UPDATE t_player SET last_recharge_game_total = last_recharge_game_total + 1 WHERE guid = %d",guid or player.guid)})
end

function virtual_table:update_player_bet_total(bet,player,guid)
	if not guid then
		if bet == 0 or (not player) or player.is_android or (not player.guid) or (0 == player.guid) then
			return
		end
	end
	post_msg_to_mysql_pb("SD_Do_OneSql",{db_name = "game",
	sql = string.format("UPDATE t_player SET bet_total = bet_total + %d WHERE guid = %d",
	bet,guid or player.guid)})
end



