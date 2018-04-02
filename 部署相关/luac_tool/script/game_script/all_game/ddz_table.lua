local pb = require "extern/lib/lib_pb"
require "game_script/virtual/virtual_table"
require "game_script/handler_net"
local post_msg_to_client_pb = post_msg_to_client_pb
require "game_script/all_game/ddz_sf"
local print_table = require "extern/lib//lib_print_r"
local ddz_sf = ddz_sf
require "game_script/virtual/virtual_player"
local ddz_robot = require "game_script/all_game/ddz_robot"
local tabletools =  require "extern/lib/lib_tablex"
local offlinePunishment_flag = false

local LAND_PLAYER_COUNT = 3
local LAND_TIME_OUT_CARD = 15
local LAND_TIME_CALL_SCORE = 15
local LAND_TIME_HEAD_OUT_CARD = 15
local LAND_TIME_WAIT_OFFLINE = 30
local LAND_TIME_IP_CONTROL = 20
local LAND_IP_CONTROL_NUM = 20
local LAND_STATUS_FREE = 1
local LAND_STATUS_CALL = 2
local LAND_STATUS_PLAY = 3
local LAND_STATUS_PLAYOFFLINE = 4
local LAND_STATUS_DOUBLE = 5
local LAND_ESCAPE_SCORE_BASE = 10
local LAND_ESCAPE_SCORE_LESS = 10
local LAND_ESCAPE_SCORE_GREATER = 2
local FARMER_ESCAPE_SCORE_BASE = 10
local FARMER_ESCAPE_SCORE_LESS = 10
local FARMER_ESCAPE_SCORE_GREATER = 2
local LAND_TIME_OVER = 1000
local vote_time_ = 300 
local OPEN_STRAGE = 16


ddz_table = virtual_table:new()
math.randomseed(tostring(os.time()):reverse():sub(1, 6))
local def_second_game_type = def_second_game_type
local def_game_name = def_game_name
local def_private=99
function ddz_table:land_post_msg_to_client_pb(player, msg_name, msg)
	if player.is_android then
		player:game_msg(msg_name, msg)
	else
		post_msg_to_client_pb(player, msg_name, msg)
	end
end
function ddz_table:land_broadcast_msg_to_client(msg_name, msg)
	for i,v in ipairs(self.player_list_) do
		if v then
			self:land_post_msg_to_client_pb(v, msg_name, msg)
		end
	end
