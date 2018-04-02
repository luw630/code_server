local pb = require "extern/lib/lib_pb"
require "game_script/virtual/virtual_gamer"
require "game_script/virtual/virtual_robot"
local virtual_active_android = virtual_active_android
require "game_script/handler_net"
local post_msg_to_client_pb = post_msg_to_client_pb
local send2redis_pb = send2redis_pb
require "extern/lib/lib_redis"
local redis_command = redis_command
local redis_cmd_query = redis_cmd_query
local Set_GameTimes = Set_GameTimes
local def_game_id = def_game_id
local IncPlayTimes = IncPlayTimes
local judgePlayTimes = judgePlayTimes
local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type
local def_game_id = def_game_id
g_init_player_ = g_init_player_ or {}
g_accout_player_ = g_accout_player_ or {}
local init_player_ = g_init_player_
local accout_player_ = g_accout_player_
if not virtual_player then
	virtual_player = virtual_gamer:new()
	virtual_player.player_count = 0
end

function virtual_player:init(guid_, account_, nickname_)
	virtual_gamer.init(self, guid_, account_, nickname_)
	self.online = true
	self.is_player = true
	self.in_game = true
	init_player_[guid_] = self
	accout_player_[account_] = self
	
	virtual_player.player_count = virtual_player.player_count + 1
	self:update_player_num()

	if def_first_game_type == 6 and guid_ > 25000 then --zjh
		post_msg_to_mysql_pb("SD_QueryPlayerRecharge", {
			guid = guid_
			})
	end
end
function virtual_player:del()
	accout_player_[self.account] = nil
	init_player_[self.guid] = nil
	
	virtual_player.player_count = virtual_player.player_count - 1
	if virtual_player.player_count <=0 then   
		g_init_player_ = nil
		g_accout_player_ = nil
		accout_player_ = nil
		init_player_ = nil
		g_init_player_ = {}
		g_accout_player_ = {}
		init_player_ = g_init_player_
		accout_player_ = g_accout_player_
	end
	if virtual_player.player_count >= 0 then
		self:update_platfrom_online_info("off")
		self:update_player_num()
	else
		log_error(string.format("player %d del, player_count %d",self.guid,virtual_player.player_count))
	end
end
function virtual_player:update_platfrom_online_info(flag)
	if flag == "on" then
		if self.phone == "android" then
			ly_android_online_count = ly_android_online_count + 1
		elseif self.phone == "ios" then
			ly_ios_online_count = ly_ios_online_count + 1
		end
	elseif flag == "off" then
		if self.phone == "android" then
			ly_android_online_count = ly_android_online_count - 1
		elseif self.phone == "ios" then
			ly_ios_online_count = ly_ios_online_count - 1
		end
	end
	if ly_android_online_count < 0 then ly_android_online_count = 0 log_error("ly_android_online_count < 0") end
	if ly_ios_online_count < 0 then ly_ios_online_count = 0 log_error("ly_ios_online_count < 0") end
	log_info(string.format("player count all %d android %d ios %d",virtual_player.player_count,ly_android_online_count,ly_ios_online_count))
	self:update_player_num()
end

function virtual_player:reset_account(account_, nickname_)
	accout_player_[self.account] = nil
	self.account = account_
	self.nickname = nickname_
	accout_player_[account_] = self
end
function virtual_player:update_player_num()
	broadcast_player_count(virtual_player.player_count,ly_android_online_count,ly_ios_online_count)
end
function virtual_player:check_room_limit(score)
	if not self.pb_base_info then
		return false
	end
	return self.pb_base_info.money < score
