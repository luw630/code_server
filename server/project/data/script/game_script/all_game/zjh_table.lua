local pb = require "extern/lib/lib_pb"
require "game_script/virtual/virtual_table"
require "game_script/all_game/zjh_robot"

local ZHAJINHUA_CARD_TYPE_BAO_ZI = pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_BAO_ZI")
local GAME_SERVER_RESULT_SUCCESS = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
local GAME_SERVER_RESULT_MAINTAIN = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_MAINTAIN")
local LOG_MONEY_OPT_TYPE_ZHAJINHUA = pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_ZHAJINHUA")
local ITEM_PRICE_TYPE_GOLD = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")
local PLAYER_STAND = -1         
local PLAYER_FREE = 0           
local PLAYER_READY = 1          
local PLAYER_WAIT = 2           
local PLAYER_CONTROL = 3        
local PLAYER_LOOK = 4           
local PLAYER_COMPARE = 5        
local PLAYER_DROP = 6           
local PLAYER_LOSE = 7           
local PLAYER_EXIT = 8           
local PLAYER_EXIT = 9           
local room_manager = g_room_mgr
local def_second_game_type = def_second_game_type
local def_game_name = def_game_name
local vote_time_ = 30  
local ZHAJINHUA_TIMER_READY = 11
local ZHAJINHUA_STATUS_FREE = 1
local ZHAJINHUA_STATUS_READY =  2
local ZHAJINHUA_STATUS_PLAY = 3



zjh_table = virtual_table:new()
function zjh_table:zjh_post_msg_to_client_pb(player, msg_name, msg)
	if player.is_android then
		player:game_msg(msg_name, msg)
	else
		post_msg_to_client_pb(player, msg_name, msg)
	end
end
function zjh_table:zjh_broadcast_msg_to_client(msg_name, msg)
	for i,v in ipairs(self.player_list_) do
		if v then
			self:zjh_post_msg_to_client_pb(v, msg_name, msg)
		end
	end
end
function zjh_table:zjh_broadcast_msg_to_client_except(guid,msg_name, msg)
	for i,v in ipairs(self.player_list_) do
		if v and v.guid ~= guid then
			self:zjh_post_msg_to_client_pb(v, msg_name, msg)
		end
	end
end

local function get_value(card) return math.floor(card / 4) end
local function get_color(card) return card % 4 end
function Queue_newquene() return {min = 1, max = 0} end
function Queue_pop(queue) queue[queue.min] = nil queue.min = queue.min + 1 end
function Queue_push(queue, value)
	queue.max = queue.max + 1  queue[queue.max] = value
    if queue.max > 10 then Queue_pop(queue) end    
end
function zjh_table:def_init()
	self.private_status = ZHAJINHUA_STATUS_FREE
	self.private_room_score_type = 1
	self.total_round = 20
	self.see_card_round = 2
	self.compare_round = 2
	self.total_round_ = 20
	self.see_card_round_ = 2
	self.compare_round_ = 2
	--self.is_addrobot = true 
	self.kuchunbj = true     
	self.helpmoneybyplayer = 0
	self.private_audience = true   
	self.private_no_money_compare = true   
	self.gamedatalist = Queue_newquene()   
	self.private_cfg_msg = {
		first_see = 1,
		first_compare = 0,
		no_money_compare = 1,
		more_round = 0,
	}
	self.private_cfg_msg_ = self.private_cfg_msg
	self.private_vote_status = false     
	self.private_vote_list = {}			 
	self.private_vote_time = 0			 
	self.private_vote_count = 0			 
	self.private_vote_bret = false       
	self.private_statistics = {}

end
function zjh_table:init(room, table_id, chair_count)
	virtual_table.init(self, room, table_id, chair_count)
	self.status = ZHAJINHUA_STATUS_FREE
    self.chair_count = chair_count
	self.cards = {}
	self.add_score_ = {}
	self.player_online = {}
	self.Round = 1
	self.Round_Times = 1 
    self.dead_count_ = 0
	self.is_dead_ = {} 
	self.max_add_score_ = 0431
	self.allready = false
	self.ready_count_down = 12
	self.show_card_list = {}
	self:def_init()

	if def_game_name == "zhajinhua" then
		if def_second_game_type == 1 then
			self.add_score_ = zhajinhua_room_score[1]
		elseif def_second_game_type == 2 then
			self.add_score_ = zhajinhua_room_score[2]
		elseif def_second_game_type == 3 then
			self.add_score_ = zhajinhua_room_score[3]
		elseif def_second_game_type == 4 then
			self.add_score_ = zhajinhua_room_score[4]
		elseif def_second_game_type == 5 then
			self.add_score_ = zhajinhua_room_score[5]
		elseif def_second_game_type == 99 then
			self:private_init()
		else
			return
		end
	end

	for i,v in pairs(self.add_score_) do
		if self.max_add_score_ < v then
			self.max_add_score_ = v
		end
	end

	self.player_status = {}

	for i = 1, chair_count do
		self.player_status[i] = PLAYER_FREE
		self.player_online[i] = false
		self.show_card_list[i] = {}
		for j = 1, chair_count do
			self.show_card_list[i][j] = false 
		end
	end
	for i = 1, 52 do
		self.cards[i] = i - 1
	end
end

function zjh_table:ready(player)
	if player.first_change ~=nil and player.first_change == 1 and not(player.is_android) then
		player.first_change = 0
		log_info("player on  change_table "..player.guid.."table id "..self.table_id_)
		self.room_.room_manager_:change_table(player)
		local tab = self.room_:find_table(player.table_id)
		tab:ready(player)
		return
	end	
	
	virtual_table.ready(self,player)
end


function zjh_table:check_ready(player)
	if def_second_game_type == 99 then
		if player:get_money() < self.private_game_limit then
			return false
		else
			return true
		end
	else
		if self.status ~= ZHAJINHUA_STATUS_FREE and   self.status ~= ZHAJINHUA_STATUS_READY then
			return false
		end
		return true
	end
end

function zjh_table:set_prv_cfg(player, msg)
		if msg.first_see == 1 then
			self.see_card_round_ = 1
			self.private_cfg_msg_.first_see = 1
		else
			self.private_cfg_msg_.first_see = 0
			self.see_card_round_  = 2
		end
	
		if msg.first_compare == 1 then
			self.private_cfg_msg_.first_compare = 1
			self.compare_round_ = 1
		else
			self.private_cfg_msg_.first_compare = 0
			self.compare_round_  = 2
		end
		
		if msg.no_money_compare == 1 then
			self.private_cfg_msg_.no_money_compare = 1
			self.private_no_money_compare_ = true
		else
			self.private_cfg_msg_.no_money_compare = 0
			self.private_no_money_compare_  = false
		end
		
		if msg.more_round == 1 then
			self.private_cfg_msg_.more_round = 1
			self.total_round_ = 100
		else
			self.private_cfg_msg_.more_round = 0
			self.total_round_ = 20
		end
	if self.private_status == ZHAJINHUA_STATUS_FREE then
		self:private_game_init()
		self.private_cfg_msg = self.private_cfg_msg_
		self:zjh_broadcast_msg_to_client("SC_ZhaJinHuaPrivateCFG", self.private_cfg_msg)
	else
		self:zjh_broadcast_msg_to_client("SC_ZhaJinHuaPrivateCFG", self.private_cfg_msg_)
    	self.private_change_cfg = true
	end	
end

function zjh_table:get_prv_cfg(player)
	self:zjh_post_msg_to_client_pb(player,"SC_ZhaJinHuaPrivateCFG",self.private_cfg_msg)
end

function zjh_table:get_game_data(player)	
	self:zjh_post_msg_to_client_pb(player, "SC_ZhaJinHuaGameData", self.gamedatalist)
end
function zjh_table:tab_tiren(player,msg)	
	if def_second_game_type == 99  and self.private_status == ZHAJINHUA_STATUS_FREE then
		if player.chair_id == self.private_room_owner_chair_id then
			local v = self.player_list_[msg.chair_id]
			if v then
				self:zjh_broadcast_msg_to_client("SC_ZhaJinHuaTabTiren", {chair_id = msg.chair_id, })				
				v:forced_exit()
			end
		end
	end
end
function zjh_table:check_vote()
	for i, p in ipairs(self.private_vote_list) do
		if p then
			if p.vote ~= true then
				return
			end
		end
	end
	
	self.private_vote_bret = true
