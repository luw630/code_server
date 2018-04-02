-- 梭哈逻辑
local pb = require "extern/lib/lib_pb"
require "game_script/virtual/virtual_table"
require "game_script/virtual/virtual_player"
require "game_script/all_game/sangong_enum"
local sangong_robot = require "game_script/all_game/sangong_robot"
local sangong_game = require "game_script/all_game/sangong_game"
local print_r = require "extern/lib//lib_print_r"
--local timermgr = require "game_helper/timermng"
local ACTION_TIME_OUT = 5
local READY_TIME_OUT = 15
function post_msg_to_client_pb_sh(player,op_name,msg)
	if player.is_android then
		player:game_msg(op_name,msg)
	else
		post_msg_to_client_pb(player,op_name,msg)
	end
    if msg then
        --print("post_msg_to_client_pb : " .. op_name)
    end
end
sangong_table = virtual_table:new()
function sangong_table:broadcast_msg_to_client_sh(op_name,msg)
	for i,v in ipairs(self.player_list_) do
		if v then
			post_msg_to_client_pb_sh(v, op_name, msg)
		end
	end
    if msg then
        --print("broadcast_msg_to_client : " .. op_name)
    end
end
function sangong_table:init(room, table_id, chair_count)
	virtual_table.init(self, room, table_id, chair_count)
	--self.timermgr = timermgr:new()
	
	self.cards = {}
	sangong_game = sangong_game:new()
	sangong_game:init()
	-- for i = 1, 52 do
	-- 	self.cards[#self.cards + 1] = i
	-- end
	self.cur_state_FSM = ETableState.TABLE_STATE_WAIT_MIN_PLAYER
	self.system_zhuang = true
	self.zhuang_chair_id = chair_count
	self.timerid = 0
	self.ready_time = 0
	self.stateevent = {}
	self.chair = {}
	for i=1,5 do
		self.chair[i] = {}
		self.chair[i].status = ESeatState.SEAT_STATE_NO_PLAYER
	end
	
	--self.stateevent[ETableState.TABLE_STATE_GAME_START] = sangong_table.gamestart
	--self.stateevent[ETableState.TABLE_STATE_BET] = sangong_table.playerbet
	--self.stateevent[ETableState.TABLE_STATE_GETBANKER] = sangong_table.playergetbanker
	-- self.stateevent[ETableState.TABLE_STATE_ONE_GAME_START] = sangong_table.onegamestart
	-- self.stateevent[ETableState.TABLE_STATE_ONE_GAME_END] = sangong_table.onegameend
	-- self.stateevent[ETableState.TABLE_STATE_ONE_GAME_REAL_END] = sangong_table.onegamerealend
	-- self.stateevent[ETableState.TABLE_STATE_GAME_END] = sangong_table.gameend
	-- self.stateevent[ETableState.TABLE_STATE_CONTINUE] = sangong_table.continue
	-- self.stateevent[ETableState.TABLE_STATE_CONTINUE_AND_STANDUP] = sangong_table.continue_and_standup
	-- self.stateevent[ETableState.TABLE_STATE_CONTINUE_AND_LEAVE] = sangong_table.continue_and_leave
end
function sangong_table:load_lua_cfg()
	local funtemp = load(self.room_.lua_cfg_)
	local sangong_config = funtemp()
	self.max_call = sangong_config.max_call --加注最高限制为max_call倍底注
	self.bet_base = sangong_config.bet_base
end
-- 检查是否可取消准备
function sangong_table:check_cancel_ready(player, is_offline)
	return not self:isPlay(player, is_offline)
end
function sangong_table:isPlay( ... )
	return self.cur_state_FSM ~= ETableState.TABLE_STATE_WAIT_MIN_PLAYER
end
function sangong_table.run(sangongtable)
	local f = nil
	while true do
		if sangongtable.cur_state_FSM == ETableState.TABLE_STATE_WAIT_MIN_PLAYER then
			break
		end
		f = sangongtable.stateevent[sangongtable.cur_state_FSM]
		if f == nil then
			break
		end
		f(sangongtable)
	end
end
function sangong_table:playergetbanker(  ) --抢庄
	--log_info("cur_turn_banker = "..self.cur_turn_banker)
	local player = self:get_player(self.cur_turn_banker)

	if player and self.ready_list_[self.cur_turn_banker] then
		if not(player.is_android) then
			player.timerid = self:addtimer(ACTION_TIME_OUT,sangong_table.getbanker_timeout,player)
		end
		self:broadcast_msg_to_client_sh("SC_SanGong_AskBanker",{chair_id=player.chair_id})
		self.cur_state_FSM = ETableState.TABLE_STATE_WAITBANKER
	else
		self.cur_turn_banker = self.cur_turn_banker + 1
		if self.cur_turn_banker > 5 then 
			self:choosebanker()
			return
		end
		self:playergetbanker()
		return
	end
	
end
function sangong_table:getbanker_timeout(player)
	if player.is_android then
		return
	end
	local msg = {}
	msg.brequest = false 
	self:player_getbanker(player,msg)
end
function sangong_table:player_getbanker(player,msg )
	player.get_banker = false
	if msg ~= nil then
		player.get_banker = msg.brequest
	end
	if not(player.is_android) then
		self:deltimer(player.timerid)
	end
	self:broadcast_msg_to_client_sh("SC_SanGong_TalkBanker",{chair_id=player.chair_id,brequest=player.get_banker})
	self.cur_turn_banker = self.cur_turn_banker + 1
	if self.cur_turn_banker > 5 then
		self:choosebanker()
		return
	end 
	self.cur_state_FSM = ETableState.TABLE_STATE_GETBANKER
	self:playergetbanker()
end

function sangong_table:choosebanker( ... )
	local pbankerlist = {}
	for k,v in pairs(self.player_list_) do
		if v and  self.ready_list_[k] and v.get_banker == true then
			table.insert(pbankerlist,v.chair_id)
		end
	end

	if #pbankerlist  == 0 then
		for k,v in pairs(self.player_list_) do	
			if v and self.ready_list_[k]  then
				table.insert(pbankerlist,v.chair_id)
			end
		end
	end

	math.randomseed(os.clock())
	local ran = math.random(1,#pbankerlist)
	self.zhuang = pbankerlist[ran]
	local getbankercount = #pbankerlist
	
	pbankerlist = nil
	self:broadcast_msg_to_client_sh("SC_SanGong_Banker",{chair_id=self.zhuang})
	self.timerid = self:addtimer(getbankercount,sangong_table.postbanker,nil)
end
function sangong_table:playerbet( )
	--print("sangong_table:playerbet")
	local player = self:get_player(self.cur_turn_banker)
	--if player ~= nil and  self.chair[self.cur_turn_banker].status == ESeatState.SEAT_STATE_PLAYING  then
		if player and  self.ready_list_[self.cur_turn_banker] and self.zhuang ~= self.cur_turn_banker  then
			if not(player.is_android) then
				player.timerid = self:addtimer(ACTION_TIME_OUT,sangong_table.playerbet_timeout,player)
			end
			self:broadcast_msg_to_client_sh("SC_SanGong_AskBet",{Bets=self.bet_base,chair_id=player.chair_id})
			self.cur_state_FSM = ETableState.TABLE_STATE_WAITBET
		else
			self.cur_turn_banker = self.cur_turn_banker + 1
			if self.cur_turn_banker >5 then 
					self.cur_state_FSM = ETableState.TABLE_STATE_GAME_START  --状态切换,游戏开始
					self:gamestart()
				return
			end
			self:playerbet()
			return
		end	
	--self.timermgr:set_timer(10,self:playerbet_timeout,msg)
end
function sangong_table:playerbet_timeout(player )
	if player.is_android then
		return
	end
	local msg = {}
	msg.target = self.bet_base[1] 
	self:player_bet(player,msg)
end
function sangong_table:player_bet( player,msg )
	if not msg then
		return
	end
	
	if msg.target <= 0 then
		log_error("player_bet "..msg.target)
	end
	player.bets = msg.target
	self:broadcast_msg_to_client_sh("SC_SanGong_Bet",{chair_id=player.chair_id,target=player.bets})
	self.cur_turn_banker = self.cur_turn_banker + 1
	if not(player.is_android) then
		self:deltimer(player.timerid)
	end
	if self.cur_turn_banker == self.zhuang then
		self.cur_turn_banker = self.cur_turn_banker + 1
	end
	if self.cur_turn_banker > 5 then
		self.cur_state_FSM = ETableState.TABLE_STATE_GAME_START  --状态切换,游戏开始
		self:gamestart()
		return
	end 
	self.cur_state_FSM = ETableState.TABLE_STATE_BET
	--sangong_table.run(self)
	self:playerbet()
end

function sangong_table:postbanker(  )
	--self:broadcast_msg_to_client_sh("SC_SanGong_Banker",{chair_id=self.zhuang})
	self.cur_state_FSM = ETableState.TABLE_STATE_BET  --状态切换
	self.cur_turn_banker = 1
	if self.zhuang == self.cur_turn_banker then
		self.cur_turn_banker = self.cur_turn_banker + 1
	end
	self:playerbet()
end
	-- body

function sangong_table:postresult(  )
	self:compare()
	local SPostResult = {}
	SPostResult.pb_splayerinfo={}
	for k,v in pairs(self.player_list_) do	
		--if v then
		if v and self.ready_list_[k]  then
			local tplayer = {}
			tplayer.cards = v.cards
			tplayer.chair_id = v.chair_id
			tplayer.add_total = 0
			tplayer.cur_round_add = v.bets
			tplayer.is_win 		= v.win_money > 0
			tplayer.guid = v.guid
			tplayer.win_money = v.win_money
			tplayer.nick = v.ip_area
			tplayer.icon = v:get_avatar()
			tplayer.Bets = self.bet_base
			tplayer.taxes = 0
			tplayer.lefttime = 0
			
			local s_old_money = v:get_money()
			local s_type = 1
			local s_tax = 0
			if v.win_money > 0 then
				s_type = 2
				s_tax = math.ceil(v.win_money*self.room_:get_room_tax())
				if s_tax == 1 then s_tax = 0 end
				tplayer.taxes = s_tax
				v:add_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money =v.win_money-s_tax}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_SANGONG")) 
				self:user_log_money(v,s_type,s_old_money,s_tax, v.win_money-s_tax,self.table_game_id)
			elseif v.win_money < 0 then
				v:cost_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money =-v.win_money}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_SANGONG")) 
				self:user_log_money(v,s_type,s_old_money,0, v.win_money,self.table_game_id)
			end


			self:update_player_bet_total(math.abs(v.win_money-s_tax),v)
			self:update_player_last_recharge_game_total(v)
			
			tplayer.gold = v:get_money()
			self.chair[k].status = ESeatState.SEAT_STATE_WAIT_START   
			self.game_log.players[v.chair_id].cards = v.cards
			self.game_log.players[v.chair_id].bets = v.bets
			self.game_log.players[v.chair_id].win_money = v.win_money
			self.game_log.players[v.chair_id].taxes = tplayer.taxes 

			table.insert(SPostResult.pb_splayerinfo,tplayer)

		end
	end
	self:clear_ready()
	self.cur_state_FSM = ETableState.TABLE_STATE_WAIT_MIN_PLAYER
	self:broadcast_msg_to_client_sh("SC_SanGong_PostResult",SPostResult)

	for k,v in pairs(self.player_list_) do	
		if v and not(v.is_android) then
			v.timerid = self:addtimer(READY_TIME_OUT,sangong_table.ready_timeout,v)
		end
	end

	self.game_log.end_game_time = os.time()
	local s_log = lua_to_json(self.game_log)
	log_info("running_game_log")
	log_info(s_log)
	self:write_game_log_to_mysql(self.game_log.table_game_id,self.def_game_name,s_log,self.game_log.start_game_time,self.game_log.end_game_time)
	local room_limit = self.room_:get_room_limit()
	for i,v in pairs(self.player_list_) do
	    if v then
	        if v.is_online == false or v.isTrusteeship then
	              v:forced_exit()
	        else
	              v:check_forced_exit(room_limit)
	        end
	    end
	end

	if self:get_player_count() > 4 and self:get_real_player_count() >= 2 then
		for i,v in ipairs(self.player_list_) do
			if v and v.is_android then
				v:forced_exit()
				break		
			end
		end
	end
	if not ly_use_robot then
		for i,v in ipairs(self.player_list_) do
			if v and v.is_android then
				v:forced_exit()	
			end
		end
	end
	self:check_game_maintain()
	log_info("postresult .. "..self.cur_state_FSM)