end
function virtual_player:handler_enter_sit_down(room_id_, table_id_, chair_id_, result_, tb)
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		local notify = {
			room_id = room_id_,
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
			ip_area = self.ip_area,
		}
		tb:foreach_except(chair_id_, function (p)
			local v = {
				chair_id = p.chair_id,
				guid = p.guid,
				account = p.account,
				nickname = p.nickname,
				level = p:get_level(),
				money = p:get_money(),
				header_icon = p:get_avatar(),
				ip_area = p.ip_area,
			}
			if tb.ready_list_ and tb.ready_list_[p.chair_id] then
				v.is_ready = true
			end
			notify.pb_visual_info = notify.pb_visual_info or {}
			table.insert(notify.pb_visual_info, v)
		end)
		
		post_msg_to_client_pb(self, "SC_EnterRoomAndSitDown", notify)
	else
		post_msg_to_client_pb(self, "SC_EnterRoomAndSitDown", {
			result = result_,
			})
	end
end
function virtual_player:change_table( room_id_, table_id_, chair_id_, result_, tb )
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		local notify = {
			room_id = room_id_,
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
		}
		tb:foreach_except(chair_id_, function (p)
			local v = {
				chair_id = p.chair_id,
				guid = p.guid,
				account = p.account,
				nickname = p.nickname,
				level = p:get_level(),
				money = p:get_money(),
				header_icon = p:get_avatar(),
				ip_area = p.ip_area,
			}
			if tb.ready_list_ and tb.ready_list_[p.chair_id] then
				v.is_ready = true
			end
			notify.pb_visual_info = notify.pb_visual_info or {}
			table.insert(notify.pb_visual_info, v)
		end)
		
		post_msg_to_client_pb(self, "SC_ChangeTable", notify)
	else
		post_msg_to_client_pb(self, "SC_ChangeTable", {
			result = result_,
			})
	end
end
function virtual_player:handler_stand_exit_room(room_id_, table_id_, chair_id_, result_)
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		post_msg_to_client_pb(self, "SC_StandUpAndExitRoom", {
			room_id = room_id_,
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
			})
		post_msg_to_mysql_pb("SD_OnlineAccount", {
			guid = self.guid,
			first_game_type = def_first_game_type,
			second_game_type = def_second_game_type,
			gamer_id = def_game_id,
			})
	else
		post_msg_to_client_pb(self, "SC_StandUpAndExitRoom", {
			result = result_,
			})
	end
end
function virtual_player:on_change_chair(table_id_, chair_id_, result_, tb)
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		local notify = {
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
			ip_area = self.ip_area,
		}
		tb:foreach_except(chair_id_, function (p)
			local v = {
				chair_id = p.chair_id,
				guid = p.guid,
				account = p.account,
				nickname = p.nickname,
				level = p:get_level(),
				money = p:get_money(),
				header_icon = p:get_avatar(),
				ip_area = p.ip_area,
			}
			if tb.ready_list_ and tb.ready_list_[p.chair_id] then
				v.is_ready = true
			end
			notify.pb_visual_info = notify.pb_visual_info or {}
			table.insert(notify.pb_visual_info, v)
		end)
		
		post_msg_to_client_pb(self, "SC_ChangeChair", notify)
	else
		post_msg_to_client_pb(self, "SC_ChangeChair", {
			result = result_,
			})
	end
end
function virtual_player:on_enter_room(room_id_, result_)
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		post_msg_to_client_pb(self, "SC_EnterRoom", {
			room_id = room_id_,
			result = result_,
			})
	else
		post_msg_to_client_pb(self, "SC_EnterRoom", {
			result = result_,
			})
	end
end
function virtual_player:on_notify_enter_room(notify)
	post_msg_to_client_pb(self, "SC_NotifyEnterRoom", notify)
end
function virtual_player:on_exit_room(room_id_, result_)
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		post_msg_to_client_pb(self, "SC_ExitRoom", {
			room_id = room_id_,
			result = result_,
		})
	else
		post_msg_to_client_pb(self, "SC_ExitRoom", {
			result = result_,
		})
	end
end
function virtual_player:on_notify_exit_room(notify)
	post_msg_to_client_pb(self, "SC_NotifyExitRoom", notify)