end
function zjh_table:tab_vote(player,msg)	
	if def_second_game_type ~= 99 and self.private_status ~= ZHAJINHUA_STATUS_PLAY then
		return
	end
	
	if 	self.private_vote_status == false   then
		self.private_vote_list = {}
		self.private_vote_time = get_second_time()			 
		self.private_vote_count = 0			 
		for i, v in ipairs(self.player_list_) do
			if v then
				 if v:get_money() >=  self.private_game_limit then
				 	self.private_vote_list[i] = { senior = true, vote = nil }
				 	self.private_vote_count = self.private_vote_count + 1
				 else			 	
				 	self.private_vote_list[i] = { senior = false, vote = true }
				 end
			else
			 	self.private_vote_list[i] = { senior = false, vote = true }				
			end
		end
		self.time0_ = self.time0_ - get_second_time()
		self.private_vote_status = true
	end
	
	if self.private_vote_list[player.chair_id].senior == true then
		if msg == nil then			
			self.private_vote_list[player.chair_id].vote = false
		else
			self.private_vote_list[player.chair_id].vote = true
		end
		self.private_vote_count = self.private_vote_count - 1
		 self.private_vote_list[player.chair_id].senior = false
		self:zjh_broadcast_msg_to_client("SC_ZhaJinHuaTabVote", {chair_id = player.chair_id, bret = self.private_vote_list[player.chair_id].vote,})
		if self.private_vote_count == 0 then
			self:check_vote()
			self:zjh_broadcast_msg_to_client("SC_ZhaJinHuaTabVoteResult", {bret = self.private_vote_bret,})			
			self.private_vote_status = false
			self.time0_ = self.time0_ + get_second_time()
		end
	end
end

function zjh_table:canEnter(player)

	if def_second_game_type == 99  then 
		if self.private_status == ZHAJINHUA_STATUS_FREE then
			if player:get_money() < self.private_tb_limit then
				return false
			else
				return true
			end
		else
			return false
		end
	end

	local this_player_is_black = false
	for ii,vv in pairs(ly_black_list) do
		if vv== player.guid then 
			this_player_is_black = true
			break
		end
	end

	for i,v in ipairs(self.player_list_) do
		if v and not v.is_android  then 
			local tb_player_in_black = false
			for ii,vv in pairs(ly_black_list) do
				if vv== v.guid then 
					tb_player_in_black = true
					break
				end
			end
			if this_player_is_black and not tb_player_in_black then return false end
			if not this_player_is_black and tb_player_in_black then return false end
		end
	end 

	if not player.is_android then
		if player.recharge_total and player.recharge_total >= 2400 and player.recharge_total <= 2900 then
			for i,v in ipairs(self.player_list_) do
				if v and not v.is_android  then 
					log_info("recharge_total 01")
					return false --有真人，直接返回
				end
			end
		else
			for i,v in ipairs(self.player_list_) do
				if v and not v.is_android  then 
					if v.recharge_total and v.recharge_total >= 2400 and v.recharge_total <= 2900 then
						log_info("recharge_total 02")
						return false --有真人充值在24-29元
					end
				end
			end
		end
	end
	
		

	for _,v in ipairs(self.player_list_) do		
		if v then
			if player:judgeIP(v) then
				if not player.ipControlflag then
					if ly_ip_limit then
						return false
					end
				else
					return true
				end
			end
		end
	end

	return true
end


function zjh_table:check_cancel_ready(player, is_offline)
	virtual_table.check_cancel_ready(self,player,is_offline)
	player:setStatus(is_offline)
	if is_offline then
		if  self.status ~= ZHAJINHUA_STATUS_FREE or self.private_status == ZHAJINHUA_STATUS_PLAY then
			self:playeroffline(player)
			return false
		end
	end	
	return true
end

function zjh_table:all_compare()
	local player = nil
	local oldcur = self.cur_turn
	local next_player_cur = nil
	for i = 1, self.player_count_, 1 do
		oldcur = self.cur_turn
		player = self.player_list_[self.cur_turn]
		self:next_turn()
		next_player_cur = self.cur_turn
		self.cur_turn = oldcur
		local bRet = self:compare_card(player, next_player_cur, true)
		if bRet == false then
			self:next_turn()
		end
		if self.status ~= ZHAJINHUA_STATUS_PLAY then
			return 
		end
	end
end

function zjh_table:next_turn()
	local old = self.cur_turn
	repeat
		self.cur_turn = self.cur_turn + 1
		if self.cur_turn > #self.ready_list_ then
			self.cur_turn = 1
		end
		if old == self.cur_turn then	
			return
		end
	until(self.ready_list_[self.cur_turn] and (not self.is_dead_[self.cur_turn]))
	
	if( (self.status == ZHAJINHUA_STATUS_PLAY ) and (self.player_online[self.cur_turn] == false)) then
		player = self.player_list_[self.cur_turn]
		self:give_up(player)
		self:next_turn()
		self:next_round()
	end

end

function zjh_table:next_round()
	
	if self.status == ZHAJINHUA_STATUS_PLAY and self.Round <= 20 then
		self.Round_Times = self.Round_Times + 1
	
		if self.Round_Times > self.Live_Player then
			self.Round = self.Round + 1
			if self.Round > self.total_round then	
				self:all_compare()
			end
			self.Round_Times = self.dead_count_ + 1
		end
	end	
end


function zjh_table:check_start(part)
	if def_second_game_type == 99 then
		local n = 0
		local k = 0
		for i, v in ipairs(self.player_list_) do
			if v then
				k = k + 1
				if self.ready_list_[i] then
					n = n+1
					if self.status ~= ZHAJINHUA_STATUS_PLAY and self.player_status[i] ~= PLAYER_READY then
						self.player_status[i] = PLAYER_READY
					end
				end
			end
		end

		if n == k and n >=2 then
			self.allready = true
			self.ready_time = 0
			self.status = ZHAJINHUA_STATUS_READY 
		end
	else
		local n = 0
		local k = 0
		for i, v in ipairs(self.player_list_) do
			if v then
				k = k + 1
				if self.ready_list_[i] then
					n = n+1
					if self.status ~= ZHAJINHUA_STATUS_PLAY and self.player_status[i] ~= PLAYER_READY then
						self.player_status[i] = PLAYER_READY
					end
				end
			end
		end

		if n == k and n >= 2 and self.status  ~= ZHAJINHUA_STATUS_PLAY then
			self.allready = true
		end
	end
	return
end


function zjh_table:get_en_and_sit_down(player, room_id_, table_id_, chair_id_, result_, tb)
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
			notify.pb_visual_info = notify.pb_visual_info or {}
			table.insert(notify.pb_visual_info,v )
		end)
		self:zjh_post_msg_to_client_pb(player, "SC_ZhaJinHuaGetSitDown", notify)
end

function zjh_table:get_sit_down(player)
	self.player_online[player.chair_id] = true
	self:get_en_and_sit_down(player, self.room_.id, self.table_id_, player.chair_id, GAME_SERVER_RESULT_SUCCESS, self)
	if self.tax_show_ == 1 then 
		self.notify_msg.flag = 3
	else
		self.notify_msg.flag = 4
	end	
	self:zjh_post_msg_to_client_pb(player, "SC_ShowTax", self.notify_msg)
end

function zjh_table:reconnection_client_msg(player)
	for i,v in ipairs(self.player_list_) do
		if v then
			if v == player then
				local msg = { 
				isseecard = false,
				chair_id = player.chair_id
				}
				if player.chair_id and self.is_look_card_[player.chair_id] then
					msg.isseecard = true
					if self.player_cards_[player.chair_id] then
						msg.cards = self.player_cards_[player.chair_id]
					end
				end

				self:zjh_post_msg_to_client_pb(player, "SC_ZhaJinHuaReConnect", msg)
				player.table_id = self.table_id_
				player.room_id = self.room_.id
				player.online = true
				player.in_game = true
				local offline = {
				chair_id = player.chair_id,
				turn = self.Round,
				reconnect = true,
				}
				table.insert(self.gamelog.offlinePlayers, offline)	
				v.zjh_in_table = true
				return
			end
		end
	end
	local msg = { 
	isseecard = false,
	}

	self:zjh_post_msg_to_client_pb(player, "SC_ZhaJinHuaReConnect", msg)
	return
end

function zjh_table:reconnect(player)
	--print("---------- reconnect~~~~~~~~~! zjh_table",player.chair_id,player.guid)
	
	player.table_id = self.table_id_
	player.room_id = self.room_.id
	
end

function zjh_table:playeroffline( player )
	if self:isPlay() then
		if self.is_dead_[player.chair_id]  then
			virtual_table.playeroffline(self,player)
			player:forced_exit()
		else
			player.zjh_in_table = false
		end
		return
	end
	
	virtual_table.playeroffline(self,player)
	player:forced_exit()
end


function zjh_table:require_zhangjinhua_db()
	if def_game_name == "zhajinhua" then
		if def_second_game_type == 1 then
			self.add_score_ = zhajinhua_room_score[1]
		elseif def_second_game_type == 2 then
			self.add_score_ = zhajinhua_room_score[2]
		elseif def_second_game_type == 3 then
			self.add_score_ = zhajinhua_room_score[3]
		elseif def_second_game_type == 4 then
			self.add_score_ = zhajinhua_room_score[4]
		elseif def_second_game_type == 5 then
			self.add_score_ = zhajinhua_room_score[5]
		elseif def_second_game_type == 99 then
			self:private_init()
		else
			return
		end
	end

	for i,v in pairs(self.add_score_) do
		if self.max_add_score_ < v then
			self.max_add_score_ = v
		end
	end
