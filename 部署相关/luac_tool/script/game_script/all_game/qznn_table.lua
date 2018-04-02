local pb = require "extern/lib/lib_pb"
tablex = require "extern/lib/lib_tablex"
require "game_script/virtual/virtual_table"
require "game_script/all_game/qznn_gl"
require "extern/lib/lib_table"
local print_r = require "extern/lib/lib_print_r"
require "game_script/virtual/virtual_player"
local zjnn_robot = require "game_script/all_game/qznn_robot"

qznn_table = virtual_table:new()
local DEBUG_MODE = false
local	BANKER_CARD_TYPE_NONE           = 100;
local	BANKER_CARD_TYPE_ONE            = 101;
local	BANKER_CARD_TYPE_TWO            = 102;
local   BANKER_CARD_TYPE_THREE 			= 103;
local	BANKER_CARD_TYPE_FOUR 			= 104;
local	BANKER_CARD_TYPE_FIVE 			= 105;
local	BANKER_CARD_TYPE_SIX 			= 106;
local	BANKER_CARD_TYPE_SEVEN 			= 107;
local	BANKER_CARD_TYPE_EIGHT 			= 108;
local	BANKER_CARD_TYPE_NIGHT 			= 109;
local	BANKER_CARD_TYPE_TEN			= 110;
local	BANKER_CARD_TYPE_FOUR_KING		= 201;
local	BANKER_CARD_TYPE_FIVE_KING		= 202;
local	BANKER_CARD_TYPE_FOUR_SAMES		= 203;
local	BANKER_CARD_TYPE_FIVE_SAMLL		= 204;
local ACTION_INTERVAL_TIME  = 2
local STAGE_INTERVAL_TIME   = 2
local STATUS_WAITING		= 0
local STATUS_SEND_CARDS		= 1
local STATUS_CONTEND_BANKER	= 2
local STATUS_CONTEND_END 	= 2.5
local STATUS_DICISION_BANKER= 3
local STATUS_BET			= 4
local STATUS_BET_END		= 4.5
local STATUS_SHOW_CARD		= 5
local STATUS_SHOW_CARD_END  = 5.5
local STATUS_SHOW_DOWN		= 6
local STATUS_OVER			= 7
local reset_count=0
local PLAYER_STATUS_READY	= 1
local PLAYER_STATUS_GAME	= 2
local PLAYER_STATUS_OFFLINE	= 3
local POSITION_BANKER		= 1
local POSITION_NORMAL		= 2
local CS_ERR_OK = 0 	 
local CS_ERR_MONEY = 1   
local CS_ERR_STATUS = 2  

local MAX_CARDS_INDEX = 1

local MIN_CARDS_INDEX = 2

function qznn_table:reset()
	self.b_status = STATUS_WAITING
	if self.b_next_game then
		self.b_timer = 0
	else
		self.b_timer = get_second_time() + 10
	end
	for i,p in ipairs(self.player_list_) do
		if self.player_list_[i] ~= false then
			if p.is_offline then
				p.is_offline = false
				p.table_id = nil
				p.chair_id = nil
				p.room_id = nil
				self.player_list_[i] = false
			end
		end
	end
	self.b_ret = {}
	self.b_pool = 0
	self.b_player = {}
	self.b_end_player = {}
	self.b_player_count = 0
	self.b_banker = {guid = 0}
	self.b_recoonect = {}
	self.b_max_bet = 0
	self.b_total_time = 0
	self.b_contend_count = 0
	self.b_bet_count = 0
	self.b_guess_count = 0
	self.b_table_busy = 0
	self.b_next_game = true
	
	self:next_game()
end
function qznn_table:t_broadcast(msg_name, msg)
	for _guid, b_player in pairs(self.b_player) do
		local l_player = self:get_player(b_player.chair)
		if l_player and b_player.onTable then
			post_msg_to_client_pb(l_player,msg_name,msg)
		end
	end
end

function qznn_table:init(room, table_id, chair_count)
	
	self.b_next_game = true 
	self.b_next_game_check = false 
	self.game_money_type = 0
	
	if def_game_name == "classic_ox" then
		self.game_money_type = pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CLASSIC_OX")
	else
		self.game_money_type = pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_BANKER_OX")
	end
	virtual_table.init(self, room, table_id, chair_count)
	self.b_player = {}
	self:reset()

	self.b_tax = self.room_:get_room_tax()
	self.b_bottom_bet = self.room_:get_room_cell_money()
	self.area_cards_ = {} 
	self.t_card_set = {}
	local cards_num = 52
	
	for i = 1, cards_num do
		self.t_card_set[i] = i - 1
	end
	
end

function qznn_table:next_game_check_player()
	for i,p in ipairs(self.player_list_) do
		if p and not self.b_player[p.guid] then
			p:forced_exit()
		end
	end
end

function qznn_table:tick()
	if ly_use_robot  and  self.b_status==STATUS_WAITING then
		ly_robot_mgr.check_table(self)
	end
	for _,v in pairs(self.player_list_) do		
		if v and v.is_android then
			v:tick()
		end
	end
	
	if get_second_time() < self.b_timer then
		return
	end
	if  self.b_next_game_check and self.b_table_busy == 0 then
		self.b_next_game_check = false
		self:next_game_check_player()
	end
	if self.b_player_count > 1 and self.b_table_busy == 0 and self:has_real_player() then
		self.b_status = STATUS_SEND_CARDS
		self.b_table_busy = 1
	end
	if self.b_table_busy == 1 then
		
		if self.b_status == STATUS_SEND_CARDS then
			self:send_player_cards()
		elseif self.b_status == STATUS_CONTEND_BANKER then
			self:begin_to_contend()
		elseif self.b_status == STATUS_CONTEND_END then
			self:decide_banker()
		elseif self.b_status == STATUS_BET then
			self:begin_to_bet()
		 elseif self.b_status == STATUS_BET_END then
			self:show_cards()
		 elseif self.b_status == STATUS_SHOW_CARD_END then
			self:send_result()
		end
	end
	if self.b_status == STATUS_OVER then
		self:reset()
	end