end
function virtual_player:on_sit_down(table_id_, chair_id_, result_)
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		post_msg_to_client_pb(self, "SC_SitDown", {
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
			})
	else
		post_msg_to_client_pb(self, "SC_SitDown", {
			result = result_,
			})
	end
	return result_
end
function virtual_player:on_notify_sit_down(notify)	
	post_msg_to_client_pb(self, "SC_NotifySitDown", notify)
end
function virtual_player:on_stand_up(table_id_, chair_id_, result_)
	if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		post_msg_to_client_pb(self, "SC_StandUp", {
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
			})
	else
		post_msg_to_client_pb(self, "SC_StandUp", {
			result = result_,
			})
	end
end
function virtual_player:on_notify_stand_up(notify)
	post_msg_to_client_pb(self, "SC_NotifyStandUp", notify)
end
function virtual_player:on_notify_android_sit_down(room_id_, table_id_, chair_id_)
	local a = virtual_active_android:find_active_android(room_id_)
	if a then
		a:think_on_sit_down(room_id_, table_id_, chair_id_) 
	end
end
function virtual_player:find(guid)
	return init_player_[guid]
end
function virtual_player:find_by_account(account)
	return accout_player_[account]
end
function virtual_player:foreach(func)
	for _, player in pairs(init_player_) do
		func(player)
	end
end
function virtual_player:broadcast_msg_to_client_pb(msg_name, pb)
	for _, player in pairs(init_player_) do
		post_msg_to_client_pb(player, msg_name, pb)
	end
end
function virtual_player:save()
	
	if self.flag_base_info and (not self.is_android) then
		self.flag_base_info = false
		post_msg_to_mysql_pb("SD_SavePlayerData", {
			guid = self.guid,
			pb_base_info = self.pb_base_info,
		})
	end
end
function virtual_player:getinfo()
end

function virtual_player:update_gamemaintain(msg)
	for _,player in pairs(init_player_) do
		player:update_game_maintain(msg)
	end
end

function virtual_player:update_game_maintain(msg)
	log_info("update_game_maintain player "..msg.first_game_type)
	post_msg_to_client_pb(self, "SC_GameMaintain", {
		result = 0,
		first_game_type = msg.first_game_type,
		second_game_type = 0,
		})
end


function virtual_player:updateNoticeEverone(msg)
	for _,player in pairs(init_player_) do
		player:updateNotice(msg)
	end
end
function virtual_player:updateNotice(msg)
	if msg.msg_type == 3 then
		
		local notify = {
			id = msg.id,
			content = msg.content,
			start_time = msg.start_time,
			end_time = msg.end_time,
			number = msg.number,
			interval_time = msg.interval_time,
		}
		local msg_data = {
			pb_msg_data = {},
		}
		table.insert(msg_data.pb_msg_data,notify)
		
		post_msg_to_client_pb(self,"SC_QueryPlayerMarquee",msg_data)
		return
	end
		local notify = {
			id = msg.id,
			is_read = msg.is_read,
			msg_type = msg.msg_type,
			content = msg.content,
			start_time = msg.start_time,
			end_time = msg.end_time,
		}
		local msg_data = {
			pb_msg_data = nil,
		}
		msg_data.pb_msg_data = {}
		table.insert(msg_data.pb_msg_data,notify)
		
		post_msg_to_client_pb(self,"SC_NewMsgData",msg_data)
end
function virtual_player:deleteNoticeEverone(msg)
	for _,player in pairs(init_player_) do
		player:deleteNotice(msg)
	end
end
function virtual_player:deleteNotice(msg)
	local notify = {
		msg_id = msg.msg_id,
		msg_type = msg.msg_type,
	}
	post_msg_to_client_pb(self,"SC_DeletMsg",msg_data)
end
function virtual_player:save2redis()
	if self.flag_base_info then
		self.flag_base_info = false
		if self.pb_base_info then
			
		end
		self.flag_save_db = true
	end
	
