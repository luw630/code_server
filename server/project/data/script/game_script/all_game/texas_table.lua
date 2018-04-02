local pb = require "extern/lib/lib_pb"
tablex = require "extern/lib/lib_tablex"
require "game_script/virtual/virtual_table"
require "game_script/all_game/texas_gamelogic"
require "extern/lib/lib_table"
require "game_script/all_game/texas_robot"
local CHEAT_MODE = false
local ROUND_THINK_TIME 		= 15
local ACTION_INTERVAL_TIME  = 5
local AWARD_TIME 			= 8
local POSITION_LITTLE_BLIND		= 1--小盲
local POSITION_BIG_BLIND 		= 2--大盲
local POSITION_BUTTON			= 3--庄家
local POSITION_NORMAL			= 4--普通玩家
local STATUS_WAITING  	= 1
local STATUS_PRE_FLOP 	= 2
local STATUS_FLOP 		= 3
local STATUS_TURN 		= 4
local STATUS_RIVER 		= 5
local STATUS_SHOW_DOWN	= 6
local PLAYER_STATUS_WAITING	= 0		--等待
local PLAYER_STATUS_GAME	= 1
local PLAYER_STATUS_ALL_IN	= 2
local PLAYER_STATUS_FOLD	= 3
--local PLAYER_STATUS_LEAVE	= 5
local ACT_CALL 		= 1 --跟注2
local ACT_RAISE 	= 2 --加注
local ACT_CHECK 	= 3 --让牌
local ACT_FOLD 		= 4 --弃牌
local ACT_ALL_IN 	= 5 --全下
local ACT_NORMAL 	= 6 --普通
local ACT_THINK 	= 7 --牌局轮到此玩家，开始思考的计时状态
local ACT_WAITING	= 8 --刚进入的玩家
local CS_ERR_OK = 0 		--正常
local CS_ERR_MONEY = 1   --钱不够
local CS_ERR_STATUS = 2  --状态和阶段不同步错误
--local pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_TEXAS") = 12
texas_table = virtual_table:new()
texas_room_config = {
Texas_FreeTime = 3,
}


function texas_table:load_texas_config_file()
	TEXAS_FreeTime = texas_room_config.Texas_FreeTime
end
--重置
function texas_table:reset()
	self.t_status = STATUS_WAITING
	self.t_timer = 0
	--self.t_status_table = TABLE_STAT_BETTING
	self.blind_big_bet = self.room_:get_room_cell_money()
	self.blind_small_bet = self.blind_big_bet / 2
	self.t_tax = self.room_:get_room_tax()
	self.t_pot = 0		--主池
	self.t_idx = 1		--计算主池的index
	self.t_award_flag = 0
	self.t_recoonect = {}
	self.t_table_end = {}
	self.t_side_pot = {}
	self.t_side_generator = {}
	--self.t_side_pot = {0,0,0,0,0,0}  -- for testing
	
	--self.t_pot_player = {}	-- to load from config
	self.t_side_pot_players = {}
	self.t_public_cards = {}
	self.t_public_show = {}
	
	self.t_min_bet = self.blind_big_bet		--read from config
	self.t_max_bet = self.blind_small_bet * 3
	self.t_cur_max_bet = 0
	self.t_cur_min_bet = 0
	self.t_round = 1
	self.play_count = 0
	self.pass_count = 0
	self.t_player_count = 0
	self.t_ready_begin = 0
	self.t_active_player = {guid = 0,chair = 0}
	self.t_next_player = {guid = 0,chair = 0}
	self.t_SB_pos = {guid = 0,chair = 0}
	self.t_BB_pos = {guid = 0,chair = 0}
	self.t_main_pot = 0
	self.t_final_pool = {}
	for t_guid, t_player in pairs(self.t_player) do
		self.t_bet[t_guid] = {0,0,0,0}
		self.t_all_bet[t_guid] = 0
	end
	self:next_game()