end

function sangong_table:check_table( tbcards )
	local objnum = 0
	if tbcards == nil then
		return objnum
	else
		for k,v in pairs(tbcards) do
			objnum = objnum + 1
		end
	end
	return objnum
end

function sangong_table:gamestart( )
	local spostcards = {}
	spostcards.pb_cards = {}
	sangong_game:initialization()
	sangong_game:generatecards(self)

	for i,v in pairs(self.player_list_) do	
		if v and self.ready_list_[i] then
			local pcards = {}
			v.cards = sangong_game:getcards(v.is_android,v.guid,v.cards)
			pcards.cards =  v.cards
			table.insert(spostcards.pb_cards,pcards)
		end
	end
	self:broadcast_msg_to_client_sh("SC_SanGong_PostCard",spostcards)
	self.timerid = self:addtimer(self:get_ready_count()*1.5,sangong_table.postresult,nil)
end
function sangong_table:get_ready_count()
	local count = 0
	for i,v in pairs(self.player_list_) do	
		if v and self.ready_list_[i] then
			count = count + 1
		end
	end
	return count
end
function sangong_table:start(player_count,is_test)
	log_info("sangong_table start ...")
	self.player_count = player_count
	self.timer = {}
	--sangong_game:initialization()
	--sangong_game:generatecards(player_count)
	self.last_action_change_time_stamp = os.time() 
	self.zhuang = self.zhuang or math.random(1,player_count)
	self.is_allin_state = false
	self.allin_money = 0
	self.cur_game_round = 0
	self.cur_turn_banker = 1 
	
	local readycount = 0
	for k,v in pairs(self.player_list_) do
		if v then
			v.is_dead = false
			v.declare_this_round = false
			v.need_eixt = false
			v.cards = {}
			v.add_total = 0
			v.cur_round_add = 0
			v.last_round_add = 0
			v.agreen = false
			v.is_win = false
			v.win_point = 0
			v.get_banker = false
			v.bets = 0
			v.win_money = 0
			v.is_online = true
			v.isTrusteeship = false
			self.chair[k].status = ESeatState.SEAT_STATE_PLAYING
			readycount = readycount + 1
			if v.timerid ~= nil then
				self:deltimer(v.timerid)
			end
		end
	end
	--log_info("readycount "..readycount)
	self.do_logic_update = true
	self.is_test = is_test
	if not is_test then
		self.table_game_id = self:get_now_game_id()
	end
	self.game_log = {
		private_room = self.private_room and true or false,
        table_game_id = self.table_game_id,
        start_game_time = os.time(),
        zhuang = self.zhuang,
        max_call = self.max_call,
        action_table = {},
        players = {},
    }
	for k,v in pairs(self.player_list_) do
		if v then
			local tmp_p = {account = v.account,nickname = v.nickname,ip_area = v.ip_area,
			guid = v.guid,chair_id = v.chair_id,money_old = v.pb_base_info.money}
			self.game_log.players[v.chair_id] = tmp_p
			self.game_log.players[v.chair_id].cards = {}
		end
	end
	if self.private_room then
		self.game_runtimes=self.game_runtimes+1
	end
	self.cur_state_FSM = ETableState.TABLE_STATE_GETBANKER
	local SC_GameStart = {}
	SC_GameStart.pb_splayerinfo = {}
	for k,v in pairs(self.player_list_) do
		if v then
			local tplayer = {}
			tplayer.cards = v.cards
			tplayer.chair_id = v.chair_id
			tplayer.add_total = v.add_total
			tplayer.cur_round_add = v.cur_round_add
			tplayer.is_win 		= false
			tplayer.guid = v.guid
			tplayer.win_money = 0
			tplayer.nick = v.ip_area
			tplayer.icon = v:get_avatar()
			tplayer.gold = v:get_money()
			tplayer.is_getbanker = v.get_banker
			tplayer.Bets = self.bet_base
			tplayer.taxes = 0
			tplayer.lefttime = 0
			table.insert(SC_GameStart.pb_splayerinfo,tplayer)		
		end
	end
	SC_GameStart.breconnect = false
	SC_GameStart.tablestatus = self.cur_state_FSM
	SC_GameStart.playerturn = self.cur_turn_banker
	SC_GameStart.zhuangchair = self.zhuang
	SC_GameStart.waittime = ACTION_TIME_OUT
	self:broadcast_msg_to_client_sh("SC_SanGong_GameStart",SC_GameStart)
	self:playergetbanker()
