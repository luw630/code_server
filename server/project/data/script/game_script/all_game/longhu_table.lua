local pb = require "extern/lib/lib_pb"
require "game_script/virtual/virtual_table"
require "extern/lib/lib_table"
require "game_script/all_game/longhu_enum"
local print_r = require "extern/lib//lib_print_r"
local ITEM_PRICE_TYPE_GOLD = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")
local longhu_robot =require "game_script/all_game/longhu_robot"
longhu_table = virtual_table:new()
local longhu_game = nil
local longhu =  require "game_script/all_game/longhu_game"
local MAX_COUNT = 20
local MAX_PLAYER_LIST = 100
local MAX_PLAYER_COUNT = 50
local MAX_TABLE_BET = 5000000


local test_time = 0

function post_msg_to_client_pb_sh(player,op_name,msg)
	if player.is_android then
		player:game_msg(op_name,msg)
	else
		if op_name == "SC_LongHuPostResult" then
			if player.is_ontable == false then
				post_msg_to_client_pb(player,"SC_Gamefinish",{
					money = player.pb_base_info.money})
				--player:forced_exit()
			end
		end
		post_msg_to_client_pb(player,op_name,msg)
	end
    if msg then
        --print("post_msg_to_client_pb : " .. op_name)
    end
end

function longhu_table:broadcast_msg_to_client_sh(op_name,msg)
	for i,v in ipairs(self.player_list_) do
		if v then
			post_msg_to_client_pb_sh(v, op_name, msg)
		end
	end
    if msg then
        --print("broadcast_msg_to_client : " .. op_name)
    end
end



function longhu_table:init(room, table_id, chair_count)
	virtual_table.init(self, room, table_id, chair_count)
	self.table_status = LONGHUTABLESTATE.TABLE_WAIT_BETS
	self.status = LONGHUSTATE.TABLE_STSTE_INIT
	self.last_tick_time =0
	self.time0_ = os.time()
	self.all_bets = {}
	self.all_Player_bets = {}
	self.cards={}
	self.card_type = {}
	self.all_player = {}
	self.playerrecord = {}
	self.currentturn = 0
	self.table_turn = 0
	self.turn_list = {}   --牌局记录
	self.luck_star = {}
	self.table_bets = 0
	self.robot_num = 0
	self.player_betinfo = {}  
	longhu_game = longhu:new()
	longhu_game:init()


	self.cheat_table= {}
	self.cheat_table.cheatmode = 0			--作弊开关
	self.cheat_table.robot_betcolor = 0		--投注颜色
	self.cheat_table.robot_cheatmoney = 0	--机器人作弊投注金额
	self.cheat_table.change_card = 0		--红黑交换
	self.cheat_table.robot_betfinish = 0	--机器人下注结束

	self.system_hhdz = {
		money = 0,
		s_change_money = 0,
		s_old_money = 0,
		s_tax = 0,
	}

end