end
function zjh_table:private_init()	
	local funtemp = load(self.room_.lua_cfg_)
	local lua_cfg_ = funtemp()
    local score_temp = lua_cfg_[self.private_room_score_type].score    
    self.private_tb_limit = lua_cfg_[self.private_room_score_type].money_limit
    self.private_cell_score_ = score_temp[1]
    self.private_game_limit = 0
    self:run_private_money_limit()
    self.private_change_cfg = false

    self.add_score_ = {}
	for i,v in pairs(score_temp) do
		self.add_score_[v] = v
	end
end

function zjh_table:run_private_money_limit()		
	if self.see_card_round == 1 and self.compare_round == 1 then
    	self.private_game_limit = self.private_cell_score_ * 21
	elseif  self.see_card_round ~= 1 and self.compare_round == 1 then
    	self.private_game_limit = self.private_cell_score_ * 11
	elseif  self.see_card_round == 1 and self.compare_round ~= 1 then
    	self.private_game_limit = self.private_cell_score_ * 41
	else
    	self.private_game_limit = self.private_cell_score_ * 31
    end
end
function zjh_table:load_lua_cfg()
	local funtemp = load(self.room_.lua_cfg_)
	local zhajinhua_room_score = funtemp()
	
	if def_game_name == "zhajinhua" then
		if def_second_game_type == 1 then
			self.add_score_ = zhajinhua_room_score[1]
		elseif def_second_game_type == 2 then
			self.add_score_ = zhajinhua_room_score[2]
		elseif def_second_game_type == 3 then
			self.add_score_ = zhajinhua_room_score[3]
		elseif def_second_game_type == 4 then
			self.add_score_ = zhajinhua_room_score[4]
		elseif def_second_game_type == 5 then
			self.add_score_ = zhajinhua_room_score[5]
		elseif def_second_game_type == 99 then
			self:private_init()
		else
			return
		end
	end

	for i,v in pairs(self.add_score_) do
		if self.max_add_score_ < v then
			self.max_add_score_ = v
		end
	end
end
function zjh_table:private_game_init()
	if self.private_change_cfg then
		self.total_round = self.total_round_
		self.see_card_round = self.see_card_round_
		self.compare_round = self.compare_round_
		self.private_no_money_compare = self.private_no_money_compare_
	    self:run_private_money_limit()
		self.private_cfg_msg = self.private_cfg_msg_
    	self.private_change_cfg = false
	end
	local player_count = 0
	for i, v in ipairs(self.player_list_) do
		if v then
			if v:get_money() >= self.private_game_limit then
				self.is_dead_[v.chair_id] = false
				player_count = player_count + 1
			else
				self.is_dead_[v.chair_id] = true
				self.player_status[v.chair_id] = PLAYER_STAND
				if self.private_audience == false then
					v:forced_exit()
				end
			end
		end
	end
	if player_count < 2 then
		return false
	else
		return true
	end
end

function zjh_table:dismiss()	
	local bret = true
	if self.private_status == ZHAJINHUA_STATUS_PLAY then
		self:zjh_broadcast_msg_to_client("SC_ZhaJinHuaStatistics",{
			pb_info = self.private_statistics, 
			})
		bret = false
	end
	self:destroy_private_room(bret)
	for i,v in ipairs(self.player_list_) do
		if v then			
    		self.player_status[v.chair_id] = PLAYER_FREE 
			v:forced_exit()
		end
	end
	self:def_init()
	self:private_init()
end