end
function sangong_table:addtimer(delay_seconds,func,arg)
	
    local act = {}
    act.dead_line = os.time() + delay_seconds
    act.execute =func
    act.arg = arg
    act.timerid = #self.timer + 1
    self.timer[act.timerid] = act
	return act.timerid
end
function sangong_table:deltimer(timerid) 
	--print("sangong_table:deltimer "..timerid)
	
	for k,v in pairs(self.timer) do
		if v.timerid == timerid then
			v.dead_line = 0
			break
		end
	end
end

function sangong_table:setTrusteeship(player,flag)
	player.isTrusteeship = flag
end
function sangong_table:gettimepass(timerid)
	if self.timer ~= nil then
		for k,v in pairs(self.timer) do
			if v.timerid == timerid then
				if v.dead_line >= os.time() then
					return (v.dead_line - os.time())
				else
					return 0
				end
				break
			end
		end
	end
	return 0
end
-- 检查是否可准备   
function sangong_table:check_ready(player)
	if self:isPlay() then
		self:send_data_to_enter_player(player,false)
	end
	return not self:isPlay()
end
function sangong_table:compare(  )
	local SanGong_Player_Info = {}
	local zhuang = self:get_player(self.zhuang)
	if zhuang then
		for k,v in pairs(self.player_list_) do
			if v and v.chair_id ~= self.zhuang then
				if self.ready_list_[k] then
					local iswin,ptype,psum = sangong_game:compare(zhuang.cards,v.cards,zhuang.guid,v.guid)
					local zhuangpoint = 0
					if iswin then
						zhuangpoint = zhuangpoint + sangong_game:sangongpoint(ptype,psum)
						v.win_point = v.win_point - sangong_game:sangongpoint(ptype,psum)
					else
						zhuangpoint = zhuangpoint - sangong_game:sangongpoint(ptype,psum)
						v.win_point = v.win_point + sangong_game:sangongpoint(ptype,psum)
					end
					zhuang.win_money = zhuang.win_money + zhuangpoint * v.bets
					v.win_money = v.win_point * v.bets
				end
			end
		end	
	end