end
-- 初始化
function texas_table:init(room, table_id, chair_count)
	virtual_table.init(self, room, table_id, chair_count)
	----FOR test
	if CHEAT_MODE then
		self.t_card_set = {
		--k 7 3 8 2   - 5 5   -3 9
		28,33,19,39,55, 23,50, 4,28, 7,9,
		17,18,19,20,21,22,23,24,25,26,27,28,29,	--梅花 A - K
		33,34,35,36,37,38,39,40,41,42,43,44,45,	--红桃 A - K
		49,50,51,52,53,54,55,56,57,58,59,60,61,	--黑桃 A - K
		}
	else
		self.t_card_set = {
		1, 2, 3, 4, 5, 6, 7, 8, 9, 10,11,12,13,	--方块 A - K
		17,18,19,20,21,22,23,24,25,26,27,28,29,	--梅花 A - K
		33,34,35,36,37,38,39,40,41,42,43,44,45,	--红桃 A - K
		49,50,51,52,53,54,55,56,57,58,59,60,61,	--黑桃 A - K
		}
		-- self.t_card_set = {
		-- 	0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,	--方块 A - K
		-- 	0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,	--梅花 A - K
		-- 	0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2A,0x2B,0x2C,0x2D,	--红桃 A - K
		-- 	0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3A,0x3B,0x3C,0x3D,	--黑桃 A - K
		-- }
	end
	virtual_table.init(self, room, table_id, chair_count)
	self.t_bet = {}
	self.t_all_bet = {}
	self.t_player = {}
	self:reset()
		--洗牌
	for i = 1,#self.t_card_set do
        local ranOne = win_random_int(1,#self.t_card_set+1-i)
        self.t_card_set[ranOne], self.t_card_set[#self.t_card_set+1-i] = self.t_card_set[#self.t_card_set+1-i],self.t_card_set[ranOne]
    end
	--self:load_texas_config_file()
	
	--测试
	--self.t_bet[10] = {10,20,30,0}

end
-- 心跳
function texas_table:tick()
	if get_second_time() >= self.t_timer then
		if self.t_player_count > 1 and self.t_ready_begin > 0 then
			if self.t_status == STATUS_WAITING and self.play_count == 0 then
				self:position_init()
			else
				self:start_game()
			end
		end
		if self.t_status == STATUS_SHOW_DOWN then
			if self.t_award_flag == 0 then
				self:end_and_award()	--结算
			else
				self:info_ready_to_all()
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
function texas_table:count_ready_player()
	local len = 0
	for k, p in pairs(self.t_player) do
		if p then
			len = len +1
		end
	end
	return len
end
function texas_table:position_init()
	self.table_game_id = self:get_now_game_id()
	self.game_log = {
	table_game_id = self.table_game_id,
	start_game_time = os.time(),
	public_cards = {},
	players = {},
	}
	self.play_count = self.t_player_count
	--大小盲注
	self:set_button_and_blind()
	
	local big_blind = self:get_big_blind()
	for i = 1,7 do
		local l_chair = big_blind.chair + i
		if l_chair > 7 then
			l_chair = l_chair - 7
		end
		local l_player = self:get_player(l_chair)
		if l_player and self.t_player[l_player.guid] and self.t_player[l_player.guid].status == PLAYER_STATUS_WAITING then
			self.t_active_player = {
			chair = l_chair,
			guid = l_player.guid
			}
			break
		end
	end
	for i = 1,7 do
		local l_chair = self.t_active_player.chair + i
		if l_chair > 7 then
			l_chair = l_chair - 7
		end
		local l_player = self:get_player(l_chair)
		if l_player and self.t_player[l_player.guid] and self.t_player[l_player.guid].status == PLAYER_STATUS_WAITING then
			self.t_next_player = {
			chair = l_chair,
			guid = l_player.guid
			}
			break
		end
	end
	--self.t_timer = get_second_time() + ACTION_INTERVAL_TIME
end
--检查是否进入下一阶段
function texas_table:check_next_round()
	--检查是否所有玩家下注的钱 是否等于最大下注
	local in_game_num =0
	local all_in_num = 0
	for t_guid,v in pairs(self.t_player) do
		if v.status == PLAYER_STATUS_GAME then
			in_game_num = in_game_num + 1
			if self.t_cur_max_bet ~= self.t_bet[t_guid][self.t_round] then
				return false
			end
		elseif v.status == PLAYER_STATUS_ALL_IN then
			all_in_num = all_in_num + 1
		end
	end
	if in_game_num == 1 then
		if all_in_num == 0 then
			self.t_status = STATUS_SHOW_DOWN
		end
		self.t_timer = 0
		return true
	end
	--判断一轮下注过牌未全等
	if self.t_status > STATUS_WAITING and self.play_count > self.pass_count  then
		return false
	end
	self.t_timer = 0
	return true
end
--game
function texas_table:start_game()
	if self:check_next_round() then
		if self.t_status == STATUS_WAITING then
			self:send_user_cards()
		elseif self.t_status < STATUS_SHOW_DOWN then
			self:send_public_cards()
		else
			return
		end
	else
		--押注切换   超时/玩家等待中/离线
		if get_second_time() > self.t_timer then
			if self.t_player[self.t_active_player.guid] and
				self.t_player[self.t_active_player.guid].status == PLAYER_STATUS_GAME then
				self:cur_active_player_time_pass()
			end
			self:set_next_player()
		end
	end
end
function texas_table:send_user_cards()
	self.t_round = 1
	self.t_status = STATUS_PRE_FLOP
	self.play_count = 0
	self.pass_count = 0
	self.t_cur_max_bet = 0	--最大下注清零
	local user_cards_idx = 0
	
	--for testing
	if CHEAT_MODE then
		for i = 1,5 do
			table.insert(self.t_public_cards, self.t_card_set[i])
		end
	else
		-- 5张公共牌
		for i = 1,5 do
			local idx = win_random_int(1,#self.t_card_set - user_cards_idx)
			local card = self.t_card_set[idx]
			table.insert(self. t_public_cards, card)
			--把最后5张的牌移到之前抽出公共牌的地方,5个idx
			self.t_card_set[idx] = self.t_card_set[#self.t_card_set - user_cards_idx]
			self.t_card_set[#self.t_card_set - user_cards_idx] = card
			user_cards_idx = user_cards_idx + 1
		end
	end
	self.game_log.t_public_cards = self.t_public_cards
	--扣除小盲注,底注
	local small_blind = self:get_small_blind()
	local l_player = self:get_player(small_blind.chair)
	self:add_bet(l_player, self.blind_small_bet)
	
	--扣除大盲注，2倍底注
	local big_blind = self:get_big_blind()
	l_player = self:get_player(big_blind.chair)
	self.t_cur_max_bet = self.blind_big_bet
	self:add_bet(l_player, self.blind_big_bet)
	--table info
	local notify = {}
	notify.pb_table = {
	state = STATUS_PRE_FLOP,
	pot = self.t_pot,
	max_bet = self.t_max_bet,
	}
	notify.pb_user = {}
	--for testing
	local card_inx = 5
	--发牌给准备的玩家
	for _guid, p in pairs(self.t_player) do
		if self.t_player[_guid].status == PLAYER_STATUS_WAITING then
			local l_player = self:get_player(p.chair)
			if l_player then
				--选出两张牌发给玩家
				local l_user_cards = {}
				if CHEAT_MODE then
					--for testing
					for i = 1,2 do
						card_inx = card_inx + 1
						l_user_cards[i] = self.t_card_set[card_inx]
					end
				else
					for i = 1,2 do
						user_cards_idx = user_cards_idx + 1
						local idx = math.random(1,#self.t_card_set - user_cards_idx)
						local card = self.t_card_set[idx]
						table.insert(l_user_cards,card)
						self.t_card_set[idx] = self.t_card_set[#self.t_card_set - user_cards_idx]
						self.t_card_set[#self.t_card_set - user_cards_idx] = card
					end
				end
				
				self.t_player[_guid].cards = l_user_cards
				self.t_player[_guid].status = PLAYER_STATUS_GAME
				l_player.is_follow = false
				local v = {
				guid = _guid,
				chair = p.chair,
				money = l_player:get_money(),
				action = ACT_NORMAL,
				hole_cards = 1,
				position = self.t_player[_guid].position,
				countdown = 0,
				bet_money = self.t_bet[_guid][self.t_round],
				win_money = 0,
				main_pot_money = 0
				}
				--当前玩家，动作为在思考
				if self.t_active_player.guid == _guid then
					v.countdown = ROUND_THINK_TIME
					v.action = ACT_THINK
				end
				
				table.insert(notify.pb_user, v)
				self.play_count = self.play_count + 1
				self.game_log.players[p.chair] = {
				nickname = l_player.nickname,
				chair = l_player.nickname,
				money_old = l_player:get_money(),
				cards = l_user_cards,
				status = {}
				}
			end
		end
	end
	if self:cheat_mode() then
		for k, p in pairs(self.game_log.players) do
			local l_player = self:get_player(p.chair)
			if l_player then
				p.cards = self.t_player[l_player.guid].cards
			end
		end	
	end
	
	--发给每个人(加上自己的底牌)
	local msg = notify
	for k, p in pairs(notify.pb_user) do
		msg.pb_user[k].cards = self.t_player[p.guid].cards
		msg.pb_user[k].cards_type = CT_HIGH_CARD
		if t_get_value(self.t_player[p.guid].cards[1]) == t_get_value(self.t_player[p.guid].cards[2]) then
			self.t_player[p.guid].cards_type = CT_ONE_PAIR
			msg.pb_user[k].cards_show = self.t_player[p.guid].cards
		end
		local l_player = self:get_player(p.chair)
		if l_player then
			post_msg_to_client_pb_sh(l_player,"SC_TexasSendUserCards", msg)
		end
		msg.pb_user[k].cards_type = nil
		msg.pb_user[k].cards_show = {}
		msg.pb_user[k].cards = {}
	end
	--清除准备状态进入游戏
	--self:clear_ready() virtual_table:clear_ready()
	self.t_timer = get_second_time() + ROUND_THINK_TIME
end

function texas_table:cheat_mode( ... )
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	local cheatmode = 0
	if ly_use_robot then
		if ly_robot_storage < 0 or (ly_robot_smart_lv > 0 and (math.random(1,100) <= ly_robot_smart_lv)) then
			cheatmode = 1
		end
	end

	if cheatmode == 0 then
		log_info("cheat_mode off")
		return false
	end

	if not(self:has_robot_player()) then
		return false
	end
	local android = {}
	local l_candidate = {}
	for _guid, p in pairs(self.t_player) do
		if self.t_player[_guid].status == PLAYER_STATUS_GAME then
			local chair_id = self.t_player[_guid].chair
			local l_info = {guid = _guid, card_type = 0,cards = {}}
			l_info.card_type, l_info.cards = t_get_type_five_from_seven(self.t_player[_guid].cards, self.t_public_cards)
			table.insert(l_candidate, l_info)
			if self:get_player(chair_id).is_android then
				table.insert(android,_guid)
			end
		end
	end
	log_info("l_candidate lenth = "..#l_candidate)

	local l_card_type, main_win_array = get_win_player(l_candidate)
	local winplayer = {}

	log_info("main_win_array lenth = "..#main_win_array)
	
	for k, _guid in ipairs(main_win_array) do
		local chair_id = self.t_player[_guid].chair
		if not(self:get_player(chair_id).is_android) then
			table.insert(winplayer,_guid)
		else
			self:get_player(chair_id).is_follow = true
			log_info("win_android  = ".._guid)
		end
	end

	if #winplayer == 0 then
		return false
	end

	local win_index = 1
	for k, _guid in ipairs(winplayer) do
		self.t_player[_guid].cards,self.t_player[android[win_index]].cards = self.t_player[android[win_index]].cards,	self.t_player[_guid].cards
		local chair_id = self.t_player[android[win_index]].chair
		self:get_player(chair_id).is_follow = true
		win_index = win_index + 1
		if win_index > #android then
			break
		end
	end

	log_info("cheat_mode on")
	return true
end

function texas_table:send_public_cards()
	--下一轮
	self.t_status = self.t_status + 1
	if self.t_status > STATUS_RIVER then
		return
	end
	
	self:cal_side_pot()
	self.t_round = self.t_round + 1
	--self.t_cur_pot = 0	  --当前轮底池清零
	self.t_cur_max_bet = 0	  --最大下注清零
	self.pass_count = 0
	self.play_count = 0
	--公共牌
	--self.t_public_show = self.t_public_cards
	self.t_public_show = {}
	for i = 1, self.t_status do
		table.insert(self.t_public_show, self.t_public_cards[i])
	end
	--公共牌增量
	local l_public_show = {}
	if self.t_status == STATUS_FLOP then
		l_public_show = self.t_public_show
	else
		l_public_show[1] = self.t_public_show[self.t_status]
	end
	local msg = {}
	msg.pb_table = {
	state = self.t_status,
	public_cards = self.t_public_show,
	side_pot = self.t_side_pot
	}
	msg.pb_user = {}
	msg.public_cards = l_public_show
	--本轮牌桌上玩家状态重置 bet_money, action
	for t_guid, t_player in pairs(self.t_player) do
		local l_player = self:get_player(t_player.chair)
		if l_player then
			local l_has_cards = 1
			if self.t_player[t_guid].status == PLAYER_STATUS_GAME then
				self.play_count = self.play_count + 1
			elseif self.t_player[t_guid].status == PLAYER_STATUS_WAITING or
				self.t_player[t_guid].status == PLAYER_STATUS_FOLD then
				l_has_cards = 0
			end
			local l_user = {
			chair = l_player.chair_id,
			guid = t_guid,
			money = l_player:get_money(),
			bet_money = self.t_bet[t_guid][self.t_round],
			hole_cards = l_has_cards,
			countdown = 0,
			win_money = 0,
			main_pot_money = 0
			}
			table.insert(msg.pb_user, l_user)
			if self.game_log.players[t_player.chair] then
				table.insert(self.game_log.players[t_player.chair].status, self.t_player[t_guid].status)
			end
		end
	end
	for k, p in pairs(msg.pb_user) do
		--牌型
		if self.t_player[p.guid].status == PLAYER_STATUS_GAME or self.t_player[p.guid].status == PLAYER_STATUS_ALL_IN then
			local analysisResult = {}
			local highestCards = {}
			if #self.t_public_show == 3 then
				local l_cards = tablex.copy(self.t_player[p.guid].cards)
				for k,v in ipairs(self.t_public_show) do
					table.insert(l_cards, v)
				end
				msg.pb_user[k].cards_type, analysisResult = t_get_card_type(l_cards)
			elseif #self.t_public_show == 5 then
				msg.pb_user[k].cards_type, highestCards, analysisResult = t_get_type_five_from_seven(self.t_player[p.guid].cards, self.t_public_show)
			elseif #self.t_public_show == 4 then
				msg.pb_user[k].cards_type, highestCards, analysisResult = t_get_type_five_from_six(self.t_player[p.guid].cards, self.t_public_show)
			end
			if msg.pb_user[k].cards_type > CT_HIGH_CARD then
				msg.pb_user[k].cards_show = t_get_highlight_cards(analysisResult, highestCards, msg.pb_user[k].cards_type)
			end
		end
		local l_player = self:get_player(p.chair)
		if l_player then
			post_msg_to_client_pb_sh(l_player, "SC_TexasSendPublicCards", msg)
		end
		msg.pb_user[k].cards_type = nil
		msg.pb_user[k].cards_show = nil
	end
	if self.play_count > 1 then
		--第一个行动 小盲位
		local l_SB = self:get_small_blind()
		self.t_active_player.chair = l_SB.chair
		self.t_active_player.guid = l_SB.guid
		--确定t_next_player
		for i = 1,7 do
			local l_chair = self.t_active_player.chair + i
			l_chair = l_chair > 7 and l_chair - 7 or l_chair
			local l_player = self:get_player(l_chair)
			if l_player and self.t_player[l_player.guid] and self.t_player[l_player.guid].status == PLAYER_STATUS_GAME then
				self.t_next_player = {
				chair = l_chair,
				guid = l_player.guid
				}
				break
			end
		end
		if self.t_player[self.t_active_player.guid] and
			self.t_player[self.t_active_player.guid].status == PLAYER_STATUS_GAME then
			local nofity = {
			chair = self.t_active_player.chair,
			action = ACT_THINK,
			bet_money = 0
			}
			local l_player = self:get_player(self.t_active_player.chair)
			nofity.pb_action = {
			chair = self.t_active_player.chair,
			guid = self.t_active_player.guid,
			money = l_player:get_money(),
			bet_money = self.t_bet[self.t_active_player.guid],
			action = ACT_THINK,
			hole_cards = 1,
			countdown = ROUND_THINK_TIME + 1,
			win_money = 0,
			main_pot_money = 0
			}
			nofity.pb_table = {
			state = self.t_status,
			max_bet = self.t_max_bet,
			min_bet = self.t_cur_min_bet,
			pot = self.t_pot,
			}
			self:t_broadcast("SC_TexasUserAction",nofity)
			self.t_player[self.t_active_player.guid].action = ACT_THINK
		else
			--如果小盲位已弃牌，查找下一个玩家
			self:set_next_player()
		end
		--发牌后需要播动画，时间加长延迟
		self.t_timer = get_second_time() + ROUND_THINK_TIME + ACTION_INTERVAL_TIME
	else
		--只有一玩家位，直接发牌
		self.t_timer = get_second_time() + ACTION_INTERVAL_TIME
	end
end
--确定庄家，盲位
function texas_table:set_button_and_blind()
	local l_player = nil
	local l_chair = nil
	if self.t_button == nil then	--or self.t_button.chair == 0
		self.t_button = {}
		for t_guid, t_player in pairs(self.t_player) do
			l_player = self:get_player(t_player.chair)
			if l_player then
				self.t_button.chair = t_player.chair
				self.t_button.guid = t_guid
				self.t_player[t_guid].position = POSITION_BUTTON
				break
			end
		end
	else
		l_chair = self.t_button.chair
		self.t_player[self.t_button.guid].position = POSITION_NORMAL
		for i = 1,7 do
			l_chair = self.t_button.chair + i
			l_chair = l_chair > 7 and l_chair - 7 or l_chair
			l_player = self:get_player(l_chair)
			if l_player and self.t_player[l_player.guid] then
				self.t_button = {chair = l_chair, guid = l_player.guid}
				self.t_player[l_player.guid].position = POSITION_BUTTON
				break
			end
		end
	end
	--大小盲位
	for i = 1,7 do
		l_chair = self.t_button.chair + i
		l_chair = l_chair > 7 and l_chair - 7 or l_chair
		l_player = self:get_player(l_chair)
		if l_player and self.t_player[l_player.guid] then
			if self.t_SB_pos.guid == 0 then
				self.t_SB_pos = {chair = l_chair, guid = l_player.guid}
				self.game_log.small_blind_info = self.t_SB_pos
			else
				self.t_BB_pos = {chair = l_chair, guid = l_player.guid}
				self.game_log.big_blind_info = self.t_BB_pos
				break
			end
		end
	end
end
--获取小盲位
function texas_table:get_small_blind()
	return self.t_SB_pos
end
--获取大盲位
function texas_table:get_big_blind()
	return self.t_BB_pos
end
--超时
function texas_table:cur_active_player_time_pass()
	--当前玩家
	local msg = {
	chair = self.t_active_player.chair,
	bet_money = self.t_bet[self.t_active_player.guid][self.t_round]
	}
	local l_player = self:get_player(self.t_active_player.chair)
	if l_player then
		--超时让牌
		if self.t_bet[l_player.guid][self.t_round] == self.t_cur_max_bet then
			
			self.pass_count = self.pass_count + 1
			msg.action = ACT_CHECK
		else
			--测试用 默认跟注 for testing
			-- local own_money = l_player:get_money()
			-- local l_bet_money = self.t_cur_max_bet - self.t_bet[l_player.guid][self.t_round]
			-- --钱不够，全下
			-- if own_money <= l_bet_money then
			-- 	l_bet_money = own_money
			-- 	msg.action = ACT_ALL_IN
			-- 	self.t_player[l_player.guid].status = PLAYER_STATUS_ALL_IN
			-- 	self.play_count = self.play_count - 1
			-- else
			-- 	msg.bet_money = l_bet_money	--增量
			-- 	msg.action = ACT_CALL
			-- 	self.pass_count = self.pass_count + 1
			-- end
			-- self:add_bet(l_player, l_bet_money)
			--超时弃牌
			self.t_player[l_player.guid].status = PLAYER_STATUS_FOLD
			msg.action = ACT_FOLD
			msg.bet_money = 0
			self.play_count = self.play_count - 1
		end
		--广播玩家动作
		msg.pb_action = {
		guid = self.t_active_player.guid,
		chair = self.t_active_player.chair,
		money = l_player:get_money(),
		bet_money = self.t_bet[l_player.guid][self.t_round],
		action = msg.action,
		hole_cards = 1,
		countdown = 0,
		win_money = 0,
		main_pot_money = 0
		}
		msg.pb_table = {
		state = self.t_status,
		pot = self.t_pot,
		side_pot = self.t_side_pot
		}
		
		self.t_player[l_player.guid].action = msg.action
		self:t_broadcast("SC_TexasUserAction", msg)
	end
end
--设置下一个说话玩家
function texas_table:set_next_player()
	if self:check_next_round() then
		return
	end
	self.t_active_player.guid = self.t_next_player.guid
	self.t_active_player.chair = self.t_next_player.chair
	for i = 1,7 do
		local l_chair = self.t_next_player.chair + i
		if l_chair > 7 then
			l_chair = l_chair - 7
		end
		local l_player = self:get_player(l_chair)
		if l_player and self.t_player[l_player.guid] and self.t_player[l_player.guid].status == PLAYER_STATUS_GAME then
			-- wait to set next player
			self.t_next_player = {
			guid = l_player.guid,
			chair = l_chair
			}
			--broadcasst next turn l_player is in thinking
			local tmp_player = self:get_player(self.t_active_player.chair)
			if tmp_player then
				local msg = {
				chair = self.t_active_player.chair,
				action = ACT_THINK,
				bet_money = 0
				}
				msg.pb_table = {
				state = self.t_status,
				pot = self.t_pot
				}
				msg.pb_action = {
				guid = self.t_active_player.guid,
				chair = self.t_active_player.chair,
				money = tmp_player:get_money(),
				hole_cards = 1,
				action = ACT_THINK,
				countdown = ROUND_THINK_TIME,
				bet_money = self.t_bet[self.t_active_player.guid][self.t_round],
				win_money = 0,
				main_pot_money = 0
				}
				self:t_broadcast("SC_TexasUserAction", msg)
				self.t_player[self.t_active_player.guid].action = ACT_THINK
				self.t_timer = get_second_time() + ROUND_THINK_TIME
				return
			end
		end
	end
	--异常退出
	self.t_timer = get_second_time() + ACTION_INTERVAL_TIME
end
--结算 --发放奖励
function texas_table:end_and_award()
	self:cal_side_pot()
	self:cal_main_pot()
	--同步游戏数据
	local msg = {}
	msg.pb_table = {
	state = self.t_status,
	pot = self.t_pot,
	side_pot = self.t_side_pot,
	}
	msg.pb_user = {}
	self.game_log.pot = self.t_pot
	self.game_log.side_pot = self.t_side_pot
	self.game_log.side_pot_players = self.t_side_pot_players
	local t_side_pool_array = {}
	--设置sc_proto返回数组
	for k, _guid in ipairs(self.t_side_pot) do
		table.insert(t_side_pool_array, 0)
	end
	local in_game_num =0
	for t_guid, t_player in pairs(self.t_player) do
		if t_player.status == PLAYER_STATUS_GAME or t_player.status == PLAYER_STATUS_ALL_IN then
			in_game_num = in_game_num + 1
		end
		if self.game_log.players[t_player.chair] then
			self.game_log.players[t_player.chair].bet = self.t_bet[t_guid]
			self.game_log.players[t_player.chair].victory = 0
			table.insert(self.game_log.players[t_player.chair].status, self.t_player[t_guid].status)
		end
	end
	if in_game_num < 2 or self.t_player_count < 2 then
		self:end_with_one_player(msg, t_side_pool_array)
		return
	end
	--每个玩家计算牌型
	for t_guid, t_player in pairs(self.t_player) do
		local l_player = self:get_player(t_player.chair)
		if l_player then
			local l_cards = {}
			local l_user = {
			chair = t_player.chair,
			guid = t_guid,
			bet_money = self.t_bet[t_guid][self.t_round],
			hole_cards = 0,
			countdown = 0,
			victory = 2,	        -- 1-win; 2-lose
			biggest_winner = 2,
			win_money = 0,
			main_pot_money = 0,
			}
			if t_player.show_cards then
				l_user.cards = t_player.cards
			end
			if self.t_player[t_guid].status == PLAYER_STATUS_GAME or
				self.t_player[t_guid].status == PLAYER_STATUS_ALL_IN then
				l_user.cards = self.t_player[t_guid].cards
				l_cards = tablex.copy(self.t_player[t_guid].cards)
				
				if #self.t_public_show == 5 then
					l_user.cards_type = t_get_type_five_from_seven(l_cards,self.t_public_show)
				end
			end
			
			msg.pb_user[t_player.chair] = l_user;
		end
	end
	local l_candidate = {}
	for guid, t_player in pairs(self.t_player) do
		if t_player.status == PLAYER_STATUS_GAME or t_player.status == PLAYER_STATUS_ALL_IN  then
			local l_info = {guid = guid, card_type = 0,cards = {}}
			l_info.card_type, l_info.cards = t_get_type_five_from_seven(self.t_player[guid].cards, self.t_public_cards)
			table.insert(l_candidate, l_info)
		end
	end
	local l_card_type, main_win_array = get_win_player(l_candidate)
	local per_money_from_main_pot = math.floor(self.t_main_pot / #main_win_array)
	self.game_log.main_pot_winner = main_win_array
	--最后玩家赢取的筹码池
	self.t_final_pool = {}
	--主池赢家
	for k, _guid in ipairs(main_win_array) do
		self.t_final_pool[_guid] = per_money_from_main_pot
		
		local main_chair = self.t_player[_guid].chair
		msg.pb_user[main_chair].victory = 1
		msg.pb_user[main_chair].biggest_winner = 1	--biggest winnwer
		msg.pb_user[main_chair].main_pot_money = per_money_from_main_pot
		self.game_log.players[main_chair] = self.game_log.players[main_chair] or {}
		self.game_log.players[main_chair].victory = 1
	end
	--遍历所有边池，计算每个边池赢家
	for _pot_id, _pot_money in ipairs(self.t_side_pot) do
		local side_win_num = 0
		local per_money_form_one_side_pot = 0
		local side_pot_winner_flag = 0
		local side_candidate = {}
		
		if self.t_side_pot_players[_pot_id] then
			for p_key, p_guid in ipairs(self.t_side_pot_players[_pot_id]) do
				--统计主池赢家在当前边池里的数量
				if self.t_final_pool[p_guid] then
					side_pot_winner_flag = side_pot_winner_flag + 1
				end
				local l_info = {guid = p_guid, card_type = 0,cards = {}}
				l_info.card_type, l_info.cards = t_get_type_five_from_seven(self.t_player[p_guid].cards, self.t_public_cards)
				table.insert(side_candidate, l_info)
			end
		end
		--如果赢家在边池里，赢家分享边池
		if side_pot_winner_flag > 0 then
			per_money_form_one_side_pot = math.floor(_pot_money / side_pot_winner_flag)
			for p_key, p_guid in ipairs(self.t_side_pot_players[_pot_id]) do
				if self.t_final_pool[p_guid] then
					self.t_final_pool[p_guid] = self.t_final_pool[p_guid] + per_money_form_one_side_pot
					local side_chair = self.t_player[p_guid].chair
					-- if msg.pb_user[side_chair].side_pot_money == nil then
					-- 	msg.pb_user[side_chair].side_pot_money = t_side_pool_array
					-- end
					msg.pb_user[side_chair].side_pot_money = msg.pb_user[side_chair].side_pot_money or t_side_pool_array
					msg.pb_user[side_chair].side_pot_money[_pot_id] = per_money_form_one_side_pot
				end
			end
		else
			--主池赢家不在边池中，重新计算边池赢家
			local l_card_type, side_win_array = get_win_player(side_candidate)
			local per_money_form_one_side_pot = math.floor(_pot_money / #side_win_array)
			for p_key, p_guid in ipairs(side_win_array) do
				self.t_final_pool[p_guid] = self.t_final_pool[p_guid] or 0
				self.t_final_pool[p_guid] = self.t_final_pool[p_guid] + per_money_form_one_side_pot
				local side_chair = self.t_player[p_guid].chair
				local side_chair = self.t_player[p_guid].chair
				-- if msg.pb_user[side_chair].side_pot_money == nil then
				-- 	msg.pb_user[side_chair].side_pot_money = t_side_pool_array
				-- end
				msg.pb_user[side_chair].side_pot_money = msg.pb_user[side_chair].side_pot_money or t_side_pool_array
				msg.pb_user[side_chair].side_pot_money[_pot_id] = per_money_form_one_side_pot
			end
		end
	end
	--返回消息
	for _guid, _final_money in pairs(self.t_final_pool) do
		if self.t_player[_guid] then
			local l_chair = self.t_player[_guid].chair
			local l_player = self:get_player(l_chair)
			local l_tax = ( _final_money - self.t_all_bet[l_player.guid] )* self.t_tax
			if l_tax < 1 then
				l_tax = 0
			else
				l_tax = math.floor(l_tax + 0.5)
			end
			msg.pb_user[l_chair].tax = l_tax
			local l_win_money = _final_money - l_tax
			if l_player then
				msg.pb_user[l_chair].win_money = l_win_money - self.t_all_bet[l_player.guid]
				l_player:add_money(
				{{ money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"),
				money = l_win_money }},
				pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_TEXAS")
				)
				--print("-------player add money",_guid,"   ",l_win_money)
				self.game_log.players[l_chair].tax = l_tax
				self.game_log.players[l_chair].win_money = l_win_money
			end
		end
	end
	for i, _v in pairs(msg.pb_user) do
		local l_player = self:get_player(msg.pb_user[i].chair)
		if l_player then
			msg.pb_user[i].money = l_player:get_money()
			if self.game_log.players[msg.pb_user[i].chair] then
				self.game_log.players[msg.pb_user[i].chair].new_money = msg.pb_user[i].money
			end
		end
	end
	self.t_table_end = msg
	--for id, val in pairs(l_players) do table.insert(msg.pb_user, val) end
	self:t_broadcast("SC_TexasTableEnd", msg)
	--重置
	self.t_award_flag = 1
	self.t_timer = get_second_time() + AWARD_TIME
	--gameLog
	self.game_log.end_game_time = os.time()
	local s_log = lua_to_json(self.game_log)
	log_info("running_game_log")
	log_info(s_log)
	self:write_game_log_to_mysql(self.game_log.table_game_id,self.def_game_name,s_log,self.game_log.start_game_time,self.game_log.end_game_time)

	self:check_exit()

end
function texas_table:end_with_one_player(msg, t_side_pool_array)
	local survive_player = {
	chair = 0,
	guid = 0
	}
	--独享主池子
	local last_one_win_money = self.t_main_pot
	for _guid, t_player in pairs(self.t_player) do
		local player = self:get_player(t_player.chair)
		if player and self.t_player[_guid] then
			local pb_player = {
			guid = _guid,
			chair = t_player.chair,
			money = player:get_money(),
			hole_cards = 1,
			countdown = 0,
			bet_money = self.t_bet[_guid][self.t_round],
			victory = 2,
			biggest_winner = 2,
			win_money = 0,
			main_pot_money = 0
			}
			if t_player.show_cards then
				l_user.cards = t_player.cards
			end
			if self.t_player[_guid].status == PLAYER_STATUS_GAME or
				self.t_player[_guid].status == PLAYER_STATUS_ALL_IN then
				pb_player.biggest_winner = 1
				pb_player.victory = 1
				pb_player.main_pot_money = self.t_pot
				survive_player.chair = t_player.chair
				survive_player.guid = _guid
				for _pot_id, _pot_money in ipairs(self.t_side_pot) do
					local side_win_num = 0
					local per_money_form_one_side_pot = 0
					local side_pot_winner_flag = 0
					local side_candidate = {}
					
					--如果赢家在当前边池里，单独分享边池
					for p_key, p_guid in ipairs(self.t_side_pot_players[_pot_id]) do
						if p_guid == survive_player.guid then
							last_one_win_money = last_one_win_money + _pot_money
							pb_player.side_pot_money = pb_player.side_pot_money or t_side_pool_array
							pb_player.side_pot_money[_pot_id] = _pot_money
						end
					end
				end
				
				local l_tax = (last_one_win_money - self.t_all_bet[_guid] ) * self.t_tax
				if l_tax < 1 then
					l_tax = 0
				else
					l_tax = math.floor(l_tax + 0.5)
				end
				local l_win_money = last_one_win_money - l_tax
				
				pb_player.tax = l_tax
				--返回消息
				local l_player = self:get_player(survive_player.chair)
				if l_player then
					l_player:add_money(
					{{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"),
					money = l_win_money}},
					pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_TEXAS")
					)
					pb_player.money = l_player:get_money()
				end
				pb_player.win_money = l_win_money - self.t_all_bet[_guid]
				if self.game_log.players[survive_player.chair] then
					self.game_log.players[survive_player.chair].victory = 1
					self.game_log.players[survive_player.chair].tax = l_tax
					self.game_log.players[survive_player.chair].win_money = l_win_money
				end
			end
			table.insert(msg.pb_user, pb_player)
		end
	end
	
	self:t_broadcast("SC_TexasTableEnd", msg)
	self.t_table_end = msg
	--重置
	self.t_award_flag = 1
	self.t_timer = get_second_time() + AWARD_TIME
	--gameLog
	self.game_log.end_game_time = os.time()
	local s_log = lua_to_json(self.game_log)
	log_info("running_game_log")
	log_info(s_log)
	self:write_game_log_to_mysql(self.game_log.table_game_id,self.def_game_name,s_log,self.game_log.start_game_time,self.game_log.end_game_time)
	self:check_exit()
end
function texas_table:check_exit()
	local room_limit = self.room_:get_room_limit()
	for i,v in pairs(self.player_list_) do
	    if v  and self.t_player[v.guid] ~= nil then
	        if self.t_player[v.guid].onTable == false  then
	        	  v:forced_exit()
	        	  self.t_player[v.guid] = nil
	        	  post_msg_to_client_pb_sh(v,"SC_Gamefinish",{
					money = v.pb_base_info.money})
	        else
	              v:check_forced_exit(room_limit)
	        end
	    end
	end

	if self:get_real_player_count() >= 2 then
		for i,v in ipairs(self.player_list_) do
			if v and v.is_android then
				v:forced_exit()
				break		
			end
		end
	end

	self:check_game_maintain()

end

--玩家下注
function texas_table:add_bet(player, money)
	-- if not player or player:get_money() < money then
	-- 	return false
	-- end
	
	--print("  [[[-------------  ]]]] bet money: ", money)
	player:cost_money(
	{{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = money}},
	pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_TEXAS")
	)
	self.t_pot = self.t_pot + money
	self.t_all_bet[player.guid] = self.t_all_bet[player.guid] + money
	self.t_bet[player.guid][self.t_round] = self.t_bet[player.guid][self.t_round] + money
	--当前最大注
	if self.t_bet[player.guid][self.t_round] >= self.t_cur_max_bet then
		self.t_cur_max_bet = self.t_bet[player.guid][self.t_round]
	end
	if player:get_money() == 0 then
		--player.guid == self.t_button.guid then --if player:get_money() == 0 then
		self.t_player[player.guid].status = PLAYER_STATUS_ALL_IN
		
		self:record_side_generator(player.guid)
		--记录边池拥有玩家
	end
	return true
end
--计算边池
function texas_table:record_side_generator(guid)
	table.insert(self.t_side_generator, guid)
end
--增加边池记录
function texas_table:cal_side_pot()
	local prev_side_pot_id = #self.t_side_pot
	if #self.t_side_generator > 0 then
		if prev_side_pot_id > 0 then
			--本轮产生新的边池之前，已有边池
			local lest_bet_money = self.t_cur_max_bet
			local bet_player_num = 0
			for t_guid, t_player in pairs(self.t_player) do
				if self.t_bet[t_guid][self.t_round] > 0 then
					bet_player_num = bet_player_num + 1
					if self.t_bet[t_guid][self.t_round] < lest_bet_money  then
						lest_bet_money = self.t_bet[t_guid][self.t_round]
					end
				end
			end
			--最小下注*人数 加入上一个边池
			self.t_side_pot[prev_side_pot_id] = self.t_side_pot[prev_side_pot_id] + bet_player_num * lest_bet_money
		end
		local side_pot_id = prev_side_pot_id + 1
		for _id, g_guid in pairs(self.t_side_generator) do
			local smallest_bet_money = self.t_bet[g_guid][self.t_round]   --5  10 15
			local g_min_bet_money = self.t_cur_max_bet			   --10 15 20
			local side_money = 0
			
			local g_bigger_than_min_num = 0
			for t_guid, t_player in pairs(self.t_player) do
				
				--只要比全下玩家大，都计入统计
				if self.t_bet[t_guid][self.t_round] > smallest_bet_money then
					g_bigger_than_min_num = g_bigger_than_min_num + 1
					self.t_side_pot_players[side_pot_id] = self.t_side_pot_players[side_pot_id] or {}
					table.insert(self.t_side_pot_players[side_pot_id], t_guid)
					
					--找除了此全下玩家之外，最小下注筹码
					if self.t_bet[t_guid][self.t_round] < g_min_bet_money  then
						g_min_bet_money = self.t_bet[t_guid][self.t_round]
					end
				end
			end
			side_money = g_bigger_than_min_num * (g_min_bet_money - smallest_bet_money)
			--在玩数量 self.play_count
			-- side_money = side_money + money
			-- self.t_side_pot_players[side_pot_num] = self.t_side_pot_players[side_pot_num] or {}
			-- table.insert(self.t_side_pot_players[side_pot_num], t_guid)
			if side_money > 0 then
				self.t_side_pot[side_pot_id] = side_money
				side_pot_id = side_pot_id + 1
			end
		end
		self.t_side_generator = {}
	elseif prev_side_pot_id > 0 then
		--本轮未产生新的边池，之前有边池
		for t_guid, t_player in pairs(self.t_player) do
			if self.t_bet[t_guid][self.t_round] > 0 then
				self.t_side_pot[prev_side_pot_id] = self.t_side_pot[prev_side_pot_id] + self.t_bet[t_guid][self.t_round]
			end
		end
	end
end
function texas_table:cal_main_pot()
	local side_pot_sum = 0
	for _pot_id, _pot_money in ipairs(self.t_side_pot) do
		side_pot_sum = side_pot_sum + _pot_money
	end
	self.t_main_pot = self.t_pot - side_pot_sum
end
function texas_table:cal_max_bet()
	--查找最大拥有金额玩家
	local table_max_money = 0
	for t_guid, t_player in pairs(self.t_player) do
		if self.t_player[t_player.guid].status == PLAYER_STATUS_GAME or
			self.t_player[t_player.guid].status == PLAYER_STATUS_ALL_IN then
			local l_player = self:get_player(t_player.chair)
			local l_money = l_player:get_money()
			if l_money > table_max_money then
				table_max_money = l_money
			end
		end
	end
	self.t_max_bet = self.t_pot > table_max_money and self.t_pot or table_max_money
end
--动作处理
function texas_table:player_action(player, talbeInstance, t_action, t_money)
	if self.t_active_player.guid ~= player.guid then
		return CS_ERR_STATUS
	end
	if t_money < 0 then
		t_money = 0
	end
	
	--cur player action
	local l_money = t_money
	local msg = {
	chair = player.chair_id,
	action = t_action,
	bet_money = l_money
	}
	--print("   (((--- player_action  ---)))   guid: ", player.guid, "  action: ",t_action)
	if t_action == ACT_CHECK then
		if self.t_cur_max_bet ~= self.t_bet[player.guid][self.t_round] then
			return CS_ERR_STATUS
		end
		self.pass_count = self.pass_count + 1
		msg.bet_money = 0
	elseif t_action == ACT_FOLD then
		self.t_player[player.guid].status = PLAYER_STATUS_FOLD
		self.play_count = self.play_count - 1
		msg.bet_money = 0
	elseif t_action == ACT_RAISE then
		if t_money == 0 then
			return CS_ERR_MONEY
		end
		local own_money = player:get_money()
		if t_money >= own_money then
			t_money = own_money
			t_action = ACT_ALL_IN
			self.t_player[player.guid].status = PLAYER_STATUS_ALL_IN
			self.play_count = self.play_count - 1
		else
			self.pass_count = self.pass_count + 1
		end
		-- t_money > self.t_cur_max_bet	or t_money < self.t_cur_min_bet
		-- if t_money > own_money or t_money > self.t_pot then
		-- 	return CS_ERR_MONEY
		-- end
		msg.bet_money = t_money
		self:add_bet(player, t_money)
	elseif t_action == ACT_CALL then
		t_money = self.t_cur_max_bet - self.t_bet[player.guid][self.t_round]
		if t_money == 0 then
			return CS_ERR_MONEY
		end
		local own_money = player:get_money()
		if t_money >= own_money then
			t_money = own_money
			t_action = ACT_ALL_IN
			self.t_player[player.guid].status = PLAYER_STATUS_ALL_IN
			self.play_count = self.play_count - 1
		else
			self.pass_count = self.pass_count + 1
		end
		msg.bet_money = t_money
		self:add_bet(player, t_money)
	elseif t_action == ACT_ALL_IN then
		local own_money = player:get_money()
		self.t_player[player.guid].status = PLAYER_STATUS_ALL_IN
		t_money = own_money
		self.play_count = self.play_count - 1
		-- t_money > self.t_cur_max_bet	or t_money < self.t_cur_min_bet
		-- if t_money > own_money or t_money > self.t_pot then
		-- 	return CS_ERR_MONEY
		-- end
		msg.bet_money = t_money
		self:add_bet(player, t_money)
		--本轮最小下注 = 本轮最大下注-本轮玩家已下注
		--self.t_cur_min_bet = self.t_cur_max_bet - self.t_bet[player.guid][self.t_round]
	end
	
	--广播玩家动作
	msg.pb_action = {
	chair = player.chair_id,
	guid = player.guid,
	money = player:get_money(),
	bet_money = self.t_bet[player.guid][self.t_round],
	action = t_action,
	hole_cards = 1,
	countdown = 0,
	win_money = 0,
	main_pot_money = 0
	}
	--if t_money > 0 then --self:cal_max_bet()end
	msg.pb_table = {
	state = self.t_status,
	max_bet = self.t_max_bet,
	pot = self.t_pot,
	}
	self.t_player[player.guid].action = t_action
	--计算边池 wait to added
	self:t_broadcast("SC_TexasUserAction", msg)
	
	--下一玩家
	self:set_next_player()
	return CS_ERR_OK
end
--打赏荷官
function texas_table:reward_dealer(player)
	self:broadcast_msg_to_client("SC_TexasReward",{guid = player.guid})
end
--结束亮牌
function texas_table:set_show_cards(player, show_card_flag)
--	print("========set_show_cards ==============",show_card_flag)
	self:broadcast_msg_to_client("SC_TexasShowCardsPermission",{chair = player.chair_id})
	self.t_player[player.guid].show_cards = show_card_flag
end
function texas_table:info_ready_to_all()
	if get_second_time() < self.t_timer then
		return
	end
	self:reset()
	local notify = {}
	notify.pb_user = {}
	notify.pb_table = {
	state = self.t_status,
	min_bet = self.t_min_bet,
	max_bet	= self.t_max_bet,
	blind_bet = self.blind_big_bet,
	pot = self.t_pot,
	side_pot = {},
	think_time = 15,
	public_cards = {},
	}
	--遍历桌上其它玩家的数据 
	for i, p in pairs(self.player_list_) do
		if self.player_list_[i] ~= false  then
			if  self.t_player[p.guid] ~= nil then
				local l_player = self.player_list_[i]
				if self.player_list_[i].is_offline == true or self.t_player[p.guid].onTable == false then
					self.t_player[p.guid] = nil
					l_player:forced_exit()
				else
					local room_limit = self.room_:get_room_limit()
					local _l_money = l_player:get_money()
					l_player:check_forced_exit(room_limit)
					if  _l_money < room_limit then
						local msg = {}
						msg.reason = "金币不足，请您充值后再继续"
						msg.num = room_limit
						post_msg_to_client_pb_sh(l_player, "SC_TexasForceLeave", msg)
						l_player:forced_exit()
						self.t_player[p.guid] = nil
					elseif self.t_player[p.guid] then
						self.t_player[p.guid].cards = {}
						self.t_player[p.guid].status = PLAYER_STATUS_WAITING
						self.t_bet[p.guid] = {0,0,0,0}
						local l_player = self:get_player(p.chair_id)
						if l_player then
							local v = {
							chair = p.chair_id,
							guid = p.guid,
							icon =  p:get_avatar(),
							--name = p.nickname,
							name = p.ip_area,
							money = p:get_money(),
							bet_money = 0,
							position = POSITION_NORMAL,
							hole_cards = 0,
							cards = {},
							countdown = 0,
							victory = 3,
							biggest_winner = 2,
							win_money = 0,
							main_pot_money = 0
							}
							table.insert(notify.pb_user, v)
						end
					end
				end
			else
				log_error("t_player nil "..p.guid)
			end
		end
	end
	local tmp_player = {}
	for i, _v in pairs(notify.pb_user) do
		local l_chair = notify.pb_user[i].chair
		notify.pb_table.own_chair = l_chair
		notify.pb_user[i].position = self.t_player[_v.guid].position
		tmp_player = self:get_player(l_chair)
		if tmp_player then
			post_msg_to_client_pb_sh(tmp_player, "SC_TexasTableInfo", notify)
		end
	end
	print("--------------- begin new game  SC_TexasTableInfo -----------------")
	self.t_timer = get_second_time() + ACTION_INTERVAL_TIME
	self.t_player_count = self:count_ready_player()
	if self.t_player_count > 1 then
		self.t_ready_begin = 1
		self.t_status = STATUS_WAITING
	end
end
-- 判断是否游戏中
function texas_table:isPlay()
	-- body
	if self.t_status > STATUS_WAITING  then
		return true
	else
		return false
	end
end
function texas_table:reconnect(player)
	--print("---------- reconnect~~~~~~~~~!",player.chair_id,player.guid)
	
	player.table_id = self.table_id_
	player.room_id = self.room_.id
	self.t_recoonect[player.guid] = 1
end

function texas_table:reconnection_client_msg(player)
	player.is_online = true
	player.isTrusteeship = false
	player.is_offline = false
	if self.t_player[player.guid] ~= nil then
		self.t_player[player.guid].onTable = true
		self:do_sit_down(player)
	end
	virtual_table.reconnection_client_msg(self,player)


end


-- 进入房间并坐下
function texas_table:do_sit_down(player)
	local notify = {}
	notify.pb_user = {}
	notify.pb_table = {
	state = self.t_status,
	min_bet = self.t_min_bet,
	max_bet	= self.t_max_bet,
	blind_bet = self.blind_big_bet,
	pot = self.t_pot,
	side_pot = self.t_side_pot,
	think_time = 15,
	public_cards = self.t_public_show,
	own_chair = player.chair_id
	}
	if self.t_player[player.guid] and self.t_recoonect[player.guid] then
	--	print("||||| Texas reconnect ----do_sit_down---- |||||", player.guid)
		self.t_player[player.guid].onTable = true

		--遍历桌上其它玩家的数据
		for _guid, p in pairs(self.t_player) do
			local l_player = self:get_player(p.chair)
			if l_player then
				local l_hole_cards = 1
				if self.t_player[_guid].status == PLAYER_STATUS_WAITING or
					self.t_player[_guid].status == PLAYER_STATUS_FOLD then
					l_hole_cards = 0
				end
				local l_bet_money = self.t_bet[_guid][self.t_round] or 0
				local v = {
				chair = p.chair,
				guid = _guid,
				icon =  l_player:get_avatar(),
				--name = l_player.nickname,
				name = l_player.ip_area,
				money = l_player:get_money(),
				bet_money = l_bet_money,
				position = self.t_player[_guid].position,
				action = self.t_player[_guid].action,
				hole_cards = l_hole_cards,
				countdown = 0,
				victory = 3,
				biggest_winner = 2,
				win_money = 0,
				main_pot_money = 0
				}
				if v.guid == player.guid then
					v.cards = self.t_player[player.guid].cards
				end
				if _guid == self.t_active_player.guid then
					v.countdown = self.t_timer - get_second_time()
				end
				table.insert(notify.pb_user, v)
			end

			if l_player.guid == player.guid then
				player.is_online = true
				player.isTrusteeship = false
				player.is_offline = false
			end
		end
		post_msg_to_client_pb_sh(player, "SC_TexasTableInfo", notify)
		if next(self.t_table_end) ~= nil then
			post_msg_to_client_pb_sh(player, "SC_TexasTableEnd", self.t_table_end)
		end
	else
		--print("||||| Texas ----do_sit_down---- |||||", player.guid)
		local newPlayerVal = {
		chair = player.chair_id,
		guid = player.guid,
		icon =  player:get_avatar(),
		--name = player.nickname,
		name = player.ip_area,
		money = player:get_money(),
		bet_money = 0,
		action = ACT_WAITING,
		position = POSITION_NORMAL,
		hole_cards = 0,
		cards = {},
		countdown = 0,
		victory = 3,
		win_money = 0,
		main_pot_money = 0
		}
		local toNewUser = {}
		toNewUser.pb_user = newPlayerVal
		table.insert(notify.pb_user, newPlayerVal)
		--遍历桌上其它玩家的数据
		for _guid, p in pairs(self.t_player) do
			local l_player = self:get_player(p.chair)
			if l_player then
				local l_hole_cards = 1
				if self.t_player[_guid].status == PLAYER_STATUS_WAITING or
					self.t_player[_guid].status == PLAYER_STATUS_FOLD then
					l_hole_cards = 0
				end
				local l_bet_money = self.t_bet[_guid][self.t_round] or 0
				
				local v = {
				chair = p.chair,
				guid = _guid,
				icon =  l_player:get_avatar(),
				--name = l_player.nickname,
				name = l_player.ip_area,
				money = l_player:get_money(),
				bet_money = l_bet_money,
				position = self.t_player[_guid].position,
				action = self.t_player[_guid].action,
				hole_cards = l_hole_cards,
				countdown = 0,
				victory = 3,
				biggest_winner = 2,
				win_money = 0,
				main_pot_money = 0
				}
				if _guid == self.t_active_player.guid then
					v.countdown = self.t_timer - get_second_time()
				end
				table.insert(notify.pb_user, v)
				post_msg_to_client_pb_sh(l_player, "SC_TexasNewUser", toNewUser)
			end
		end
		
		post_msg_to_client_pb_sh(player, "SC_TexasTableInfo", notify)
		--print("--------------- player_sit_down  SC_TexasTableInfo -----------------chair.id: ",player.chair_id)
		self.t_player[player.guid] = {
		chair = player.chair_id,
		cards = {},
		cards_type = CT_HIGH_CARD,
		status = PLAYER_STATUS_WAITING,
		action = ACT_WAITING,
		onTable = true,
		position = POSITION_NORMAL,
		show_cards = false
		}
		self.t_bet[player.guid] = {0,0,0,0}
		self.t_all_bet[player.guid] = 0
		
		self.t_player_count = self.t_player_count + 1
		if self.t_status == STATUS_WAITING then
			self.t_timer = get_second_time() + ACTION_INTERVAL_TIME
		end
		
		if self.t_player_count > 1 then
			self.t_ready_begin = 1
		end
	end
end
--玩家坐下、初始化
function texas_table:player_sit_down(player, chair_id_)
	--print("---------------texas_table player_sit_down  -----------------", chair_id_)
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
	log_info(string.format("GameInOutLog,texas_table:player_sit_down, guid %s, table_id %s, chair_id %s",
	tostring(player.guid),tostring(player.table_id),tostring(player.chair_id)))
end
function texas_table:sit_on_chair(player, _chair_id)
	--print ("get_sit_down-----------------  texase   ----------------")
	local result_, table_id_, chair_id_ = virtual_room_mgr.sit_down(self, player, self.table_id_, _chair_id)
	--print ("player.room_id_, player.table_id_, player.chair_id",self.room_.id, self.table_id_, _chair_id)
	self:do_sit_down(player)
end
--玩家站起离开房间
function texas_table:player_stand_up(player, is_offline)
	log_info(string.format("GameInOutLog,texas_table:player_stand_up, guid %s, table_id %s, chair_id %s, is_offline %s",
	tostring(player.guid),tostring(player.table_id),tostring(player.chair_id),tostring(is_offline)))
	--print("!!!!!-----------STAND_UPPPP --------------" ,player.chair_id, is_offline)
	--print(player.table_id,player.chair_id,player.guid)
	if self.t_player[player.guid] == nil then
		return
	end

	-- if self:isPlay() then
	-- 	player.is_offline = true
	-- 	player.is_ontable = false
	-- 	if self.t_player[player.guid] ~= nil then
	-- 		self.t_player[player.guid].onTable = false
	-- 	end
	-- 	return
 --    end

	if is_offline and self.t_player[player.guid] then
		self.t_player[player.guid].onTable = false
		player.is_offline = true
		return
	end

		self.t_player[player.guid].onTable = false
		player.is_offline = true
	
	if self.t_active_player.guid == player.guid then
		self.t_timer = get_second_time()
	end
	self.t_player_count = self.t_player_count - 1
	if self.t_player[player.guid] and (self.t_player[player.guid].status == PLAYER_STATUS_GAME or
		self.t_player[player.guid].status == PLAYER_STATUS_ALL_IN) then
		self.play_count = self.play_count - 1
	end
	if self.t_button and player.guid == self.t_button.guid then
		self.t_button = nil
	end
	--广播此玩家离线
	local msg = {}
	msg.pb_user = {
	guid = player.guid,
	chair = player.chair_id,
	action = ACT_FOLD,
	money = 0,
	hole_cards = 0,
	countdown = 0,
	win_money = 0,
	main_pot_money = 0
	}
	self:t_broadcast("SC_TexasUserLeave", msg)
	virtual_table.player_stand_up(self,player,is_offline)
	self.room_:player_exit_room(player)
	self.t_player[player.guid] = nil
	if self.t_player_count < 1 then
		self:reset()
		return
	end
	
	if self.play_count < 2 then
		self.t_status = STATUS_SHOW_DOWN
		self.t_timer = get_second_time()
	end
	
	if self.t_player_count < 2 then
		if self.t_pot == 0 then
			self:info_ready_to_all()
		else
			self.t_status = STATUS_SHOW_DOWN
			self.t_timer = get_second_time()
		end
		return
	end
	if player.chair_id == self.t_active_player.chair then
		self:set_next_player()
	elseif player.chair_id == self.t_next_player.chair then
		for i = 1,7 do
			l_chair = player.chair_id + i
			if l_chair > 7 then
				l_chair = l_chair - 7
			end
			local player = self:get_player(l_chair)
			if player and self.t_player[player.guid] and self.t_player[player.guid].status == PLAYER_STATUS_GAME
				then
				self.t_next_player = {
				guid = player.guid,
				chair = l_chair
				}
				return
			end
		end
	end
end
function texas_table:player_leave(player)
	--print ("player_leave-----------------  texase   ----------------")
	
	--print ("player.room_id_, player.table_id_, player.chair_id",self.room_.id, self.table_id_, player.chair_id)
	
	self:player_stand_up(player, false)
end
function texas_table:t_broadcast(ProtoName, msg)
	for _guid, t_player in pairs(self.t_player) do
		local l_player = self:get_player(t_player.chair)
		if l_player and t_player.onTable then
			post_msg_to_client_pb_sh(l_player, ProtoName, msg)
		end
	end
end

function post_msg_to_client_pb_sh(player,op_name,msg)
	if player.is_android then
		player:game_msg(op_name,msg)
	else
		log_info("post_msg_to_client_pb_sh "..op_name)
		post_msg_to_client_pb(player,op_name,msg)
	end
    if msg then
        --print("post_msg_to_client_pb_sh : " .. op_name)
    end
end