end
function qznn_table:canEnter(player)
	if true then
	return true
	end
	if self.b_table_busy == 1 or self.b_player_count == 5 then
		return false
	end
	self.b_timer = get_second_time() + 2
	return true
end
function qznn_table:send_player_cards()
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	
	self.b_status = STATUS_SEND_CARDS
	self.b_next_game_check = true 
	self.b_next_game = false
	self.table_game_id = self:get_now_game_id()
	self.game_log = {
        table_game_id = self.table_game_id,
        start_game_time = os.time(),
        bottom_bet  = self.b_bottom_bet,
        cell_money = self.room_:get_room_cell_money(),
        banker = {},
        banker_contend = {},
        players = {},
    }
	local notify = {}
	notify.pb_player = {}
	notify.pb_table = {
		state = self.b_status,
		bottom_bet = self.b_bottom_bet,
	}
	local user_cards_idx = 0
	for _guid, b_player in pairs(self.b_player) do
		b_player.status = PLAYER_STATUS_GAME
		local player = self:get_player(b_player.chair)
		table.insert(notify.pb_player, {
			guid = _guid,
			chair = b_player.chair,
			--name = player.nickname,
			name = player.ip_area,
			icon =  player:get_avatar(),
			money = player:get_money()
		})
		self.game_log.players[b_player.chair] = {
		--	nickname = player.nickname,
			nickname = player.ip_area,
			chair = b_player.chair,
			money_old = player:get_money()
		}
	end
	local _idx = 1
	local setCount = #self.t_card_set or 52

	local cards_tmp_pre = {}
	
	if DEBUG_MODE then
		local player_count=self:get_player_count()
		if player_count==2 then
			cards_tmp_pre={{1,7,20,21,33},{51,50,49,48,47}} 
			--cards_tmp_pre={{1,7,20,21,33},{2,3,5,6,9}} 
		elseif player_count==3 then
			cards_tmp_pre={{1,7,20,21,33},{51,50,49,48,47},{2,3,5,6,9}}	 
		elseif player_count==4 then
			cards_tmp_pre={{1,7,20,21,33},{4,28,40,41,42},{8,24,44,45,46},{51,50,49,48,47}}
		elseif player_count==5 then	
			cards_tmp_pre={{1,7,20,21,33},{4,28,40,41,42},{8,24,44,45,46},{51,50,49,48,47},{43,36,37,38,39}}
		end	
	else
		for _key, _player in pairs(notify.pb_player) do
			local this_card = {}
			for i = 1,5 do
				local idx = win_random_int(1,setCount - user_cards_idx)
				local card = self.t_card_set[idx]
				table.insert(this_card, card)
				self.t_card_set[idx] = self.t_card_set[#self.t_card_set - user_cards_idx]
				self.t_card_set[#self.t_card_set - user_cards_idx] = card
				user_cards_idx = user_cards_idx + 1
			end	
			cards_tmp_pre[#cards_tmp_pre + 1] = this_card
		end
	end
	

	local cards_tmp_result = {}
	for i, t_this_card in ipairs(cards_tmp_pre) do
		local ox_type_,value_list_,color_, extro_num_, sort_cards_ = get_cards_type(t_this_card)
		local times_=get_type_times(ox_type_,extro_num_)
		
		cards_tmp_result[#cards_tmp_result + 1] = 
		{
			ox_type = ox_type_,
			val_list = value_list_,
			color = color_,
			extro_num = extro_num_,
			sort_cards=sort_cards_,
			cards_times =times_,
			index = i
		}
	end
	
	local has_robot_in_tb = false
	for i,_b_player in pairs(self.b_player) do
		if _b_player.player_.is_android then
			has_robot_in_tb = true
		end
	end
	if ly_use_robot and has_robot_in_tb then
		if ly_robot_storage > 0 and ly_robot_smart_lv < 0 then
			if (ly_robot_storage > self.room_:get_room_cell_money()*500 ) and math.random(1,100) < math.abs(ly_robot_smart_lv) then 	
				table.sort(cards_tmp_result,function(a,b)
					
					return compare_cards(a,b)
					end)
				local len = #cards_tmp_result
				local len_half = math.floor(len/2)
				for i=1,len_half do
					cards_tmp_result[i],cards_tmp_result[len+1 -i] = cards_tmp_result[len+1 -i],cards_tmp_result[i]
				end
			end	
		elseif ly_robot_storage < 0 or (ly_robot_smart_lv > 0 and (math.random(1,100) <= ly_robot_smart_lv)) or 
		((ly_robot_storage < self.room_:get_room_cell_money()*250) and math.random(1,100) < 30 ) then
			table.sort(cards_tmp_result,function(a,b)
				return compare_cards(a,b)
				end)
		end		
	end

	local cards_size = #cards_tmp_pre
	
	local icount_ad=0
	local icount_real=0
	local adroid_ready_k={}
	local real_ready_k={}
	
	for i,_b_player in pairs(self.b_player) do
		if _b_player.player_.is_android then
			icount_ad=icount_ad+1
			table.insert(adroid_ready_k,icount_ad)
		else	
			table.insert(real_ready_k,cards_size-icount_real)
			icount_real=icount_real+1	
		end
	end
	for _key, _player in pairs(notify.pb_player) do
		notify.pb_table.chair = _player.chair
		local player = self:get_player(_player.chair)
		local guid=_player.guid
		local chair=_player.chair
		
		local random_index=nil
		local random_pos=nil

		
		
		if player.is_android then
			
			random_index,random_pos=bs_helper.randomValueInTb(adroid_ready_k)
			table.remove(adroid_ready_k,random_pos)
		
		else
			random_index,random_pos=bs_helper.randomValueInTb(real_ready_k)
			table.remove(real_ready_k,random_pos)	
		
		end
		local cards_index=cards_tmp_result[random_index].index
		self.b_player[guid].cards =cards_tmp_pre[cards_index]
		--self:sort_niuniucards(self.b_player[guid].cards)
		
		local ox_type=cards_tmp_result[random_index].ox_type
		local extro_num=cards_tmp_result[random_index].extro_num
		local val_list=cards_tmp_result[random_index].val_list
		local color=cards_tmp_result[random_index].color
		local sort_cards=cards_tmp_result[random_index].sort_cards
		local cards_times=cards_tmp_result[random_index].cards_times
		
		if def_game_name == "classic_ox" then
			self.b_player[guid].card_times = get_type_times_classic(ox_type,extro_num)
		end
		self.b_ret[guid] =
			{
			guid = guid,
			ox_type = ox_type,
			val_list = val_list,
			color = color,
			extro_num = extro_num,
			cards_times = cards_times
			}
		if ox_type== BANKER_CARD_TYPE_ONE then
			self.b_player[guid].cards_type = BANKER_CARD_TYPE_NONE + extro_num
			self.b_player[guid].sort_cards = sort_cards
		elseif ox_type_ == BANKER_CARD_TYPE_TEN then
			self.b_player[guid].cards_type = ox_type
			self.b_player[guid].sort_cards = sort_cards
		else
			self.b_player[guid].cards_type = ox_type
		end
		self.game_log.players[chair].cards_type = self.b_player[guid].cards_type
		self.game_log.players[chair].cards_info = self.b_ret[guid]	
		notify.cards = {}
		
		for i = 1,4 do
			if def_game_name == "classic_ox" then
				notify.cards[i] = -1
			else
				notify.cards[i] = self.b_player[guid].cards[i]
			end
		end
		notify.cards[5] = -1
		post_msg_to_client_pb(player, "SC_BankerSendCards",notify)
		for k,v in pairs(self.b_player) do
			if v and v.player_.is_android==true and v.player_.guid==player.guid then
				v.player_:game_msg("SC_BankerSendCards",notify)
			end
		end
		
		self.game_log.players[chair].cards = self.b_player[guid].cards
	end
	
	self.b_status = self.b_status + 1
	self.b_timer = get_second_time() + STAGE_INTERVAL_TIME

	for k,v in pairs(self.player_list_) do
		if v then
			v.qznn_in_table = true
		end
	end
end

function qznn_table:sort_niuniucards( cards)
	local point_list = {}
	for i = 1,5 do
		point_list[i] = get_value_ox(math.floor(cards[i]/4))
	end

	if ((point_list[1] + point_list[2] + point_list[5]) %10 ==0) then
		cards[3],cards[5] = cards[5],cards[3]
	elseif ((point_list[2] + point_list[3] + point_list[5]) %10 ==0) then
		cards[1],cards[5] = cards[5],cards[1]
	elseif ((point_list[3] + point_list[4] + point_list[5]) %10 ==0) then
		cards[2],cards[5] = cards[5],cards[2]
		cards[4],cards[1] = cards[1],cards[4]
	elseif ((point_list[1] + point_list[3] + point_list[5]) %10 ==0) then
		cards[2],cards[5] = cards[5],cards[2]
	elseif ((point_list[1] + point_list[4] + point_list[5]) %10 ==0) then
		cards[2],cards[5] = cards[5],cards[2]
		cards[3],cards[4] = cards[4],cards[3]
	elseif ((point_list[2] + point_list[4] + point_list[5]) %10 ==0) then
		cards[3],cards[5] = cards[5],cards[3]
		cards[1],cards[4] = cards[4],cards[1]
	end


end

function qznn_table:set_b_ret()
	for _guid,_b_player in pairs(self.b_player) do
		if _b_player.cards~=nil and #_b_player.cards~=0 then 
			local ox_type_,value_list_,color_, extro_num_, sort_cards_ = get_cards_type(_b_player.cards)
			local times = get_type_times(ox_type_,extro_num_)
			if def_game_name == "classic_ox" then
				_b_player.card_times = get_type_times_classic(ox_type_,extro_num_)
			end
				self.b_ret[_guid] =
				{
					guid = _guid,
					ox_type = ox_type_,
					val_list = value_list_,
					color = color_,
					extro_num = extro_num_,
					cards_times = times
				}
				
			if ox_type_ == BANKER_CARD_TYPE_ONE then
				_b_player.cards_type = BANKER_CARD_TYPE_NONE + extro_num_
				_b_player.sort_cards = sort_cards_
			elseif ox_type_ == BANKER_CARD_TYPE_TEN then
				_b_player.cards_type = ox_type_
				_b_player.sort_cards = sort_cards_
			else
				_b_player.cards_type = ox_type_
			end
			self.game_log.players[_b_player.chair].cards_type = _b_player.cards_type
			self.game_log.players[_b_player.chair].cards_info = self.b_ret[_guid]					
		end	
	end
end

function qznn_table:decide_banker()
	self.b_status = STATUS_DICISION_BANKER
	self.b_total_time = 0
	local banker_candidate = {}	
	local max_ratio = -1
	
	for _guid, b_player in pairs(self.b_player) do
    repeat
		if b_player.status ~= PLAYER_STATUS_GAME then
			break
		end
		if next(b_player.cards) ~= nil then
			if b_player.ratio == 0 then
				local msg = {
					chair = b_player.chair,
					ratio = -1
				}
				self:t_broadcast("SC_BankerPlayerContend", msg)
				
				self.game_log.banker_contend[b_player.chair] = 1
			end
			if b_player.ratio > max_ratio then
				max_ratio = b_player.ratio
				banker_candidate = {}
				table.insert(banker_candidate, _guid)
			elseif b_player.ratio == max_ratio then
				table.insert(banker_candidate, _guid)
			end
		else
			local l_player = self:get_player(self.b_banker.chair)
			self.b_player[_guid] = nil
			self.room_.room_manager_:change_table(l_player)
		end
    until true
	end
	local msg = {}
	if #banker_candidate > 1 then
		msg.chairs = {}
		for _key, _guid in pairs(banker_candidate) do
			table.insert(msg.chairs, self.b_player[_guid].chair)
		end
		local idx = math.random(1, #msg.chairs)
		self.b_banker = {
			chair = self.b_player[banker_candidate[idx]].chair,
			guid = banker_candidate[idx],
			ratio = self.b_player[banker_candidate[idx]].ratio
		}
		msg.banker_chair = self.b_player[banker_candidate[idx]].chair
	else
		self.b_banker = {
			chair = self.b_player[banker_candidate[1]].chair,
			guid = banker_candidate[1],
			ratio = self.b_player[banker_candidate[1]].ratio
		}
		msg.banker_chair = self.b_player[banker_candidate[1]].chair
		msg.chairs = { msg.banker_chair }
	end
	if self.b_banker.ratio < 1 then
		self.b_banker.ratio = 1
		self.b_player[self.b_banker.guid].ratio = 1
	end
	msg.banker_ratio = self.b_banker.ratio
	self.game_log.banker = self.b_banker
	
	local banker_player = self:get_player(self.b_banker.chair)
	local banker_money = banker_player:get_money()
	self.b_max_bet = math.floor(banker_money / (self.b_player_count - 1))
	self:t_broadcast("SC_BankerChoosingBanker", msg)
	
	self.b_status = self.b_status + 1
	self.b_timer = get_second_time() + 5
	if banker_player.is_android then
		ly_niuniu_banker_times = ly_niuniu_banker_times + 1
	end
end

function qznn_table:show_cards()
	
	self.b_status = STATUS_SHOW_CARD
	self.b_total_time = 0

	for _guid, b_player in pairs(self.b_player) do
    repeat
		if b_player.status ~= PLAYER_STATUS_GAME then
			break
		end
		
		if next(b_player.cards) ~= nil then
			if b_player.bet == 0 and _guid ~= self.b_banker.guid then

				self.b_player[_guid].bet = self.b_bottom_bet * self.b_banker.ratio
				local msg = {
					chair = b_player.chair,
					bet_money = self.b_player[_guid].bet
				}
				self:t_broadcast("SC_BankerPlayerBet", msg)
				
				self.game_log.players[b_player.chair].bet = self.b_player[_guid].bet
			end
		
		else
			local l_player = self:get_player(self.b_banker.chair)
			self.b_player[_guid] = nil
			self.room_.room_manager_:change_table(l_player)
		end
    until true
	end

	local msg = {
		countdown = 10,
		total_time = 10,
	}
	for _guid, b_player in pairs(self.b_player) do
    repeat
		if b_player.status ~= PLAYER_STATUS_GAME then
			break
		end
		msg.cards = b_player.cards
		msg.cards_type = b_player.cards_type
		local player = self:get_player(b_player.chair)
		if player then
			
			post_msg_to_client_pb(player, "SC_BankerShowOwnCards",msg)
		end
    until true
	end
	
	for k,v in pairs(self.b_player) do
		if v and v.player_.is_android==true then
			v.player_:game_msg("ShowCards")
		end
	end
	self.b_status = STATUS_SHOW_CARD_END
	
	self.b_timer = get_second_time() + msg.total_time
	self.b_total_time = msg.total_time
end
function qznn_table:send_result()
	self.b_total_time = 0
	
	for _guid, _b_player in pairs(self.b_player) do
    
		if _b_player.status==PLAYER_STATUS_GAME then
		
			if _b_player and _guid > 0 then
				self:update_player_last_recharge_game_total(_b_player.player,_guid)
			end
			
			if _b_player.show_card == 0 and next(_b_player.cards) ~= nil then
				local msg = {
					chair = _b_player.chair,
					cards_type = _b_player.cards_type,
				}
				if msg.cards_type > BANKER_CARD_TYPE_NONE and msg.cards_type < BANKER_CARD_TYPE_FOUR_KING then
					msg.flag = 1
					msg.cards = self.b_player[_guid].sort_cards or self.b_player[_guid].cards
				else
					msg.flag = 2
					msg.cards = self.b_player[_guid].cards
				end
				self:t_broadcast("SC_BankerShowCards", msg)
			
			end
		end
  
	end

	self.b_status = STATUS_SHOW_DOWN
	local notify = {}
	notify.pb_table = {
		state = self.b_status,
		bottom_bet = self.b_bottom_bet,
	}
	notify.pb_player = {}
	local banker_result = self.b_ret[self.b_banker.guid]
	local banker_player	= self.b_player[self.b_banker.guid]	
	local banker_money = (self:get_player(self.b_banker.chair)):get_money() or 0
	
	local xianjia_list={}			
	local xianjia_summoney_win = 0	
	local xianjia_summoney_lose = 0	
	
	for _guid, _b_player in pairs(self.b_player) do
		
		if _guid ~= self.b_banker.guid and _b_player.status == PLAYER_STATUS_GAME then
			local xianjia = {}
			local win = compare_cards(self.b_ret[_guid], banker_result)
			local win_money = _b_player.bet
			
			local chair=self.b_player[_guid].chair
			local l_player = self:get_player(chair)
			local l_money = l_player:get_money()
			
			if def_game_name == "classic_ox" then
				local win_card_times = 1
				if win then
					win_card_times = _b_player.card_times
				else
					win_card_times = banker_player.card_times
				end
				win_money = win_money*win_card_times
			elseif def_game_name == "banker_ox" then
				local function t_get_banker_ox_times(ox_type)
					ox_type = ox_type or 0
					if ox_type < 7 then
						return 1
					elseif ox_type == 7 then
						return 2
					elseif ox_type == 8 then
						return 3
					elseif ox_type == 9 then
						return 4
					else
						return 5
					end
				end
				local win_card_times = 1
				--print(win_card_times)
				if win then
					win_card_times = t_get_banker_ox_times(self.b_ret[_guid].cards_times)
				else
					win_card_times = t_get_banker_ox_times(banker_result.cards_times)
				end
				--print(win_card_times)
				win_money = win_money*win_card_times
			end
			
			
			if win then 
				xianjia_summoney_win = xianjia_summoney_win+win_money
			else
				
				win_money=math.min(win_money,l_money)
				
				xianjia_summoney_lose = xianjia_summoney_lose+win_money
			end	
			
			xianjia.win = win
			xianjia.win_money = win_money	
			xianjia.old_money = l_money
			xianjia_list[_guid] = xianjia
	
			
		end
	
	end
	
	for _guid,_xianjia in pairs(xianjia_list) do
		local chair=self.b_player[_guid].chair
		local l_player = self:get_player(chair)
		local pb_player = {}
		
		if _xianjia.win then
			if xianjia_summoney_win > (banker_money+xianjia_summoney_lose) then
				_xianjia.win_money = math.floor(_xianjia.win_money * (banker_money + xianjia_summoney_lose) / xianjia_summoney_win + 0.5)
			end
			local pb_tax = _xianjia.win_money * self.room_:get_room_tax()
			if pb_tax < 1 then
				pb_tax = 0
			else
				pb_tax = math.floor(pb_tax + 0.5)
			end
			
			pb_player = {
				chair = chair,
				victory = 1,
				tax = pb_tax,
				increment_money = _xianjia.win_money - pb_tax
			}
			if l_player then
				l_player:add_money(
					{{ money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"),
					money = pb_player.increment_money }},
					self.game_money_type
					)

				if l_player.is_android then
					l_player:add_money(
					{{ money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"),
					money = pb_tax }},
					self.game_money_type
					)
					pb_player.tax = 0

				end

				if def_game_name == "classic_ox" then
					notify_win_big_money(l_player.nickname, def_game_id, pb_player.increment_money)
				else
					notify_win_big_money(l_player.nickname, def_game_id, pb_player.increment_money)
				end
				self:update_player_bet_total(math.abs(pb_player.increment_money),l_player,_guid)
				pb_player.money = l_player:get_money()
				self:user_log_money(l_player,2,_xianjia.old_money,pb_player.tax,pb_player.increment_money,self.table_game_id)
				
			end
			self.b_pool = self.b_pool - _xianjia.win_money
			self.game_log.players[chair].tax = pb_tax
		else
			
			
			pb_player = {
				chair = chair,
				victory = 2,
				increment_money = -_xianjia.win_money
				}
				
			if l_player then
				l_player:cost_money(
					{{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = -pb_player.increment_money}},
					self.game_money_type
					)
				pb_player.money = l_player:get_money()
				self:update_player_bet_total(math.abs(pb_player.increment_money),l_player,_guid)
				self:user_log_money(l_player,1,_xianjia.old_money,0.0,pb_player.increment_money,self.table_game_id)
			end
			self.b_pool = self.b_pool +_xianjia.win_money
			
		end
		table.insert(notify.pb_player, pb_player)
		self.game_log.players[chair].increment_money = pb_player.increment_money
		self.game_log.players[chair].money_new = pb_player.money
	end

	local pb_banker = {
		chair = self.b_banker.chair,
	}
	local l_player = self:get_player(self.b_banker.chair)
	if self.b_pool > 0 then
		pb_banker.victory = 1
		local pb_tax = self.b_pool * self.room_:get_room_tax()
		if pb_tax < 1 then
			pb_tax = 0
		else
			pb_tax = math.floor(pb_tax + 0.5)
		end
		pb_banker.tax = pb_tax
		pb_banker.increment_money = self.b_pool - pb_banker.tax
		if l_player then
			l_player:add_money(
				{{ money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"),
				money = pb_banker.increment_money }},
				self.game_money_type
			)
			
			if l_player.is_android then
				l_player:add_money(
				{{ money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"),
				money = pb_tax }},
				self.game_money_type
				)
				pb_banker.tax = 0

			end


			if def_game_name == "classic_ox" then
				notify_win_big_money(l_player.nickname, def_game_id, pb_banker.increment_money)
			else
				notify_win_big_money(l_player.nickname, def_game_id, pb_banker.increment_money)
			end
			self:update_player_bet_total(math.abs(pb_banker.increment_money),l_player,self.b_banker.guid)
			pb_banker.money = l_player:get_money()
			
			self:user_log_money(l_player,2,banker_money,pb_banker.tax,pb_banker.increment_money,self.table_game_id)
		end
		self.game_log.players[self.b_banker.chair].tax = pb_banker.tax
		self.game_log.banker.tax = pb_banker.tax
	else
		pb_banker.victory = 2
		pb_banker.increment_money = self.b_pool
		local lose_money = -self.b_pool
		
		if l_player then
			pb_banker.money = l_player:get_money()
			if lose_money > pb_banker.money then
				lose_money = pb_banker.money
			end
			l_player:cost_money(
				{{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = lose_money}},
				self.game_money_type
			)
			pb_banker.money = pb_banker.money - lose_money
			self:update_player_bet_total(math.abs(lose_money),l_player,self.b_banker.guid)
			self:user_log_money(l_player,1,banker_money,0.0,pb_banker.increment_money,self.table_game_id)
		end
	end
	table.insert(notify.pb_player, pb_banker)
	self.game_log.players[self.b_banker.chair].increment_money = pb_banker.increment_money
	self.game_log.players[self.b_banker.chair].money_new = pb_banker.money
	self.game_log.banker.increment_money = pb_banker.increment_money
	self.game_log.banker.money_new = pb_banker.money_new
	self:t_broadcast("SC_BankerGameEnd", notify)
	self.b_end_player = notify.pb_player
	
	for k,v in pairs(self.b_player) do
		if v and v.player_.is_android==true then
			v.player_:game_msg("GameOver")
		end
	end

	if self:get_player_count() > 4 then
		for i,v in ipairs(self.player_list_) do
			if v and v.is_android then
				v:forced_exit()
				break
			end
		end
	end

	self.robot_random_num=math.random(1,3)

	self.b_status = STATUS_OVER
	self.game_log.end_game_time = os.time()
	local s_log = lua_to_json(self.game_log)
	log_info("running_game_log")
	log_info(s_log)
	self:write_game_log_to_mysql(self.game_log.table_game_id,self.def_game_name,s_log,self.game_log.start_game_time,self.game_log.end_game_time)

	for i,v in ipairs(self.player_list_) do
		if v and (not v.is_android) and (false == v.qznn_in_table) then
			v:forced_exit()
		end
	end

	self:check_game_maintain()

end
function qznn_table:begin_to_bet()
	
	local msg = {
		countdown = 5,
		total_time = 5,
	}
	self:t_broadcast("SC_BankerPlayerBeginToBet", msg)
	
	if self.b_banker.ratio==nil then
		return
	end
	for k,v in pairs(self.b_player) do
		if v and v.player_.is_android==true and v.player_.guid~=self.b_banker.guid then
			v.player_:game_msg("BeginToBet")
		end
	end
	self.b_status = STATUS_BET_END
	self.b_timer = get_second_time() + msg.countdown
	self.b_total_time = msg.total_time
end
function qznn_table:begin_to_contend()
	local msg = {
		countdown = 5,
		total_time = 5
	}
	self:t_broadcast("SC_BankerBeginToContend", msg)
	for k,v in pairs(self.b_player) do
		if v and v.player_.is_android==true then
			v.player_:game_msg("BeginToContend")
		end
	end
	self.b_status = STATUS_CONTEND_END
	self.b_timer = get_second_time() + msg.total_time
	self.b_total_time = msg.total_time
	
end
function qznn_table:banker_bet(player, t_money)
	if self.b_status ~= STATUS_BET_END then
		return
	end
	if self.b_player[player.guid] == nil then
		return
	end
	if self.b_player[player.guid].status ~= PLAYER_STATUS_GAME then
		return
	end
	if self.b_player[player.guid].bet ~= 0 then
		return
	end
	
	if t_money==0 then 
		t_money=self.b_bottom_bet*self.b_banker.ratio
	end

	self.b_player[player.guid].bet = t_money
	local msg = {
		chair = player.chair_id,
		bet_money = t_money
	}
	self:t_broadcast("SC_BankerPlayerBet", msg)
	self.game_log.players[player.chair_id].bet = t_money
	self.b_bet_count = self.b_bet_count + 1
	if self.b_bet_count == self.b_player_count - 1 then
		self.b_timer = get_second_time()
	end
end
function qznn_table:banker_guess_cards(player)
	if self.b_status==STATUS_OVER   then
		return
	end
	if self.b_player[player.guid] == nil then
		return
	end
	if self.b_player[player.guid].status ~= PLAYER_STATUS_GAME then
		return
	end
	if player and next(self.b_player[player.guid]) ~= nil then
		local msg = {
			chair = player.chair_id,
			cards = self.b_player[player.guid].cards,
			cards_type = self.b_player[player.guid].cards_type,
		}
		if msg.cards_type > BANKER_CARD_TYPE_NONE and msg.cards_type < BANKER_CARD_TYPE_FOUR_KING then
			msg.flag = 1
			msg.cards = self.b_player[player.guid].sort_cards and self.b_player[player.guid].sort_cards or self.b_player[player.guid].cards
		else
			msg.flag = 2
			msg.cards = self.b_player[player.guid].cards
		end
			
		self:t_broadcast("SC_BankerShowCards", msg)
		self.b_player[player.guid].show_card = 1
		self.b_guess_count = self.b_guess_count + 1
		if self.b_guess_count == self.b_player_count then
			self.b_timer = get_second_time()
		end
	end
end
function qznn_table:banker_contend(player, ratio)
	if self.b_status > STATUS_CONTEND_END then
		return
	end
	if self.b_player[player.guid] == nil then
		return
	end
	if self.b_player[player.guid].status ~= PLAYER_STATUS_GAME then
		return
	end
	local max_ratio = 4
	if  ratio==0 then
		ratio=-1
	end
	if ratio ~= -1 and (ratio < 1 or ratio > max_ratio) then
		return
	end

	self.b_player[player.guid].ratio = ratio
	local msg = {
		chair = player.chair_id,
		ratio = ratio
	}
	self.b_contend_count = self.b_contend_count + 1
	self:t_broadcast("SC_BankerPlayerContend", msg)
	self.game_log.banker_contend[player.chair_id] = ratio
	if self.b_contend_count == self.b_player_count then
		self.b_timer = get_second_time()
	end
	
end
function qznn_table:reconnect(player)
	if self.b_status == STATUS_WAITING then
		return
	end
	player.table_id = self.table_id_
	player.room_id = self.room_.id
	self.b_recoonect[player.guid] = 1
	return
end
function qznn_table:next_game_playe(player)
		self.b_player[player.guid] = {
			chair = player.chair_id,
			cards = {},
			status = PLAYER_STATUS_READY,
			position = POSITION_NORMAL,
			bet = 0,
			ratio = 0,
			show_card = 0,
			cards_type = BANKER_CARD_TYPE_NONE,
			onTable = true,
			player_ = player
		}
		self.b_player[player.guid].onTable = true
		if self.b_table_busy ~= 1 then
			self.b_player_count = self.b_player_count + 1
			local n = 0
			for i, v in ipairs(self.player_list_) do
				if v then
					n = n +1
				end
			end
			if n == self.b_player_count  then
				self.b_timer = get_second_time() + 1
			end
		end
		self:broadcast_msg_to_client("SC_ReEanter_Next_Game", {chair_id = player.chair_id, })
end
local function arrayClone(arraySrc)
	local arrayDes = {}
	for k,v in pairs(arraySrc) do
		arrayDes[k] = v
	end
	return arrayDes
end
function qznn_table:do_sit_down(player)
	if self.b_player[player.guid] and type(self.b_player[player.guid]) == "table" then
		local tmp_b_player = self.b_player[player.guid]
			self.b_player[player.guid] = {
				chair = tmp_b_player.chair_id or player.chair_id,
				cards = tmp_b_player.cards or {},
				status = tmp_b_player.status or PLAYER_STATUS_READY,
				position = tmp_b_player.position or POSITION_NORMAL,
				bet = tmp_b_player.bet or 0,
				ratio = tmp_b_player.ratio or 0,
				show_card = tmp_b_player.show_card or 0,
				cards_type = tmp_b_player.cards_type or BANKER_CARD_TYPE_NONE,
				onTable = tmp_b_player.onTable or true,
				player_ = tmp_b_player.player_ or player,
				card_times=tmp_b_player.card_times or 0
			}
	else	
		self.b_player[player.guid] = {
			chair = player.chair_id,
			cards = {},
			status = PLAYER_STATUS_READY,
			position = POSITION_NORMAL,
			bet = 0,
			ratio = 0,
			show_card = 0,
			cards_type = BANKER_CARD_TYPE_NONE,
			onTable = true,
			player_ = player
		}
		
	end
	
		local notify = {}
		notify.pb_table = {
			state = math.floor(self.b_status),
			bottom_bet = self.b_bottom_bet,
			chair = player.chair_id
		}
		notify.pb_player = {}
		if next(self.b_end_player) == nil then
			for _guid, b_player in pairs(self.b_player) do
				local l_player = self:get_player(b_player.chair)
				local pb_player = {
					guid = _guid,
					chair = b_player.chair,
					--name = l_player.nickname,
					name = l_player.ip_area,
					icon =  l_player:get_avatar(),
					money = l_player:get_money(),
					ratio = b_player.ratio,
					position = _guid == self.b_banker.guid and 1 or -1,
					bet_money = b_player.bet,
					increment_money = 0,
					status = b_player.status
				}
				if _guid == player.guid and next(b_player.cards) ~= nil then
					pb_player.cards = arrayClone(b_player.cards)
					if self.b_status < STATUS_SHOW_CARD then
						pb_player.cards[5] = -1
					end
				end
				table.insert(notify.pb_player, pb_player)
			end
		else
			for _key, b_player in pairs(self.b_end_player) do
				notify.pb_player = b_player
				local l_player = self:get_player(b_player.chair)
				notify.pb_player.guid = l_player.guid
				--notify.pb_player.name = l_player.nickname
				notify.pb_player.name = l_player.ip_area
				notify.pb_player.icon =  l_player:get_avatar()
				notify.pb_player.ratio = self.b_player[l_player.guid].ratio
				notify.pb_player.position = l_player.guid == self.b_banker.guid and 1 or -1
				notify.pb_player.bet_money = self.b_player[l_player.guid].bet
				notify.pb_player.increment_money = b_player.increment_money or 0
				notify.pb_player.victory = b_player.victory or 0
				if l_player.guid == player.guid and next(b_player.cards) ~= nil then
					notify.pb_player.cards = self.b_player[l_player.guid].cards
				end
			end
		end
		if self.b_status > STATUS_BET then
			for _key, b_player in ipairs(notify.pb_player) do
				notify.pb_player[_key].cards = arrayClone(self.b_player[b_player.guid].cards)
				if self.b_status < STATUS_SHOW_CARD then
					if player.guid == b_player.guid then
						notify.pb_player[_key].cards[5] = -1
					else
						notify.pb_player[_key].cards = {-1,-1,-1,-1,-1}
					end
				end
				notify.pb_player[_key].cards_type = self.b_player[b_player.guid].cards_type and
				self.b_player[b_player.guid].cards_type or BANKER_CARD_TYPE_NONE
				if notify.pb_player[_key].cards_type > BANKER_CARD_TYPE_NONE and notify.pb_player[_key].cards_type < BANKER_CARD_TYPE_FOUR_KING then
					notify.pb_player[_key].flag = 1
				else
					notify.pb_player[_key].flag = 2
				end
			end
		end
		if self.b_status < STATUS_SHOW_CARD then
			for _key, b_player in ipairs(notify.pb_player) do
				notify.pb_player[_key].cards_type = nil
			end
		end

		notify.total_time = self.b_total_time
		if notify.total_time > 0 then
			notify.countdown = math.floor(self.b_timer - get_second_time() + 0.5)
		else
			notify.countdown = 3
			if math.floor(self.b_status) == STATUS_SHOW_CARD then
				notify.total_time = 10
			else
				notify.total_time = 5
			end
		end

		for _key, b_player in ipairs(notify.pb_player) do
			if notify.pb_player[_key].cards == nil then
				notify.pb_player[_key].cards = {-1,-1,-1,-1,-1}
			end
		end
		self.b_player[player.guid].onTable = true
		post_msg_to_client_pb(player, "SC_BankerReconnectInfo", notify)
	if not (self.b_player[player.guid] and self.b_recoonect[player.guid])then
		local nmsg = {
			pb_info = {
				guid = player.guid,
				chair = player.chair_id,
				--name = player.nickname,
				name = player.ip_area,
				icon = player:get_avatar(),
				money = player:get_money()
				},
		state = self.b_player[player.guid].status
		}
		self:t_broadcast("SC_BankerPlayerSitDown", nmsg)
	end

	if self.b_table_busy ~= 1 then
		self.b_player_count = self.b_player_count + 1
		if not self.b_next_game then
			self.b_timer = get_second_time() + 3
		else
			post_msg_to_client_pb(player, "SC_Next_Game_Time", {time_num = self.b_timer - get_second_time() , })
		end
		local n = 0
		for i, v in ipairs(self.player_list_) do
			if v then
				n = n +1
			end
		end
		if n == self.b_player_count  then
			self.b_timer = get_second_time() + 1
		end
	end
end

function qznn_table:player_sit_down(player, chair_id_)
	for i,v in pairs(self.player_list_) do
		if v == player then
			player:on_stand_up(self.table_id_, v.chair_id, pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS"))
			return
		end
	end
	player.table_id = self.table_id_
	player.chair_id = chair_id_
	player.room_id = self.room_.id
	self.player_list_[chair_id_] = player
end
function qznn_table:sit_on_chair(player, _chair_id)
	local result_, table_id_, chair_id_ = virtual_room_mgr.sit_down(self, player, self.table_id_, _chair_id)
	self:do_sit_down(player)
	player.qznn_in_table = true
end
function qznn_table:re_sit_on_chair(player, _chair_id)
	local result_, table_id_, chair_id_ = virtual_room_mgr.sit_down(self, player, self.table_id_, _chair_id)
	self:next_game_playe(player)
end
function qznn_table:check_reEnter(player, chair_id)
	local room_limit = self.room_:get_room_limit()
	local l_money = player:get_money()
	player:check_forced_exit(room_limit)
	if  l_money < room_limit  then
		local msg = {}
		msg.reason = "金币不足，请您充值后再继续"
		msg.num = room_limit
		
		post_msg_to_client_pb(player, "SC_BankerForceToLeave", msg)
		
		player:forced_exit()
	else
		if player.is_android and self:get_player_count() > 4   then
			player:forced_exit()
		elseif player.is_android and (not ly_use_robot) then
			player:forced_exit()
		elseif self.b_status < STATUS_SEND_CARDS then
			self:re_sit_on_chair(player, chair_id)
		else	
			self:sit_on_chair(player,chair_id)
			
		end
	end
end
function qznn_table:player_stand_up(player, is_offline)
    if self.b_status < STATUS_SEND_CARDS then
		virtual_table.player_stand_up(self,player,is_offline)
		self.room_:player_exit_room(player)
		if self.b_player[player.guid] then
			self.b_player[player.guid] = nil
			self.b_player_count = self.b_player_count - 1
			if self.b_player_count < 1 then
				self:reset()
			end
		end
	else
		player.is_offline = true
		player.qznn_in_table = false
		if self.b_player[player.guid] then
			self.b_player[player.guid].onTable = false
		end
	end
end
function qznn_table:check_cancel_ready(player, is_offline)
	virtual_table.check_cancel_ready(self,player,is_offline)
	player:setStatus(is_offline)
	if is_offline then
		if  self.b_status > STATUS_WAITING then
			self:playeroffline(player)
			return false
		end
	end
	return true
end
function qznn_table:player_leave(player)
	if self:isPlay(player) then
		log_error(string.format("player %d leave error, is playing",player.guid))
		return
	end
	nmsg = { table_id = self.table_id_,
		     chair_id = player.chair_id,
		     guid = player.guid,
		     is_offline = false,
		 }
	virtual_table.player_stand_up(self,player,false)
	self.room_:player_exit_room(player)
	if self.b_player[player.guid] then
		self.b_player[player.guid] = nil
		self.b_player_count = self.b_player_count - 1
		if self.b_player_count < 1 then
			self:reset()
		end
	end
	self:broadcast_msg_to_client("SC_NotifyStandUp", nmsg)
end
function  qznn_table:isPlay(player)
	if player then
		local bp = self.b_player[player.guid]
		if bp and bp.status ~= PLAYER_STATUS_GAME then
			return false
		end
	end
	if self.b_status > STATUS_WAITING then
		return true
	else
		return false
	end
end