end

local starttick = os.time()
function sangong_table:tick()
	if self.do_logic_update then
		
		local dead_list = {}
		for k,v in pairs(self.timer) do
			if os.time() > v.dead_line and v.dead_line > 0 then
				v.execute(self,v.arg)
				dead_list[#dead_list + 1] = k
			elseif v.dead_line == 0 then
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
                   
                    local iRet = virtual_table:onNotifyReadyPlayerMaintain(v)
                end
            end
        end
	end
	 if ly_use_robot then
	 	ly_robot_mgr.check_table(self)
	 end

	 -- if self.cur_state_FSM == ETableState.TABLE_STATE_WAIT_MIN_PLAYER then
	 -- 	if os.time() - self.ready_time > 15 then
	 -- 		local n = 0
		-- 	for i, p in ipairs(self.player_list_) do
		-- 		if p then
		-- 			if self.ready_list_[p.chair_id] ~= true then
		-- 				--print("player stand up "..p.guid)
		-- 				p:forced_exit()
		-- 			else
		-- 				n = n + 1
		-- 			end
		-- 		end
		-- 	end
			
	 -- 	end
	 -- end


	for _,v in ipairs(self.player_list_) do		
		if v and v.is_android then
			v:tick()
		end
	end



--test print playercount
	-- if os.time() - starttick > 3 and self:get_player_count() > 0 then
	-- 	starttick = os.time()
	-- 	log_info("sangongtable player_count "..self:get_player_count())
	-- end


end
function sangong_table:safe_event(...)
end
function sangong_table:playeroffline( player )
	player.is_online = false
	player.isTrusteeship = true
	if self:isPlay() then
		return
	end
	--print("sangong_table:playeroffline")
	virtual_table.playeroffline(self,player)
	player:forced_exit()
	self.chair[player.chair_id].status = ESeatState.SEAT_STATE_ESCAPE
end
function sangong_table:notify_offline(player)
	player.is_online = false
	player.isTrusteeship = true
	if self:isPlay() then
		return
	end
	self.room_:player_exit_room(player)
	player:forced_exit()
end
function sangong_table:reconnect(player)
    player.deposit = false
    player.is_online = true
end
-- function sangong_table:player_stand_up(player,is_offline)
-- 	player.is_online = false
-- 	if self:isPlay() then
-- 		return
-- 	end
-- 	log_info("sangong_table:player_stand_up")
-- 	virtual_table.player_stand_up(self,player,is_offline)
-- end
--请求玩家数据
function sangong_table:reconnection_client_msg(player)
	--log_info("player Reconnection : ".. player.chair_id)
	player.is_online = true
	player.isTrusteeship = false
	virtual_table.reconnection_client_msg(self,player)
    self:send_data_to_enter_player(player,true)
end
function sangong_table:send_data_to_enter_player(player,is_reconnect)
    local SC_GameStart = {}
	SC_GameStart.pb_splayerinfo = {}
	for k,v in pairs(self.player_list_) do
		--if v then
		if v and self.ready_list_[k] then
			local tplayer = {}
			tplayer.cards = v.cards or {}
			tplayer.chair_id = v.chair_id
			tplayer.add_total = v.add_total
			tplayer.cur_round_add = v.bets
			tplayer.is_win 		= false
			tplayer.guid = v.guid
			tplayer.win_money = v.win_money
			tplayer.nick = v.ip_area
			tplayer.icon = v:get_avatar()
			tplayer.gold = v:get_money()
			tplayer.is_getbanker = v.get_banker or false
			tplayer.Bets = self.bet_base
			tplayer.taxes = 0
			tplayer.lefttime = self:gettimepass(v.timerid)
			table.insert(SC_GameStart.pb_splayerinfo,tplayer)		
		end
	end
	SC_GameStart.breconnect = is_reconnect
	SC_GameStart.tablestatus = self.cur_state_FSM
	SC_GameStart.playerturn = self.cur_turn_banker or 1
	SC_GameStart.zhuangchair = self.zhuang or 1
	SC_GameStart.waittime = ACTION_TIME_OUT
	
	post_msg_to_client_pb_sh(player,"SC_SanGong_GameStart",SC_GameStart)
--	log_info("send SC_SanGong_GameStart")
end
function sangong_table:send_finish_msg_to_player(player,is_reconnect)
	local msg = {pb_players = {}}
	for k,v in pairs(self.player_list_) do
		if v then
			local tplayer = {}
			tplayer.chair_id = v.chair_id
			tplayer.tiles = self:get_cur_round_cards(v,true)
			tplayer.is_win 		= v.chair_id == self.win_player_chair_id
			tplayer.is_give_up = v.is_dead
			if tplayer.is_win then
				tplayer.win_money = self.win_money
				tplayer.taxes = self.win_taxes
			end
			tplayer.nick = v.ip_area
			tplayer.icon = v:get_avatar()
			tplayer.gold = v:get_money()
			table.insert(msg.pb_players,tplayer)
		end
	end
	post_msg_to_client_pb_sh(player,"SC_sangong_Game_Finish",msg)
end
function sangong_table:private_init()
	self.game_runtimes = 0
end
function sangong_table:destroy_private_room()
	local __checkrlt = self.game_runtimes>0 and true or false
	virtual_table.destroy_private_room(__checkrlt)
	self:update_state(FSM_S.GAME_PRI_CLOSE)
end
function sangong_table:live_count()
	local live_count = 0
	for k,v in pairs(self.player_list_) do
		if v and not v.is_dead then
			live_count = live_count + 1
		end
	end
	return live_count
end


function sangong_table:ready_timeout(player)
	for i,v in ipairs(self.player_list_) do		
		if v and v.guid == player.guid then
			if not(self.ready_list_[i]) then
				player:forced_exit()
				log_info(string.format("ready_timeout forced_exit %d",player.guid))
				break
			end
		end
	end
end

-- function sangong_table:ready(player)
-- 	virtual_table.ready(self,player)
-- 	if self.ready_list_[player.chair_id] then
-- 		self.chair[player.chair_id].status = ESeatState.SEAT_STATE_READY
-- 	end
-- end
