-- 梭哈逻辑
local pb = require "extern/lib/lib_pb"
require "game_script/virtual/virtual_table"
require "game_script/virtual/virtual_player"
local LOG_MONEY_OPT_TYPE_POINT21 = pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_POINT21")
local point21_robot = require "game_script/all_game/point21_robot"
local FSM_E = {
	UPDATE          = 0,	--time update
	BET 			= 1,	--下注
	GET_CARD 		= 2,	--要牌
	STOP 			= 3,	--停牌	
	CALL_DOUBLE		= 4,	--加倍
	SPLIT			= 5,	--分牌
	INSURANCE		= 6,	--买保险
	SURRENDER		= 7,	--投降
}
local FSM_S = {
    PER_BEGIN       		= 0,	--预开始
	XIA_ZHU					= 1,	--下注
    XI_PAI		    		= 2,    --洗牌 
	TOU_XIANG				= 3,	--投降
	MAI_BAO_XIAN			= 4,	--买保险
	GAME_ROUND				= 5,	--游戏回合	
	GAME_BALANCE			= 15,	--结算
	GAME_CLOSE				= 16,	--关闭游戏
	GAME_ERR				= 17,	--发生错误
	GAME_IDLE_HEAD			= 0x1000, --用于客户端播放动画延迟				
}
local cards_state = {
	NORMAL 	= 0,
	STOP 	= 1,
	DEAD 	= 2,
}
local ACTION_TIME_OUT = 15
local function arrayClone(arraySrc)
	local arrayDes = {}
	for k,v in pairs(arraySrc) do
		arrayDes[k] = v
	end
	return arrayDes
end
local function tableCloneSimple(ori_tab)
    if (type(ori_tab) ~= "table") then
        return ori_tab;
    end
    local new_tab = {};
    for i,v in pairs(ori_tab) do
        local vtyp = type(v);
        if (vtyp == "table") then
            new_tab[i] = mj_util.tableCloneSimple(v);
        elseif (vtyp == "thread") then
            new_tab[i] = v;
        elseif (vtyp == "userdata") then
            new_tab[i] = v;
        else
            new_tab[i] = v;
        end
    end
    return new_tab;
end
function post_msg_to_client_pb_point21(player,op_name,msg)
	if player.is_android then
		player:game_msg(op_name,msg)
	else
		post_msg_to_client_pb(player,op_name,msg)
	end
end
point21_table = virtual_table:new()
function point21_table:broadcast_msg_to_client_point21(op_name,msg)
	for i,v in ipairs(self.player_list_) do
		if v then
			post_msg_to_client_pb_point21(v, op_name, msg)
		end
	end
end
function point21_table:broadcast_msg_to_client_enter_data()
	for i,v in ipairs(self.player_list_) do
		if v then
			self:send_data_to_enter_player(v)
		end
	end
end
-- 检查是否可取消准备
function point21_table:check_cancel_ready(player, is_offline)
	return not self:isPlay(player, is_offline)
end
-- 检查是否可准备
function point21_table:check_ready(player)
	return not self:isPlay(player)
end
function point21_table:get_cards_point(cards)
	local A_count = 0
	local point = 0
	for k,v in pairs(cards) do
		local p = math.ceil(v/4)
		if p > 10 then p = 10 end --JQK
		if p == 1 then
			A_count = A_count + 1
			point = point + 11
		else
			point = point + p
		end
	end
	repeat
		if point > 21 and A_count > 0 then
			point = point - 10
			A_count = A_count - 1
		else
			break
		end
	until false
	return point
end
function point21_table:isPlay( ... )
	if self.do_logic_update then
		return true
	end
	return false
end
-- 玩家下注
function point21_table:do_bet(player, msg)
	if not self.do_logic_update then return end
	if msg and msg.target > 0 then
        self:safe_event({chair_id = player.chair_id,type = FSM_E.BET,target = msg.target})
    end
end
function point21_table:notify_do_bet(msg)
	self:broadcast_msg_to_client_point21("SC_Point21_Bet",msg)
	local player = self.player_list_[msg.chair_id] 
	table.insert(self.game_log.action_table,{bet_total = player.bets[1] + player.bets[2],act = "Bet",msg = msg})
end
-- 要牌
function point21_table:get_card(player, msg)
	if not self.do_logic_update then return end
	self:safe_event({chair_id = player.chair_id,type = FSM_E.GET_CARD})
end
function point21_table:notify_get_card(msg)
	self:broadcast_msg_to_client_point21("SC_Point21_GetCard",msg)
	local player = self.player_list_[msg.chair_id] 
	table.insert(self.game_log.action_table,{bet_total = player.bets[1] + player.bets[2],act = "GetCard",msg = msg})