end
function ddz_table:init(room, table_id, chair_count)
	virtual_table.init(self, room, table_id, chair_count)	
	self.callsore_time = 0
	self.status = LAND_STATUS_FREE
	self.land_player_cards = {}
	for i = 1, chair_count do
		self.land_player_cards[i] = ddz_sf:new()
	end
	self.cards = {}
	self.cards_out_list = {}
	self.buxipai = false
	self.turn_round = 0
	self.shuffle_mode = 1
	
	local tmp_card = {}
	for i = 1, 54 do
		tmp_card[i] = i - 1
	end
	for i = 1, 54 do
		local x = win_random_int(1,#tmp_card)
		self.cards[#self.cards + 1] = tmp_card[x]
		table.remove(tmp_card,x)
	end


	for i = 1, 10 do
		local x = win_random_int(1,54)
		local y = win_random_int(1,54)
		if x ~= y then
			self.cards[x], self.cards[y] = self.cards[y], self.cards[x]
		end
	end

	self:clear_ready()
end
function ddz_table:check_ready(player)
	if self.status ~= LAND_STATUS_FREE then
		return false
	end
	if def_second_game_type==def_private then
		if player:get_money() < self.private_room_cell_money * 20 then
			self:land_post_msg_to_client_pb(player, "SC_ReadyFailed", {
				result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_READY_FAILED"), 
				money = self.private_room_cell_money * 20,
				})
			return false
		end
	end
	return true
end
function ddz_table:check_cancel_ready(player, is_offline)
	virtual_table.check_cancel_ready(self,player,is_offline)
	player:setStatus(is_offline)
	if is_offline then
		if  self.status ~= LAND_STATUS_FREE or def_second_game_type==def_private then
			self:playeroffline(player)
			return false
		end
	end	
	if def_second_game_type == 99 then
		if self.status == LAND_STATUS_FREE and player.chair_id ==  self.private_room_owner_chair_id and self.private_room ~= false then
    		self:dismiss()
    		return false
    	end
    	return false
	end
	return true
end
		-- cbPosition=rand()%(cbBufferCount-cbRandCount);
		-- cbCardBuffer[cbRandCount++]=cbCardData[cbPosition];
		-- cbCardData[cbPosition]=cbCardData[cbBufferCount-cbRandCount];
function ddz_table:randcardlist( ... )
	local cbCardData = {}
	for i=1,54 do
		table.insert(cbCardData,self.cards[i])
	end

	local cbRandCount = 0
	local cbPosition = 0
	while cbRandCount < 54 do
		cbPosition = (win_random_int(1,100000)%(54 - cbRandCount))
		self.cards[cbRandCount+1] = cbCardData[cbPosition+1]
		--log_info("randcardlist "..cbPosition.."  count "..cbRandCount)
		cbCardData[cbPosition+1]=cbCardData[54-cbRandCount]
		cbRandCount = cbRandCount + 1
	end

end

function ddz_table:shuffle()

	-- for i = 1, 512 do
	-- 	local x = win_random_int(1,54)
	-- 	local y = win_random_int(1,54)
	-- 	if x ~= y then
	-- 		self.cards[x], self.cards[y] = self.cards[y], self.cards[x]
	-- 	end
	--  end

	-- for i = 1, 2 do
	-- 	for j=1,54 do
	-- 		math.randomseed(os.time()+j*def_game_id)
	-- 		local x = math.random(1,54)
	-- 		--local x = win_random_int(1,54)
	-- 		if j ~= x then
	-- 			--log_info(x)
	-- 			self.cards[j],self.cards[x] = self.cards[x],self.cards[j]
	-- 		end
	-- 	end
	--  end

	 self:randcardlist()
	 -- local tempcard = {}
	 -- for i=1,17 do
	 -- 	table.insert(tempcard,self.cards[i])
	 -- end
	 -- local three_count = ddz_sf:getAllThreeCard(tempcard)
	 -- log_info("three_count "..three_count)

	self.shuffle_count = self.shuffle_count or 0
	self.shuffle_count = self.shuffle_count + 1
	
	local all_is_real_player = true 
	for k,v in pairs(self.player_list_) do
		if v and v.is_android then
			all_is_real_player = false
			break	
		end
	end
	if all_is_real_player then 
		self.buxipai = true 
	else
		self.buxipai = false 
	end

	--一直开启不洗牌
	self.buxipai = true
	--一直开启不洗牌
	--低倍场暂时不开
	if def_game_id == 20 or def_game_id == 21  then
		self.buxipai = false
	end
	--低倍场暂时不开

	if self.buxipai and #self.cards_out_list > 0 and self.shuffle_count < 6 then
		local c = self.cards_out_list
		local t_card = {}
		t_card[1] = {c[1],c[2],c[3],c[4],c[5],  	c[16],c[17],c[18],c[19],c[20],	c[31],c[32],c[33],c[34],c[35],	c[46],c[47],}
		t_card[2] = {c[6],c[7],c[8],c[9],c[10],		c[21],c[22],c[23],c[24],c[25],	c[36],c[37],c[38],c[39],c[40],	c[48],c[49],}
		t_card[3] = {c[11],c[12],c[13],c[14],c[15],	c[26],c[27],c[28],c[29],c[30],	c[41],c[42],c[43],c[44],c[45],	c[50],c[51],}
		t_card[4] = {c[52],c[53],c[54]}

		for i = 1, 3 do
			local tr = win_random_int(1,3)
			for j = 1, 5 do
				t_card[1][j + (i-1)*5],t_card[tr][j + (i-1)*5] = t_card[tr][j + (i-1)*5],t_card[1][j + (i-1)*5]
			end
		end

		self.cards = {}
		for k,v in pairs(t_card) do
			for k1,v1 in pairs(v) do
				table.insert(self.cards,v1)
			end
		end
	else
		self.shuffle_count = 0
	end
	self.cards_out_list = {}
	self.valid_card_idx = math.random(51)
end
function ddz_table:load_lua_cfg()
	local fucT = load(self.room_.lua_cfg_)
	local land_config = fucT()
	if land_config then
		if def_second_game_type==def_private then
			self.GameLimitCdTime = 10
		else
			if land_config.GameLimitCdTime then
				self.GameLimitCdTime = land_config.GameLimitCdTime
			end
		end
	end
end
function ddz_table:start()
	virtual_table.start(self)
	if def_second_game_type == 99 then
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
	self.gamelog.start_game_time = get_second_time()
	self:shuffle()
	self.first_turn = math.floor((self.valid_card_idx-1)/17)+1
	self.callpoints_log = {
		start_time = get_second_time(),
		first_turn = self.first_turn,
		player_cards = {},
		callpoints_process = {},
		land_card = string.format("%d %d %d",self.cards[52], self.cards[53], self.cards[54]),
	}
	local msg = {
		valid_card_chair_id = self.valid_card_idx,
		valid_card = self.cards[self.valid_card_idx],
	}
	
	local GAME_START_msg = {wCurrentUser = self.first_turn,cbHandCard = {}}
	
	local chair_id_cards = {}
	local dapai_playernum = 0
	local cur = 0
	for i,v in ipairs(self.player_list_) do
		if v then
			if v.ddz_dapai_times ~= nil and v.ddz_dapai_times < 3  and (def_game_id == 20 or def_game_id == 21) then
				dapai_playernum = dapai_playernum + 1
			end
			v.ddz_in_table = true
			chair_id_cards[i] = {}
			

			for j = 1, 17 do
			 	table.insert(chair_id_cards[i], self.cards[i+3*(j-1)])
			end	
			-- for j = cur+1, cur+17 do
			-- 	table.insert(chair_id_cards[i], self.cards[j])
			-- end
			-- cur = cur + 17

			-- for j = 1, 6 do
			-- 	if j < 6 then
			-- 		table.insert(chair_id_cards[i], self.cards[i+9*(j-1)+2*(i-1)])
			-- 		table.insert(chair_id_cards[i], self.cards[i+9*(j-1)+1+2*(i-1)])
			-- 		table.insert(chair_id_cards[i], self.cards[i+9*(j-1)+2+2*(i-1)])
			-- 	else
			-- 		table.insert(chair_id_cards[i], self.cards[i+9*(j-1)+1*(i-1)])
			-- 		table.insert(chair_id_cards[i], self.cards[i+9*(j-1)+1+1*(i-1)])
			-- 	end
			-- end
			table.sort(chair_id_cards[i], function(a, b) return a < b end)
		end
	end
	if ly_use_robot then
		local function move_cards(self_card,card_list,card_val_list)
			for _,card_val in pairs(card_val_list) do
				for i,v in pairs(card_list) do
					local b_find_card = false
					for ii,vv in pairs(v) do
						if card_val == vv then
							for iii,vvv in ipairs(self_card) do
								local not_in_card_val_list = true
								for i4,v4 in pairs(card_val_list) do
									if v4 == vvv then not_in_card_val_list = false end
								end
								if not_in_card_val_list then
									self_card[iii],v[ii] = v[ii],self_card[iii]
									table.sort(self_card, function(a, b) return a < b end)
									break
								end
							end
							b_find_card = true
							break
						end
					end
					if b_find_card then break end
				end
			end
			for i,v in pairs(card_list) do
				table.sort(v, function(a, b) return a < b end)
			end
		end
		local function produce_big_card_non(chair_id)
		end
		local function produce_big_card(chair_id)
			local big_card = {40,41,42,43,   44,45,46,47,   48,49,50,51,   52,53}
			local card_pro = {20,30,40,50,   20,30,40,100,   20,20,50,100,   40,100}
			for k,cv in ipairs(big_card) do
				if math.random(1,100) < card_pro[k] then
					move_cards(chair_id_cards[chair_id],chair_id_cards,{cv})
				end
			end
			local lian_list = {7,8}
			local lian_pro  = {40,30}
			for k,v in pairs(lian_list) do
				local lian_begin = math.random(3,10-(v-5))
				if math.random(1,100) < lian_pro[k] then
					lian_begin = lian_begin - 3
					local t_card_list = {}
					for i=1,v do
						local t_card = lian_begin*4 + math.random(0,3)
						for _,p_card in pairs(chair_id_cards[chair_id]) do
							if math.floor(p_card/4) == math.floor(t_card/4) then
								t_card = p_card
								break
							end
						end
						table.insert(t_card_list,t_card)
						lian_begin = lian_begin + 1
					end
					move_cards(chair_id_cards[chair_id],chair_id_cards,t_card_list)
					break
				end
			end
		end
		local function produce_big_card_01(chair_id)
			--0-3    4-7   8-11   12-15   16-19   20-23  24-27  28-31  32-35
			-- 3      4      5      6       7       8      9      10     J
			--							Q				K			  A				2			 w 				7
			local big_card_list = {  { 36,37,38,39,   40,41,42,43,   44,45,46,47,   48,49,50,51,   52,53,	16,17,18,19},
										--	Q				K			  A				2			 w 			3
									 { 36,37,38,39,   40,41,42,43,   44,45,46,47,   48,49,50,51,   52,53,	0,1,2,3},	
									--	Q				K			  A				2			 w 				3		 9
									 { 36,37,38,39,   40,41,42,43,   44,45,46,47,   48,49,50,51,   52,53,	0,1,2,3,  24,25,26,27}	
									}
				--						Q				K			  A				2			 w 				7
			local card_pro_list = {  {100,100,0,0,	 20,20,0,0,   	0,0,0,100,     0,0,0,100,   100,100,	100,100,50,40},
									--	Q					K			  	A				2		  w 				3
									{100,100,100,0,  	0,0,100,100,   0,0,100,100,    0,0,100,100,   0,100,		0,100,100,100},
									--	Q					K			  	A				2		  w 				3				9
									{100,100,100,0,  	0,0,100,100,   0,0,100,100,    0,0,100,100,   0,100,		0,100,100,100,  0,100,100,100}
									}
			local random_index = math.random(#big_card_list)
			local big_card = big_card_list[random_index]
			local card_pro = card_pro_list[random_index]
			for k,cv in ipairs(big_card) do
				if math.random(1,100) < card_pro[k] then
					move_cards(chair_id_cards[chair_id],chair_id_cards,{cv})
				end
			end
			local lian_list = {7,8}
			local lian_pro  = {0,0}
			for k,v in pairs(lian_list) do
				local lian_begin = math.random(3,10-(v-5))
				if math.random(1,100) < lian_pro[k] then
					lian_begin = lian_begin - 3
					local t_card_list = {}
					for i=1,v do
						local t_card = lian_begin*4 + math.random(0,3)
						for _,p_card in pairs(chair_id_cards[chair_id]) do
							if math.floor(p_card/4) == math.floor(t_card/4) then
								t_card = p_card
								break
							end
						end
						table.insert(t_card_list,t_card)
						lian_begin = lian_begin + 1
					end
					move_cards(chair_id_cards[chair_id],chair_id_cards,t_card_list)
					break
				end
			end
		end
		
		if dapai_playernum > 0 then
			for i,v in ipairs(self.player_list_) do
				if v and not v.is_android and v.ddz_dapai_times ~= nil and v.ddz_dapai_times < 3 then
					produce_big_card(i)
					v.ddz_dapai_times = v.ddz_dapai_times + 1
					on_redis_ddzdapai(v,3,v.ddz_dapai_times)
					log_info("ddz_dapai_times produce_big_card  "..v.guid.."times "..v.ddz_dapai_times)
					break
				end
			end
		else
			if ly_robot_storage < 0 or (ly_robot_smart_lv > 0 and (math.random(1,100) <= ly_robot_smart_lv)) then
				local need_open_strage = false
				for i,v in ipairs(self.player_list_) do
					if v and (not v.is_android) and ((v:get_money() + v:get_bank()) > OPEN_STRAGE*100) then
						need_open_strage = true	
					end
				end

				if def_game_id ~= 20 or need_open_strage then --低倍场暂时不开库存控制，书不了多少钱
					local big_list = {}
					for i,v in ipairs(self.player_list_) do
						if v and v.is_android then
							big_list[#big_list + 1] = i
						end
					end
					if #big_list > 0 then
						produce_big_card_01(big_list[math.random(#big_list)])
					end
				end
			elseif ly_robot_storage > 0 and ly_robot_smart_lv < 0 then
				for i,v in ipairs(self.player_list_) do
					if v and not v.is_android then
						produce_big_card(i)
						break
					end
				end
			end
		end

	end
	local heimingdan_chair = {}
	local lucky_chair = {}
	for i,v in ipairs(self.player_list_) do
		if v  then 
			v.is_heimingdan = false
			for ii,vv in pairs(ly_black_list) do
				if vv== v.guid then 
					v.is_heimingdan = true
					table.insert(heimingdan_chair,i)
				end
			end
			if not (v.is_heimingdan) then
				table.insert(lucky_chair,i)
			end
		end
	end 


	local blackcount = #heimingdan_chair
	local bigcard = {}

	if dapai_playernum == 0 then
		if blackcount < 3 then
			if blackcount == 1 then
				self:collectbig(chair_id_cards[heimingdan_chair[1]],bigcard)
				if #bigcard > 0 then
					table.sort(bigcard,function(t1,t2)return t1 < t2 end)
					while #bigcard > 0 do
						for i,v in ipairs(lucky_chair) do
							local scard = self:collectsmall(chair_id_cards[v],bigcard[1])
							table.remove(bigcard,1)
							self:insertsmall(chair_id_cards[heimingdan_chair[1]],scard)	
							if #bigcard == 0 then
								break
							end
						end	
					end
				end
				self:swap_cards(chair_id_cards[heimingdan_chair[1]],chair_id_cards[lucky_chair[1]])
				local xran = math.random(1,#lucky_chair)
				self.first_turn= lucky_chair[xran]
			elseif blackcount == 2 then
				self:collectbig(chair_id_cards[heimingdan_chair[1]],bigcard)
				local big_num1 = #bigcard
				self:collectbig(chair_id_cards[heimingdan_chair[2]],bigcard)
				local big_num2 = #bigcard - big_num1
				if #bigcard > 0 then
					table.sort(bigcard,function(t1,t2)return t1 < t2 end)
					while #bigcard > 0 do
						for i=1,big_num1 do
							local scard = self:collectsmall(chair_id_cards[lucky_chair[1]],bigcard[1])
							if self:insertsmall(chair_id_cards[heimingdan_chair[1]],scard) then
								table.remove(bigcard,1)
							end
						end

						for i=1,big_num2 do
							local scard = self:collectsmall(chair_id_cards[lucky_chair[1]],bigcard[1])
							if self:insertsmall(chair_id_cards[heimingdan_chair[2]],scard) then
								table.remove(bigcard,1)
							end
						end	
					end
				end
				self:swap_cards(chair_id_cards[heimingdan_chair[1]],chair_id_cards[lucky_chair[1]])
				self:swap_cards(chair_id_cards[heimingdan_chair[2]],chair_id_cards[lucky_chair[1]])
				self.first_turn= lucky_chair[1] 
			end
		end
	end






--[[
	local littel_card_pro = {
		50,50,50,50,--3
		50,50,50,50,--4
		25,25,25,25,--5
		25,25,25,25,--6
		10,10,10,10,--7
		50,50,50,50,--8
		50,50,50,50,--9
		30,30,30,30,--10
		25,25,25,25,--j
		10,10,10,10,--q
		25,25,25,25,--k
		25,25,25,25,--a
		10,10,20,30,--2
		10,10--wang
	}
	local t_card = {}
	for i = 1, 54 do
		t_card[i] = i - 1
	end
	for i = 1, 54 do
		local rnum = math.random(i,54)
		t_card[i],t_card[rnum] = t_card[rnum],t_card[i]
	end
	for i = 1, 54 do
		self.cards[i] = t_card[i]
	end

	local little = 2--math.random(1,2)
	local little_card = {{},{}}
	local big_card = {{},{}}
	if little == 1 then
		for k,v in pairs(t_card) do
			local rnum = math.random(1,100)
			if #little_card[1] < 17 then
				if rnum < littel_card_pro[v+1] then
					little_card[1][#little_card[1] + 1] = v
					t_card[k] = false
				end
			end
			if t_card[k] and #big_card[1] < 17 then
				if rnum < (littel_card_pro[v+1] + (100 - littel_card_pro[v+1])/2) then
					big_card[1][#big_card[1] + 1] = v
					t_card[k] = false
				end
			end
			if t_card[k] and #big_card[2] < 17 then
				big_card[2][#big_card[2] + 1] = v
				t_card[k] = false
			end
		end
	elseif little == 2 then
		for k,v in pairs(t_card) do
			local rnum = math.random(1,100)
			if #little_card[1] < 17 then
				if rnum < littel_card_pro[v+1] then
					little_card[1][#little_card[1] + 1] = v
					t_card[k] = false
				end
			end
			if t_card[k] and #little_card[2] < 17 then
				if rnum < (littel_card_pro[v+1]*2) then
					little_card[2][#little_card[2] + 1] = v
					t_card[k] = false
				end
			end
			if t_card[k] and #big_card[1] < 17 then
				big_card[1][#big_card[1] + 1] = v
				t_card[k] = false
			end
		end
	end

	chair_id_cards[1] = little_card[1]
	chair_id_cards[2] = little_card[2]
	chair_id_cards[3] = big_card[1]
]]


	
	for i,v in ipairs(self.player_list_) do
		if v then
			v.outTime = 0
			v.isTrusteeship = false 
			v.is_double = nil
			self.land_player_cards[v.chair_id]:init(chair_id_cards[i])
			msg.cards = chair_id_cards[i]
			msg.first_turn =  self.first_turn
			GAME_START_msg.cbHandCard[i] = chair_id_cards[i]
			self:land_post_msg_to_client_pb(v, "SC_LandStart", msg)
			local player_card = {
				chair_id = v.chair_id,
				guid = v.guid,
				cards = table.concat(msg.cards, ','),
			}
			table.insert(self.callpoints_log.player_cards,player_card)
		end
	end


	
	GAME_START_msg.landcards = {self.cards[52], self.cards[53], self.cards[54]}
	GAME_START_msg.wCurrentUser = self.first_turn
	for i,v in ipairs(self.player_list_) do
		if v and v.is_android then
			v:game_msg("GAME_START", GAME_START_msg)
		end
	end
	self.cur_turn = self.first_turn
	self.cur_call_score = 0
	self.cur_call_score_chair_id = 0
	self.status = LAND_STATUS_CALL
	local notify = {
		cur_chair_id = self.cur_turn,
		call_chair_id = cur_chair_id,
		call_score = 0,
		}
	self:land_broadcast_msg_to_client("SC_LandCallScore", notify)
	self.time0_ = get_second_time()
	if self.private_room then
		self.game_runtimes=self.game_runtimes+1
	end
end

function ddz_table:bomb_detect(cards_b )
	table.sort(cards_b,function(t1,t2)return t1 < t2 end)
	local bomb = {}
	for i=1,#cards_b do
		local j = 0
		while j < 49 do
			if cards_b[i] == j then
				if i + 3 <= #cards_b then
					if cards_b[i]+1 == cards_b[i+1] and cards_b[i+1]+1 == cards_b[i+2] and cards_b[i+2]+1 == cards_b[i+3] then
						table.insert(bomb,i)
					end
				end
			end
			j = j + 4
		end	
	end

	return bomb
end

function ddz_table:swap_cards(cards_b,cards_w )
	local bomb_cards = self:bomb_detect(cards_b)
	while true  do
		if #bomb_cards > 0 then
			local x = win_random_int(1,8)
			for i,v in ipairs(bomb_cards) do
				cards_b[v],cards_w[x] =cards_w[x],cards_b[v] 
			end
		else
			break
		end
		bomb_cards = self:bomb_detect(cards_b)
	end
end


function ddz_table:collectbig( cards,colleccards)
	table.sort(cards,function(t1,t2)return t1 > t2 end)
	for k,v in ipairs(cards) do
		if v > 43 then
			table.insert(colleccards,v)
			cards[k] = -1
		else
			break
		end
	end
	return 
end

function ddz_table:collectsmall( cards,bigcard)
	local soucecard 
	table.sort(cards,function(t1,t2)return t1 < t2 end)
	local x = win_random_int(1,8)
	soucecard,cards[x] = cards[x],bigcard
	return soucecard
end

function ddz_table:insertsmall(cards,smallcard)
	for k,v in pairs(cards) do
		if v == -1 then
			cards[k] = smallcard
			return true
		end
	end
	return false
end


function ddz_table:send_land_cards(player)
	log_info("send_land_cards")
	--self:startsaveInfo()
	for k,v in ipairs(self.player_list_) do
		if not v then
			log_error("ddz_table:send_land_cards(player)   player false")
		end
	end
	self.flag_land = self.cur_call_score_chair_id
	self.flag_chuntian = true
	self.flag_fanchuntian = true
	self.time_outcard_ = LAND_TIME_HEAD_OUT_CARD
	self.cur_turn = self.cur_call_score_chair_id
	local cards_ = {self.cards[52], self.cards[53], self.cards[54]}
	self.landcards = cards_
	self.land_player_cards[self.cur_call_score_chair_id]:add_cards(cards_)
	self.last_out_cards = nil
	self.Already_Out_Cards = {}
	local msg = {
		land_chair_id = self.first_turn,
		call_score = self.cur_call_score,
		cards = cards_,
		}
	self:land_broadcast_msg_to_client("SC_LandInfo", msg)
	if def_second_game_type==def_private and self.privateRules[5].allow_double==1 then
		self:status_double_finish()
	else
		self.status = LAND_STATUS_DOUBLE
		self.time0_ = get_second_time()
		for i,v in ipairs(self.player_list_) do
			if v and v.chair_id == self.first_turn then
				v.is_double = false
				break
			end
		end
	end

	player.first_land = 1
	for k,v in pairs(self.player_list_) do
		if v and  self.ready_list_[k]  then
			if v.guid ~= player.guid then
				v.first_land = 0
			end
		end
	end

	for k,v in pairs(self.player_list_) do
		if v and  self.ready_list_[k]  then
			log_info("player_first_land = "..v.first_land.." guid  "..v.guid)
		end
	end


end
function ddz_table:status_double_finish()
	self.status = LAND_STATUS_PLAY
	self.time0_ = curtime
	local msg = {
		land_chair_id = self.first_turn
		}
	self:land_broadcast_msg_to_client("SC_LandCallDoubleFinish", msg)
	self:startGame()
end
function ddz_table:call_double(player,is_double)
	if self.status ~= LAND_STATUS_DOUBLE or self.first_turn == player.chair_id then
		return
	end
	player.is_double = is_double
	local notify = {
		call_chair_id = player.chair_id,
		is_double = 1
	}
	if is_double then notify.is_double = 2 end
	self:land_broadcast_msg_to_client("SC_LandCallDouble", notify)
	local all_is_done = true
	for i,v in ipairs(self.player_list_) do
		if v and v.is_double == nil then
			all_is_done = false
			break
		end
	end
	if all_is_done then self:status_double_finish()	end
end
function ddz_table:startGame( ... )
	self.table_game_id = self:get_now_game_id()
	self:next_game()	
	self.time0_ = get_second_time()
	self.start_time = self.time0_
	table.insert(self.gamelog.CallPoints,self.callpoints_log)
	self.gamelog.landid = self.flag_land
	self.gamelog.land_cards = string.format("%s",table.concat(self.land_player_cards[self.flag_land].cards_,","))
	self.gamelog.table_game_id = self.table_game_id
	self.gamelog.start_game_time = self.time0_
	for i,v in ipairs(self.player_list_) do
		if v then
			local t_guid = v.guid or 0
			local t_room_id = v.room_id or 0
			local t_table_id = v.table_id or 0
		end
	end
end
function ddz_table:setTrusteeship(player,flag)
	player.TrusteeshipTimes = 0
	player.isTrusteeship = not player.isTrusteeship
	if player.isTrusteeship then 
		if self.cur_turn == player.chair_id then
			self:trusteeship(player)
		end
		if flag == true then
			player.finishOutGame = true
		end
	else
		player.finishOutGame = false
	end
	local msg = {
		chair_id = player.chair_id,
		isTrusteeship = player.isTrusteeship,
		}
	self:land_broadcast_msg_to_client("SC_LandTrusteeship", msg)
end

function ddz_table:call_score(player, callscore)
	if self.status ~= LAND_STATUS_CALL then
		return
	end
	if player.chair_id ~= self.cur_turn then
		return
	end
	if callscore < 0 or callscore > 3 then
		return
	end
	if callscore > 0 and callscore <= self.cur_call_score then
		return
	end

	--log_info("function ddz_table:call_score(player, callscore)  " .. callscore.." chair_id "..player.chair_id)
	local call_log = {
		chair_id = player.chair_id,
		callscore = callscore,
		calltimes = self.callsore_time + 1,
	}	
	table.insert(self.callpoints_log.callpoints_process,call_log)
	if callscore == 3 then
		local notify = {
			cur_chair_id = 0,
			call_chair_id = player.chair_id,
			call_score = callscore,
			}
		self:land_broadcast_msg_to_client("SC_LandCallScore", notify)
		self.cur_call_score = callscore
		self.cur_call_score_chair_id = self.cur_turn
		self.first_turn = self.cur_turn
		self:send_land_cards(player)
		return
	end

	if callscore > 0 then
		self.cur_call_score_chair_id = self.cur_turn
		self.cur_call_score = callscore
	end	
	if self.cur_turn == 3 then
		self.cur_turn = 1
	else
		self.cur_turn = self.cur_turn + 1
	end
	local notify = {
		cur_chair_id = self.cur_turn,
		call_chair_id = player.chair_id,
		call_score = callscore,
		}
	self:land_broadcast_msg_to_client("SC_LandCallScore", notify)
	if self.first_turn == self.cur_turn then
		if self.cur_call_score > 0 then
			self.first_turn = self.cur_call_score_chair_id
			self:send_land_cards(player)
		else
			self.callsore_time = self.callsore_time + 1
			if self.callsore_time < 3 then
				self:land_broadcast_msg_to_client("SC_LandCallFail")
				table.insert(self.gamelog.CallPoints,self.callpoints_log)
				self:start() 
			else
				self.cur_call_score_chair_id = self.first_turn
				self.cur_call_score = 1
				self:send_land_cards(player)
			end
			return
		end
	end
	self.time0_ = get_second_time()
	self:Next_Player_Proc()
end

function ddz_table:out_card(player, cardslist, flag)
	if self.status ~= LAND_STATUS_PLAY then
		return
	end
	if player.chair_id ~= self.cur_turn then
		return
	end
	if not self.player_list_[player.chair_id] then
		log_error(tostring(player.chair_id)) log_error(tostring(player.guid))
		for k,v in pairs(self.player_list_) do
			if v then
				log_error(tostring(k)) log_error(tostring(v.guid))
			end
		end
	end

	local playercards = self.land_player_cards[player.chair_id]
	if not playercards:check_cards(cardslist) then
		return
	end

	if #cardslist > 1 then
		table.sort(cardslist, function(a, b) return a < b end)
	end
	local cardstype, cardsval = playercards:get_cards_type(cardslist)
	if not cardstype then
		return
	end
	if cardstype == pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_SINGLE") and cardslist[1] == 53 then
		cardsval = 14
	end
	local cur_out_cards = {cards_type = cardstype, cards_count = #cardslist, cards_val = cardsval}
	if not playercards:compare_cards(cur_out_cards, self.last_out_cards) then
		return
	end	
	if not flag or flag == false then
		player.TrusteeshipTimes = 0
	end
	local outcard = {
		chair_id = player.chair_id,
		outcards = string.format("%s",table.concat(cardslist, ',')),
		sparecards = "",
		time = get_second_time(),
		isTrusteeship = player.isTrusteeship and 1 or 0,
	}
	self.last_out_cards = cur_out_cards
	self.last_cards = cardslist
	table.insert(self.Already_Out_Cards,cardslist)
	if self.flag_fanchuntian == true and self.cur_turn == self.flag_land and #self.land_player_cards[self.cur_turn].cards_ < 20 then
		self.flag_fanchuntian = false
	end
	if self.cur_turn ~= self.flag_land and self.flag_chuntian then
		self.flag_chuntian = false
	end
	if self.flag_chuntian == false and self.cur_turn == self.flag_land then
		self.flag_fanchuntian = false
	end	
	self.time_outcard_ = LAND_TIME_OUT_CARD
	if cardstype == pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_MISSILE") or cardstype == pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_BOMB") then
		playercards:add_bomb_count()
		self.bomb = self.bomb + 1
	end
	self.first_turn = self.cur_turn
	if cardstype ~= pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_MISSILE") then
		if self.cur_turn == 3 then
			self.cur_turn = 1
		else
			self.cur_turn = self.cur_turn + 1
		end
	else
		self.last_out_cards = nil
	end
	local notify = {
		cur_chair_id = self.cur_turn,
		out_chair_id = player.chair_id,
		cards = cardslist,
		turn_over = (cardstype == pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_MISSILE") and 1 or 0),
		}
	self:land_broadcast_msg_to_client("SC_LandOutCard", notify)

	for k,v in pairs(cardslist) do
		table.insert(self.cards_out_list,v)
	end
	
	player.outTime = 0
	self.time0_ = get_second_time()
	local outCardFlag = not playercards:out_cards(cardslist)
	outcard.sparecards = string.format("%s",table.concat(playercards.cards_, ','))
	table.insert(self.gamelog.outcard_process,outcard)
	if outCardFlag then
		if def_second_game_type==def_private then
			self:privatefinishgame(player)
		else
			self:finishgame(player)
		end
	else
		self:Next_Player_Proc()
	end
end


function ddz_table:pass_card(player, flag)
	if self.status ~= LAND_STATUS_PLAY then
		return
	end
	if player.chair_id ~= self.cur_turn then
		return
	end
	if not self.last_out_cards then
		return
	end
	if not flag or flag == false then
		player.TrusteeshipTimes = 0
	end
	local outcard = {
		chair_id = player.chair_id,
		outcards = "pass card",
		sparecards = string.format("%s",table.concat(self.land_player_cards[player.chair_id].cards_, ',')),
		time = get_second_time(),		
		isTrusteeship = player.isTrusteeship and 1 or 0,
	}
	table.insert(self.gamelog.outcard_process,outcard)
	if self.cur_turn == 3 then
		self.cur_turn = 1
	else
		self.cur_turn = self.cur_turn + 1
	end
	local is_turn_over = (self.cur_turn == self.first_turn and 1 or 0)
	if is_turn_over == 1 then
		self.last_out_cards = nil
	end
	local notify = {
		cur_chair_id = self.cur_turn,
		pass_chair_id = player.chair_id,
		turn_over = is_turn_over,
		}
	self:land_broadcast_msg_to_client("SC_LandPassCard", notify)
	self:Next_Player_Proc()
end
function ddz_table:Next_Player_Proc( ... )
	if  self.status == LAND_STATUS_CALL then
		if not self.player_list_[self.cur_turn] then
			self:finishgameError()
		elseif self.player_list_[self.cur_turn].Dropped or self.player_list_[self.cur_turn].isTrusteeship then
			self.time0_ = get_second_time() - LAND_TIME_CALL_SCORE + 1
		end
	elseif self.status == LAND_STATUS_PLAY then
		if (not self.cur_turn) or (not self.player_list_[self.cur_turn]) then
			log_error(tostring(self.cur_turn))
			for k,v in pairs(self.player_list_) do
				if v then
					log_error(tostring(k)) log_error(tostring(v.guid))
				end
			end
		end

		if self.player_list_[self.cur_turn].Dropped or self.player_list_[self.cur_turn].isTrusteeship then
			self.time0_ = get_second_time() - self.time_outcard_ + 1
		else
			self.time0_ = get_second_time()
		end
	end
end

function  ddz_table:reconnect(player)
end
function  ddz_table:isPlay( ... )
	if self.status == LAND_STATUS_DOUBLE or self.status == LAND_STATUS_PLAY or self.status == LAND_STATUS_PLAYOFFLINE or self.status == LAND_STATUS_CALL then
		return true
	end
	return false
end

function ddz_table:reconnection_client_msg(player)
	virtual_table.reconnection_client_msg(self,player)
	if def_second_game_type == def_private and self.status == LAND_STATUS_FREE then
		player.isTrusteeship = true
		self:setTrusteeship(player,false)
		self:land_post_msg_to_client_pb(player, "SC_RecconectReady")
		return
	end
	local notify = {
			room_id = player.room_id,
			table_id = player.table_id,
			chair_id = player.chair_id,
			result = GAME_SERVER_RESULT_SUCCESS,
			ip_area = player.ip_area,
			private_room = self.private_room,
			private_room_score_type = self.private_room_score_type,
			private_room_cell_money = self.private_room_cell_money,
			private_room_id = self.private_room_id,
		}
	if self.game_runtimes then
		notify.private_room_has_start = (self.game_runtimes > 0 and 1 or 2)
	end
	if self.ready_list_[player.chair_id] then
		notify.is_ready = true
	end
	self:foreach_except(player.chair_id, function (p)
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
		if self.status ~= LAND_STATUS_FREE or self.ready_list_[p.chair_id] then
			v.is_ready = true
		end
		notify.pb_visual_info = notify.pb_visual_info or {}
		table.insert(notify.pb_visual_info, v)
	end)
	
	self:land_post_msg_to_client_pb(player, "SC_PlayerReconnection", notify)
	self:recoveryplayercard(player)
	local notify_double = {
		pb_double_state = {},
		double_count_down = 0
	}
	if self.status == LAND_STATUS_DOUBLE and player.is_double == nil then
		local curtime = get_second_time()
		notify_double.double_count_down = LAND_TIME_CALL_SCORE + self.time0_ - curtime 
	end
	for i,v in ipairs(self.player_list_) do
		if v then
			local m = {
				chair_id = v.chair_id,
				is_double = 1
			}
			if v.is_double then 
				m.is_double = 2
			elseif v.is_double == nil then
				m.is_double = 3
			end
			table.insert(notify_double.pb_double_state,m)
		end
	end
	
	self:land_post_msg_to_client_pb(player, "SC_LandRecoveryPlayerDouble", notify_double)
	local notify = {
		cur_online_chair_id = player.chair_id,
		cur_chair_id = self.cur_turn,
	}
	self:land_broadcast_msg_to_client("SC_LandPlayerOnline", notify)
	player.isTrusteeship = true
	self:setTrusteeship(player,false)
	--掉线状态关闭
	if player.is_offline  then
		player.is_offline = false 
	end
	player.ddz_in_table = true
end
function ddz_table:ready(player)
	if self:isPlay() then
		return
	end
	if not self:canEnter(player) then
		self.room_.room_manager_:change_table(player)
		local tab = self.room_:find_table(player.table_id)
		tab:ready(player)
		return
	end

	if def_game_id > 20 then --斗地主农民不换桌,地主强制换桌
		--if player.first_land ~=nil and player.first_land == 1 and not(player.is_android) then
		if player.first_land ~=nil and player.first_land == 1 then
			--player.first_land = 0
			--log_info("player change_table "..player.guid)
			self.room_.room_manager_:change_table(player)
			local tab = self.room_:find_table(player.table_id)
			tab:ready(player)
			return
		end	
	end


	virtual_table.ready(self,player)
	player.offtime = nil
	player.isTrusteeship = false
	player.finishOutGame = false
	local msg = {
		chair_id = player.chair_id,
		isTrusteeship = player.isTrusteeship,
		}
	self:land_broadcast_msg_to_client("SC_LandTrusteeship", msg)
end

function ddz_table:change_table(player)
	log_info("ddz_robot change_table "..player.guid)
	self.room_.room_manager_:change_table(player)
end

function  ddz_table:recoveryplayercard(player)
	if self.status == LAND_STATUS_PLAY or self.status == LAND_STATUS_DOUBLE then
		local notify = {
			cur_chair_id = player.chair_id,
			cards = self.land_player_cards[player.chair_id].cards_,
			pb_msg = {},
			landchairid = self.flag_land,
			landcards = self.landcards,
			call_score = self.cur_call_score,
			lastCards  = self.last_cards,
			lastcardid = self.first_turn,
			outcardid  = self.cur_turn,
			alreadyoutcards = self.Already_Out_Cards,
			bomb = self.bomb,
		}
		for i,v in ipairs(self.player_list_) do
			if v.chair_id ~= player.chair_id then
				local m = {
					chair_id = v.chair_id,
					cardsnum = #self.land_player_cards[v.chair_id].cards_,
					isTrusteeship = v.isTrusteeship,
				}
				table.insert(notify.pb_msg,m)
			end
		end
		self:land_post_msg_to_client_pb(player, "SC_LandRecoveryPlayerCard", notify)
	elseif self.status == LAND_STATUS_PLAYOFFLINE or self.status == LAND_STATUS_CALL then
		local notify = {
			cur_chair_id = self.cur_turn,
			call_chair_id = self.cur_call_score_chair_id,
			call_score = self.cur_call_score,
			cards = self.land_player_cards[player.chair_id].cards_,
			pb_playerOfflineMsg = {}
		}
		player.offtime = nil
		local waitT = 0
		for i,v in ipairs(self.player_list_) do
			if v then
				if v.offtime then
					local pptime = get_second_time() - v.offtime
					if pptime >= LAND_TIME_WAIT_OFFLINE then
						pptime = 0
					else
						pptime = LAND_TIME_WAIT_OFFLINE - pptime
					end
					local xxnotify = {
						chair_id = v.chair_id,
						outTimes = pptime,
					}
					table.insert(notify.pb_playerOfflineMsg, xxnotify)
					if v.offtime then
						if v.offtime > waitT then
							waitT = v.offtime
						end
					end
				end
			end
		end
		self:land_post_msg_to_client_pb(player, "SC_LandRecoveryPlayerCallScore", notify)
		if waitT == 0 then
			self.time0_ = get_second_time()
			self.status = LAND_STATUS_CALL
		else
			self.time0_ = waitT
		end
	end
end

function  ddz_table:playeroffline( player )
	virtual_table.playeroffline(self,player)
	if self.status == LAND_STATUS_FREE then
		player:forced_exit()
	elseif self.status == LAND_STATUS_PLAY or self.status == LAND_STATUS_CALL or self.status == LAND_STATUS_DOUBLE then
		self:setTrusteeship(player,true)
		player.ddz_in_table = false
	elseif self.status == LAND_STATUS_PLAYOFFLINE then
		local notify = {
			cur_chair_id = player.chair_id,
			wait_time = LAND_TIME_WAIT_OFFLINE,
		}
		self:land_broadcast_msg_to_client("SC_LandCallScorePlayerOffline", notify)
		player.offtime = get_second_time()
		local i = 0
		for i,v in ipairs(self.player_list_) do
			if v then
				i = i + 1
			end
		end
		if i == 3 then
			local room_limit = self.room_:get_room_limit()
			for i,v in ipairs(self.player_list_) do
				if v then
					v:forced_exit()
				end
			end
			self:clear_ready()
			return
		end
	end		
end
function ddz_table:finishgameError()
	log_error("-------------------------finishgameError ddz-----------------------------------------")
	for i,v in ipairs(self.player_list_) do
		if v then
			local t_guid = v.guid or 0
			local t_room_id = v.room_id or 0
			local t_table_id = v.table_id or 0
		end
	end
	local notify = {
		pb_conclude = {},
		chuntian = 0,
		fanchuntian = 0,
	}
	for i=1,3 do
		c = {}
		c.score = 0
		c.bomb_count = 0
		c.cards = {}
		c.flag = self.room_.tax_show_
		c.tax = 0
		notify.pb_conclude[i] = c
	end
	self:land_broadcast_msg_to_client("SC_LandConclude",notify)
	self.gamelog.end_game_time = get_second_time()
	self.gamelog.onlinePlayer = {}
	for i,v in pairs(self.player_list_) do
		if v then
			table.insert(self.gamelog.onlinePlayer, i)
			v:forced_exit()
		end
	end
	local s_log = lua_to_json(self.gamelog)
	log_info("running_game_log")
	log_info(s_log)
	self:write_game_log_to_mysql(self.gamelog.table_game_id,self.def_game_name,s_log,self.gamelog.start_game_time,self.gamelog.end_game_time)
	self:clear_ready()
end
function  ddz_table:finishgame(player)
	for i,v in ipairs(self.player_list_) do
		if v then
			local t_guid = v.guid or 0
			local t_room_id = v.room_id or 0
			local t_table_id = v.table_id or 0
			self:update_player_last_recharge_game_total(v)
		end
	end

	self.gamelog.end_game_time = get_second_time()
	local notify = {
		pb_conclude = {},
		chuntian = 0,
		fanchuntian = 0,
	}
	local bomb_count = 0

	local carNum
	local carNums = 0
	local land_M = {
		chair_id = self.flag_land,
		landMoney = 0,
	}
	local farmer_M = {}
	local offcharid = 0
	local offtimes = get_second_time()

	for k,v in pairs(self.land_player_cards) do
		for k1,v1 in pairs(v.cards_) do
			table.insert(self.cards_out_list,v1)
		end
	end

	for i,v in ipairs(self.player_list_) do
		if v then
			local c = {}
			carNum = 0
			carNum = #self.land_player_cards[v.chair_id].cards_
			c.cards = self.land_player_cards[v.chair_id].cards_
			c.bomb_count = self.land_player_cards[v.chair_id]:get_bomb_count()
			c.score = 0
			bomb_count = bomb_count + c.bomb_count
			notify.pb_conclude[v.chair_id] = c
			if v.chair_id ~= self.flag_land and carNum == 17 then
				carNums = carNums + 1;
			end
			if v.offtime ~= nil then
				local offlinePlayers = {
					chair_id = v.chair_id,
					offtime = v.offtime,
				}
				table.insert(self.gamelog.offlinePlayers,offlinePlayers)
			end
			self.gamelog.playInfo[v.chair_id] = {
				chair_id = v.chair_id,
				guid = v.guid,
				old_money = v.pb_base_info.money,
				new_money = v.pb_base_info.money,
				tax = 0,
				gameEndStatus = "",
				channel_id = v.channel_id,
				phone_type = v.phone_type,
				ip = v.ip,
			}
			if v.chair_id == self.flag_land then
				land_M.landMoney = v.pb_base_info.money
				land_M.is_double = v.is_double
			else
				local farmerM = {
					farmerMoney = v.pb_base_info.money,
					chair_id = v.chair_id,
					is_double = v.is_double
				}
				table.insert(farmer_M,farmerM)
			end
			if v.offtime ~= nil then
				if v.offtime < offtimes then
					offcharid = v.chair_id
					offtimes = v.offtime
				end
			end
		else
			log_error(string.format("========player_list_ [%d] is nil or false",i))
		end
	end
	if carNums == 2 then
		self.flag_chuntian = true
	end
	local score = self.cur_call_score
	if self.cur_call_score <= 0 then
		score = 1
	end
	
	if bomb_count > 0 then
		score = score * (2^bomb_count)
	end
	local score_multiple = 0
	local room_cell_score = self.cell_score_
	local land_master_win = true
	if self.status == LAND_STATUS_PLAYOFFLINE then
		land_M = {}
		farmer_M = {}
		for i,v in ipairs(self.player_list_) do
			if v.chair_id == offcharid then
				land_M.landMoney = v.pb_base_info.money
				land_M.is_double = v.is_double
			else
				local farmerM = {
					farmerMoney = v.pb_base_info.money,
					chair_id = v.chair_id,
					is_double = v.is_double
				}
				table.insert(farmer_M,farmerM)
			end
		end
		local land_score = 0
		land_score = score* room_cell_score
		local m_f1_score = land_score
		local m_f2_score = land_score
		if land_M.is_double then
			m_f1_score = m_f1_score*2
			m_f2_score = m_f2_score*2
		end
		if farmer_M[1].is_double then
			m_f1_score = m_f1_score*2
		end
		if farmer_M[2].is_double then
			m_f2_score = m_f2_score*2
		end
		if m_f1_score > farmer_M[1].farmerMoney then
			m_f1_score = farmer_M[1].farmerMoney
		end
		if m_f2_score > farmer_M[2].farmerMoney then
			m_f2_score = farmer_M[2].farmerMoney
		end
		
		local f_score_total = m_f1_score+m_f2_score
		if (m_f1_score+m_f2_score) > land_M.landMoney then
			m_f1_score = math.floor((land_M.landMoney*m_f1_score)/f_score_total)
			m_f2_score = math.floor((land_M.landMoney*m_f2_score)/f_score_total)
		end
		
		self.gamelog.table_game_id = self.table_game_id
		self:next_game()
		for i,v in ipairs(self.player_list_) do
			if self:isDroppedline(v) then
			end
			local s_type = 1
			local s_old_money = v.pb_base_info.money
			local s_tax = 0
			if v.chair_id == offcharid then	
				s_type = 3
				self.gamelog.playInfo[v.chair_id].gameEndStatus = "callsoure offline loss"
				notify.pb_conclude[v.chair_id].score = -(m_f1_score + m_f2_score)
				v:cost_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = (m_f1_score + m_f2_score)}}, pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_LAND"),true)
				self:update_player_bet_total(math.abs(money),v)
			else
				s_type = 2
				local farmer_score = 0
				if v.chair_id == farmer_M[1].chair_id then
					farmer_score = m_f1_score 
				else
					farmer_score = m_f2_score
				end
				self.gamelog.playInfo[v.chair_id].gameEndStatus = "callsoure online win"
				notify.pb_conclude[v.chair_id].score = farmer_score				
				s_tax = math.ceil(notify.pb_conclude[v.chair_id].score * self.room_:get_room_tax())
				notify.pb_conclude[v.chair_id].score = notify.pb_conclude[v.chair_id].score - s_tax
				v:add_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = notify.pb_conclude[v.chair_id].score}}, pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_LAND"))
				notify_win_big_money(v.nickname, def_game_id, notify.pb_conclude[v.chair_id].score)
				self:update_player_bet_total(math.abs(notify.pb_conclude[v.chair_id].score),v)
				self:tax_channel_invite(v.channel_id,v.guid,v.inviter_guid,s_tax)
			end
			self.gamelog.playInfo[v.chair_id].tax = s_tax
			self.gamelog.playInfo[v.chair_id].new_money = v.pb_base_info.money
			self:user_log_money(v,s_type,s_old_money,s_tax,notify.pb_conclude[v.chair_id].score,self.table_game_id)
		end
	else
		self.gamelog.win_chair = player.chair_id
		if self.flag_land == player.chair_id then
			land_master_win = true
			if self.flag_chuntian then
				score = score * 2
				notify.chuntian = 1
			end
			score_multiple = score
			local land_score = 0
			local land_cell=room_cell_score
			land_score = score_multiple * land_cell
			local m_f1_score = land_score
			local m_f2_score = land_score
			if land_M.is_double then
				m_f1_score = m_f1_score*2
				m_f2_score = m_f2_score*2
			end
			if farmer_M[1].is_double then
				m_f1_score = m_f1_score*2
			end
			if farmer_M[2].is_double then
				m_f2_score = m_f2_score*2
			end
			if m_f1_score > farmer_M[1].farmerMoney then
				m_f1_score = farmer_M[1].farmerMoney
			end
			if m_f2_score > farmer_M[2].farmerMoney then
				m_f2_score = farmer_M[2].farmerMoney
			end
			
			local f_score_total = m_f1_score+m_f2_score
			if (m_f1_score+m_f2_score) > land_M.landMoney then
				m_f1_score = math.floor((land_M.landMoney*m_f1_score)/f_score_total)
				m_f2_score = math.floor((land_M.landMoney*m_f2_score)/f_score_total)
			end
			
			for i,v in ipairs(self.player_list_) do
				local s_type = 1
				local s_old_money = v.pb_base_info.money
				local s_tax = 0
				if self.flag_land == v.chair_id then
					s_type = 2
					if self:isDroppedline(v) and offlinePunishment_flag then
						s_type = 3
						notify.pb_conclude[v.chair_id].score = 0
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "land win but offline"
					else
						notify.pb_conclude[v.chair_id].score = m_f1_score + m_f2_score
						s_tax = math.ceil(notify.pb_conclude[v.chair_id].score * self.room_:get_room_tax())
						notify.pb_conclude[v.chair_id].score = notify.pb_conclude[v.chair_id].score - s_tax
						v:add_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = notify.pb_conclude[v.chair_id].score}}, pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_LAND"))
						notify_win_big_money(v.nickname, def_game_id, notify.pb_conclude[v.chair_id].score)
						self:update_player_bet_total(math.abs(notify.pb_conclude[v.chair_id].score),v)
						self:tax_channel_invite(v.channel_id,v.guid,v.inviter_guid,s_tax)
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "land win"
					end
				else
					s_type = 1
					local farmer_score = 0
					if v.chair_id == farmer_M[1].chair_id then
						farmer_score = m_f1_score
					else
						farmer_score = m_f2_score
					end
					self.gamelog.playInfo[v.chair_id].gameEndStatus = "farmer loss"
					
					if self:isDroppedline(v) and offlinePunishment_flag then
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "farmer loss and offline"
						s_type = 3
						if score_multiple < FARMER_ESCAPE_SCORE_BASE then
							farmer_score = FARMER_ESCAPE_SCORE_LESS* room_cell_score
						else
							farmer_score = score_multiple * room_cell_score * FARMER_ESCAPE_SCORE_GREATER
						end
						if farmer_score > v.pb_base_info.money then
							farmer_score = v.pb_base_info.money
						end
					end
					notify.pb_conclude[v.chair_id].score = -farmer_score
					v:cost_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = farmer_score}}, pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_LAND"),true)
					self:update_player_bet_total(math.abs(farmer_score),v)
				end
				self.gamelog.playInfo[v.chair_id].tax = s_tax
				self.gamelog.playInfo[v.chair_id].new_money = v.pb_base_info.money				
				notify.pb_conclude[v.chair_id].tax = s_tax
				s_tax = math.ceil(notify.pb_conclude[v.chair_id].score * self.room_:get_room_tax())		
				notify.pb_conclude[v.chair_id].flag = self.room_.tax_show_
				self:user_log_money(v,s_type,s_old_money,s_tax,notify.pb_conclude[v.chair_id].score,self.table_game_id)
			end
		else
			land_master_win = false
			if self.flag_fanchuntian then
				score = score * 2
				notify.fanchuntian = 1
			end
			score_multiple = score
			local land_score = 0
			local land_cell = room_cell_score
			land_score = score_multiple * land_cell
			
			local m_f1_score = land_score
			local m_f2_score = land_score
			if land_M.is_double then
				m_f1_score = m_f1_score*2
				m_f2_score = m_f2_score*2
			end
			if farmer_M[1].is_double then
				m_f1_score = m_f1_score*2
			end
			if farmer_M[2].is_double then
				m_f2_score = m_f2_score*2
			end
			if m_f1_score > farmer_M[1].farmerMoney then
				m_f1_score = farmer_M[1].farmerMoney
			end
			if m_f2_score > farmer_M[2].farmerMoney then
				m_f2_score = farmer_M[2].farmerMoney
			end
			local f_score_total = m_f1_score+m_f2_score
			if (m_f1_score+m_f2_score) > land_M.landMoney then
				m_f1_score = math.floor((land_M.landMoney*m_f1_score)/f_score_total)
				m_f2_score = math.floor((land_M.landMoney*m_f2_score)/f_score_total)
			end
			
			for i,v in ipairs(self.player_list_) do
				local s_type = 1
				local s_old_money = v.pb_base_info.money
				local s_tax = 0
				if self.flag_land == v.chair_id then
					s_type = 1
					self.gamelog.playInfo[v.chair_id].gameEndStatus = "land loss"
					if self:isDroppedline(v) and offlinePunishment_flag then
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "land loss and offline"
						s_type = 3
						if score_multiple < LAND_ESCAPE_SCORE_BASE then
							land_score = LAND_ESCAPE_SCORE_LESS * land_cell
						else
							land_score = score_multiple * LAND_ESCAPE_SCORE_GREATER * land_cell
						end						
						if land_score > land_M.landMoney/2 then
							land_score = land_M.landMoney
						end
					else
						land_score = m_f1_score + m_f2_score
					end
					notify.pb_conclude[v.chair_id].score = -land_score

					v:cost_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = land_score}}, pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_LAND"),true)
					self:update_player_bet_total(math.abs(land_score),v)

				else
					s_type = 2
					local farmer_score = 0
					if v.chair_id == farmer_M[1].chair_id then
						farmer_score = m_f1_score
					else
						farmer_score = m_f2_score
					end
					if not self:isDroppedline(v) or not offlinePunishment_flag then
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "farmer win"
						notify.pb_conclude[v.chair_id].score = farmer_score
						
						s_tax = math.ceil(notify.pb_conclude[v.chair_id].score * self.room_:get_room_tax())
						notify.pb_conclude[v.chair_id].score = notify.pb_conclude[v.chair_id].score - s_tax

						v:add_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = notify.pb_conclude[v.chair_id].score}}, pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_LAND"))

						notify_win_big_money(v.nickname, def_game_id, notify.pb_conclude[v.chair_id].score)
						self:update_player_bet_total(math.abs(notify.pb_conclude[v.chair_id].score),v)
						self:tax_channel_invite(v.channel_id,v.guid,v.inviter_guid,s_tax)
					else
						s_type = 3
						notify.pb_conclude[v.chair_id].score = 0
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "farmer win but offline"
					end
				end
				self.gamelog.playInfo[v.chair_id].tax = s_tax
				self.gamelog.playInfo[v.chair_id].new_money = v.pb_base_info.money
				self:user_log_money(v,s_type,s_old_money,s_tax,notify.pb_conclude[v.chair_id].score,self.table_game_id)
				notify.pb_conclude[v.chair_id].tax = s_tax
				notify.pb_conclude[v.chair_id].flag = self.room_.tax_show_
			end
		end
	end
	for i,v in ipairs(self.player_list_) do
		if v then
			if v.is_double then
				self.gamelog.playInfo[v.chair_id].is_double = 1
			else
				self.gamelog.playInfo[v.chair_id].is_double = 0
			end
			v.friend_list = {}
			if land_master_win then
				if v.chair_id == self.flag_land then
					for ct,pt in ipairs(self.player_list_) do
						if ct ~= v.flag_land then
							table.insert( v.friend_list, pt.guid )
						end
					end
				end
			else
				if v.chair_id ~= self.flag_land then
					for ct,pt in ipairs(self.player_list_) do
						if ct ~= v.chair_id and ct ~= v.flag_land then
							table.insert( v.friend_list, pt.guid )
						end
					end
				end
			end
		end
	end
	self.gamelog.cell_score = self.cell_score_
	self.gamelog.finishgameInfo = notify
	local s_log = lua_to_json(self.gamelog)
	log_info("running_game_log")
	log_info(s_log)
	self:write_game_log_to_mysql(self.gamelog.table_game_id,self.def_game_name,s_log,self.gamelog.start_game_time,self.gamelog.end_game_time)
	log_info(string.format("-------------------game finish : %s -------------------------",self.table_game_id))
	self:land_broadcast_msg_to_client("SC_LandConclude", notify)
	local room_limit = self.room_:get_room_limit()
	for i,v in ipairs(self.player_list_) do
		if v then
			if (not v.is_android) and (self:isDroppedline(v) or (v.isTrusteeship and v.finishOutGame)) then
				if not(v.online)  then
					v:forced_exit()
				end
				if self:isDroppedline(v) or v.isTrusteeship then
					v.isTrusteeship = false
					v.finishOutGame = false
				end

			elseif v.is_android and (not ly_use_robot) then
				v:forced_exit()
			else
				v:check_forced_exit(room_limit)
			end
			v.ipControlTime = get_second_time()
			v.Dropped = false
		else
		end
	end
	for i,v in ipairs(self.player_list_) do
		if v and (not v.is_android) and (false == v.ddz_in_table) then
			v:forced_exit()
		end
	end
	self:clear_ready()

	self:check_game_maintain()

end
function  ddz_table:privatefinishgame(player)
	for i,v in ipairs(self.player_list_) do
		if v then
			local t_guid = v.guid or 0
			local t_room_id = v.room_id or 0
			local t_table_id = v.table_id or 0
		end
	end
	self.gamelog.end_game_time = get_second_time()
	local notify = {
		pb_conclude = {},
		chuntian = 0,
		fanchuntian = 0,
	}
	local bomb_count = 0
	local carNum
	local carNums = 0
	local land_M = {
		chair_id = self.flag_land,
		landMoney = 0,
	}
	local farmer_M = {}
	local offcharid = 0
	local offtimes = get_second_time()
	for i,v in ipairs(self.player_list_) do
		if v then
			local c = {}
			c.score = 0
			c.cards = self.land_player_cards[v.chair_id].cards_
			c.bomb_count = self.land_player_cards[v.chair_id]:get_bomb_count()
			
			carNum = 0
			carNum = #self.land_player_cards[v.chair_id].cards_
			bomb_count = bomb_count + c.bomb_count
			notify.pb_conclude[v.chair_id] = c
			if v.chair_id ~= self.flag_land and carNum == 17 then
				carNums = carNums + 1;
			end
			if v.offtime ~= nil then
				local offlinePlayers = {
					chair_id = v.chair_id,
					offtime = v.offtime,
				}
				table.insert(self.gamelog.offlinePlayers,offlinePlayers)
			end
			self.gamelog.playInfo[v.chair_id] = {
				chair_id = v.chair_id,
				guid = v.guid,
				old_money = v.pb_base_info.money,
				new_money = v.pb_base_info.money,
				tax = 0,
				gameEndStatus = "",
				channel_id = v.channel_id,
				phone_type = v.phone_type,
				ip = v.ip,
			}
			if v.chair_id == self.flag_land then
				land_M.landMoney = v.pb_base_info.money
				land_M.is_double = v.is_double
			else
				local farmerM = {
					farmerMoney = v.pb_base_info.money,
					chair_id = v.chair_id,
					is_double = v.is_double
				}
				table.insert(farmer_M,farmerM)
			end
			if v.offtime ~= nil then
				if v.offtime < offtimes then
					offcharid = v.chair_id
					offtimes = v.offtime
				end
			end
		else
			log_error(string.format("========player_list_ [%d] is nil or false",i))
		end
	end
	if carNums == 2 then
		self.flag_chuntian = true
	end
	local score = self.cur_call_score
	if self.cur_call_score <= 0 then
		score = 1
	end
	
	if bomb_count > 0 then
		score = score * (2^bomb_count)
	end
	local score_multiple = 0
	local room_cell_score = self.privateRules[1].cell   
	local land_master_win = true
	if self.status == LAND_STATUS_PLAYOFFLINE then	
		land_M = {}
		farmer_M = {}
		for i,v in ipairs(self.player_list_) do
			if v.chair_id == offcharid then
				land_M.landMoney = v.pb_base_info.money
				land_M.is_double = v.is_double
			else
				local farmerM = {
					farmerMoney = v.pb_base_info.money,
					chair_id = v.chair_id,
					is_double = v.is_double
				}
				table.insert(farmer_M,farmerM)
			end
		end
		
		local land_score = 0
		land_score = score* room_cell_score
		local m_f1_score = land_score
		local m_f2_score = land_score
		if land_M.is_double then
			m_f1_score = m_f1_score*2
			m_f2_score = m_f2_score*2
		end
		if farmer_M[1].is_double then
			m_f1_score = m_f1_score*2
		end
		if farmer_M[2].is_double then
			m_f2_score = m_f2_score*2
		end
		if m_f1_score > farmer_M[1].farmerMoney then
			m_f1_score = farmer_M[1].farmerMoney
		end
		if m_f2_score > farmer_M[2].farmerMoney then
			m_f2_score = farmer_M[2].farmerMoney
		end
		
		local f_score_total = m_f1_score+m_f2_score
		if (m_f1_score+m_f2_score) > land_M.landMoney then
			m_f1_score = math.floor((land_M.landMoney*m_f1_score)/f_score_total)
			m_f2_score = math.floor((land_M.landMoney*m_f2_score)/f_score_total)
		end

		self.gamelog.table_game_id = self.table_game_id
		self:next_game()
		for i,v in ipairs(self.player_list_) do
			if self:isDroppedline(v) then
			end
			local s_type = 1
			local s_old_money = v.pb_base_info.money
			local s_tax = 0
			if v.chair_id == offcharid then	
				s_type = 3
				self.gamelog.playInfo[v.chair_id].gameEndStatus = "callsoure offline loss"
				notify.pb_conclude[v.chair_id].score = -(m_f1_score + m_f2_score) 

				v:cost_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = (m_f1_score + m_f2_score) }}, pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_LAND"),true)
				self:update_player_bet_total(math.abs(m_f1_score + m_f2_score),v)

			else
				s_type = 2
				local farmer_score = 0
				if v.chair_id == farmer_M[1].chair_id then
					farmer_score = m_f1_score 
				else
					farmer_score = m_f2_score  
				end
				self.gamelog.playInfo[v.chair_id].gameEndStatus = "callsoure online win"
				notify.pb_conclude[v.chair_id].score = farmer_score				
				s_tax = math.ceil(notify.pb_conclude[v.chair_id].score * self.room_:get_room_tax())
				
				notify.pb_conclude[v.chair_id].score = notify.pb_conclude[v.chair_id].score - s_tax

				v:add_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = notify.pb_conclude[v.chair_id].score}}, pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_LAND"))

				notify_win_big_money(v.nickname, def_game_id, notify.pb_conclude[v.chair_id].score)
				self:update_player_bet_total(math.abs(notify.pb_conclude[v.chair_id].score),v)
				self:tax_channel_invite(v.channel_id,v.guid,v.inviter_guid,s_tax)
			end
			self.gamelog.playInfo[v.chair_id].tax = s_tax
			self.gamelog.playInfo[v.chair_id].new_money = v.pb_base_info.money
			log_info(string.format("game finish playerid[%d] guid[%d] money [%d]",v.chair_id,v.guid,v.pb_base_info.money))
			self:user_log_money(v,s_type,s_old_money,s_tax,notify.pb_conclude[v.chair_id].score,self.table_game_id)
		end
	else     
		self.gamelog.win_chair = player.chair_id
		if self.flag_land == player.chair_id then 
			land_master_win = true
			if self.flag_chuntian then
				score = score * 2
				notify.chuntian = 1
			end
			score_multiple = score
			local land_score = 0
			local land_cell = room_cell_score
			land_score = score_multiple * land_cell
			local m_f1_score = land_score
			local m_f2_score = land_score
			if land_M.is_double then
				m_f1_score = m_f1_score*2
				m_f2_score = m_f2_score*2
			end
			if farmer_M[1].is_double then
				m_f1_score = m_f1_score*2
			end
			if farmer_M[2].is_double then
				m_f2_score = m_f2_score*2
			end
			if self.privateRules[6].highBeishuLimit ~= 1 then
				if (m_f1_score/(room_cell_score*self.cur_call_score)) >self.privateRules[6].highBeishuLimit and self.privateRules[6].highBeishuLimit>0  then 
					m_f1_score = (room_cell_score*self.cur_call_score)*self.privateRules[6].highBeishuLimit
				end
				if (m_f2_score/(room_cell_score*self.cur_call_score)) >self.privateRules[6].highBeishuLimit and self.privateRules[6].highBeishuLimit>0  then 
					m_f2_score = (room_cell_score*self.cur_call_score)*self.privateRules[6].highBeishuLimit
				end
			end
			if m_f1_score > farmer_M[1].farmerMoney then 
				m_f1_score = farmer_M[1].farmerMoney
			end
			if m_f2_score > farmer_M[2].farmerMoney then
				m_f2_score = farmer_M[2].farmerMoney
			end
			
			local f_score_total = m_f1_score+m_f2_score
			if f_score_total > land_M.landMoney and  self.privateRules[7].allowYixiaoBoDa==1 then
				m_f1_score = math.floor((land_M.landMoney*m_f1_score)/f_score_total)
				m_f2_score = math.floor((land_M.landMoney*m_f2_score)/f_score_total)
			end
			
			for i,v in ipairs(self.player_list_) do
				local s_type = 1
				local s_tax = 0
				local s_old_money = v.pb_base_info.money
				if self.flag_land == v.chair_id then
					s_type = 2
					
					s_tax = 0
					notify.pb_conclude[v.chair_id].score = m_f1_score + m_f2_score
					log_info("ceil befor :"..notify.pb_conclude[v.chair_id].score)
					notify.pb_conclude[v.chair_id].score = notify.pb_conclude[v.chair_id].score - s_tax
					log_info("ceil after :"..notify.pb_conclude[v.chair_id].score)

					v:add_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = notify.pb_conclude[v.chair_id].score}}, pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_LAND"))

					notify_win_big_money(v.nickname, def_game_id, notify.pb_conclude[v.chair_id].score)
					self:update_player_bet_total(math.abs(notify.pb_conclude[v.chair_id].score),v)
					log_info("land win add money:"..notify.pb_conclude[v.chair_id].score)
					self:tax_channel_invite(v.channel_id,v.guid,v.inviter_guid,s_tax)
					self.gamelog.playInfo[v.chair_id].gameEndStatus = "land win"
				else
					s_type = 1
					local farmer_score = 0
					if v.chair_id == farmer_M[1].chair_id then
						farmer_score = m_f1_score
					else
						farmer_score = m_f2_score
					end
					self.gamelog.playInfo[v.chair_id].gameEndStatus = "farmer loss"
					
					
					notify.pb_conclude[v.chair_id].score = -farmer_score

					v:cost_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = farmer_score}}, pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_LAND"),true)
					self:update_player_bet_total(math.abs(farmer_score),v)

					
				end
				self.gamelog.playInfo[v.chair_id].tax = s_tax
				self.gamelog.playInfo[v.chair_id].new_money = v.pb_base_info.money				
				notify.pb_conclude[v.chair_id].tax = s_tax
				
				notify.pb_conclude[v.chair_id].flag = false
				self:user_log_money(v,s_type,s_old_money,s_tax,notify.pb_conclude[v.chair_id].score,self.table_game_id)
			end
		else  
			land_master_win = false
			if self.flag_fanchuntian then
				score = score * 2
				notify.fanchuntian = 1
			end
			score_multiple = score
			
			local land_score = 0
			local land_cell = self.privateRules[1].cell
			land_score = score_multiple * land_cell
			
			local f1_score = land_score
			local f2_score = land_score
			if land_M.is_double then
				f1_score = f1_score*2
				f2_score = f2_score*2
			end
			if farmer_M[1].is_double then
				f1_score = f1_score*2
			end
			if farmer_M[2].is_double then
				f2_score = f2_score*2
			end
			land_score = f1_score+f2_score;

			if self.privateRules[6].highBeishuLimit ~= 1 then
				if (land_score/(land_cell*self.cur_call_score)) >(self.privateRules[6].highBeishuLimit*2) and self.privateRules[6].highBeishuLimit>0  then 
					land_score = (land_cell*self.cur_call_score)*self.privateRules[6].highBeishuLimit*2
				end
			end
			if  land_score > land_M.landMoney then
				land_score = land_M.landMoney
			end
			m_f1_score = math.floor((land_score*f1_score)/(f1_score+f2_score))
			m_f2_score = math.floor((land_score*f2_score)/(f1_score+f2_score))
			if m_f1_score > farmer_M[1].farmerMoney and self.privateRules[7].allowYixiaoBoDa==1 then
				m_f1_score = farmer_M[1].farmerMoney
			end
			
			if m_f2_score > farmer_M[2].farmerMoney  and self.privateRules[7].allowYixiaoBoDa==1 then
				m_f2_score = farmer_M[2].farmerMoney
			end

			land_score = m_f1_score+m_f2_score
			for i,v in ipairs(self.player_list_) do
				local s_type = 1
				local s_old_money = v.pb_base_info.money
				local s_tax = 0
				if self.flag_land == v.chair_id then
					s_type = 1
					self.gamelog.playInfo[v.chair_id].gameEndStatus = "land loss"
					notify.pb_conclude[v.chair_id].score = -land_score

					v:cost_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = land_score}}, pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_LAND"),true)
					self:update_player_bet_total(math.abs(land_score),v)
				else
					s_type = 2
					local farmer_score = 0
					if v.chair_id == farmer_M[1].chair_id then
						farmer_score = m_f1_score
					else
						farmer_score = m_f2_score
					end
					s_tax=0
					self.gamelog.playInfo[v.chair_id].gameEndStatus = "farmer win"
					notify.pb_conclude[v.chair_id].score = farmer_score
					notify.pb_conclude[v.chair_id].score = notify.pb_conclude[v.chair_id].score - s_tax
					v:add_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = notify.pb_conclude[v.chair_id].score}}, pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_LAND"))
					notify_win_big_money(v.nickname, def_game_id, notify.pb_conclude[v.chair_id].score)
					self:update_player_bet_total(math.abs(notify.pb_conclude[v.chair_id].score),v)
					self:tax_channel_invite(v.channel_id,v.guid,v.inviter_guid,s_tax)
				end
				self.gamelog.playInfo[v.chair_id].tax = s_tax
				self.gamelog.playInfo[v.chair_id].new_money = v.pb_base_info.money
				self:user_log_money(v,s_type,s_old_money,s_tax,notify.pb_conclude[v.chair_id].score,self.table_game_id)
				
				notify.pb_conclude[v.chair_id].tax = s_tax
				notify.pb_conclude[v.chair_id].flag = false
			end
		end
	end
	for i,v in ipairs(self.player_list_) do
		if v then
			if v.is_double then
				self.gamelog.playInfo[v.chair_id].is_double = 1
			else
				self.gamelog.playInfo[v.chair_id].is_double = 0
			end
			v.friend_list = {}
			if land_master_win then
				if v.chair_id == self.flag_land then
					for ct,pt in ipairs(self.player_list_) do
						if ct ~= v.flag_land then
							table.insert( v.friend_list, pt.guid )
						end
					end
				end
			else
				if v.chair_id ~= self.flag_land then
					for ct,pt in ipairs(self.player_list_) do
						if ct ~= v.chair_id and ct ~= v.flag_land then
							table.insert( v.friend_list, pt.guid )
						end
					end
				end
			end
			if def_second_game_type==def_private then
				self.totalwinlost[v.chair_id]=self.totalwinlost[v.chair_id]+notify.pb_conclude[v.chair_id].score
				notify.pb_conclude[v.chair_id].totoalwinlost = self.totalwinlost[v.chair_id]
			end
		end
	end
	self.gamelog.cell_score = self.cell_score_
	self.gamelog.finishgameInfo = notify
	local s_log = lua_to_json(self.gamelog)
	log_info("running_game_log")
	log_info(s_log)
	self:write_game_log_to_mysql(self.gamelog.table_game_id,self.def_game_name,s_log,self.gamelog.start_game_time,self.gamelog.end_game_time)
	log_info("-------------------------------game finish-------------------------------")
	self:land_broadcast_msg_to_client("SC_LandConclude", notify)
	self:clear_ready()
	for i,v in ipairs(self.player_list_) do
		if v and v:get_money() < self.private_room_cell_money * 20 then
			self:dismiss(v.guid, v.chair_id)
			return
		end
	end