end
function virtual_player:do_save()
	for _, player in pairs(init_player_) do
		player:save()
	end
end
function virtual_player:get_level()
	if not self.pb_base_info then
		return 0
	end
	return self.pb_base_info.level
end
function virtual_player:get_money()
	if not self.pb_base_info then
		log_error("get_money pb nil, guid " .. tostring(self.guid))
		return 0
	end
	if self.pb_base_info.money and self.pb_base_info.money < 0 then
		log_error("get_money < 0, guid " .. tostring(self.guid))
	end
	return self.pb_base_info.money
end
function virtual_player:get_bank()
	if not self.pb_base_info then
		log_error("get_bank pb nil, guid " .. tostring(self.guid))
		return 0
	end
	if self.pb_base_info.bank and self.pb_base_info.bank < 0 then
		log_error("get_bank < 0, guid " .. tostring(self.guid))
	end
	return self.pb_base_info.bank
end

function virtual_player:get_avatar()
	if self.pb_base_info ~= nil then
		return self.pb_base_info.header_icon
	end
	
end
function virtual_player:cost_money(price, opttype, bRet)
	log_info ("cost_money begin player :"..  self.guid)
	local money = self.pb_base_info.money
	local oldmoney = money
	local iRet = true
	for _, p in ipairs(price) do
	
		if p.money_type == pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD") then
			if p.money <= 0 or money < p.money then
				if p.money ~= 0 then
					log_error(string.format("cost_money error [%d] [%d] [%d]",self.guid,p.money,money))
				end
				if math.floor(p.money) < p.money then
					p.money = math.floor(p.money)
					log_error("cost_money p.money is float" .. tostring(p.money))
				end
				if money < p.money then
					money = p.money
				end
				iRet = false
				if bRet == nil  then
					return false
				end
			end

			log_info(string.format("money = [%d] - [%d]" , money,p.money))
			money = money - p.money
			if self.is_android then ly_robot_storage = ly_robot_storage - p.money end
		else
			log_error("cost_money  error  money_type " .. tostring(p.money_type))
		end
	end
	self.pb_base_info.money = money
	self.flag_base_info = true
	self:save()
	if self.is_android then
		post_msg_to_mysql_pb("SD_Save_Storage", {
			game_id = def_game_id,
			storage = ly_robot_storage
		})
		
	end
	local money_ = money
	if not self.is_android then
		post_msg_to_client_pb(self, "SC_NotifyMoney", {
			opt_type = opttype,
			money = money_,
			change_money = money_-oldmoney,
			})
	end
	post_msg_to_mysql_pb("SD_LogMoney", {
			guid = self.guid,
			old_money = oldmoney,
			new_money = self.pb_base_info.money,
			old_bank = self.pb_base_info.bank or 0,
			new_bank = self.pb_base_info.bank or 0,
			opt_type = opttype,
		})
	log_info(string.format("player %d cost_money  end, oldmoney[%d] new_money[%d]" , self.guid, oldmoney, self.pb_base_info.money))
	return iRet