end
-- 加倍
function point21_table:call_double(player, msg)
	if not self.do_logic_update then return end
	self:safe_event({chair_id = player.chair_id,type = FSM_E.CALL_DOUBLE})
end
function point21_table:notify_call_double(msg)
	self:broadcast_msg_to_client_point21("SC_Point21_CallDouble",msg)
	local player = self.player_list_[msg.chair_id] 
	table.insert(self.game_log.action_table,{bet_total = player.bets[1] + player.bets[2],act = "CallDouble",msg = msg})
end
-- 停牌
function point21_table:do_stop(player, msg)
	if not self.do_logic_update then return end
	self:safe_event({chair_id = player.chair_id,type = FSM_E.STOP})
end
function point21_table:notify_do_stop(msg)
	self:broadcast_msg_to_client_point21("SC_Point21_Stop",msg)
	local player = self.player_list_[msg.chair_id] 
	table.insert(self.game_log.action_table,{bet_total = player.bets[1] + player.bets[2],act = "Stop",msg = msg})
end
-- 分牌
function point21_table:do_split(player, msg)
	if not self.do_logic_update then return end
	self:safe_event({chair_id = player.chair_id,type = FSM_E.SPLIT})
end
function point21_table:notify_do_split(msg)
	self:broadcast_msg_to_client_point21("SC_Point21_Split",msg)
	local player = self.player_list_[msg.chair_id] 
	table.insert(self.game_log.action_table,{bet_total = player.bets[1] + player.bets[2],act = "Split",msg = msg})
end
-- 买保险
function point21_table:do_insurance(player, msg)
	if not self.do_logic_update then return end
	self:safe_event({chair_id = player.chair_id,type = FSM_E.INSURANCE})
end
function point21_table:notify_do_insurance(msg)
	self:broadcast_msg_to_client_point21("SC_Point21_Insurance",msg)
	local player = self.player_list_[msg.chair_id] 
	table.insert(self.game_log.action_table,{bet_total = player.bets[1] + player.bets[2],act = "Insurance",msg = msg})
end
-- 投降
function point21_table:do_surrender(player, msg)
	if not self.do_logic_update then return end
	self:safe_event({chair_id = player.chair_id,type = FSM_E.SURRENDER})
end
function point21_table:notify_do_surrender(msg)
	self:broadcast_msg_to_client_point21("SC_Point21_Surrender",msg)
	local player = self.player_list_[msg.chair_id] 
	table.insert(self.game_log.action_table,{bet_total = player.bets[1] + player.bets[2],act = "Surrender",msg = msg})
end
function point21_table:is_black_jack(cards)
	if #cards ~= 2 or (cards[1] ~= 3 and cards[1] ~= 43) or (cards[2] ~= 3 and cards[2] ~= 43) then
		return false
	end
	return true