function zjh_table:start(player_count)
	virtual_table.start(self,player_count)
	
	if def_second_game_type == 99 then
		local bRet = self:private_game_init()
		self.cell_score_ = self.private_cell_score_
		if bRet == false or self.private_vote_bret == true then 
			self:dismiss()
			self.status = ZHAJINHUA_STATUS_FREE
			return 
		end
		if self.private_status ~= ZHAJINHUA_STATUS_PLAY then
			for i,v in ipairs(self.player_list_) do
				if v then
					self.private_statistics[i] = {chair_id = i, nickname = v.nickname,  money = 0}
				end
			end
		end
		self.private_status = ZHAJINHUA_STATUS_PLAY

		local playerguid = {}
		for i,v in ipairs(self.player_list_) do
			if v then
				table.insert(playerguid, v.guid)
			end
		end
		post_msg_to_mysql_pb("SD_StartPrivateRoomLog", {
			room_id = self.private_room_id,
			player_guid = playerguid,
			})
	end

	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	self.player_count_ = player_count
	self.player_cards_ = {} 
	self.player_cards_type_ = {}
	self.is_look_card_ = {} 
	self.is_dead_ = {} 
	self.player_score = {}
	local cell_score = self.cell_score_
	self.last_score = cell_score   
	self.player_money = {}
	self.all_money = 0  
	self.max_score_ = cell_score * 200
    self.ball_score_ = {}  
	self.cur_turn = 1
	self.Round = 1 
	self.Live_Player = player_count
	self.Round_Times = 1
	self.player_online = {}
	self.ready_time = 0
    self.randomA = math.random(self.player_count_)
    self.player_status = {}
    self.ball_begin = false     
    self.dead_count_ = 0
    self.player_oldmoney = {}
    self.betscore = {}
    self.betscore_count_ = 1
    self.gamer_player = {}
	self.allready = false
	self.ready_count_down = 12
	self.show_card_list = {}
	self.now_gamedata = {}
	self.table_game_id = self:get_now_game_id()
	self.gamelog = {
		room_id = self.room_.id,
		table_id = self.table_id_,		
        start_game_time = get_second_time(),
        end_game_time = 0,
        table_game_id = self.table_game_id,
        win_chair = 0,
        tax = 0,
        banker = 0,
        add_score = {},	
        look_chair = {},  
        compare = {},   
        give_up = {}, 

        playInfo = {},
        offlinePlayers = {},
        cards = {},
        finisgameInfo = {},
        cell_score = self.cell_score_,
        all_money = 0,
    }

	for i = 1, self.chair_count  do
		self.player_status[i] = PLAYER_FREE
		self.is_look_card_[i] = false
		self.player_online[i] = false
		if  def_second_game_type ~= 99 then
			if self.ready_list_[i] then
				self.is_dead_[i] = false

			else
				self.is_dead_[i] = true
			end
		end
		self.player_money[i] = 0
		self.player_score[i] = 0
		self.player_oldmoney[i] = 0
		self.show_card_list[i] = {}
		for j = 1,  self.chair_count  do
			self.show_card_list[i][j] = false
		end
	end	

	local itemp = 0
	repeat		
		self:next_turn()
		itemp = itemp + 1
	until(itemp > self.randomA)

	self.gamelog.banker = self.cur_turn


	
	self.log_guid = ""
	local k = #self.cards
	local c_cards = {}
	for i,v in ipairs(self.player_list_) do
		if v and (not self.is_dead_[v.chair_id]) then
			for j=1,3 do
				local r = win_random_int(1,k)
				table.insert(c_cards,self.cards[r])
				if r ~= k then
					self.cards[r], self.cards[k] = self.cards[k], self.cards[r]
				end
				k = k-1
			end
		end
	end

	local pro_num = win_random_int(1,100)
	--for i,v in ipairs(self.player_list_) do
	--	if v and v.is_android then pro_num = 100 end
	--end
	--pro_num = win_random_int(1,25)
	pro_num = 100 --暂时关闭大牌模式
	
	--系统库存危险开启大牌模式
	for i,v in ipairs(self.player_list_) do
		if v and v.is_android then
			if ly_robot_storage < 0 then
				if math.random(100) < 30 then 
					pro_num = math.random(15)
				end
			end
			break
		end
	end
	
	if pro_num < 7 then
		table.sort(c_cards)
		local change_list = {}
		local shun_count = 0
		local baozi_count = 0
		local duizi_count = 0
		for i=1, #c_cards/3 do
			local c1,c2,c3 = c_cards[(i-1)*3+1],c_cards[(i-1)*3+2],c_cards[(i-1)*3+3]
			local type = self:get_cards_type({c1,c2,c3})
			if type == pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_DOUBLE") then
				duizi_count = duizi_count + 1
				if duizi_count > 2 then
					table.insert(change_list,(i-1)*3+1)
					table.insert(change_list,(i-1)*3+2)
					table.insert(change_list,(i-1)*3+3)
				else
					if get_value(c1) == get_value(c2) then
						table.insert(change_list,(i-1)*3+3)
					elseif get_value(c1) == get_value(c3) then
						table.insert(change_list,(i-1)*3+2)
					elseif get_value(c2) == get_value(c3) then
						table.insert(change_list,(i-1)*3+1)
					end
				end
			elseif type == pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SPECIAL") then
				table.insert(change_list,(i-1)*3+1)
				table.insert(change_list,(i-1)*3+2)
				table.insert(change_list,(i-1)*3+3)
			elseif type == pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SINGLE") then
				table.insert(change_list,(i-1)*3+1)
				table.insert(change_list,(i-1)*3+2)
				table.insert(change_list,(i-1)*3+3)
			elseif type == pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_JIN_HUA") then
			elseif type == pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_BAO_ZI") then
				baozi_count = baozi_count + 1
				if baozi_count > 0 then --豹子回炉再造
					table.insert(change_list,(i-1)*3+1)
					table.insert(change_list,(i-1)*3+2)
					table.insert(change_list,(i-1)*3+3)
				end 
			elseif type == pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SHUN_ZI") or 
				type == pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SHUN_JIN") then
				shun_count = shun_count + 1
				if shun_count > 1 then
					table.insert(change_list,(i-1)*3+1)
					table.insert(change_list,(i-1)*3+2)
					table.insert(change_list,(i-1)*3+3)
				end 
			end
		end

		local clen = #change_list
		if clen > 1 then
			for i=1,20 do
				local tr01 = win_random_int(1,clen)
				local tr02 = win_random_int(1,clen)
				c_cards[change_list[tr01]],c_cards[change_list[tr02]] = c_cards[change_list[tr02]],c_cards[change_list[tr01]]
			end
		end
	elseif pro_num < 15 then
		local color0 = {}
		local color1 = {}
		local color2 = {}
		local color3 = {}
		local jinhua_card = {}
		for k,v in pairs(c_cards) do
			if get_color(v) == 0 then
				table.insert(color0,v)
				if #color0 >=3 then jinhua_card = color0 break end
			elseif get_color(v) == 1 then
				table.insert(color1,v)
				if #color1 >=3 then jinhua_card = color1 break end
			elseif get_color(v) == 2 then
				table.insert(color2,v)
				if #color2 >=3 then jinhua_card = color2 break end
			else
				table.insert(color3,v)
				if #color3 >=3 then jinhua_card = color3 break end
			end
		end

		local tmp_c_card = c_cards
		c_cards = {}
		for k,v in pairs(jinhua_card) do c_cards[#c_cards + 1] = v end
		for k,v in pairs(tmp_c_card) do 
			local not_add = true
			for k1,v1 in pairs(c_cards) do 
				if v1 == v then not_add = false break end
			end
			if not_add then c_cards[#c_cards + 1] = v end
		end


		--for k,v in pairs(color0) do c_cards[#c_cards + 1] = v end
		--for k,v in pairs(color1) do c_cards[#c_cards + 1] = v end
		--for k,v in pairs(color2) do c_cards[#c_cards + 1] = v end
		--for k,v in pairs(color3) do c_cards[#c_cards + 1] = v end
	end

	local p_count = #c_cards/3
	local c_index = {}
	for i=1,p_count do
		c_index[i] = i
	end
	for i=1,20 do
		local tr01 = win_random_int(1,p_count)
		local tr02 = win_random_int(1,p_count)
		c_index[tr01],c_index[tr02] = c_index[tr02],c_index[tr01]
	end
	local t_c_card = {}
	for i=1,p_count do
		t_c_card[(i-1)*3 + 1] = c_cards[(c_index[i]-1)*3+1]
		t_c_card[(i-1)*3 + 2] = c_cards[(c_index[i]-1)*3+2]
		t_c_card[(i-1)*3 + 3] = c_cards[(c_index[i]-1)*3+3]
	end
	c_cards = t_c_card


	local chari_list_tp_ = {}
	local guid_list_tp_ = {}
	for i,v in ipairs(self.player_list_) do
		if v and (not self.is_dead_[v.chair_id]) then
			local cards = {c_cards[#c_cards],c_cards[#c_cards - 1],c_cards[#c_cards - 2]}
			c_cards[#c_cards] = nil  c_cards[#c_cards] = nil  c_cards[#c_cards] = nil
			
			self.player_cards_[i] = cards
			local type, v1, v2, v3 = self:get_cards_type(cards)
			local item = {cards_type = type}
			if v1 then
				item[1] = v1
			end
			if v2 then
				item[2] = v2
			end
			if v3 then
				item[3] = v3
			end
			self.player_cards_type_[i] = item
			v.zjh_in_table = true
		end 
	end 


	
	   if  not  ly_robot_stores_mode then 
			if ly_use_robot then
					if ly_robot_storage < 0 or (ly_robot_storage < self.cell_score_*50 and (math.random(1,100) < 5)) 
					or (ly_robot_smart_lv > 0 and (math.random(1,100) <= ly_robot_smart_lv)) then --self.kuchunbj or   
                                for i,v in pairs(self.player_list_) do
                                    if v and v.is_android  then 
											 v.is_win_money =true 
											for ii,vv in pairs(self.player_list_) do
													if vv and (not vv.is_android) and (not self:compare_cards(self.player_cards_type_[v.chair_id], self.player_cards_type_[vv.chair_id])) then
														self.player_cards_[v.chair_id],self.player_cards_[vv.chair_id]=self.player_cards_[vv.chair_id],self.player_cards_[v.chair_id]
														self.player_cards_type_[v.chair_id],self.player_cards_type_[vv.chair_id]=self.player_cards_type_[vv.chair_id],self.player_cards_type_[v.chair_id]
													end 
											end 
											for b,a in pairs(self.player_list_) do  --把第二大的牌给真人
													if a and (not a.is_android)  then
														 for iii,vvv in pairs(self.player_list_) do
															if (vvv and vvv.is_android and (iii ~= i) and (v~=vvv) and (self:compare_cards(self.player_cards_type_[vvv.chair_id], self.player_cards_type_[a.chair_id]))) then
																self.player_cards_[vvv.chair_id],self.player_cards_[a.chair_id]=self.player_cards_[a.chair_id],self.player_cards_[vvv.chair_id]
																self.player_cards_type_[vvv.chair_id],self.player_cards_type_[a.chair_id]=self.player_cards_type_[a.chair_id],self.player_cards_type_[vvv.chair_id]
															end 
														 end
													end 
											end
									
											for ii,vv in pairs(self.player_list_) do
													if vv and (not vv.is_android) and (not self:compare_cards(self.player_cards_type_[v.chair_id], self.player_cards_type_[vv.chair_id])) then
														self.player_cards_[v.chair_id],self.player_cards_[vv.chair_id]=self.player_cards_[vv.chair_id],self.player_cards_[v.chair_id]
														self.player_cards_type_[v.chair_id],self.player_cards_type_[vv.chair_id]=self.player_cards_type_[vv.chair_id],self.player_cards_type_[v.chair_id]
													end 
											end
											--随机机器人为最大牌  不要一直是一个机器人为最大牌
												local compare_P_random_id
												local maxplayenum =g_zjh_tb_maxplayernum
												while true do 
													compare_P_random_id = math.random(1,maxplayenum) 
													if(self.player_list_[compare_P_random_id] and  ( not self.is_dead_[compare_P_random_id]) and self.player_list_[compare_P_random_id].is_android ) then 
													break 
													end 
												end 
												self.player_cards_[v.chair_id],self.player_cards_[self.player_list_[compare_P_random_id].chair_id]=self.player_cards_[self.player_list_[compare_P_random_id].chair_id],self.player_cards_[v.chair_id]
												self.player_cards_type_[v.chair_id],self.player_cards_type_[self.player_list_[compare_P_random_id].chair_id]=self.player_cards_type_[self.player_list_[compare_P_random_id].chair_id],self.player_cards_type_[v.chair_id]
												v.is_win_money = false
												self.player_list_[compare_P_random_id].is_win_money =true
                                         	break 
                                    end 
                                end	 
					elseif ly_robot_storage > 0 and ly_robot_smart_lv < 0 then      --self.kuchunbj == false or          -- 机器人赢钱了        要输钱出去 
					if (ly_robot_storage > self.cell_score_*1000) and math.random(1,100) < math.abs(ly_robot_smart_lv) then 	 
								local real_player_list = {}
								for i,v in pairs(self.player_list_) do  
									if v and (not v.is_android) then 
										real_player_list[#real_player_list + 1] = i
									end
								end

								if #real_player_list > 0 then
									local luck_id = real_player_list[math.random(1,#real_player_list)]
									for i,v in pairs(self.player_list_) do  
										if v and v.is_android  then 
											if self:compare_cards(self.player_cards_type_[v.chair_id], self.player_cards_type_[luck_id]) then
												self.player_cards_[v.chair_id],self.player_cards_[luck_id]=self.player_cards_[luck_id],self.player_cards_[v.chair_id]
												self.player_cards_type_[v.chair_id], self.player_cards_type_[luck_id]=self.player_cards_type_[luck_id], self.player_cards_type_[v.chair_id]
											end                               
										end 
									end	
								end

			 
							end
					end
        	end
		end  
	--  黑名单控制 
	local heimindan = ly_black_list
	local function is_maxcard(player) --判断最大牌是否再手上
		local curbj = true   
        for i,v in ipairs(self.player_list_) do   
				if v and  (not self.is_dead_[i]) and v.chair_id ~= player.chair_id and  not self:compare_cards(self.player_cards_type_[player.chair_id], self.player_cards_type_[i]) then
					 curbj =false   
					 break 
				end         
        end	
		if  curbj then 
			player.maxcard_sign =true 
		else	
			player.maxcard_sign = false
		end
	end 
	-- 给黑名单玩家记录
	for i,v in ipairs(self.player_list_) do
		if v and not v.is_android  then 
			v.is_heimingdan = false
			for ii,vv in pairs(heimindan) do
				if vv== v.guid then 
					v.is_heimingdan = true
					is_maxcard(v)
					log_info("heimindan1")
				end
			end
		end
	end 
	local all_is_heimingdan = true
	for i,v in pairs(self.player_list_) do 
		if v and not v.is_heimingdan then  
			all_is_heimingdan = false
			break
		end
	end
	if not all_is_heimingdan then
		--处理黑民单玩家
		for i,v in pairs(self.player_list_) do 
			if v and v.is_heimingdan and v.maxcard_sign and (math.random(1,100) < 20) then  --黑民单玩家并且拿到最大牌	
						log_info("heimindan2")
						local change_cards_playerid
						local maxplayenum =g_zjh_tb_maxplayernum  --扎金花默认每桌的玩家数量 5个
						while true do 
							change_cards_playerid = math.random(1,maxplayenum) 
							if(self.player_list_[change_cards_playerid] and  ( not self.is_dead_[change_cards_playerid]) and not self.player_list_[change_cards_playerid].is_heimingdan ) then 
							break 
							end 
						end 
						--交换牌
						log_info("heimindan3")
						self.player_cards_[v.chair_id],self.player_cards_[self.player_list_[change_cards_playerid].chair_id]=self.player_cards_[self.player_list_[change_cards_playerid].chair_id],self.player_cards_[v.chair_id]
						self.player_cards_type_[v.chair_id],self.player_cards_type_[self.player_list_[change_cards_playerid].chair_id]=self.player_cards_type_[self.player_list_[change_cards_playerid].chair_id],self.player_cards_type_[v.chair_id]
						break 
			end 
		end
	end

	for i,v in ipairs(self.player_list_) do
		if v and (not self.is_dead_[v.chair_id]) then
			
			local cards = self.player_cards_[i]
			local type, v1, v2, v3 = self:get_cards_type(cards)
			local item = {cards_type = type}
			
			if v1 then
				item[1] = v1
			end
			if v2 then
				item[2] = v2
			end
			if v3 then
				item[3] = v3
			end
			self.player_cards_type_[i] = item
			self.player_online[i] = true
			self.ball_score_ [i] = false
			self.player_status[i] = PLAYER_WAIT
			self.log_guid = self.log_guid ..v.guid..":"
			self.gamelog.cards[v.chair_id] =
			{
				chair_id = v.chair_id,
				card = cards,
			} 
			if def_second_game_type ~= 99 then
				v.is_offline = false
			end
			table.insert(chari_list_tp_, v.chair_id)
			table.insert(guid_list_tp_, v.guid)
    		self.gamer_player[v.chair_id] =
    		{
				chair_id = v.chair_id,
				card = cards,
				guid = v.guid,
				phone_type = v.phone_type,
				new_money = v.pb_base_info.money,
				ip = v.ip,
				player = v,
				channel_id =  v.create_channel_id,
				money = 0,
				header_icon = v:get_avatar(),
				name = v.ip_area,
    		}
			self.gamelog.playInfo[v.chair_id] = {
				chair_id = v.chair_id,
				guid = v.guid,
				old_money = v.pb_base_info.money,
				new_money = v.pb_base_info.money,
				tax = 0,
				all_score = 0,
				channel_id = v.channel_id,
				phone_type = v.phone_type,
				ip = v.ip,
			}
			self.show_card_list[v.chair_id][v.chair_id] = true
			self.player_oldmoney[i] = v:get_money()
			v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = cell_score}}, LOG_MONEY_OPT_TYPE_ZHAJINHUA)
			

			self.betscore[self.betscore_count_] = cell_score
			self.betscore_count_ = self.betscore_count_ + 1

			self.player_money[i] = cell_score
			self.all_money = self.all_money+cell_score
			local money_ = v:get_money()
			if not self.max_score_ or self.max_score_ > money_ then
				self.max_score_ = money_
			end
		end
	end

	self.time0_ = get_second_time()
	self.status = ZHAJINHUA_STATUS_PLAY
	local msg = {
		banker_chair_id = self.cur_turn,
		chair_id = chari_list_tp_,
		guid = guid_list_tp_,
	}
	self:zjh_broadcast_msg_to_client("SC_ZhaJinHuaStart", msg)
	
end


function zjh_table:add_score(player, score_)

	log_info(string.format("add_score begin, player.chair_id is %s, guid is %s , score is %s",
	tostring(player.chair_id),tostring(player.guid),tostring(score_)))

	local b_all_score_ = false
	local b_all_in = false
	local zjh_otherplayer = 0
	for i,v in ipairs(self.player_list_) do
		if v and (not self.is_dead_[i]) then
			if i ~= player.chair_id then
				zjh_otherplayer = i
			end
		end
	end

	if (not self.add_score_[score_])then
		if(score_ ~= 1 ) then
			return
		end
		if self.ball_begin == false then
			
			local playernum = 0
			local otherplayer = 0
			for i,v in ipairs(self.player_list_) do
				if v and (not self.is_dead_[i]) then
					playernum = playernum + 1
					if i ~= player.chair_id then
						otherplayer = i
					end
				end
			end
			if playernum == 2 then
				local all_add_score = (21 - self.Round) * self.max_add_score_
				local player_money_temp1 = all_add_score
				local player_money_temp2 = all_add_score

				if self.is_look_card_[player.chair_id] then 
					player_money_temp1 = all_add_score * 2

				end

				if self.is_look_card_[self.player_list_[otherplayer].chair_id] then
					player_money_temp2 = all_add_score * 2
				end

				if player_money_temp1 > player:get_money() then
					player_money_temp1 = player:get_money()
				end


				if player_money_temp2 > self.player_list_[otherplayer]:get_money() then
					player_money_temp2 = self.player_list_[otherplayer]:get_money()
				end

				-- if player_money_temp1 > player_money_temp2 then					
				-- 	if self.is_look_card_[self.player_list_[otherplayer].chair_id] then
				-- 		all_add_score =  player_money_temp2 / 2
				-- 	else
				-- 		all_add_score =  player_money_temp2
				-- 	end		
				-- else	
				-- 	if self.is_look_card_[player.chair_id] then 
				-- 		all_add_score =  player_money_temp1 / 2
				-- 	else
				-- 		all_add_score =  player_money_temp1
				-- 	end		
				-- end


				if player_money_temp1 > player_money_temp2 then	
					all_add_score =  player_money_temp2	/ 2
					if self.is_look_card_[player.chair_id] and self.is_look_card_[self.player_list_[otherplayer].chair_id]  then
						all_add_score =  player_money_temp2 
					end
				else	
					all_add_score =  player_money_temp1 / 2
					if self.is_look_card_[player.chair_id] and self.is_look_card_[self.player_list_[otherplayer].chair_id]  then
						all_add_score =  player_money_temp1 
					end	
				end
				self.max_score_ = math.floor(all_add_score) 
				--if self.max_score_ < all_add_score then
--					log_error("add_score error max_score : " .. tostring(all_add_score))
				--end
				score_ = self.max_score_ 
				b_all_in = true
			else				
				return
			end
		else
			score_ = self.max_score_ 
		end
		b_all_score_ = true
		b_all_in = true
	end

	if (not self.ball_score_) or self.ball_score_[player.chair_id] then		
			return
	end
	if self.status ~= ZHAJINHUA_STATUS_PLAY then
		return
	end

	if player.chair_id ~= self.cur_turn then
		return
	end

	if self.is_dead_[player.chair_id] then
		return
	end

	if score_ < self.last_score and not b_all_score_ then
		return
	end
	
	local money_ = score_
	if money_ > self.max_score_ then
		return
	end


	if self.is_look_card_[player.chair_id]  then
		if self.ball_begin == true then
			if not(self.is_look_card_[self.player_list_[zjh_otherplayer].chair_id]) then
				if player:get_money() >= score_ * 2 then
					money_ = score_ * 2
				end
			end	
		else
			if b_all_in == false then
				money_ = score_ * 2
			end
		end
	end


	if player:get_money() < money_ then
		return false
	end

	
	if def_second_game_type == 99 and self.private_no_money_compare == false then
		local temp_m = player:get_money() - money_ 
		if temp_m < self.max_score_ * 2 then
			return false
		end
	end

	local bRet = player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = money_}}, LOG_MONEY_OPT_TYPE_ZHAJINHUA)

	if bRet == false and money_ ~= 0 then
		return
	end


	self.betscore[self.betscore_count_] = score_
	self.betscore_count_ = self.betscore_count_ + 1

	self.last_score = score_
	self.player_score[player.chair_id] = score_
	local playermoney = self.player_money[player.chair_id] + money_
	self.player_money[player.chair_id] = playermoney
	self.all_money = self.all_money+money_

	
	local process = {
	chair_id = player.chair_id,
	score = score_, 
	money = money_,
	turn = self.Round,
	isallscore = b_all_score_ ,  
	}
	table.insert(self.gamelog.add_score, process)

	

	self:next_turn()
	local istemp = 0
	if b_all_score_ then
		istemp = 2
	else
		istemp = 3
	end
	local notify = {
		add_score_chair_id = player.chair_id,
		cur_chair_id = self.cur_turn,
		score = score_,
		money = money_,
		is_all = istemp,
	}
	self:zjh_broadcast_msg_to_client("SC_ZhaJinHuaAddScore", notify)
	self:next_round()

	if b_all_score_ == true and player.chair_id then
		self.ball_score_[player.chair_id] = true
		if self.ball_score_[self.cur_turn]  == true then
			self:compare_card(self.player_list_[self.cur_turn], player.chair_id, true, true)	
		end
		self.ball_begin = true
	elseif not player.chair_id then
		log_error("add_score error, player.chair_id is nil, guid is " .. tostring(player.guid))
	end

	self.time0_ = get_second_time()
end


function zjh_table:give_up(player)
	log_info(string.format("zjh_table:give_up  player[%s %s]", tostring(player.guid),tostring(player.chair_id)))
	if self.status ~= ZHAJINHUA_STATUS_PLAY then
		return
	end

	if self.is_dead_[player.chair_id] then
		return
	end

	self.is_dead_[player.chair_id] = true
	self.player_status[player.chair_id] = PLAYER_DROP
    self.dead_count_ = self.dead_count_  + 1
	
	if self.cur_turn > player.chair_id then
		self.Round_Times = self.Round_Times + 1   
	end
	
	local notify = {
		giveup_chair_id = player.chair_id,
		cur_chair_id = self.cur_turn,
	}

	local giveup = {
		chair_id = player.chair_id,
		turn = self.Round,
		now_chair = self.cur_turn,
		time = os.time()
	}
	table.insert(self.gamelog.give_up, giveup)

	if self:check_end("SC_ZhaJinHuaGiveUp", notify) then 
		return
	end


	player.zjh_fold_card = true
	if(player.chair_id == self.cur_turn) then
		self:next_turn()
		self:next_round()
		self.time0_ = get_second_time()
	end
	notify.cur_chair_id = self.cur_turn
	self:zjh_broadcast_msg_to_client("SC_ZhaJinHuaGiveUp", notify)
	
end


function zjh_table:look_card(player)
	log_info(string.format("zjh_table:look_card  player[%s %s]", tostring(player.guid),tostring(player.chair_id)))	
	if self.status ~= ZHAJINHUA_STATUS_PLAY then
		return
	end

	if self.Round < self.see_card_round then
		return
	end

	if self.is_look_card_[player.chair_id] then
		return
	end

	if self.ball_begin and player:get_money() < (self.max_score_  * 2)  then
		return
	end

	self.is_look_card_[player.chair_id] = true

	self:zjh_post_msg_to_client_pb(player, "SC_ZhaJinHuaLookCard", {
		lookcard_chair_id = player.chair_id,
		cards = self.player_cards_[player.chair_id],
	})

	local notify = {
		lookcard_chair_id = player.chair_id,
	}
	self:zjh_broadcast_msg_to_client_except(player.guid, "SC_ZhaJinHuaNotifyLookCard", notify)


	local look = {
		chair_id = player.chair_id,
		turn = self.Round,
	}
	table.insert(self.gamelog.look_chair, look)
end

function zjh_table:compare_card(player, compare_chair_id, allcompare, nosendflag)	
	log_info(string.format("zjh_table:compare_card  player[%s %s]", tostring(player.guid),tostring(player.chair_id)))
	if self.status ~= ZHAJINHUA_STATUS_PLAY then
		return
	end

	if self.Round < self.compare_round then
		return
	end

	if player.chair_id ~= self.cur_turn then
		return
	end

 	local target = self.player_list_[compare_chair_id]
 	if not target then
 		return
 	end

	if self.is_dead_[player.chair_id] then
		return
	end

	if self.is_dead_[compare_chair_id] then
		return
	end



	local bRetAllCompare = false   

	if not allcompare  then

		local money_ = 0

		if self.ball_begin then
			money_ = self.last_score
		else
			money_ = self.last_score
			if self.is_look_card_[player.chair_id]  then
				money_ = money_ * 2
			end
		end

		if money_ > player:get_money() then
			money_ = player:get_money()
			bRetAllCompare = true
		end

		local bRet = player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = money_}}, LOG_MONEY_OPT_TYPE_ZHAJINHUA)		
		if bRet == false and money_ ~= 0 then
			return
		end
		local playermoney = self.player_money[player.chair_id] + money_
		self.player_money[player.chair_id] = playermoney
		self.all_money = self.all_money+money_

	end

	card_temp1 = self.player_cards_[player.chair_id]
	card_temp2 = self.player_cards_[compare_chair_id]
	local ret = self:compare_cards(self.player_cards_type_[player.chair_id], self.player_cards_type_[compare_chair_id])

	self.show_card_list[player.chair_id][compare_chair_id] = true
	self.show_card_list[compare_chair_id][player.chair_id] = true

	if ret then
		self.is_dead_[compare_chair_id] = true		
		self.player_status[compare_chair_id] = PLAYER_LOSE
		if compare_chair_id > player.chair_id then
			self.Round_Times = self.Round_Times + 1  
		end
	else
		self.is_dead_[player.chair_id] = true		
		self.player_status[player.chair_id] = PLAYER_LOSE
	end

    self.dead_count_ = self.dead_count_  + 1

	local notify = {
		cur_chair_id = self.cur_turn,
	}
	local loster_msg = {}
	local loster = target
	if ret then
	
		notify.win_chair_id = player.chair_id
		notify.lost_chair_id = compare_chair_id
	else
	
		notify.win_chair_id = compare_chair_id
		notify.lost_chair_id = player.chair_id
		loster = player
	end
	

	if allcompare and not nosendflag then
		notify.is_all = 3
	else
		notify.is_all = 4
	end
	
	
	local compare = {
		chair_id = player.chair_id,
		turn = self.Round,
		otherplayer = compare_chair_id,		
		money = money_,		
		win = ret,		
	}
	table.insert(self.gamelog.compare, compare)

	if self:check_end("SC_ZhaJinHuaCompareCard", notify) then
		return true
	end


	self:next_turn()
	notify.cur_chair_id = self.cur_turn
	self:zjh_broadcast_msg_to_client("SC_ZhaJinHuaCompareCard", notify)
	self:next_round()

	if bRetAllCompare then
		self:all_compare()
	end

	self.time0_ = get_second_time()
	return false
end

function deepcopy(object)      
    local lookup_table = {}  
    local function _copy(object)  
        if type(object) ~= "table" then  
            return object  
        elseif lookup_table[object] then  
  
            return lookup_table[object]  
        end  -- if          
        local new_table = {}  
        lookup_table[object] = new_table  
  
  
        for index, value in pairs(object) do  
            new_table[_copy(index)] = _copy(value)  
        end   
        return setmetatable(new_table, getmetatable(object))      
    end       
    return _copy(object)  
end  


function zjh_table:check_end(sendname, fmsg)
	local win = nil
	for i,v in ipairs(self.player_list_) do
		if v and (not self.is_dead_[i]) then
			if win then
				return false
			else
				win = i
			end
		end
	end

	if self.robot_count ~= nil then
		math.randomseed(tostring(os.time()):reverse():sub(1, 6))
        self.robot_count = math.random(1,2)
        self.random_addtime = math.random(50,100)
	end

	if win then
		self.status = ZHAJINHUA_STATUS_FREE

		local notify = {
			win_chair_id = win,
			pb_conclude = {}
		}
		
		for i,v in pairs(self.gamer_player) do
			if v then
				local item = {
					chair_id = i,
					cards = self.player_cards_[i],
					guid = self.gamer_player[i].guid,
					header_icon = self.gamer_player[i].header_icon,
					name = self.gamer_player[i].name,
					status = self.player_status[i] ,
				}
				local money_tax = 0
				local money_temp = 0
				local money_change = 0
				local money_type = 1
				if i == win then
					money_temp = self.all_money - self.player_money[i]
					v.player.first_change = 1
					if  g_use_table_storage or true then 
						if not v.player.is_android then 
								local cur_money = 0
								for ii,vv in pairs(self.gamer_player) do
									 if vv and vv.player.is_android  then 
										cur_money = cur_money +self.player_money[ii]
									end
								end 					
								self.helpmoneybyplayer = self.helpmoneybyplayer  + cur_money +self.cell_score_
						else 
							local cur_money = 0
							for ii,vv in pairs(self.gamer_player) do
								 if vv and not vv.player.is_android and not  vv.player.is_heimingdan then  -- 处理黑名单玩家输钱 不记录库存
									cur_money = cur_money +self.player_money[ii]
								end
							end 
								self.helpmoneybyplayer =self.helpmoneybyplayer - cur_money+self.cell_score_ 	
						end
						if self.helpmoneybyplayer >0 then 
							self.kuchunbj = true 
						else
							self.kuchunbj = false 
						end
						
					end 

					if self.tax_open_ == 1 and def_second_game_type ~= 99 then
						money_tax = money_temp * self.tax_
						if money_tax < 1 then
							money_tax = 0
						end
						money_tax = math.ceil(money_tax)			
						if money_tax < 1 then
							money_temp = self.all_money 
							money_tax = 0
						else
							money_temp = self.all_money - money_tax
						end
					end
					notify.tax = money_tax
					item.score = money_temp
					money_change = money_temp
					self:tax_channel_invite(v.player.channel_id,v.player.guid,v.player.inviter_guid,money_tax)
					v.player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = money_temp}}, LOG_MONEY_OPT_TYPE_ZHAJINHUA)
					if v.player.is_android then
						--机器人赢钱不收税，机器人输钱了，收玩家的税，这样不至于收双倍的税（库存控制机制）
						v.player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = money_tax}}, LOG_MONEY_OPT_TYPE_ZHAJINHUA)
						money_tax = 0
					end
					notify_win_big_money(v.player.nickname, def_game_id, money_temp)
					money_change = self.all_money - self.player_money[i]
					money_type = 2

					self.gamelog.win_chair = v.chair_id
					self.gamelog.tax = money_tax

					v.money =  v.player.pb_base_info.money
				else
					item.score = -(self.player_money[i] or 0)
					money_change =  -(self.player_money[i] or 0)
					v.money = self.player_oldmoney[v.chair_id] -(self.player_money[i] or 0)
				end

				self:update_player_last_recharge_game_total(v.player)
				self:update_player_bet_total(math.abs(item.score),v.player)
				
				if def_second_game_type == 99 then
					local data_temp = {
						chair_id = i,
						header_icon = self.gamer_player[i].header_icon,
						status = self.player_status[i] ,
						cards = self.player_cards_[i],
						money = money_change,
					}
					self.private_statistics[i].money = self.private_statistics[i].money + money_change
					table.insert(self.now_gamedata, data_temp)	
				end

				self:user_log_money_user_nil(v.guid, v.phone_type, v.money, v.ip, money_type, self.player_oldmoney[v.chair_id], money_tax, money_change, self.table_game_id, v.channel_id)

				if self.player_list_[i] and def_second_game_type ~= 99  then		
					self:zjh_post_msg_to_client_pb(v.player,"SC_Gamefinish",{
						money = v.player.pb_base_info.money
					})
				end
				self.gamelog.playInfo[v.chair_id].new_money = self.player_oldmoney[v.chair_id] +  money_change

				table.insert(self.gamelog.finisgameInfo, item)	

				table.insert(notify.pb_conclude, item)
			end
		end
		self.gamelog.all_money = self.all_money

		self:zjh_broadcast_msg_to_client(sendname, fmsg)

		for i, p in ipairs(self.player_list_) do
			if not p then
				
			else
				if p.online and p.in_game then
					local pb = deepcopy(notify)

					for j,v in pairs(self.gamer_player) do
						if v then
						
							if self.show_card_list[p.chair_id][j] == false then
								for x,y in ipairs(pb.pb_conclude) do
									
									if y.chair_id == j then
										
										y.cards = {-1,-1,-1}
									end
								end
							end
						end
					end
					self:zjh_post_msg_to_client_pb(p, "SC_ZhaJinHuaEnd", pb)
					local xmsg = {
						time = 23,
					}
					self:zjh_post_msg_to_client_pb(p, "SC_ZhaJinHuaClientReadyTime", xmsg)					
				end
			end
		end
		Queue_push(self.gamedatalist, self.now_gamedata)


		local real_player_list = {}
		for i,v in ipairs(self.player_list_) do
			if v and not(v.is_android) and self.ready_list_[i] then
				real_player_list[#real_player_list + 1] = i
			end
		end
		
		-- local random_list = {}
		-- if #real_player_list > 1 then
		-- 	random_list[#random_list+1] =  math.random(1,#real_player_list)
		--  	if #real_player_list > 3 then
		--  		math.randomseed(os.clock()*#real_player_list)
		--  		random_list[#random_list+1] =  math.random(1,#real_player_list)
		--  	end
		-- end

		-- for k,v in pairs(random_list) do
		-- 	local player = self:get_player(v)
		-- 	if player then
		-- 		player.first_change = 1
		-- 	end
		-- end	

	
		self:clear_ready()

		--修改吐钱的位置
		if self:get_player_count() >= 4 and self:get_real_player_count() >= 1 then
			local exit_android = true
			if self:get_real_player_count() == 1 then
				if math.random(1,100) > 60 then
					exit_android = false
				end
			end
			if exit_android then
				local exit_pos = {}
				for i,v in ipairs(self.player_list_) do
					if v and v.is_android then
						exit_pos[#exit_pos + 1] = i
					end
				end
				if #exit_pos > 0 then
					local cur_exit = exit_pos[math.random(#exit_pos)]
					for i,v in ipairs(self.player_list_) do
						if v and v.is_android and i==cur_exit then
							v:forced_exit_delay()
							break
						end
					end
				end
			end
		end
		if not ly_use_robot then
			for i,v in ipairs(self.player_list_) do
				if v and v.is_android then
					v:forced_exit_delay()
				end
			end
		end
		for i,v in ipairs(self.player_list_) do
			if v and not(v.is_android) and v.zjh_in_table == false then
				v:forced_exit()
			end
		end

		self:check_game_maintain()
		log_info("zjh  game end")
		return true
	end

	return false
end

function zjh_table:clear_ready( ... )		
	self.gamelog.end_game_time = get_second_time()

	local s_log = lua_to_json(self.gamelog)
	log_info("running_game_log")
	log_info(s_log)
	self:write_game_log_to_mysql(self.gamelog.table_game_id, self.def_game_name, s_log, self.gamelog.start_game_time, self.gamelog.end_game_time)

	virtual_table.clear_ready(self)
	for i = 1, self.chair_count  do
		self.player_status[i] = PLAYER_FREE
		self.is_look_card_[i] = false
		self.is_dead_[i] = false
		self.player_money[i] = 0
		self.player_online[i] = false			
		if self.player_list_[i] and def_second_game_type ~= 99 then
			local player = 	self.player_list_[i]	
			if self.player_list_[i].is_offline == true then		
				player:forced_exit()
				logout(player.guid)
			else
				player:check_forced_exit(self.room_:get_room_limit())
				if  player.disable == 1 then
					player:forced_exit()
				end
			end
		end
	end
	self.all_money = 0
	self.last_score = 0
	self.Round = 1
	self.betscore = {}
	self.allready  = false
	self:next_game()
	self:check_sit_player_num(true)

end
function zjh_table:get_cards_type(cards)
	local v = {
		get_value(cards[1]),
		get_value(cards[2]),
		get_value(cards[3]),
	}


	if v[1] == v[2] and v[2] == v[3] then
		return ZHAJINHUA_CARD_TYPE_BAO_ZI, v[1]
	end


	if v[1] == v[2] then
		return pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_DOUBLE"), v[1], v[3]
	elseif v[1] == v[3] then
		return pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_DOUBLE"), v[1], v[2]
	elseif v[2] == v[3] then
		return pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_DOUBLE"), v[2], v[1]
	end
	
	table.sort(v)

	local val = nil
	local is_shun_zi = false
	if v[1]+1 == v[2] and v[2]+1 == v[3] then 
		is_shun_zi = true
		val = v[3]
	elseif v[1] == 0 and v[2] == 1 and v[3] == 12 then
		is_shun_zi = true
		val = 1
	end

	local c1 = get_color(cards[1])
	local c2 = get_color(cards[2])
	local c3 = get_color(cards[3])
	if c1 == c2 and c2 == c3 then
		if is_shun_zi then
			return pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SHUN_JIN"), val
		else
			
			return pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_JIN_HUA"), v[3], v[2], v[1]
		end
	elseif is_shun_zi then
	
		return pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SHUN_ZI"), val
	end

	if v[1] == 0 and v[2] == 1 and v[3] == 3 then
		return  pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SPECIAL")
	end

	return pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SINGLE"), v[3], v[2], v[1]
end


function zjh_table:compare_cards(first, second)	
	if first.cards_type ~= second.cards_type then
		
		if first.cards_type == ZHAJINHUA_CARD_TYPE_BAO_ZI and second.cards_type ==  pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SPECIAL") then
			return false
		elseif second.cards_type == ZHAJINHUA_CARD_TYPE_BAO_ZI and first.cards_type ==  pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SPECIAL") then
		 	return true
		end
		return first.cards_type > second.cards_type
	end

	if first.cards_type == pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SHUN_ZI") or first.cards_type == pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SHUN_JIN") or first.cards_type == ZHAJINHUA_CARD_TYPE_BAO_ZI then
		return first[1] > second[1]
	end

	if first.cards_type == pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_DOUBLE") then
		if first[1] > second[1] then
			return true
		elseif first[1] == second[1] then
			return first[2] > second[2]
		end
		return false
	end

	if first[1] > second[1] then
		return true
	elseif first[1] == second[1] then
		if first[2] > second[2] then
			return true
		elseif first[2] == second[2] then
			return first[3] > second[3]
		end
	end
	return false
end


function zjh_table:check_sit_player_num(bRet)
	local n = 0
	for i,v in pairs(self.player_list_) do
		if v then
			n = n + 1
			if def_second_game_type == 99 and bRet then
				self.ready_list_[v.chair_id] = true
			end
		else
			self.player_list_[i] = false
		end
	end
	if n >= 2 and self.status == ZHAJINHUA_STATUS_FREE then
		if bRet then
			self.ready_count_down = 23
		end
		if not self.allready  then
			local msg = {
			time = self.ready_count_down,
			}
			self:zjh_broadcast_msg_to_client("SC_ZhaJinHuaReadyTime", msg)
		end
		self.ready_time = get_second_time()
		self.status = ZHAJINHUA_STATUS_READY
	end
end

function zjh_table:send_playerinfo(player)
	self:get_sit_down(player)
end
		
function zjh_table:player_sit_down(player, chair_id_)
	for i,v in pairs(self.player_list_) do
		if v == player then
			player.chari_id_ = v.chari_id_
			player:on_stand_up(self.table_id_, chari_id_, GAME_SERVER_RESULT_SUCCESS)
			return
		end
	end
	if self.status == ZHAJINHUA_STATUS_FREE or self.status == ZHAJINHUA_STATUS_READY then
		player.table_id = self.table_id_
		player.chair_id = chair_id_
		player.room_id = self.room_.id	
	--	player.noready = true 
		self.player_list_[chair_id_] = player

		self.player_status[player.chair_id] = PLAYER_FREE
		if player.is_player then
			for i, p in ipairs(self.player_list_) do
				if p == false then
				
					player:on_notify_android_sit_down(player.room_id, self.table_id_, i)
				end
			end
		end	
		if  self.status == ZHAJINHUA_STATUS_READY then
			msg = {
				time = get_second_time() - self.ready_time,
			}		
			self:zjh_post_msg_to_client_pb(player, "SC_ZhaJinHuaReadyTime", msg)
		else
			if def_second_game_type ~= 99 then
				self:check_sit_player_num()
			end
		end
	else
		if self.player_list_[chair_id_] then
			return
		end
		player.table_id = self.table_id_
		player.chair_id = chair_id_
		player.room_id = self.room_.id
--		player.noready = true 
		self.player_list_[chair_id_] = player
		self.ready_list_[chair_id_] = false
		self.player_status[player.chair_id] = PLAYER_STAND
		self:zjh_post_msg_to_client_pb(player, "SC_ShowTax", self.notify_msg)
	end
end


function zjh_table:get_play_Status(player)
	local lost_score_ = 0
	for i,v in pairs(self.add_score_) do
		lost_score_ = v
		break
	end
	if def_second_game_type == 99 then
	self:zjh_post_msg_to_client_pb(player, "SC_ZhaJinHuaTabCFG", {
			score_type = self.private_room_score_type,
			chair_num = 5,
			lost_score = lost_score_,
			vote_result = self.private_vote_bret,
			private_room_id = self.private_room_id 
			})
	end
	local notify = {
		isseecard = self.is_look_card_,
		banker_chair_id = self.cur_turn,
		room_status = self.status,
		totalmoney = self.all_money,
		score = self.last_score,
		round = self.Round,
		status = self.player_status,
		playermoney = self.player_money,
		allbet = self.betscore
	}

	self:zjh_post_msg_to_client_pb(player, "SC_ZhaJinHuaWatch", notify)
end
function  zjh_table:isPlay( ... )
	if  def_second_game_type == 99 and self.private_status == ZHAJINHUA_STATUS_PLAY then 
		return true
	end
	if self.status == ZHAJINHUA_STATUS_PLAY then
		return true
	end
	return false
end

function zjh_table:player_stand_up(player, is_offline)
    if def_second_game_type == 99 then
    	if self.private_status ~= ZHAJINHUA_STATUS_FREE  and self.private_vote_bret ~= true then
    		is_offline = true

			local offline = {
			chair_id = player.chair_id,
			turn = self.Round,
			reconnect = false,
			}
			table.insert(self.gamelog.offlinePlayers, offline)	
			virtual_table.player_stand_up(self,player,is_offline)
    		return false
    	end
    	if self.private_status  == ZHAJINHUA_STATUS_FREE and player.chair_id ==  self.private_room_owner_chair_id and self.private_room ~= false then
    		self:dismiss()
    		return 
    	end
    end

	if self.status == ZHAJINHUA_STATUS_READY then
		
		local n = 0
		for i,v in pairs(self.player_list_) do
			n = n + 1
		end

		if n < 2 then
			self.status = ZHAJINHUA_STATUS_FREE
		end
	elseif self.status == ZHAJINHUA_STATUS_PLAY and not is_offline  and not self.is_dead_[player.chair_id] then
		self:give_up(player)
		return 

	elseif self.status == ZHAJINHUA_STATUS_PLAY and is_offline  and not self.is_dead_[player.chair_id] then
			local offline = {
			chair_id = player.chair_id,
			turn = self.Round,
			reconnect = false,
			}

			table.insert(self.gamelog.offlinePlayers, offline)	
	end

	if not is_offline and self.player_online[player.chair_id] == false then
		local notify = {
			table_id = player.table_id,
			chair_id = player.chair_id,
			guid = player.guid,
		}
		self:zjh_broadcast_msg_to_client("SC_NotifyStandUp",notify)
	end


	if self.status ~= ZHAJINHUA_STATUS_PLAY and is_offline then	
		virtual_table.player_stand_up(self,player,is_offline)
		self.room_:player_exit_room(player)
	else
		local bRet = false
		if self.player_status[player.chair_id] ~= PLAYER_STAND and self.player_status[player.chair_id] ~= PLAYER_READY then
			bRet = true
		end
		virtual_table.player_stand_up(self,player,is_offline)
		if bRet and not is_offline then
			self:zjh_post_msg_to_client_pb(player,"SC_Gamefinish",{
					money = player.pb_base_info.money
				})
			self.room_:player_exit_room(player)
		end
	end
	if is_offline then
		player.is_offline = true -- 掉线了
	end
end

function zjh_table:tick()
	if self.status == ZHAJINHUA_STATUS_PLAY and self.private_vote_status ~= true  then
		local curtime = get_second_time()
		if (curtime - self.time0_) >= 17 then
			
			local player = self.player_list_[self.cur_turn]
			if player then
				self.player_online[player.chair_id] = false
				self:give_up(player)
			end
			self.time0_ = curtime
		end
	end

	if self.status == ZHAJINHUA_STATUS_READY then
		local curtime = get_second_time()
		if curtime - self.ready_time >= self.ready_count_down  or self.allready then
			
			local n = 0
			for i, p in ipairs(self.player_list_) do
				if p then
					if self.ready_list_[p.chair_id] ~= true then
						self.player_online[p.chair_id] = false
						self:player_stand_up(p, false)
					else
						n = n + 1
					end
				end
			end
			
			if n >= 2 then
				self:start(n)
			else
				self.status = ZHAJINHUA_STATUS_FREE
				self.allready  = false
			end
		end
	end
	
	if  self.private_vote_status == true and get_second_time() - self.private_vote_time > vote_time_  then		
		for i, p in ipairs(self.private_vote_list) do
			if p then
				if p.senior == true then
					p.vote = true
				end
			end
		end
		self:check_vote()		
		self.private_vote_status = false
		self.time0_ = self.time0_ + get_second_time()
	end

	if ly_use_robot then
		ly_robot_mgr.check_table(self)
	end
	for _,v in ipairs(self.player_list_) do		
		if v and v.is_android then
			v:tick()
		end
	end

end