end
function  ddz_table:isDroppedline(player)
	if player then
		player.ipControlTime = get_second_time()
		return not player.online or player.Dropped
	end
	return false
end
function ddz_table:clear_ready( ... )	
	virtual_table.clear_ready(self)
	self.status = LAND_STATUS_FREE
	self.time0_ = get_second_time()
	self.landcards = nil
	self.last_cards = nil
	self.Already_Out_Cards = {}
	self.bomb = 0
	self.callsore_time = 0
	self.table_game_id = 0
	self.gamelog = {
        CallPoints = {},
        landid = 0,
        ddz_sf = "",
        table_game_id = 0,
        start_game_time = 0,
        end_game_time = 0,
        win_chair = 0,
        outcard_process = {},
        finishgameInfo = {},
        playInfo = {},
        offlinePlayers = {},
        cell_score = 0,
    }
end

function ddz_table:trusteeship(player)	
	if self.last_out_cards and player.chair_id ~= self.first_turn then
		local playercards = self.land_player_cards[player.chair_id]
		local player_card = tabletools.copy(playercards.cards_)
		local cardstype, cardsval = playercards:get_cards_type(player_card)
		if not cardstype then
			self:pass_card(player,true)
			return
		end
		local cardsnum = #player_card
		local cur_out_cards = {cards_type = cardstype, cards_count = cardsnum, cards_val = cardsval}
		if not playercards:compare_cards(cur_out_cards, self.last_out_cards) then
			self:pass_card(player,true)
			return
		end	
		self:out_card(player, player_card, true)
	else
		local playercards = self.land_player_cards[self.cur_turn]
		local player_card = tabletools.copy(playercards.cards_)
		local cardstype, cardsval = playercards:get_cards_type(player_card)
		if not cardstype then
			self:out_card(player, {playercards.cards_[1]} , true)
			return
		end
		local cardsnum = #player_card
		local cur_out_cards = {cards_type = cardstype, cards_count = cardsnum, cards_val = cardsval}
		self:out_card(player, player_card, true)
		--self:out_card(player, {playercards.cards_[1]} , true)
	end