function longhu_table:initialization(  )
	longhu_game:initialization()
	for i=LONGHUBET.BET_DRAGON_WIN,LONGHUBET.BET_DRAW_WIN do
		self.all_bets[i] = 0
		self.all_Player_bets[i] = 0
	end
	
	self.time0_ = os.time() + LONGHUTABLETIME.TABLE_BETS_TIME
	log_info("start initialization time = "..self.time0_)


	self.table_status = LONGHUTABLESTATE.TABLE_WAIT_BETS
	self.status = LONGHUSTATE.TABLE_STSTE_INIT
	self.currentturn = self.currentturn + 1
	self.table_turn = self.table_turn + 1
	self.table_bets = 0
	self.table_game_id = self:get_now_game_id()


	if self.all_player[self.currentturn] == nil then
		self.all_player[self.currentturn] = {}
	end



	local list = self.all_player[self.currentturn]
	for k,v in pairs(self.player_list_) do
		if v and self.ready_list_[k] then
			self:init_player(v,true)
			list[v.guid]  = {}
			list[v.guid].player_bet = 0
			list[v.guid].win_lost = 0


			local findplayer = false
			for i,j in ipairs(self.playerrecord) do
				if j.guid == v.guid then
					findplayer = true
					break
				end
			end

			if findplayer == false then
				local recordplayer = {}
				recordplayer.player_bet = 0
				recordplayer.win_money = 0
				recordplayer.header_icon = v:get_avatar()
				recordplayer.ip_area = v.ip_area
				recordplayer.player_money = v:get_money()
				recordplayer.win_lost = 0
				recordplayer.guid = v.guid
				recordplayer.chair_id = v.chair_id
				table.insert(self.playerrecord,recordplayer)
			end

		end
	end

	
	self.cards[1] = {}
	self.cards[2] = {}
	self.card_type[1] = LONGHUTYPE.HONGHEI_GAOPAI
	self.card_type[2] = LONGHUTYPE.HONGHEI_GAOPAI
	self.table_init = 1


	local startmsg = {
	start_waittime = LONGHUTABLETIME.TABLE_BETS_TIME,
	playerbets = self.bet_base,
	allbets = self.all_bets,
	table_status = self.table_status,
}
	self:broadcast_msg_to_client_sh("SC_LongHuStart",startmsg)
	--print_r(startmsg)
	log_info("longhu_table:initialization")


	self.game_log = {
		private_room = self.private_room and true or false,
        table_game_id = self.table_game_id,
        start_game_time = os.time(),
        zhuang = 1,
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

	self.system_hhdz.s_old_money = self.system_hhdz.money
	self.system_hhdz.s_change_money = 0
	self.system_hhdz.s_tax = 0

	self.cheat_table = nil
	self.cheat_table= {}
	self.cheat_table.cheatmode = 0			--作弊开关
	self.cheat_table.robot_betcolor = 0		--投注颜色
	self.cheat_table.robot_cheatmoney = 0	--机器人作弊投注金额
	self.cheat_table.change_card = 0		--红黑交换
	self.cheat_table.robot_betfinish = 0	--机器人下注结束
		
	if ly_robot_storage < 0 or win_random_int(1,100) > 95  then
		self.cheat_table.cheatmode  = 1
		log_info("cheatmode on")
	end
	longhu_game:generatecards()

end

function longhu_table:init_player( player ,isinit)
	player.is_ontable = true
	if player.is_init == nil or isinit == true then
		player.is_dead = false
		player.is_win = false
		player.win_point = 0
		player.win_money = 0
		player.is_online = true
		player.isTrusteeship = false
		player.tax = 0
		player.bets = {}
		player.is_init = true
		player.all_bets = 0
		player.win_lost = 0
		for i=LONGHUBET.BET_DRAGON_WIN,LONGHUBET.BET_DRAW_WIN do
			player.bets[i] = 0
		end
	end
end


function longhu_table:getplayerbets( player )
	local allbets = 0
	for i=LONGHUBET.BET_DRAGON_WIN,LONGHUBET.BET_DRAW_WIN do
		allbets = allbets + player.bets[i] 
	end
	return allbets
end

function longhu_table:player_bet(player,money_,bettype)
	if money_ <= 0 or bettype < LONGHUBET.BET_DRAGON_WIN or bettype > LONGHUBET.BET_DRAW_WIN  then
		post_msg_to_client_pb_sh(player,"SC_LongHuPlayerBet",{playerbet_result=2,allbets=self.all_bets})
		return
	end

	if player:get_money() <  money_ then
		post_msg_to_client_pb_sh(player,"SC_LongHuPlayerBet",{playerbet_result=2,allbets=self.all_bets})
		return
	end

	if self.table_bets + money_ > MAX_TABLE_BET then
		post_msg_to_client_pb_sh(player,"SC_LongHuPlayerBet",{playerbet_result=2,allbets=self.all_bets})
		return
	end
	self.table_bets = self.table_bets + money_


	if self.player_betinfo[player.chair_id] == nil then
		self.player_betinfo[player.chair_id] = {}
	end

	local betinfo = self.player_betinfo[player.chair_id]
	if betinfo[bettype] == nil then
		betinfo[bettype] = 0
	end
	betinfo[bettype] = betinfo[bettype] + money_


	local list = self.all_player[self.currentturn]
	if list[player.guid] == nil then
		list[player.guid] = {}
		list[player.guid].player_bet = 0
		list[player.guid].win_lost = 0
	end
	list[player.guid].player_bet = 	list[player.guid].player_bet + money_


	local findplayer = false
	for i,j in ipairs(self.playerrecord) do
		if j.guid == player.guid then
			j.player_bet = j.player_bet + money_
			findplayer = true
			break
		end
	end

	if player.is_init == nil then
		self:init_player(player)
	end
	if not player.bets then 
		player.bets = {0,0,0}
	end 

	if findplayer == false then
		local recordplayer = {}
		recordplayer.player_bet = money_
		recordplayer.win_money = 0
		recordplayer.header_icon = player:get_avatar()
		recordplayer.ip_area = player.ip_area
		recordplayer.player_money = player:get_money()
		recordplayer.win_lost = 0
		recordplayer.guid = player.guid
		recordplayer.chair_id = player.chair_id
		table.insert(self.playerrecord,recordplayer)
	end


	self:cost_money(player,{{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money =money_}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_LONGHU")) 
	--self:user_log_money(player,1,player:get_money(),0, -money_,self.table_game_id)

	player.bets[bettype] = player.bets[bettype] + money_
	self.all_bets[bettype] = self.all_bets[bettype] + money_

	-- self.system_hhdz = {
	-- 	money = 0,
	-- 	s_change_money = 0,
	-- 	s_old_money = 0,
	-- 	s_tax = 0,
	-- }

	if not(player.is_android) then
		self.all_Player_bets[bettype] = self.all_Player_bets[bettype] + money_
		self.system_hhdz.money = self.system_hhdz.money + money_
		self.system_hhdz.s_change_money = self.system_hhdz.s_change_money + money_
	end


	local hongheiplayerbet = {
		playerbet_result=1,
		allbets=self.all_bets,
		player_chairid=player.chair_id,
		playerbet = money_,
		playerbettype = bettype,
	}
	--post_msg_to_client_pb_sh(player,"SC_LongHuPlayerBet",hongheiplayerbet)	

	self:broadcast_msg_to_client_sh("SC_LongHuPlayerBet",hongheiplayerbet)
	--self:broadcast_msg_to_client_sh("SC_HongHeiAllBet",{allbets=self.all_bets})
	log_info("SC_LongHuPlayerBet type "..bettype)
	--print_r(self.all_bets)
end

function longhu_table:load_lua_cfg()
	local funtemp = load(self.room_.lua_cfg_)
	local hhdz_config = funtemp()
	self.bet_base = hhdz_config.bet_base
end



function longhu_table:post_cards(player)
	--longhu_game:generatecards()
	local postcard = {}
	postcard.result_waittime = self.time0_ - os.time()
	postcard.pb_card = {}
	if self.cheat_table.change_card > 0 then
		postcard.pb_card.red_cards = longhu_game:getcard(LONGHUBET.BET_TIGER_WIN)
		postcard.pb_card.black_cards = longhu_game:getcard(LONGHUBET.BET_DRAGON_WIN)
	else
		postcard.pb_card.red_cards = longhu_game:getcard(LONGHUBET.BET_DRAGON_WIN)
		postcard.pb_card.black_cards = longhu_game:getcard(LONGHUBET.BET_TIGER_WIN)
	end

	postcard.table_status = self.table_status

	if player ~= nil then
		post_msg_to_client_pb_sh(player,"SC_LongHuPostCard",postcard)
				
	else
		self:broadcast_msg_to_client_sh("SC_LongHuPostCard",postcard)
	end
	log_info("longhu_table:post_cards to  ")
	print_r(postcard.pb_card)
end

function longhu_table:post_result()
	local redcards 
	local blackcards 
	if self.cheat_table.change_card > 0 then
		redcards  = longhu_game:getcard(LONGHUBET.BET_TIGER_WIN)
		blackcards = longhu_game:getcard(LONGHUBET.BET_DRAGON_WIN)
	else
		redcards  = longhu_game:getcard(LONGHUBET.BET_DRAGON_WIN)
		blackcards = longhu_game:getcard(LONGHUBET.BET_TIGER_WIN)
	end
	self.game_log.redcards = redcards
	self.game_log.blackcards = blackcards

	local record = {}

	record.win_type = longhu_game:compare(redcards,blackcards)

	self.win_type = record.win_type

	record.turn = self.table_turn
	table.insert(self.turn_list,record)

	log_info("post_result  win_type "..record.win_type)
	
	local richlist = {}
	richlist.pb_richlist = {}

	local result = {}
	result.next_waittime = LONGHUTABLETIME.TABLE_RESULT_TIME
	result.table_status = self.table_status
	local list = self.all_player[self.currentturn]
	for k,v in pairs(self.player_list_) do
		if v and  self.ready_list_[k] and v.bets ~= nil then
			if not v.win_money then 
						v.win_money = 0
			end 

			for i=LONGHUBET.BET_DRAGON_WIN,LONGHUBET.BET_DRAW_WIN do
				if v.bets[i] > 0 then
					if i == self.win_type then
						v.win_money=math.floor(v.win_money + v.bets[i] * LONGHUMULTIPLE[i])
					end
				end
			end

			if self.win_type == LONGHUBET.BET_DRAW_WIN then --开平局需要退税
				for i=LONGHUBET.BET_DRAGON_WIN,LONGHUBET.BET_TIGER_WIN do
					if v.bets[i] > 0 then
						self:add_money(v,{{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = v.bets[i]},tax=0},  pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_LONGHU"))
					end
				end
			end

			-- self.system_hhdz = {
			-- 	money = 0,
			-- 	s_change_money = 0,
			-- 	s_old_money = 0,
			-- 	s_tax = 0,
			-- }

			local s_old_money = v:get_money()
			local s_type = 1
			result.tax = 0
			local curallbets =  v.bets[1] +v.bets[2] + v.bets[3]
			if v.win_money > 0 then
				if  curallbets >=  v.win_money  then --下注大于赢钱即输钱 不扣税
					result.tax = 0 
				else 
					result.tax = math.ceil((v.win_money -curallbets )*self.room_:get_room_tax()) --只扣赢钱部分的税
				end 	
				if result.tax == 1 then result.tax = 0 end
				result.tax = result.tax
				v.taxes = result.tax
				self:add_money(v,{{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = v.win_money-result.tax},tax=result.tax},  pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_LONGHU"))



				if not(v.is_android) then 
					if  curallbets >=  v.win_money  then --下注大于赢钱即输钱 
						-- v:add_lose_game_total() --记录玩家输的场次	
						--self:PlayerMoneyLog(v,s_type,s_old_money+curallbets,result.tax, v.win_money-result.tax-curallbets,self.table_game_id)
					else 
						s_type = 2
						--v:add_win_game_total()  --记录玩家赢的场次
						--self:PlayerMoneyLog(v,s_type,s_old_money+curallbets,result.tax, v.win_money-result.tax-curallbets,self.table_game_id)
					end 			
				end 
				--broadcast_world_marquee_win_money(v.nickname, def_first_game_type, v.win_money-result.tax)
			else 
				if curallbets>0  then --没下注的不计算
					--v:add_lose_game_total() --记录玩家输的场次	
				--self:PlayerMoneyLog(v,s_type,v:get_money()+curallbets,0, -curallbets,self.table_game_id)
				end 			
			end
			result.victory = v.win_money - self:getplayerbets(v)
			result.chair = v.chair_id
			result.money = v.win_money
			result.win_area = record.win_color
			result.win_type = record.win_type
			post_msg_to_client_pb_sh(v,"SC_LongHuPostResult",result)


			if not(v.is_android) and curallbets > 0  then
				 log_info("longhu_table:post_result to player ---------------"..v.guid)
				self.system_hhdz.s_change_money = 	self.system_hhdz.s_change_money - (v.win_money-result.tax)
				self.system_hhdz.money = 	self.system_hhdz.money - (v.win_money-result.tax)
				self.system_hhdz.s_tax = self.system_hhdz.s_tax + v.taxes
			end

			if result.victory > 0 then
				if list[v.guid] ~= nil then
					list[v.guid].win_lost = list[v.guid].win_lost + 1
				else
					log_info("list nil ?????>>>>>>>>>>"..v.guid)
				end
				
				for i,j in ipairs(self.playerrecord) do
					if j.guid == v.guid then
						j.player_money = v:get_money()
						j.win_lost = j.win_lost + 1
						j.win_money = v.win_money
						break
					end
				end
			else
				for i,j in ipairs(self.playerrecord) do
					if j.guid == v.guid then
						j.player_money = v:get_money()
						break
					end
				end
				
			end

-- 			//富豪榜前几名
-- message SC_HongHeiRichPlayer {
-- 	optional int32 chair = 1;		//椅子
-- 	optional int64 money = 2;		//钱
-- 	optional int64 tax = 3;		//税收		输玩家：-1
-- 	optional int32 victory = 4;	//输赢状态	1-赢； 2-输
-- }
			for m,n in ipairs(self.playerrecord) do
				if n.guid == v.guid  and m < 9 then
					local rich = {}
					rich.chair = v.chair_id
					rich.money = v:get_money()
					rich.tax = result.tax 
					rich.victory = result.victory
					table.insert(richlist.pb_richlist ,rich)
				end
			end
			--user_log_money(player,s_type,s_old_money,s_tax,s_change_money,s_id)
			local oldmoney = self.game_log.players[v.chair_id].money_old
			if self:getplayerbets(v) > 0 then
				if result.victory > 0 then
					self:user_log_money(v,2,oldmoney,result.tax, result.victory,self.table_game_id)
				else
					self:user_log_money(v,1,oldmoney,0, -self:getplayerbets(v),self.table_game_id)
				end
			end
		end
    end

    self:broadcast_msg_to_client_sh("SC_LongHuRichList",richlist)
    log_info("longhu_table:post_result")
    self:statistics_rank()
   -- self:table_rest()

	for k,v in pairs(self.player_list_) do
		if v and self.game_log.players[v.chair_id] then
			self.game_log.players[v.chair_id].money_new = v.pb_base_info.money
			self.game_log.players[v.chair_id].bets = v.bets
		end
	end

   	self.game_log.end_game_time = get_second_time()
   	if self:get_real_player_count() > 0 then
	   	local s_log = lua_to_json(self.game_log)
		self:write_game_log_to_mysql(self.game_log.table_game_id,self.def_game_name,s_log,self.game_log.start_game_time,self.game_log.end_game_time)
		if self.system_hhdz.s_change_money > 0 then
			virtual_table:user_log_money_user_nil(160, "system_hhdz",self.system_hhdz.money, "system_hhdz", 2,self.system_hhdz.s_old_money,self.system_hhdz.s_tax,self.system_hhdz.s_change_money,"system_hhdz","system_hhdz")
		else
			virtual_table:user_log_money_user_nil(160, "system_hhdz",self.system_hhdz.money, "system_hhdz", 1,self.system_hhdz.s_old_money,self.system_hhdz.s_tax,self.system_hhdz.s_change_money,"system_hhdz","system_hhdz")
		end
   	end
			-- self.system_hhdz = {
			-- 	money = 0,
			-- 	s_change_money = 0,
			-- 	s_old_money = 0,
			-- 	s_tax = 0,
			-- }
	--self:Save_Game_Log(self.gamelog.table_game_id, self.def_game_name, s_log, self.gamelog.start_game_time, self.gamelog.end_game_time)
	--virtual_table:user_log_money_user_nil(guid, phone_type,money, ip, s_type,s_old_money,s_tax,s_change_money,s_id,channel_id)

	
end


function longhu_table:statistics_rank( player )
	--log_info("all_player lenth = "..#self.all_player)
	if self.currentturn > MAX_COUNT  then
		if #self.all_player > MAX_COUNT then
			local listindex = #self.all_player - MAX_COUNT
			if self.all_player[listindex] ~= nil then
				for k,v in pairs(self.all_player[listindex]) do
					for i,j in ipairs(self.playerrecord) do
						if j.guid == k and self:isinplayerlist(j.guid) then
							j.player_bet = j.player_bet - v.player_bet
							j.win_lost = j.win_lost - v.win_lost
							if j.player_bet < 0 then
								j.player_bet = 0
							end

							if j.win_lost < 0 then
								j.win_lost = 0
							end
							break
						end
					end	
				end
			end
		end
	end 

	local honghpostrecord = {}
	honghpostrecord.pb_record={}

	if #self.turn_list > 200 then   --大于200局,删除80局数据
		for i=1,80 do
			self.turn_list[i] = nil
		end
		self:sort_gamerecord()
	end 

	local lastcolor = 0
	local row_element = 0
	local rownum = 0
	for i=#self.turn_list,1 ,-1 do
		if lastcolor == 0 then
			lastcolor = self.turn_list[i].win_color
			row_element = row_element + 1
			rownum = rownum + 1
		elseif lastcolor == self.turn_list[i].win_color then
			row_element = row_element + 1
			if row_element >= 6 then
				row_element = 0
				rownum = rownum + 1
			end
		else
			row_element = 0
			rownum = rownum + 1
		end
		lastcolor = self.turn_list[i].win_color
		if rownum <= MAX_COUNT then
			table.insert(honghpostrecord.pb_record,self.turn_list[i])
		else
			break
		end
	end
	table.sort(honghpostrecord.pb_record,function (a ,b )
		return a.turn < b.turn 
	end)

	self:broadcast_msg_to_client_sh("SC_LongHuGameRecord",honghpostrecord)
	--log_info("SC_HongHeiGameRecord")
	--print_r(honghpostrecord)



	local onlineplayer = {}
	onlineplayer.pb_onlinelist ={}
	local listplayer = self.playerrecord
	table.sort(listplayer,function(a,b)return a.win_lost > b.win_lost end)
	for i,v in ipairs(listplayer) do
		self.luck_star = v
		table.insert(onlineplayer.pb_onlinelist,v)
		break
	end

	table.sort(listplayer,function(a,b)return a.player_bet > b.player_bet end)
	local ranklist = {}
	local count = 1
	for i,v in ipairs(listplayer) do
		table.insert(onlineplayer.pb_onlinelist,v)
		if count >= 50 then
			break
		end
		count = count + 1
	end
	
	local ncount = 0
	if #onlineplayer.pb_onlinelist == 0 then
		for k,v in pairs(self.player_list_) do
			if v then
				local ponlinelist = 
				{
					header_icon = v:get_avatar(),
					ip_area = v.ip_area,
					player_money = v:get_money(),
					player_bet = 0,
					player_win = 0,
					player_rank = k,
					win_lost = 0,
					win_money = 0,
					guid = v.guid,
					chair_id = v.chair_id,
				}
				table.insert(onlineplayer.pb_onlinelist,ponlinelist)
				ncount = ncount + 1

				if ncount >= MAX_PLAYER_COUNT then
					break
				end
			end
		end	
	end
	--print_r(onlineplayer)
	if player ~= nil then
		post_msg_to_client_pb_sh(player,"SC_LongHuPlayerList",onlineplayer)
		return
	end
	self:broadcast_msg_to_client_sh("SC_LongHuPlayerList",onlineplayer)
end

function longhu_table:sort_gamerecord( ... )
	local xrecord = deepcopy(self.turn_list)
	self.turn_list = nil
	self.turn_list = {}
	for i,v in pairs(xrecord) do
		table.insert(self.turn_list,v)
	end
	table.sort(self.turn_list,function (a ,b )
		return a.turn < b.turn 
	end)
end

function longhu_table:isinplayerlist(playerguid )
	for i,v in ipairs(self.player_list_) do
		if v and self.ready_list_[i] then
			if v.guid == playerguid then
				return true
			end
		end
	end
	--log_info("players no in list "..playerguid)
	return false
end

function longhu_table:post_player_result(player)
	 player.win_money = player.win_money or 0  -- player.win_money 有时会报错为nil
	local result = {}
	result.next_waittime =  self.time0_ - os.time()
	result.tax = player.tax
	result.victory = player.win_money - self:getplayerbets(player)
	result.chair = player.chair_id
	result.money = player.win_money
	result.table_status = self.table_status
	result.win_area = self.win_color
	result.win_type = self.win_type
	post_msg_to_client_pb_sh(player,"SC_LongHuPostResult",result)
	log_info("longhu_table:post_player_result to player "..player.guid)		
  
end

	-- self.cheat_table= {}
	-- self.cheat_table.cheatmode = 0			--作弊开关
	-- self.cheat_table.robot_betcolor = 0		--投注颜色
	-- self.cheat_table.robot_cheatmoney = 0	--机器人作弊投注金额
	-- self.cheat_table.change_card = 0		--红黑交换

function longhu_table:cheatmode_bet()
	--longhu_game:generatecards()
	if self.cheat_table.cheatmode == 0 then
		return
	end

	if self.table_init == 0 then
		return
	end

	if self.cheat_table.robot_betfinish > 0 then
		return
	end

	if not ( ly_use_robot ) then
		return
	end

	if self.time0_ - os.time() <= 1 then  --2秒倒计时

		local redbets = self.all_Player_bets[LONGHUBET.BET_DRAGON_WIN]	--玩家投注
		local blackbets = self.all_Player_bets[LONGHUBET.BET_TIGER_WIN]

		if redbets == blackbets then
			return
		end

		local all_redbets = self.all_bets[LONGHUBET.BET_DRAGON_WIN]	--所有的投注
		local all_blackbets = self.all_bets[LONGHUBET.BET_TIGER_WIN]
		

		if redbets > blackbets then
			self.cheat_table.robot_cheatmoney = math.floor((redbets - blackbets) * 1.5 / self.robot_num/2)
			self.cheat_table.robot_betcolor = LONGHUBET.BET_TIGER_WIN
		elseif redbets < blackbets then
			self.cheat_table.robot_cheatmoney = math.floor((blackbets - redbets) * 1.5 / self.robot_num/2)
			self.cheat_table.robot_betcolor = LONGHUBET.BET_DRAGON_WIN
		end

		local redcards  = longhu_game:getcard(LONGHUBET.BET_DRAGON_WIN)
		local blackcards = longhu_game:getcard(LONGHUBET.BET_TIGER_WIN)
		local iswin,type1,type2 = longhu_game:compare(redcards,blackcards)
		if iswin == 1 and self.cheat_table.robot_betcolor == LONGHUBET.BET_DRAGON_WIN then
			return
		elseif iswin == 2 and  self.cheat_table.robot_betcolor == LONGHUBET.BET_TIGER_WIN then
			return
		end
		self.cheat_table.change_card = 1
		self.cheat_table.robot_betfinish = 1


		if self.cheat_table.robot_cheatmoney > 0 then
			if ly_use_robot then
				local robot_num = math.floor(self.robot_num/2) + 1
			 	for _,v in ipairs(self.player_list_) do		
					if v and v.is_android then
						v:robot_cheatbet(self.cheat_table.robot_betcolor,self.cheat_table.robot_cheatmoney)
						robot_num = robot_num - 1
						if robot_num == 0 then
							break
						end
						--log_info("robot_cheatmoney "..self.cheat_table.robot_cheatmoney)
					end
				end
			end
		end
	end 
end



function longhu_table:tick()
	if self.table_status == LONGHUTABLESTATE.TABLE_WAIT_BETS then
		if self.status == LONGHUSTATE.TABLE_STSTE_INIT then
			self:initialization()
			self.status = LONGHUSTATE.TABLE_STSTE_CARDS 
		end
		self:cheatmode_bet()
		--log_info("initialization time "..os.time().."	time0_	"..self.time0_)
		if os.time()- self.time0_ >= 0 then
			self.table_status = LONGHUTABLESTATE.TABLE_POST_CARDS
			self.time0_ = os.time() + LONGHUTABLETIME.TABLE_CARDS_TIME
		end
	elseif self.table_status ==  LONGHUTABLESTATE.TABLE_POST_CARDS then
		if self.status == LONGHUSTATE.TABLE_STSTE_CARDS then
			self.status = LONGHUSTATE.TABLE_STSTE_RESULE 
			self:post_cards()
		end
		
		if os.time()- self.time0_ >= 0 then
			self.table_status = LONGHUTABLESTATE.TABLE_POST_RESULT
			self.time0_ = os.time() + LONGHUTABLETIME.TABLE_RESULT_TIME
		end

	elseif self.table_status ==  LONGHUTABLESTATE.TABLE_POST_RESULT then
		if self.status == LONGHUSTATE.TABLE_STSTE_RESULE then
			self.status = LONGHUSTATE.TABLE_STSTE_REST
			self:post_result()
		end

		if os.time()- self.time0_ >= 0 then
			self.table_status = LONGHUTABLESTATE.TABLE_REST
			self.time0_ = os.time() + LONGHUTABLETIME.TABLE_REST_TIME
		end


	elseif self.table_status ==  LONGHUTABLESTATE.TABLE_REST then
		if self.status == LONGHUSTATE.TABLE_STSTE_REST then
			self.status = LONGHUSTATE.TABLE_STSTE_INIT
			self:table_rest()
		end

		if os.time()- self.time0_ >= 0 then
			self.table_status = LONGHUTABLESTATE.TABLE_WAIT_BETS
			self.time0_ = os.time() + LONGHUTABLETIME.TABLE_BETS_TIME
		end
	end


	if ly_use_robot then
	 	ly_robot_mgr.check_table(self)
	 	for _,v in ipairs(self.player_list_) do		
			if v and v.is_android then
				v:tick()
			end
		end
	end
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


function longhu_table:table_rest(player )
	log_info("table_rest time = "..(os.time()-test_time))
	test_time = os.time()

	for i,v in ipairs(self.player_list_) do
		if v then
			v.is_init = true
			self:init_player(v,true)
		end
	end

	local room_limit = self.room_:get_room_limit()
	for i,v in pairs(self.player_list_) do
	    if v then
	        if v.is_ontable == false or v.is_offline  then
	        	log_info("forced_exit player "..v.guid)
				self:remove_playerlist(v)
	             v:forced_exit()  
	        end
			if v:check_room_limit(room_limit) then
				self:remove_playerlist(v)
				v:forced_exit()
			end
			if v.is_android then
				v:game_msg("table_rest",{})
			end 
			  
	    end
	end
	self:broadcast_msg_to_client_sh("SC_LongHuRest",{rest_waittime=(self.time0_ - os.time())})


--release	memory
	if #self.all_player > MAX_PLAYER_LIST then
		local temptable = {}
		local all_player = self.all_player
		for i=#all_player-MAX_COUNT,#all_player do
			if all_player[i] ~= nil then
				table.insert(temptable,all_player[i])
			end
		end

		for i,j in ipairs(self.all_player) do
			for k,v in pairs(j) do
				v = nil 
			end
		end
		self.all_player = nil 
		self.all_player = {}
		self.all_player = deepcopy(temptable)
		self.currentturn = #self.all_player

		temptable = nil
	end

	for k,v in pairs(self.player_betinfo) do
		self.player_betinfo[k] = nil
	end

	
	self:check_game_maintain()
	self:next_game()
	self.table_init = 0

end

function longhu_table:isPlay(player)
	if player then 
		if self.table_status ~= LONGHUTABLESTATE.TABLE_REST then 
			if player.bets ~= nil then
				if self:getplayerbets(player) > 0 then
					return true
				end
			end
		end
	end
	return false
end

function longhu_table:reconnection_client_msg(player)
	log_info("player reconnection_client_msg : ".. player.guid)
	virtual_table.reconnection_client_msg(self,player)
	player.is_online = true
	player.is_ontable = true
	player.is_offline = false
	self:init_player(player)
    self:send_reconnect_player(player,true)
end


function longhu_table:notify_offline(player)
    if self:isPlay(player) then
		player.is_offline = true
		player.is_ontable = false
	else
		self:remove_playerlist(player)
		self:playeroffline(player)
		player:forced_exit()
    end
end




function longhu_table:reconnect(player)
    player.is_offline = false
end


function longhu_table:check_cancel_ready(player, is_offline)
	virtual_table.check_cancel_ready(self,player,is_offline)
	player:setStatus(is_offline)
	return not(self:isPlay(player))
end

-- 检查是否可准备   
function longhu_table:check_ready(player)
	self:init_player(player)
	self:send_reconnect_player(player,false)
	return not self:isPlay()
end

function longhu_table:send_reconnect_player(player,isreconnet )
	local reconnect = {}
	reconnect.playerbets = self.bet_base
	reconnect.allbets = self.all_bets
	reconnect.table_status = self.table_status
	reconnect.player_bet = 0
	reconnect.pb_card = {}
	reconnect.table_waittime =  self.time0_ - os.time()
	if self.table_status >  LONGHUTABLESTATE.TABLE_WAIT_BETS then
		reconnect.pb_card.red_cards = longhu_game:getcard(LONGHUBET.BET_DRAGON_WIN)
		reconnect.pb_card.black_cards =longhu_game:getcard(LONGHUBET.BET_TIGER_WIN)
	end

	if isreconnet then
		local list = self.all_player[self.currentturn]
		reconnect.player_bet =  list[player.guid].player_bet 
	end
	reconnect.pb_player_bet_info = {}
	for k,v in pairs(self.player_betinfo) do
		local pbbetinfo = {}
		pbbetinfo.chair = k
		pbbetinfo.bet_money={}
		for i,j in pairs(v) do
			if j > 0 then
				pbbetinfo.bet_money[i] = j
			end
		end
		table.insert(reconnect.pb_player_bet_info,pbbetinfo)
	end
	--print_r(reconnect.pb_player_bet_info)
	post_msg_to_client_pb_sh(player,"SC_LongHuReConnect",reconnect)

	if self.table_status >  LONGHUTABLESTATE.TABLE_POST_CARDS then
		self:post_player_result(player)
	end

	if isreconnet == false then
		local tmp_p = {account = player.account,nickname = player.nickname,ip_area = player.ip_area,
		guid = player.guid,chair_id = player.chair_id,money_old = player.pb_base_info.money}
		self.game_log.players[player.chair_id] = tmp_p
		self.game_log.players[player.chair_id].cards = {}
	end

end


function longhu_table:send_data_to_enter_player(player,isreconnet )
	if self.table_status == LONGHUTABLESTATE.TABLE_WAIT_BETS then
		local startmsg = {
			start_waittime = self.time0_  - os.time(),
			playerbets = self.bet_base,
			allbets = self.all_bets,
			table_status = self.table_status
		}
		post_msg_to_client_pb_sh(player,"SC_LongHuStart",startmsg)
		log_info("longhu_table:SC_LongHuStart to player "..player.guid)		
	elseif self.table_status ==  LONGHUTABLESTATE.TABLE_POST_CARDS then
		self:post_cards(player)
	elseif self.table_status ==  LONGHUTABLESTATE.TABLE_POST_RESULT then
		self:post_player_result(player)
	elseif self.table_status ==  LONGHUTABLESTATE.TABLE_REST then
		self:table_rest(player)
	end

end


function longhu_table:remove_playerlist( player )
	--for i,j in ipairs(self.playerrecord) do
	for k,v in pairs(self.all_player) do
		if v[player.guid] ~= nil then
			v[player.guid] = nil
		end
	end

	for i,j in ipairs(self.playerrecord) do
		if j.guid == player.guid then
			j = nil 
			table.remove(self.playerrecord,i)
			log_info("remove_playerlist "..player.guid)
			break
		end
	end	
end


function longhu_table:cost_money( player,price, opttype )
	log_info ("cost_money begin player :"..  player.guid)
	local money = player.pb_base_info.money
	local oldmoney = money
	local iRet = true
	for _, p in ipairs(price) do
	
		if p.money_type == pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD") then
			if p.money <= 0 or money < p.money then
				if p.money ~= 0 then
					log_error(string.format("cost_money error [%d] [%d] [%d]",player.guid,p.money,money))
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
			if not(player.is_android) then ly_robot_storage = ly_robot_storage + p.money end
		else
			log_error("cost_money  error  money_type " .. tostring(p.money_type))
		end
	end
	player.pb_base_info.money = money
	player.flag_base_info = true
	player:save()
	if not(player.is_android) then
		post_msg_to_mysql_pb("SD_Save_Storage", {
			game_id = def_game_id,
			storage = ly_robot_storage
		})
		
	end
	local money_ = money
	if not player.is_android then
		post_msg_to_client_pb_sh(player, "SC_NotifyMoney", {
			opt_type = opttype,
			money = money_,
			change_money = money_-oldmoney,
			})
	end
	post_msg_to_mysql_pb("SD_LogMoney", {
			guid = player.guid,
			old_money = oldmoney,
			new_money = player.pb_base_info.money,
			old_bank = player.pb_base_info.bank or 0,
			new_bank = player.pb_base_info.bank or 0,
			opt_type = opttype,
		})
	log_info(string.format("player %d cost_money  end, oldmoney[%d] new_money[%d]" , player.guid, oldmoney, player.pb_base_info.money))
	return iRet
end


function longhu_table:add_money( player,price, opttype )
	log_info ("add_money begin player :"..  player.guid)
	local money = player.pb_base_info.money
	local oldmoney = money
	
	for _, p in ipairs(price) do
		if p.money_type == pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD") then
			if p.money <= 0 then
				if p.money < 0 then
					log_error(string.format("add_money error [%d] [%d] [%d]",player.guid,p.money,money))
				end
				return false
			end
			if math.floor(p.money) < p.money then
				p.money = math.floor(p.money)
				log_error("add_money  p.money is float" .. tostring(p.money))
			end
			
			log_info(string.format("money = [%d] + [%d]" , money,p.money))
			money = money + p.money
			if not(player.is_android) then ly_robot_storage = ly_robot_storage - p.money end
		else
			log_error("add_money  error  money_type " .. tostring(p.money_type))
		end
	end
	
	player.pb_base_info.money = money
	player.flag_base_info = true
	player:save()
	if not(player.is_android) then
		post_msg_to_mysql_pb("SD_Save_Storage", {
			game_id = def_game_id,
			storage = ly_robot_storage
		})
		
	end
	local money_ = money
	if not player.is_android then
	post_msg_to_client_pb_sh(player, "SC_NotifyMoney", {
		opt_type = opttype,
		money = money_,
		change_money = money_-oldmoney,
		})
	end
	post_msg_to_mysql_pb("SD_LogMoney", {
			guid = player.guid,
			old_money = oldmoney,
			new_money = player.pb_base_info.money,
			old_bank = player.pb_base_info.bank or 0,
			new_bank = player.pb_base_info.bank or 0,
			opt_type = opttype,
		})

	log_info(string.format("player %d add_money end ,old money=%d , new money=%d ",player.guid,oldmoney,money_))
	return true
end


-- function longhu_table:player_stand_up(player, is_offline)

-- end