end
function virtual_player:add_money(price, opttype)
	log_info ("add_money begin player :"..  self.guid)
	local money = self.pb_base_info.money
	local oldmoney = money
	
	for _, p in ipairs(price) do
		if p.money_type == pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD") then
			if p.money <= 0 then
				if p.money < 0 then
					log_error(string.format("add_money error [%d] [%d] [%d]",self.guid,p.money,money))
				end
				return false
			end
			if math.floor(p.money) < p.money then
				p.money = math.floor(p.money)
				log_error("add_money  p.money is float" .. tostring(p.money))
			end
			
			log_info(string.format("money = [%d] + [%d]" , money,p.money))
			money = money + p.money
			if self.is_android then ly_robot_storage = ly_robot_storage + p.money end
		else
			log_error("add_money  error  money_type " .. tostring(p.money_type))
		end
	end
	
	self.pb_base_info.money = money
	self.flag_base_info = true
	self:save()
	if self.is_android then
		post_msg_to_mysql_pb("SD_Save_Storage", {
			game_id = def_game_id,
			storage = ly_robot_storage
		})
		
	end
	local money_ = money
	if not self.is_android then
	post_msg_to_client_pb(self, "SC_NotifyMoney", {
		opt_type = opttype,
		money = money_,
		change_money = money_-oldmoney,
		})
	end
	post_msg_to_mysql_pb("SD_LogMoney", {
			guid = self.guid,
			old_money = oldmoney,
			new_money = self.pb_base_info.money,
			old_bank = self.pb_base_info.bank or 0,
			new_bank = self.pb_base_info.bank or 0,
			opt_type = opttype,
		})

	log_info(string.format("player %d add_money end ,old money=%d , new money=%d ",self.guid,oldmoney,money_))
	return true
end
function virtual_player:add_item(id, num)
	local item = data_item[id]
	if not item then
		return
	end
	
	if item.item_type == pb.get_ev("ITEM_TYPE", "ITEM_TYPE_MONEY") then
		local oldmoney = self.pb_base_info.money
		self.pb_base_info.money = self.pb_base_info.money + num
		self.flag_base_info = true
		self:save()

		post_msg_to_mysql_pb("SD_UpdateEarnings", {
			guid = self.guid,
			money = num,
		})

		post_msg_to_mysql_pb("SD_LogMoney", {
			guid = self.guid,
			old_money = oldmoney,
			new_money = self.pb_base_info.money,
			old_bank = self.pb_base_info.bank,
			new_bank = self.pb_base_info.bank,
			opt_type = pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_BOX"),
		})
		return
	end
	
	self.pb_item_bag = self.pb_item_bag or {}
	self.pb_item_bag.items = self.pb_item_bag.items or {}
	for _, item in ipairs(self.pb_item_bag.items) do
		if item.item_id == id then
			item.item_num = item.item_num + num
			self.flag_item_bag = true
			return
		end
	end
	
	table.insert(self.pb_item_bag.items, {item_id = id, item_num = num})
	self.flag_item_bag = true
end

function virtual_player:setStatus(is_onLine)
	
	if is_onLine then
		self.online = false
	else
		self.online = true
	end
end
function  virtual_player:changeBankMoney( value )
	local bank = self.pb_base_info.bank
	if value < 0 then
		if bank + value < 0 then
			log_error(string.format("changeBankMoney error [%d] [%d] [%d]",self.guid,value,bank))
			return pb.get_ev("ChangeMoneyRecode", "ChangMoney_NotEnoughMoney")
		end
	end	
	self.pb_base_info.bank = bank + value
	return pb.get_ev("ChangeMoneyRecode", "ChangMoney_Success"),bank,self.pb_base_info.bank
end
function virtual_player:change_bank(value, opttype, is_savedb, bReturn)
	log_info(string.format("change_bank  player[%d] begin value[%d] opttype[%d]" , self.guid, value, opttype))
	local bank = self.pb_base_info.bank
	local oldbank = bank
	local bRet = true
	if(value < 0) then
		local tempMoney = bank + value
		if(tempMoney < 0) then
			log_error(string.format("change_bank error [%d] [%d] [%d]",self.guid,value,bank))
			value = bank
			bRet = false
			if bReturn == nil then
				return false
			end
		end
	end
	self.pb_base_info.bank = bank + value
	self.flag_base_info = true
	self:save()
	
	local bank_ = self.pb_base_info.bank
	post_msg_to_client_pb(self, "SC_NotifyBank", {
		opt_type = opttype,
		bank = bank_,
		change_bank = bank_ - oldbank,
		})
	
	post_msg_to_mysql_pb("SD_LogMoney", {
			guid = self.guid,
			old_money = self.pb_base_info.money,
			new_money = self.pb_base_info.money,
			old_bank =  oldbank,
			new_bank = self.pb_base_info.bank,
			opt_type = opttype,
		})
	if is_savedb then
		post_msg_to_mysql_pb("SD_SavePlayerBank", {
			guid = self.guid,
			bank = bank_,
		})
	end
	log_info(string.format("change_bank  end, oldbank[%d] new_bank[%d]" , oldbank, self.pb_base_info.bank))
	return bRet