end
function ddz_table:canEnter(player)
	for _,v in ipairs(self.player_list_) do		
		if v and v.guid ~= player.guid then
			if player:judgeIP(v) then
				if ly_ip_limit then
					return false
				end	
			end
			if (20 == def_game_id) and (not player.is_android) and (not v.is_android) then --低倍场全机器人对真人  防止刷钱
				return false
			end
		end
	end
	return true
end

function ddz_table:tick()
	if self.private_vote_chairid~=nil and self.private_vote_chairid>0 then
		if  self.private_vote_status == true and get_second_time() - self.private_vote_time > vote_time_  then		
			for i, p in ipairs(self.private_vote_list) do
				if p then
					if p.senior == true then
						p.vote = true
					end
				end
			end
			self:check_vote()
		end
		return 
	end
	if self.status == LAND_STATUS_FREE then
		if def_second_game_type == 99 then
			return
		end
		if get_second_time() - self.time0_ > 2 then
			self.time0_ = get_second_time()
			local curtime = self.time0_
			local maintainFlg = 0
			for _,v in ipairs(self.player_list_) do
				if v then
					v.ipControlTime = v.ipControlTime or get_second_time()
					local t = v.ipControlTime
					local iRet = virtual_table:onNotifyReadyPlayerMaintain(v)
					if iRet == true then
						maintainFlg = 1
					end
					if t then
						if curtime -  t >= LAND_TIME_IP_CONTROL then
							v.ipControlTime = get_second_time()
							if self:isDroppedline(v) then
								if self:isDroppedline(v) or v.isTrusteeship then
									v.isTrusteeship = false
									v.finishOutGame = false
								end
								v:forced_exit()
							else
								v.ipControlflag = true				
								if self:get_player_count() == 1 and self.ready_list_[v.chair_id] then
									self.room_.room_manager_:change_table(v)
									local tab = self.room_:find_table(v.table_id)
									tab:ready(v)
								end
							end
						end
					end
				end
			end
		end
	elseif self.status == LAND_STATUS_PLAY then
		local curtime = get_second_time()
		if curtime - self.time0_ >= self.time_outcard_ then
			local player = self.player_list_[self.cur_turn]
			if player and player.chair_id then
				if not player.TrusteeshipTimes then
					player.TrusteeshipTimes = 0
				end
				player.TrusteeshipTimes = player.TrusteeshipTimes + 1
				if player.TrusteeshipTimes >= 2 and not player.isTrusteeship then
					self:setTrusteeship(player,true)
				else
					self:trusteeship(player)
				end
			else
				self:finishgameError()
			end
		elseif curtime - self.gamelog.start_game_time > LAND_TIME_OVER then
			self:finishgameError()	
		end
	elseif self.status == LAND_STATUS_CALL then
		local curtime = get_second_time()
		if curtime - self.time0_ >= LAND_TIME_CALL_SCORE then
			local player = self.player_list_[self.cur_turn]
			if player then
				self:call_score(player, 0)
			else
				self:finishgameError()
			end
			self.time0_ = curtime
		end	
	elseif self.status == LAND_STATUS_DOUBLE then
		local curtime = get_second_time()
		if curtime - self.time0_ >= LAND_TIME_CALL_SCORE then
			for i,v in ipairs(self.player_list_) do
				if v and v.is_double == nil then
					self:call_double(v,false)
				end
			end
		end
	elseif self.status == LAND_STATUS_PLAYOFFLINE then
		local curtime = get_second_time()
		if curtime - self.time0_ >= LAND_TIME_WAIT_OFFLINE then
			if def_second_game_type==def_private then
				self:privatefinishgame(player)
			else
				self:finishgame(player)
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