end
function point21_table:init(room, table_id, chair_count)
	virtual_table.init(self, room, table_id, chair_count)
	
	self.cards = {}
	-- A 2 3 --- J Q K
	-- 红桃 方块 黑桃 梅花
	for i = 1, 52 do
		self.cards[#self.cards + 1] = i
	end
	self.cur_state_FSM = FSM_S.PER_BEGIN
	self.system_zhuang = true
	self.zhuang_chair_id = chair_count
	-- test --
	--ly_robot_mgr.add_a_robot(self)
end
function point21_table:load_lua_cfg()
	local funtemp = load(self.room_.lua_cfg_)
	local cfg = funtemp()
	self.max_call = cfg.max_call
	self.bet_base = cfg.bet_base
end
-- 开始游戏
function point21_table:start(player_count)
	self.player_count = player_count
	self.timer = {}
	self.last_action_change_time_stamp = os.time() --上次状态 更新的 时间戳
	self.cur_turn = -1
	
	for k,v in pairs(self.player_list_) do
		if v and self.ready_list_[k] then
			v.is_dead = false
			v.need_eixt = false
			v.cards = {{},{}}
			v.bets = {0,0}
			v.cards_state = {cards_state.DEAD,cards_state.DEAD}
			v.tou_xiang = nil
			v.mai_bao_xian = nil
			v.mai_bao_xian_val = 0
			v.win_money = 0
			v.taxes = 0
		end
	end
	self:update_state(FSM_S.PER_BEGIN)
	self.do_logic_update = true
	self.table_game_id = self:get_now_game_id()
    self:next_game()
	self.game_log = {
		private_room = self.private_room and true or false,
        table_game_id = self.table_game_id,
        start_game_time = os.time(),
        zhuang = self.zhuang,
		max_call = self.max_call,
		bet_base = self.bet_base,
        action_table = {},
        players = {},
    }
	for k,v in pairs(self.player_list_) do
		if v and self.ready_list_[k] then
			local tmp_p = {
				account = v.account,
				nickname = v.nickname,
				ip_area = v.ip_area,
				guid = v.guid,
				chair_id = v.chair_id,
				money_old = v.pb_base_info.money,
				cards = v.cards,
				bets = v.bets,
				cards_state = v.cards_state,
			}
			self.game_log.players[v.chair_id] = tmp_p
		end
	end
end
-- 玩家坐下
function point21_table:player_sit_down(player, chair_id_)
	virtual_table.player_sit_down(self,player, chair_id_)
	if self.system_zhuang and (not self.player_list_[self.zhuang_chair_id]) then
		ly_robot_mgr.add_a_robot(self,self.zhuang_chair_id)
	end
end
-- 心跳
function point21_table:tick()
	if self.do_logic_update then
		self:safe_event({type = FSM_E.UPDATE})
		local dead_list = {}
		for k,v in pairs(self.timer) do
			if os.time() > v.dead_line then
				v.execute()
				dead_list[#dead_list + 1] = k
			end
		end
		for k,v in pairs(dead_list) do
			self.timer[v] = nil
		end
    else
        self.Maintain_time = self.Maintain_time or get_second_time()
        if get_second_time() - self.Maintain_time > 5 then
            self.Maintain_time = get_second_time()
            for _,v in ipairs(self.player_list_) do
                if v then
                    --维护时将准备阶段正在匹配的玩家踢出
                    local iRet = virtual_table:onNotifyReadyPlayerMaintain(v)--检查游戏是否维护
                end
            end
        end
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
function point21_table:safe_event(...)
    -- test --
    self:FSM_event(...)
   --[[
    local ok = xpcall(point21_table.FSM_event,function() print(debug.traceback()) end,self,...)
    if not ok then
        print("safe_event error") 
        self:update_state(FSM_S.GAME_ERR)
    end
    ]]
end
function point21_table:update_state(new_state)
    self.cur_state_FSM = new_state
    self.last_action_change_time_stamp = os.time()
    self:broad_cast_desk_state()
	if new_state == FSM_S.GAME_ROUND then
		self:next_turn()
	elseif new_state == FSM_S.GAME_BALANCE then
		table.insert(self.game_log.action_table,{act = "GAME_BALANCE"})
	end
end
function point21_table:update_state_delay(new_state,delay_seconds)
	--[[self:update_state(new_state)]]
	
    self.cur_state_FSM = new_state + FSM_S.GAME_IDLE_HEAD
    local act = {}
    act.dead_line = os.time() + delay_seconds
    act.execute = function()
        self:update_state(self.cur_state_FSM - FSM_S.GAME_IDLE_HEAD)
    end
    self.timer[#self.timer + 1] = act
	
end
function point21_table:is_action_time_out()
	local time_out = (os.time() - self.last_action_change_time_stamp) >= ACTION_TIME_OUT 
    return time_out
end
function point21_table:reset_action_time()
   self.last_action_change_time_stamp = os.time()
end
function point21_table:broad_cast_desk_state()
    if self.cur_state_FSM == FSM_S.PER_BEGIN or self.cur_state_FSM >= FSM_S.GAME_IDLE_HEAD then
        return
    end
    self:broadcast_msg_to_client_point21("SC_Point21_Desk_State",{state = self.cur_state_FSM})
end
function point21_table:notify_offline(player)
    if self.do_logic_update then
		player.deposit = true
    else
        self.room_:player_exit_room(player)
    end
end
function point21_table:reconnect(player)
    player.deposit = false
end
--请求玩家数据
function point21_table:reconnection_client_msg(player)
	log_info("player Reconnection : ".. player.chair_id)
	virtual_table.reconnection_client_msg(self,player)
    self:send_data_to_enter_player(player,true)
end

function point21_table:send_data_to_enter_player(player,is_reconnect)
    local msg = {}
	msg.table_state = self.cur_state_FSM
	msg.zhuang_chair_id = self.zhuang_chair_id
    msg.self_chair_id = player.chair_id
    msg.act_time_limit = ACTION_TIME_OUT
    msg.is_reconnect = is_reconnect
	msg.base_score = self.cell_score_
	msg.max_call = self.max_call
	msg.bet_base = self.bet_base
    msg.pb_players = {}
    for k,v in pairs(self.player_list_) do
        if v and self.ready_list_[k] then
            local tplayer = {}
            tplayer.chair_id = v.chair_id
			tplayer.nick = v.ip_area
			tplayer.icon = v:get_avatar()
			tplayer.gold = v:get_money()
			tplayer.guid = v.guid
            tplayer.pb_tiles = {}
			if v.cards then
				for index,cards in pairs(v.cards) do
					if #cards > 0 then
						local t_cards_info = {}
						t_cards_info.cards = arrayClone(cards)
						if tplayer.chair_id == self.zhuang_chair_id and player.chair_id ~= self.zhuang_chair_id and self.cur_state_FSM <= FSM_S.GAME_ROUND then
							t_cards_info.cards[2] = 255
						end
						t_cards_info.stata = v.cards_state[index]
						t_cards_info.bet = v.bets[index]
						table.insert(tplayer.pb_tiles,t_cards_info)
					end
				end
			end
            table.insert(msg.pb_players,tplayer)
        end
    end
    if is_reconnect then
        msg.pb_rec_data = {}
		self.last_action_change_time_stamp = self.last_action_change_time_stamp or os.time() 
        msg.pb_rec_data.act_left_time = self.last_action_change_time_stamp + ACTION_TIME_OUT - os.time()   
        if msg.pb_rec_data.act_left_time < 0 then msg.pb_rec_data.act_left_time = 0 end 
    end
    post_msg_to_client_pb_point21(player,"SC_Point21_EnterData",msg)
	if is_reconnect then
		self:broadcast_next_turn()
	end
	if self.cur_state_FSM == FSM_S.GAME_BALANCE or self.cur_state_FSM == FSM_S.GAME_CLOSE or 
	self.cur_state_FSM == (FSM_S.GAME_BALANCE+FSM_S.GAME_IDLE_HEAD) or self.cur_state_FSM == (FSM_S.GAME_CLOSE+FSM_S.GAME_IDLE_HEAD) then
		self:send_finish_msg_to_player(player,is_reconnect)
	end
end
function point21_table:send_finish_msg_to_player(player,is_reconnect)
	local msg = {pb_players = {}}
	for k,v in pairs(self.player_list_) do
        if v and self.ready_list_[k] then
            local tplayer = {}
            tplayer.chair_id = v.chair_id
			tplayer.nick = v.ip_area
			tplayer.icon = v:get_avatar()
			tplayer.gold = v:get_money()
			tplayer.guid = v.guid
			tplayer.win_money = v.win_money
			tplayer.taxes = v.win_taxes
            tplayer.pb_tiles = {}
			if v.cards then
				for index,cards in pairs(v.cards) do
					if #cards > 0 then
						local t_cards_info = {}
						t_cards_info.cards = arrayClone(cards)
						if tplayer.chair_id == self.zhuang_chair_id and player.chair_id ~= self.zhuang_chair_id and self.cur_state_FSM <= FSM_S.GAME_ROUND then
							t_cards_info.cards[2] = 255
						end
						t_cards_info.stata = v.cards_state[index]
						t_cards_info.bet = v.bets[index]
						table.insert(tplayer.pb_tiles,t_cards_info)
					end
				end
			end
            table.insert(msg.pb_players,tplayer)
        end
    end
	post_msg_to_client_pb_point21(player,"SC_Point21_Game_Finish",msg)
end
function point21_table:get_one_card()
	self.k = self.k or #self.cards
	if self.k < 1 then
		log_error("point21_table:get_one_card error self.k < 1")
		return 1
	end
	local r = win_random_int(1,self.k)
	local this_card = self.cards[r]
	if r ~= self.k then
		self.cards[r], self.cards[self.k] = self.cards[self.k], self.cards[r]
	end
	self.k = self.k-1
	return this_card
end
function point21_table:check_xia_zhu_finish()
	local all_bet = true
	for k,v in pairs(self.player_list_) do
        if v and self.ready_list_[k] and v.chair_id ~= self.zhuang_chair_id and v.bets[1] == 0 then 
			all_bet = false
			break
		end 
    end
	if all_bet then
		for k,v in pairs(self.player_list_) do
        	if v and self.ready_list_[k] and v.chair_id ~= self.zhuang_chair_id then 
				local s_type = 1
				local s_old_money = v:get_money()
				local s_tax = 0

				v:cost_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = v.bets[1]}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_POINT21")) 
				self:user_log_money(v,s_type,s_old_money,s_tax,-v.bets[1],self.table_game_id)

			end 
    	end
		self:update_state_delay(FSM_S.XI_PAI,1)
	end
end
function point21_table:check_game_balance()
	local round_finish = true
	for k,v in pairs(self.player_list_) do
		if v and self.ready_list_[k] and v.chair_id ~= self.zhuang_chair_id then 
			if (v.cards_state[1] == cards_state.NORMAL) or (v.cards_state[2] == cards_state.NORMAL) then
				round_finish = false
				break
			end
		end 
	end
	if round_finish then
		self:update_state(FSM_S.GAME_BALANCE)
	end
	return round_finish
end
function point21_table:broadcast_next_turn()
	self:broadcast_msg_to_client_point21("SC_Point21_NextTurn",{chair_id = self.cur_turn})
end
function point21_table:next_turn()
	if self:check_game_balance() then
		return	
	end
	if self.cur_turn == -1 then
		for k,v in pairs(self.player_list_) do
        	if v and self.ready_list_[k] and v.chair_id ~= self.zhuang_chair_id then 
				self.cur_turn = v.chair_id
			end 
    	end
	else
		local cur_player = self.player_list_[self.cur_turn]
		repeat
			local len = #self.player_list_
			self.cur_turn = self.cur_turn + 1
			if self.cur_turn > len then self.cur_turn = 1 end
			local player = self.player_list_[self.cur_turn]
			if player and self.ready_list_[self.cur_turn] and (player.chair_id ~= self.zhuang_chair_id)
			and (player.cards_state[1] == cards_state.NORMAL or player.cards_state[2] == cards_state.NORMAL) then
				break
			end
		until false
	end
	self:broadcast_next_turn()
end
function point21_table:FSM_event(event_table)
    if self.cur_state_FSM == FSM_S.PER_BEGIN then
        if event_table.type == FSM_E.UPDATE then
            self:update_state_delay(FSM_S.XIA_ZHU,1)
			self:broadcast_msg_to_client_enter_data()
        else 
            log_info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type)
        end
	elseif self.cur_state_FSM == FSM_S.XIA_ZHU then
		if event_table.type == FSM_E.UPDATE then
			if self:is_action_time_out() then
				for k,v in pairs(self.player_list_) do
        			if v and self.ready_list_[k] and v.chair_id ~= self.zhuang_chair_id then
						if v.bets[1] == 0 then
							v.bets[1] = self.cell_score_
							self:notify_do_bet({target = self.cell_score_,chair_id = v.chair_id})
						end
					end
				end
				self:check_xia_zhu_finish()
			end
		elseif event_table.type == FSM_E.BET then
			if event_table.chair_id ~= self.zhuang_chair_id then
				local function check_bet_valid(bet)
					for k,v in pairs(self.bet_base) do
						if v == bet then
							return true
						end
					end
					return false
				end 
				local cur_player = self.player_list_[event_table.chair_id]
				if cur_player.bets[1] == 0 and (cur_player:get_money() >= event_table.target) and check_bet_valid(event_table.target) then
					cur_player.bets[1] = event_table.target
					self:notify_do_bet({target = event_table.target,chair_id = event_table.chair_id})
					self:check_xia_zhu_finish()
				end
			end
		end
    elseif self.cur_state_FSM == FSM_S.XI_PAI then
        if event_table.type == FSM_E.UPDATE then
			math.randomseed(tostring(os.time()):reverse():sub(1, 6))
			self.k = nil
			-- 发底牌
			for _key, _player in pairs(self.player_list_) do
				if _player and self.ready_list_[_key] then
					local this_card = {}
					for i = 1,2 do
						this_card[i] = self:get_one_card()
					end	
					_player.cards[1] = this_card
					_player.cards_state[1] = cards_state.NORMAL
				end
			end
			--self.player_list_[self.zhuang_chair_id].cards[1][1] = 2
			--self.player_list_[6].cards[1] = {3,43}
			self:broadcast_msg_to_client_enter_data()
			local zhuang_first_card = self.player_list_[self.zhuang_chair_id].cards[1][1]
			if zhuang_first_card < 5 then
				self:update_state_delay(FSM_S.MAI_BAO_XIAN,1)
			else
				self:update_state_delay(FSM_S.TOU_XIANG,1)
			end
        else
            log_info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end
	elseif self.cur_state_FSM == FSM_S.TOU_XIANG then--投降
		if event_table.type == FSM_E.UPDATE then
			if self:is_action_time_out() then
				for i,v in ipairs(self.player_list_) do
					if v and self.ready_list_[k] and v.chair_id ~= self.zhuang_chair_id and v.tou_xiang == nil then
						v.tou_xiang = false
						self:notify_do_surrender({chair_id = v.chair_id,surrender = v.tou_xiang})
					end
				end
				self:update_state_delay(FSM_S.GAME_ROUND,1)	
			end
		elseif event_table.type == FSM_E.SURRENDER then
			local cur_player = self.player_list_[event_table.chair_id]
			cur_player.tou_xiang = event_table.tou_xiang
			cur_player.cards_state[1] = cards_state.DEAD
			local all_deal = true
			for i,v in ipairs(self.player_list_) do
				if v and self.ready_list_[k] and v.chair_id ~= self.zhuang_chair_id and v.tou_xiang == nil then
					all_deal = false
					break
				end
			end
			self:notify_do_surrender({chair_id = cur_player.chair_id,surrender = cur_player.tou_xiang})
			if all_deal then
				self:update_state_delay(FSM_S.GAME_ROUND,1)	
			end
		end
	elseif self.cur_state_FSM == FSM_S.MAI_BAO_XIAN then--买保险	
		if event_table.type == FSM_E.UPDATE then
			if self:is_action_time_out() then
				for i,v in ipairs(self.player_list_) do
					if v and self.ready_list_[k] and v.chair_id ~= self.zhuang_chair_id and v.mai_bao_xian == nil then
						v.mai_bao_xian = false
						self:notify_do_insurance({cost = 0,chair_id = v.chair_id})
					end
				end
				self:update_state_delay(FSM_S.GAME_ROUND,1)	
			end
		elseif event_table.type == FSM_E.INSURANCE then
			local cur_player = self.player_list_[event_table.chair_id]
			cur_player.mai_bao_xian = event_table.mai_bao_xian
			local cost = 0
			if cur_player:get_money() >= cur_player.bets[1]/2 and cur_player.mai_bao_xian then
				local s_type = 1
				local s_old_money = cur_player:get_money()
				local s_tax = 0
				local cost = math.ceil(cur_player.bets[1]/2)

				cur_player:cost_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = cost}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_POINT21")) 
				self:user_log_money(cur_player,s_type,s_old_money,s_tax,-cost,self.table_game_id)

				cur_player.mai_bao_xian_val = cost
			else
				cur_player.mai_bao_xian = false
			end
			self:notify_do_insurance({cost = cost,chair_id = cur_player.chair_id})
			local all_deal = true
			for i,v in ipairs(self.player_list_) do
				if v and self.ready_list_[k] and v.chair_id ~= self.zhuang_chair_id and v.mai_bao_xian == nil then
					all_deal = false
					break
				end
			end
			if all_deal then
				self:update_state_delay(FSM_S.GAME_ROUND,1)	
			end
		end
	elseif self.cur_state_FSM == FSM_S.GAME_ROUND then
		local cur_turn_player = self.player_list_[self.cur_turn]
        if event_table.type == FSM_E.UPDATE then
			if self:is_action_time_out() then	
				if cur_turn_player.cards_state[1] == cards_state.NORMAL then
					cur_turn_player.cards_state[1] = cards_state.STOP
				elseif cur_turn_player.cards_state[2] == cards_state.NORMAL then
					cur_turn_player.cards_state[2] = cards_state.STOP
				end
				self:next_turn()	
			end
		elseif event_table.type == FSM_E.SPLIT then--分牌
			if event_table.chair_id == cur_turn_player.chair_id then
				if (#cur_turn_player.cards[1] == 2) and (#cur_turn_player.cards[2] == 0)
				and (math.floor(cur_turn_player.cards[1][1]/4) == math.floor(cur_turn_player.cards[1][2]/4)) then
					if cur_turn_player:get_money() >= cur_turn_player.bets[1] then
						cur_turn_player.cards[2][1] = cur_turn_player.cards[1][2]
						cur_turn_player.cards[1][2] = nil
						cur_turn_player.cards_state[2] = cards_state.NORMAL	
						cur_turn_player.bets[2] = cur_turn_player.bets[1]
						cur_turn_player.cards[1][2] = self:get_one_card()
						cur_turn_player.cards[2][2] = self:get_one_card()
	
						local s_type = 1
						local s_old_money = cur_turn_player:get_money()
						local s_tax = 0

						cur_turn_player:cost_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = cur_turn_player.bets[2]}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_POINT21")) 
						self:user_log_money(cur_turn_player,s_type,s_old_money,s_tax,-cur_turn_player.bets[2],self.table_game_id)

						local tiles = {{cards = cur_turn_player.cards[1],stata = cur_turn_player.cards_state[1],bet = cur_turn_player.bets[1]},
									  {cards = cur_turn_player.cards[2],stata = cur_turn_player.cards_state[2],bet = cur_turn_player.bets[2]}}
						
						self:notify_do_split({target = cur_turn_player.bets[2],chair_id = cur_turn_player.chair_id,tiles = tiles})
					end
				end
			end
		elseif event_table.type == FSM_E.GET_CARD or event_table.type == FSM_E.CALL_DOUBLE then--要牌\加倍
			if event_table.chair_id == cur_turn_player.chair_id then
				local cur_index = 1
				if cur_turn_player.cards_state[1] ~= cards_state.NORMAL then
					cur_index = 2
				end
				local kou_kuan_suc = true
				if event_table.type == FSM_E.CALL_DOUBLE then
					if cur_turn_player:get_money() >= cur_turn_player.bets[cur_index] then
						local s_type = 1
						local s_old_money = cur_turn_player:get_money()
						local s_tax = 0

						cur_turn_player:cost_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = cur_turn_player.bets[cur_index]}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_POINT21")) 
						self:user_log_money(cur_turn_player,s_type,s_old_money,s_tax,-cur_turn_player.bets[cur_index],self.table_game_id)

						cur_turn_player.bets[cur_index] = cur_turn_player.bets[cur_index] * 2
					else
						kou_kuan_suc = false
					end
				end
				if kou_kuan_suc then
					local this_card = self:get_one_card()
					table.insert(cur_turn_player.cards[cur_index],this_card)
					if event_table.type == FSM_E.CALL_DOUBLE then
						cur_turn_player.cards_state[cur_index] = cards_state.STOP
						self:notify_call_double({card = this_card,chair_id = cur_turn_player.chair_id,
							target = cur_turn_player.bets[cur_index],cur_index = cur_index})
					else
						self:notify_get_card({card = this_card,chair_id = cur_turn_player.chair_id})
					end
					local cards_point = self:get_cards_point(cur_turn_player.cards[cur_index])
					if cards_point > 21 then
						cur_turn_player.cards_state[cur_index] = cards_state.DEAD
					end
					self:next_turn()
				end
			end
		elseif event_table.type == FSM_E.STOP then--停牌	
			if event_table.chair_id == cur_turn_player.chair_id then
				local cur_index = 1
				if cur_turn_player.cards_state[1] ~= cards_state.NORMAL then
					cur_index = 2
				end
				cur_turn_player.cards_state[cur_index] = cards_state.STOP
				self:notify_do_stop({chair_id = cur_turn_player.chair_id,cur_index = cur_index})
				self:next_turn()
			end
        else
            log_info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end
	elseif self.cur_state_FSM == FSM_S.GAME_BALANCE then
        if event_table.type == FSM_E.UPDATE then
			local zhuang_player = self.player_list_[self.zhuang_chair_id]
			local zhuang_cards = zhuang_player.cards[1]
			local zhuang_point = 0
			local zhuang_is_dead = false
			repeat
				zhuang_point = self:get_cards_point(zhuang_cards)
				if zhuang_point < 17 then
					table.insert(zhuang_cards,self:get_one_card())
				else
					if zhuang_point > 21 then
						zhuang_player.cards_state[1] = cards_state.DEAD
						zhuang_is_dead = true
					end
					break
				end
			until false
			local zhuang_win = 0
			for i,v in ipairs(self.player_list_) do
				if v and self.ready_list_[k] and v.chair_id ~= self.zhuang_chair_id then
					if v.tou_xiang then
						local s_type = 2
						local s_old_money = v:get_money()
						local s_tax = 0
						local add = math.ceil(v.bets[1]/2)

						v:add_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = add}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_POINT21")) 
						self:user_log_money(v,s_type,s_old_money,s_tax, add,self.table_game_id)

						zhuang_win = zhuang_win + add
						v.win_money = -add
						v.taxes = 0
					else
						for index,cards in pairs(v.cards) do
							if #cards > 0 then
								local cards_p = self:get_cards_point(cards)
								if v.cards_state[index] == cards_state.DEAD then
									zhuang_win = zhuang_win + v.bets[index]
									v.win_money = v.win_money - v.bets[index]
									v.taxes = v.taxes + 0
								else
									if zhuang_is_dead or self:is_black_jack(cards) or zhuang_point < cards_p then
										local s_type = 2
										local s_old_money = v:get_money()
										local pei_qian = 0
										if self:is_black_jack(cards) then
											pei_qian = math.ceil(v.bets[index] + v.bets[index]*1.5)
										else
											pei_qian = math.ceil(v.bets[index] + v.bets[index])
										end
										local s_tax = math.ceil(pei_qian * self.room_:get_room_tax())
										if s_tax == 1 then s_tax = 0 end -- 一分就不收税
										local s_win = pei_qian - s_tax
	

										v:add_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = s_win}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_POINT21")) 
										self:user_log_money(v,s_type,s_old_money,s_tax, s_win,self.table_game_id)

										v.win_money = v.win_money + s_win
										v.taxes = v.taxes + s_tax
										
										zhuang_win = zhuang_win - pei_qian
									elseif self:is_black_jack(zhuang_cards) or zhuang_point > cards_p then
										local pei_qian = 0
										if self:is_black_jack(zhuang_cards) then
											pei_qian = math.ceil(v.bets[index]*1.5)
											local need_cost_more = pei_qian - v.bets[index]
											local s_type = 1
											local s_old_money = v:get_money()
											local s_tax = 0

											v:cost_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = need_cost_more}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_POINT21")) 
											self:user_log_money(v,s_type,s_old_money,s_tax,-need_cost_more,self.table_game_id)

										else
											pei_qian = v.bets[index]
										end
										zhuang_win = zhuang_win + pei_qian
										v.win_money = v.win_money - pei_qian
										v.taxes = v.taxes + 0
									elseif zhuang_point == cards_p then
										local s_type = 2
										local s_old_money = v:get_money()
										local s_tax = math.ceil(v.bets[index] * self.room_:get_room_tax())
										if s_tax == 1 then s_tax = 0 end -- 一分就不收税
										s_tax = 0 --没有输赢不收税
										local s_win = v.bets[index] - s_tax
	

										v:add_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = s_win}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_POINT21")) 
										self:user_log_money(v,s_type,s_old_money,s_tax, s_win,self.table_game_id)

										v.win_money = v.win_money + 0
										v.taxes = v.taxes + 0
									end
								end
							end
						end
						if v.mai_bao_xian then
							if zhuang_point == 21 and #zhuang_cards == 2 then
								local s_type = 2
								local s_old_money = v:get_money()
								local s_tax = 0 --不收税
								local s_win = v.mai_bao_xian_val * 2
		

								v:add_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = s_win}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_POINT21")) 
								self:user_log_money(v,s_type,s_old_money,s_tax, s_win,self.table_game_id)

								v.win_money = v.win_money + s_win
								v.taxes = v.taxes + 0
							end
						end	
					end
				end
			end
			if zhuang_win > 0 then
				local s_type = 2
				local s_old_money = zhuang_player:get_money()
				local s_tax = math.ceil(zhuang_win*self.room_:get_room_tax())
				if s_tax == 1 then s_tax = 0 end -- 一分就不收税

				zhuang_player:add_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = zhuang_win - s_tax}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_POINT21")) 
				self:user_log_money(zhuang_player,s_type,s_old_money,s_tax, zhuang_win - s_tax,self.table_game_id)

				zhuang_player.win_money = zhuang_win - s_tax
				zhuang_player.taxes = s_tax
			elseif zhuang_win < 0 then
				local s_type = 1
				local s_old_money = zhuang_player:get_money()
				local s_tax = 0

				zhuang_player:cost_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = -zhuang_win}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_POINT21")) 
				self:user_log_money(zhuang_player,s_type,s_old_money,s_tax,zhuang_win,self.table_game_id)

				zhuang_player.win_money = zhuang_win
				zhuang_player.taxes = s_tax
			end
			for k,v in pairs(self.player_list_) do
				if v then
					self:send_finish_msg_to_player(v,false)
				end
			end
			for k,v in pairs(self.game_log.players) do
				if v and self.player_list_[k] and self.ready_list_[k] then
					v.win_money = self.player_list_[k].win_money
					v.taxes = self.player_list_[k].taxes
				end
			end
			self.game_log.zhuang = self.zhuang_chair_id
            self.game_log.end_game_time = os.time()
			self.game_log.cell_score = self.cell_score_
            local s_log = lua_to_json(self.game_log)
			log_info("running_game_log")
			log_info(s_log)
	        self:write_game_log_to_mysql(self.game_log.table_game_id,self.def_game_name,s_log,self.game_log.start_game_time,self.game_log.end_game_time)
            self:update_state(FSM_S.GAME_CLOSE)
        else
            log_info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end
    elseif self.cur_state_FSM == FSM_S.GAME_CLOSE then
        if event_table.type == FSM_E.UPDATE then
			self.do_logic_update = false
            self:clear_ready()
            local room_limit = self.room_:get_room_limit()
            for i,v in ipairs(self.player_list_) do
                if v then
                    if v.deposit or v.need_eixt then
                        v:forced_exit()
                    else
                        v:check_forced_exit(room_limit)
                    end
                end
            end
			for i,v in ipairs(self.player_list_) do
                if v and v.is_android then
                    v:game_msg("GAME_CLOSE")
                end
            end
            for i,v in pairs (self.player_list_) do
                if ly_game_switch == 1 then--游戏将进入维护阶段
                    if  v then 
                        post_msg_to_client_pb(v, "SC_GameMaintain", {
                        result = GAME_SERVER_RESULT_MAINTAIN,
                        first_game_type = def_first_game_type,
						second_game_type = def_second_game_type,
                        })
                        v:forced_exit()
                    end
                end
            end
        else
            log_info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end
    elseif self.cur_state_FSM == FSM_S.GAME_ERR then
        if event_table.type == FSM_E.UPDATE then  
            self:update_state(FSM_S.GAME_CLOSE)
        else
            log_info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end
    elseif self.cur_state_FSM >= FSM_S.GAME_IDLE_HEAD then
    end
    return true
end