end
function virtual_player:change_money(value, opttype, is_savedb, bReturn)	
	value = value or 0
	log_info(string.format("change_money  player[%d] begin value[%d] opttype[%d]" , self.guid, value, opttype))
	local money = self.pb_base_info.money
	local oldmoney = money
	local bRet = true
	if(value < 0) then
		local tempMoney = money + value
		if(tempMoney < 0) then
			log_error(string.format("change_money error [%d] [%d] [%d]",self.guid,value,money))
			value = money
			bRet = false
			if bReturn == nil  then
				return false
			end
		end
	end
	self.pb_base_info.money = money + value
	self.flag_base_info = true
	self:save()
	
	local money_ = self.pb_base_info.money 
	post_msg_to_client_pb(self, "SC_NotifyMoney", {
		opt_type = opttype,
		money = money_,
		change_money = money_ - oldmoney,
		})
	post_msg_to_mysql_pb("SD_LogMoney", {
			guid = self.guid,
			old_money = oldmoney,
			new_money = self.pb_base_info.money,
			old_bank =  self.pb_base_info.bank,
			new_bank = self.pb_base_info.bank,
			opt_type = opttype,
		})
	if is_savedb then
		post_msg_to_mysql_pb("SD_SavePlayerMoney", {
			guid = self.guid,
			money = money_,
		})
	end
	log_info(string.format("change_money  end, oldmoney[%d] new_money[%d]" , oldmoney, self.pb_base_info.money))
	return bRet
end
function virtual_player:player_save_ox_data(player_info)
	post_msg_to_mysql_pb("SD_SavePlayerOxData", {
		guid = player_info.guid,
		is_android = player_info.is_android,
		table_id = player_info.table_id,
		banker_id = player_info.banker_id,
		nickname = player_info.nickname,
		money = player_info.money,
		win_money = player_info.win_money,
		bet_money = player_info.bet_money,
		tax = player_info.tax,
		curtime = player_info.curtime,
	})
	
end
function virtual_player:SetPlayerIpContrl(player_list)
	local gametype = string.format("%d_%d",def_first_game_type,def_second_game_type)
	for _,v in ipairs(player_list) do
		if v and v.guid ~= self.guid then
			Set_GameTimes(gametype,self.guid,v.guid,true)
		end
	end
end
function virtual_player:IncPlayTimes()
	
	local gametype = string.format("%d_%d",def_first_game_type,def_second_game_type)
	IncPlayTimes(gametype,self.guid,true)
end
function virtual_player:judgePlayTimes(other,GameLimitCdTime)
	local gametype = string.format("%d_%d",def_first_game_type,def_second_game_type)
	if judgePlayTimes(gametype,self.guid,other.guid,GameLimitCdTime,true) then
		return true
	else
		return false
	end
end
function  virtual_player:judgeIP(player)
	firstip = self:GetIP()
	secondip = self:GetIP(player)
	return firstip == secondip
end
function virtual_player:GetIP(player)	
	local str = self.ip
	if player then
		str = player.ip
	end
	local ts = string.reverse(str)
	_,i = string.find(ts,"%p")
	m = string.len(ts) - i
	return string.sub(str, 1, m)
end

function  virtual_player:getwinmoney()
	if self.pb_base_info ~= nil then
		local win_money = self.pb_base_info.money + self.pb_base_info.bank + self.cash_total - self.recharge_total
		return win_money
	end
	return 0
end