function ddz_table:private_init()
    local __cell = self.private_room_cell_money
    local __moneylimit = __cell*self.private_room_chair_count
	self.privateRules={{cell=__cell},
	{allow_chair=self.private_room_chair_count},
	{allow_lookon=false},
	{moneyLimit=__moneylimit},
	{allow_double=1},
	{highBeishuLimit=1},
	{allowYixiaoBoDa=1},
	{nguid=self.private_room_owner_guid},
	{nstatues=1}}
	self.game_runtimes = 0
	self.private_vote_status = false     
	self.private_vote_list = {}			 
	self.private_vote_time = 0			 
	self.private_vote_count = 0			 
	self.private_vote_chairid=0 	 
	self.totalwinlost={0,0,0}
	self:clear_ready()
end
function ddz_table:land_configchange(player, configlist)
	local nallow = configlist[1]
	local nlimitbeishu = configlist[2]
	local nallowYiXiaoBoda = configlist[3]
	self.privateRules[5].allow_double=nallow
	if nlimitbeishu==1 then
		self.privateRules[6].highBeishuLimit=1
	else
		self.privateRules[6].highBeishuLimit=32
	end
	
	self.privateRules[7].allowYixiaoBoDa=nallowYiXiaoBoda
	self.privateRules[9].nstatues=1
	local notify = {
		nallowDouble = self.privateRules[5].allow_double,
		nlimitbeishu = nlimitbeishu,
		nallowYiXiaoBoda = self.privateRules[7].allowYixiaoBoDa,
		ncell = self.privateRules[1].cell,
		nlimit = self.privateRules[4].moneyLimit,
		nhosterguid= self.privateRules[8].nguid,
		nstatues=self.privateRules[9].nstatues,
		nreason = 1,
		private_room_has_start = (self.game_runtimes > 0 and 1 or 2),
	}
	self:land_broadcast_msg_to_client("SC_PrivateConfigChange", notify)
end
function ddz_table:land_getconfig( player)
	local notify = {
		nallowDouble = self.privateRules[5].allow_double,
		nlimitbeishu = self.privateRules[6].highBeishuLimit,
		nallowYiXiaoBoda = self.privateRules[7].allowYixiaoBoDa,
		ncell = self.privateRules[1].cell,
		nlimit = self.privateRules[4].moneyLimit,
		nhosterguid= self.privateRules[8].nguid,
		nstatues=self.privateRules[9].nstatues,
		nreason = 2,
		private_room_has_start = (self.game_runtimes > 0 and 1 or 2),
	}
	self:land_post_msg_to_client_pb(player, "SC_PrivateConfigChange", notify)
end

function ddz_table:tab_vote(player,msg)	
	if def_second_game_type ~= def_private then
		log_error("tab_vote error type", def_second_game_type, self.status)
		return
	end
	if 	self.private_vote_status == false   then
		self.private_vote_list = {}
		self.private_vote_time = get_second_time()		
		self.private_vote_count = 0		
		self.private_vote_chairid = player.chair_id
		for i, v in ipairs(self.player_list_) do
			if v then
				 self.private_vote_list[i] = { senior = true, vote = false }
				 self.private_vote_count = self.private_vote_count + 1
			else
			 	self.private_vote_list[i] = { senior = false, vote = true }				
			end
		end
		self.private_vote_status = true
	end

	if self.private_vote_list[player.chair_id].senior == true then
		self.private_vote_list[player.chair_id].vote = msg.bret
		self.private_vote_count = self.private_vote_count - 1
		self.private_vote_list[player.chair_id].senior = false
		self:land_broadcast_msg_to_client("SC_TabVoteInfo", {chair_id = player.chair_id, bret = msg.bret,vote_chairid=self.private_vote_chairid})
		if self.private_vote_count == 0 or not msg.bret then
			self:check_vote()
		end
	end
end
function ddz_table:check_vote()	
	for i, p in ipairs(self.private_vote_list) do
		if p then
			if p.vote ~= true then
				self.private_vote_chairid = 0
				self.private_vote_status = false
				return
			end
		end
	end
	self:dismiss()
end

function ddz_table:dismiss(guid_, chair_id_)
	local __checkrlt = self.game_runtimes==0
	self:destroy_private_room(__checkrlt)
	if guid_ then
		self:land_broadcast_msg_to_client("SC_Dismiss", {
			guid = guid_,
			chair_id = chair_id_,
			})
	end
	
	local notify = {
		totoalscore= {}
	}
	notify.totoalscore=self.totalwinlost;
	self:land_broadcast_msg_to_client("SC_TotalScoreInfo", notify)
	for i,v in ipairs(self.player_list_) do
		if v then
			v:forced_exit()
		end
	end
	self:private_init()
end
function ddz_table:tab_tiren(player,msg)
	if def_second_game_type == def_private  and self.status == LAND_STATUS_FREE then
		if player.chair_id == self.private_room_owner_chair_id then
			local v = self.player_list_[msg.chair_id]
			if v then
				self:land_broadcast_msg_to_client("SC_TickNotify", {
					tickchairid = msg.chair_id,
					})
				v:forced_exit()
			end
		end
	end
end
function ddz_table:tab_getvoteinfo(player, msg)
	if self.private_vote_status then
		local notify={
			pb_sctableinfo={},
			votechairid=self.private_vote_chairid
		}
		for i, p in ipairs(self.private_vote_list) do
			if p then
				local m = {
					chair_id = i,
					bret = p.vote
				}
				table.insert(notify.pb_sctableinfo,m)
			end
		end
		self:land_post_msg_to_client_pb(player, "SC_TabVoteArray", notify)
	else
		self:land_post_msg_to_client_pb(player, "SC_TabVoteArray", {})
	end
end
