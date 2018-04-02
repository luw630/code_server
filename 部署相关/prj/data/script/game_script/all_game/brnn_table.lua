local pb = require "extern/lib/lib_pb"
require "game_script/virtual/virtual_table"
require "extern/lib/lib_table"
local many_ox_room_config = many_ox_room_config
local ox_bet_num=ox_bet_num
local OX_AREA_ONE = pb.get_ev("OX_SCORE_AREA","OX_AREA_ONE")
local OX_AREA_TWO = pb.get_ev("OX_SCORE_AREA","OX_AREA_TWO")
local OX_AREA_THREE = pb.get_ev("OX_SCORE_AREA","OX_AREA_THREE")
local OX_AREA_FOUR = pb.get_ev("OX_SCORE_AREA","OX_AREA_FOUR")
local GAME_SERVER_RESULT_MAINTAIN = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_MAINTAIN")
local ITEM_PRICE_TYPE_GOLD = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")
require "game_script/all_game/brnn_robot"
local ROBOT_BET_MONEY_OPTION_TOTAL = 2
local ROBOT_BET_TIMES_COEFF = 10
local ROBOT_BET_LAST_TIME = 2
local SWITCH_BET_ROBOT = 1
local MAX_CARDS_INDEX = 1
local MIN_CARDS_INDEX = 2
local SYSTEM_MUST_WIN_PROB = 5
local SYSTEM_FLOAT_PROB = 3
local SYSTEM_COEFF = 10000
local MIN_TAX_LIMIT = 1
local SYSTEM_BANKER_SWITCH = 1
local BANKER_ROBOT_INIT_UID = 100000
local BET_ROBOT_INIT_UID = 200000
local BANKER_ROBOT_START_MONEY = 10000000
local BET_ROBOT_START_MONEY = 100000
local ROBOT_BET_TOTAL = 5000
local ROBOT_BET_MAX_NUM = 5
local TYPE_ROBOT_BANKER = 1
local TYPE_ROBOT_BET = 2
local OX_TIME_READY = 3
local OX_TIME_ADD_SCORE = 18
local OX_TIME_OPEN_CARD = 15
local OX_STATUS_READY = 1
local OX_STATUS_PLAY = 2
local OX_STATUS_OVER = 3
local CLOWN_EXSITS = false
local MAX_SCORE_AREA = 4
local MAX_SCOREBORD_LEN =10
local OX_PLAYER_TAX = 0.05
local OX_EXCHANGE_RATE = 100
local OX_MAX_TIMES = 10
local OX_BANKER_LIMIT = 10000*100
local OX_PLAYER_MIN_LIMIT = 1000
local OX_PLAYER_LIST_MAX = 8
local DEFAULT_CONTINUOUS_BANKER_TIMES = 5
local DEFAUT_PLAYER_APPLY_BANKER_FLAG = 0
local PLAYER_MIN_LIMIT = 5
local BET_ROBOT_RAND_COEFF = 5
local robot_money_option ={}
if def_second_game_type==1 then	
	robot_money_option=ox_bet_tb.high
elseif  def_second_game_type==2 then
	robot_money_option=ox_bet_tb.low
end
local time_last = 0
local def_second_game_type = def_second_game_type
local def_game_name = def_game_name
local function is_same_day(time_sp_a,time_sp_b)
	local a = os.date("*t",time_sp_a)
	local b = os.date("*t",time_sp_b)
	return (a.day == b.day and a.year == b.year and a.month == b.month) and true or false
end

local function tableCloneSimple(ori_tab)
    if (type(ori_tab) ~= "table") then
        return ori_tab;
    end
    local new_tab = {};
    for i,v in pairs(ori_tab) do
        local vtyp = type(v);
        if (vtyp == "table") then
            new_tab[i] = tableCloneSimple(v);
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

brnn_table = virtual_table:new()

function brnn_table:get_max_score(score)
	return math.floor(score/OX_MAX_TIMES)
end

function brnn_table:get_banker_list_num()
	local banker_num = 0
	for i, v in ipairs(self.bankerlist) do
		if v then
			banker_num = banker_num + 1
		end
	end
	return banker_num
end

function brnn_table:update_bankerlist_info(guid,new_money)
	if #self.bankerlist == 0 then 
		return
	end
	for i, v in ipairs(self.bankerlist) do
		if v and v.guid == guid then
			v.money = new_money
			break
		end
	end
end

function brnn_table:send_latest_bankerlist_info()
	local msg = {}
	if #self.bankerlist == 0 then 
		self.bankerlist = self.bankerlist or {}
		msg = {banker_num_total = 0, pb_banker_list = self.bankerlist}
		self:broadcast_msg_to_client("SC_OxBankerList", msg)
		return
	end
	
	for i, v in ipairs(self.bankerlist) do
		if v and v.money <  OX_BANKER_LIMIT then
			table.remove(self.bankerlist,i)
		end
	end 
	local banker_num_total = self:get_banker_list_num();
	self.bankerlist = self.bankerlist or {}
	msg = {banker_num_total = banker_num_total, pb_banker_list = self.bankerlist}
	self:broadcast_msg_to_client("SC_OxBankerList", msg)
end

function brnn_table:applyforbanker(player)	
	if self.player_apply_banker_flag == 1 then
		local msg = {
			result = pb.get_ev("Banker_Result","FORBIDAPPLYBANKER_FLAG"), --禁止玩家申请上庄
		}
		post_msg_to_client_pb(player, "SC_OxForBankerFlag", msg)
		return
	end

	local player_money = player:get_money()
	local player_headicon = player:get_avatar()
	if player_money >= OX_BANKER_LIMIT then
		local banker = {
			guid = player.guid,
			nickname = player.nickname,
			money = player_money,
			header_icon = player_headicon,
		}
		table.insert(self.bankerlist, banker)
		local msg = {
			result = pb.get_ev("Banker_Result","APPLYFORBANKER_OK"), 
		}
		post_msg_to_client_pb(player, "SC_OxForBankerFlag", msg)
		local banker_num_total = self:get_banker_list_num();
		self.bankerlist = self.bankerlist or {}
		local msg = {banker_num_total = banker_num_total, pb_banker_list = self.bankerlist}
		self:broadcast_msg_to_client("SC_OxBankerList", msg)
 	else
		local msg = {
			result = pb.get_ev("Banker_Result","APPLYFORBANKER_FAILED"),
		}
		post_msg_to_client_pb(player, "SC_OxForBankerFlag", msg)
	end
	
end

function brnn_table:leaveforbanker(player)	
	for i, v in ipairs(self.bankerlist) do
		if v and v.guid == player.guid then
			table.remove(self.bankerlist, i)
			local msg = {
				result = pb.get_ev("BankerLeave_Result","LEAVELFORBANKER_OK"),
			}
			post_msg_to_client_pb(player, "SC_OxBankerLeaveFlag", msg)
			local banker_num_total = self:get_banker_list_num()
			self.bankerlist = self.bankerlist or {}
			local msg = {banker_num_total = banker_num_total, pb_banker_list = self.bankerlist}
			self:broadcast_msg_to_client("SC_OxBankerList", msg)
			break
		end
	end
end
function brnn_table:init(room, table_id, chair_count)
	virtual_table.init(self, room, table_id, chair_count)
	self.status = OX_STATUS_READY
	self.ox_game_player_list = {}
	for i = 1, chair_count+10 do
		self.ox_game_player_list[i] = false
	end
	self.which_type = 1
	if def_game_name == "ox" then
		if def_second_game_type == 1 then
			require "game_script/all_game/brnn_gl_1"
			OX_MAX_TIMES = 10  
			self.betCF=many_ox_room_config[self.which_type].Ox_basic_chip
		elseif def_second_game_type == 2 then
			require "game_script/all_game/brnn_gl_2"
			OX_MAX_TIMES = 3  
			CLOWN_EXSITS = true
			self.which_type = 2 
			self.betCF=many_ox_room_config[self.which_type].Ox_basic_chip
		else
			log_error(string.format("brnn_table:def_second_game_type[%d] ", def_second_game_type))
			return
		end
	end	


	self.cards = {}
	local cards_num = CLOWN_EXSITS and 54 or 52
	for i = 1, cards_num do
		self.cards[i] = i - 1
	end
	for i = 1, 1000 do
		local a = math.random(#self.cards)
		local b = math.random(#self.cards)
		self.cards[a],self.cards[b] = self.cards[b],self.cards[a]
	end

	self.t_player_SC_OxResult_map = {}
	self.scoreboard = {}
	self.bankerlist = {}
	self.cur_banker_info = {
		guid = 0,
		nickname = nil,
		money = 0,
		bankertimes = 0,
		max_score = 0,
		banker_score = 0,
		left_score = 0,
		header_icon = 0,
	}
	self.lastbankeruid = 0
	self:get_banker()
	self.last_tick_time =0
	local curtime = get_second_time()
	self.time0_ = curtime
	self:init_global_val()
	self:load_many_ox_config_file(self.which_type)
end

function brnn_table:load_many_ox_config_file(index_num)
	OX_TIME_READY = many_ox_room_config[index_num].Ox_FreeTime
	OX_TIME_ADD_SCORE = many_ox_room_config[index_num].Ox_BetTime
	OX_TIME_OPEN_CARD = many_ox_room_config[index_num].Ox_EndTime
	SYSTEM_MUST_WIN_PROB = many_ox_room_config[index_num].Ox_MustWinCoeff
	OX_BANKER_LIMIT = many_ox_room_config[index_num].Ox_bankerMoneyLimit
	SYSTEM_BANKER_SWITCH = many_ox_room_config[index_num].Ox_SystemBankerSwitch
	DEFAULT_CONTINUOUS_BANKER_TIMES = many_ox_room_config[index_num].Ox_BankerCount
	BANKER_ROBOT_INIT_UID = many_ox_room_config[index_num].Ox_RobotBankerInitUid
	BANKER_ROBOT_START_MONEY = many_ox_room_config[index_num].Ox_RobotBankerInitMoney
	SWITCH_BET_ROBOT = many_ox_room_config[index_num].Ox_BetRobotSwitch
	BET_ROBOT_INIT_UID = many_ox_room_config[index_num].Ox_BetRobotInitUid
	BET_ROBOT_START_MONEY = many_ox_room_config[index_num].Ox_BetRobotInitMoney
	BET_ROBOT_RAND_COEFF = many_ox_room_config[index_num].Ox_BetRobotNumControl
	ROBOT_BET_TIMES_COEFF = many_ox_room_config[index_num].Ox_BetRobotTimeControl
	ROBOT_BET_TOTAL = many_ox_room_config[index_num].Ox_RobotBetMoneyControl
	robot_money_option=self.betCF
	SYSTEM_FLOAT_PROB = many_ox_room_config[index_num].Ox_FloatingCoeff --浮动概率
	OX_PLAYER_MIN_LIMIT = many_ox_room_config[index_num].Ox_PLAYER_MIN_LIMIT --携带金币数小于该值不能下注
end

function brnn_table:load_lua_cfg()
	local funtemp = load(self.room_.lua_cfg_)
	local ox_config = funtemp()
	OX_TIME_READY = ox_config.Ox_FreeTime
	OX_TIME_ADD_SCORE = ox_config.Ox_BetTime
	OX_TIME_OPEN_CARD = ox_config.Ox_EndTime
	SYSTEM_MUST_WIN_PROB = ox_config.Ox_MustWinCoeff
	OX_BANKER_LIMIT = ox_config.Ox_bankerMoneyLimit
	SYSTEM_BANKER_SWITCH = ox_config.Ox_SystemBankerSwitch
	DEFAULT_CONTINUOUS_BANKER_TIMES = ox_config.Ox_BankerCount
	BANKER_ROBOT_INIT_UID = ox_config.Ox_RobotBankerInitUid
	BANKER_ROBOT_START_MONEY = ox_config.Ox_RobotBankerInitMoney
	SWITCH_BET_ROBOT = ox_config.Ox_BetRobotSwitch
	BET_ROBOT_INIT_UID = ox_config.Ox_BetRobotInitUid
	BET_ROBOT_START_MONEY = ox_config.Ox_BetRobotInitMoney
	BET_ROBOT_RAND_COEFF = ox_config.Ox_BetRobotNumControl
	ROBOT_BET_TIMES_COEFF = ox_config.Ox_BetRobotTimeControl
	ROBOT_BET_TOTAL = ox_config.Ox_RobotBetMoneyControl
	self.betCF = ox_config.Ox_basic_chip
	robot_money_option=self.betCF
	ox_bet_num = #ox_config.Ox_basic_chip
	SYSTEM_FLOAT_PROB = ox_config.Ox_FloatingCoeff
	if  ox_config.Ox_PLAYER_MIN_LIMIT ~= nil then
		OX_PLAYER_MIN_LIMIT = ox_config.Ox_PLAYER_MIN_LIMIT
	end	
end
function brnn_table:init_global_val()
	local bRet = virtual_table.start(self,0)
	self.all_player_list = {}
	self.area_cards_ = {} 
	self.area_score_ = {}
	self.is_open_ = {}
	self.last_score = 0
	self.player_apply_banker_flag = DEFAUT_PLAYER_APPLY_BANKER_FLAG
	self.conclude = {}
	self.area_score_total = {
		max_bet_score = self.max_score_, 
		bet_tian_total = 0,  
		bet_di_total = 0, 
		bet_xuan_total = 0,   
		bet_huang_total = 0, 
		left_money_bet = self.max_score_, 
		total_all_area_bet_money = 0,  
	}  
	self.curbankerleave_flag = 0
	self.cardResult = {}
	self.tb_bet_robot = {} 
	self.robot_start_bet_flag = 0 
	self.robot_bet_info = {}
	self.flag_banker_robot = 0 
	self.last_bet_time = 0 
	--self.change_banker_flag = 0 
	OX_PLAYER_TAX = self.tax_
	self.cell_money = self.room_:get_room_cell_money()
	self.player_bet_all_info = {}
	self.tax_total = 0
	local curtime = get_second_time()
	self.table_game_id = 0

	self.gamelog = {
		start_game_time = 0, 
        end_game_time = 0,  
		table_game_id = 0,   
		banker_id = 0,		 
		cell_money = 0,		 
		player_count = 0,	 
		system_banker_flag = 0,
		system_tax_total = 0,
		tax = 0,			 
		CardTypeInfo = {},   
		Record_result = {},  
		Area_bet_all_count = {},
		Area_bet_info = {}, 
		Game_Conclude = {} 
    }
	self.gamelog.start_game_time = curtime
	self.gamelog.tax = OX_PLAYER_TAX
	self:get_curBanker_type()
	self.chip_count = 0
	time_last = 0
	self.this_game_robot_bets = 0
end
function brnn_table:creat_banker_robot(robot_type,robot_num,uid,money)
	local robot = brnn_robot:get_one_robot(robot_type, robot_num,uid,money)
	for i,v in pairs (self.ox_game_player_list) do
		if not v then
			robot.chair_id = i
			self.ox_game_player_list[i] = robot
			break
		end
	end
	return robot
end

function brnn_table:creat_rand_bet_robot(robot_type, robot_num,uid,money)
	local bet_robot_ = {}
	bet_robot_ = brnn_robot:get_one_robot(TYPE_ROBOT_BET, robot_num,uid,money)
	for _,v1 in pairs (bet_robot_) do
		if v1 then
			for i,v in pairs (self.ox_game_player_list) do
				if not v then
					v1.chair_id = i
					v1.header_icon = math.random(1,10)
					self.ox_game_player_list[i] = v1
					break
				end
			end
		end
	end
	return bet_robot_
end
function brnn_table:send_banker_info_to_client()
	if #self.bankerlist == 0 then
		local banker_robot = self:creat_banker_robot(TYPE_ROBOT_BANKER, 1,BANKER_ROBOT_INIT_UID,BANKER_ROBOT_START_MONEY)
			local max_bet_score = self:get_max_score(banker_robot.money <=0 and 0 or banker_robot.money)
			self.cur_banker_info = {
				guid = banker_robot.guid,
				nickname = banker_robot.nickname,
				money = banker_robot.money,
				bankertimes = 1,
				max_score = max_bet_score,
				banker_score = 0,
				left_score = max_bet_score,
				header_icon = banker_robot.header_icon,
			}
		self.cur_banker_info = self.cur_banker_info or {}
		local msg = {pb_banker_info = self.cur_banker_info}
		self:broadcast_msg_to_client("SC_OxBankerInfo",msg)
		
	else
		local curbanker = self.bankerlist[1]
		local money_ = self:get_max_score(curbanker.money <= 0 and 0 or curbanker.money)
		if money_ > 0 then
			self.max_score_ = money_
		end
		local banker = {
			guid = curbanker.guid,  
			nickname = curbanker.nickname, 
			money = curbanker.money,  
			bankertimes = 1,           
			max_score = self.max_score_, 
			banker_score = 0,           
			left_score = self.max_score_, 
			header_icon = curbanker.header_icon, 
		}
		banker = banker or {}
		local msg = {pb_banker_info = banker}
		self:broadcast_msg_to_client("SC_OxBankerInfo",msg)
		table.remove(self.bankerlist, 1)
		local banker_num_total = self:get_banker_list_num();
		self.bankerlist = self.bankerlist or {}
		local msg = {banker_num_total = banker_num_total, pb_banker_list = self.bankerlist}
		self:broadcast_msg_to_client("SC_OxBankerList", msg)
		self.cur_banker_info = {
			guid = curbanker.guid,
			nickname = curbanker.nickname,
			money = curbanker.money,
			bankertimes = 1,
			max_score = self.max_score_,
			banker_score = 0,
			left_score = self.max_score_,
			header_icon = curbanker.header_icon, 
		}
		
	end	
	self.max_score_ = self.cur_banker_info.max_score
	
end

function brnn_table:del_robot(uid)
	for i, v in pairs(self.ox_game_player_list) do
		if v and v.guid == uid then
			self.ox_game_player_list[i] = false
			if ly_robot_mgr.robot_list[uid] then
				ly_robot_mgr.robot_list[uid] = false
			end
			break
		end
	end
end

function brnn_table:del_player(uid)
	for i, v in pairs(self.ox_game_player_list) do
		if v and v.guid == uid then
			self.ox_game_player_list[i] = false
			break
		end
	end
end


function brnn_table:force_leavel_banker(banker)
	if banker.money < OX_BANKER_LIMIT then
		self.lastbankeruid = banker.guid
		self:change_banker()
	end
end

function brnn_table:change_banker()
	self.change_banker_flag = 0
	self.lastbankeruid = self.cur_banker_info.guid
	self:send_banker_info_to_client()
end

function brnn_table:leave_cur_banker(player)
	if player.guid == self.cur_banker_info.guid then
		--self.curbankerleave_flag = 1
		self.change_banker_flag = 1
	end
end

function brnn_table:send_cur_banker_to_client()
	self.cur_banker_info = self.cur_banker_info or {}
	local msg = {pb_banker_info = self.cur_banker_info}
	self:broadcast_msg_to_client("SC_OxBankerInfo",msg)
end

function brnn_table:get_banker()
	if self.cur_banker_info.bankeruid == self.lastbankeruid then 
		self.cur_banker_info.bankertimes = self.cur_banker_info.bankertimes + 1
		self:send_cur_banker_to_client()
	else
		if #self.bankerlist == 0 then
			local banker_robot = self:creat_banker_robot(TYPE_ROBOT_BANKER, 1,BANKER_ROBOT_INIT_UID,BANKER_ROBOT_START_MONEY)
			local max_bet_score = self:get_max_score(banker_robot.money <=0 and 0 or banker_robot.money)
			self.cur_banker_info = {
				guid = banker_robot.guid,
				nickname = banker_robot.nickname,
				money = banker_robot.money,
				bankertimes = 1,
				max_score = max_bet_score,
				banker_score = 0,
				left_score = max_bet_score,
				header_icon = banker_robot.header_icon,
			}
		
			self.cur_banker_info = self.cur_banker_info or {}
			local msg = {pb_banker_info = self.cur_banker_info}
			self:broadcast_msg_to_client("SC_OxBankerInfo",msg)
			
		else 
			self:send_banker_info_to_client()
		end
	end
	self.max_score_ = self.cur_banker_info.max_score

end

function brnn_table:update_online_player_list()
	local playerinfo = {}
	local num_total = 0
	for i,v in pairs(self.ox_game_player_list) do
		if v then
			if v.is_player == true then
				local money = v:get_money()
				local headericon = v:get_avatar()
				table.insert(playerinfo, {guid = v.guid,head_id = headericon,nickname = v.nickname,money = money, header_icon = headericon})
			else
				if v.nickname ~= "system_banker" and v.header_icon ~= -1 then
					local robot_money = v.money
					local robot_headericon = v.header_icon
					table.insert(playerinfo, {guid = v.guid,head_id = robot_headericon,nickname = v.nickname,money = robot_money, header_icon = robot_headericon})
				end
			end
		end
	end
	table.sort(playerinfo, function (a, b)
		if a.money == b.money then
			return a.guid < b.guid
		else
			return a.money > b.money
		end
	end)
	self.all_player_list = {}
	for i=1,OX_PLAYER_LIST_MAX do
		local p = playerinfo[i]
		if p == nil then
			break
		end
		self.all_player_list[i] = p
		num_total = num_total + 1
	end
	return num_total
end

function brnn_table:send_player_list()
	local real_num = self:update_online_player_list()
	self.all_player_list = self.all_player_list or {}
	local msg = {top_player_total = real_num,pb_player_info_list = self.all_player_list}
	self:broadcast_msg_to_client("SC_OxPlayerList",msg)
end

function brnn_table:check_score_area(score_area_)
	if score_area_ < OX_AREA_ONE or score_area_ > OX_AREA_FOUR then
		return false
	end
	local max_score_area =0
	return (max_score_area < MAX_SCORE_AREA) and true or false 
end

function brnn_table:add_area_score(uid_,area_,score_)
	local current_state = self.area_score_[area_]
	if not current_state then
		current_state = {}
		current_state[uid_] = score_
		self.area_score_[area_] = current_state
	else
		local old_score_ = (not current_state[uid_]) and 0 or current_state[uid_]
		current_state[uid_] = old_score_ + score_
		self.area_score_[area_] = current_state
	end
	return current_state[uid_]
end

function brnn_table:add_score(player, score_area_,score_)
	if player == nil then
		log_warning("player is nil,return.")
		return
	end
	local player_money = 0
	if player.is_player  == true then
		player_money = player:get_money()
	else
		player_money = player.money
	end

	if self.status ~= OX_STATUS_PLAY then
		log_warning(string.format("brnn_table:add_score guid[%d] status error", player.guid))
		return
	end
	
	if player.guid == self.cur_banker_info.guid then
		log_warning(string.format("brnn_table:add_score, banker[%d] = guid[%d]",self.cur_banker_info.guid,player.chair_id))
		return
	end
	if score_ <= 0 then
		log_error(string.format("brnn_table:add_score guid[%d] score[%d] <= 0", player.guid, score_))
		return
	end

	if not self:check_score_area(score_area_) then
		log_error(string.format("brnn_table:add_score guid[%d], score_area_[%d] error",player.guid,score_area_))
		return
	end

	if player_money < OX_PLAYER_MIN_LIMIT then
		local FailMsg = {
			result = pb.get_ev("Bet_Result","MONEY_LIMIT"),
		}
		post_msg_to_client_pb(player, "SC_OxBetCoin", FailMsg)
		return
	end

	if score_ * OX_MAX_TIMES > player_money then
		local FailMsg = {
			result = pb.get_ev("Bet_Result","MONEY_ERROR"),
		}
		post_msg_to_client_pb(player, "SC_OxBetCoin", FailMsg)
		return
	end

	if #self.player_bet_all_info == 0 then
		table.insert(self.player_bet_all_info,{is_player = player.is_player,guid = player.guid,bet_total = score_} )
	else
		local find_player_flag = 0
		for i, v in pairs (self.player_bet_all_info) do
			if v and v.guid == player.guid then
				find_player_flag = 1
				local bet_money = v.bet_total + score_
				if bet_money * OX_MAX_TIMES > player_money + v.bet_total then --下注总额与原下注前的自身携带金币总数比较
					return
				else
					v.bet_total = bet_money
				end
			end
		end
		if find_player_flag == 0 then
			table.insert(self.player_bet_all_info,{is_player = player.is_player,guid = player.guid,bet_total = score_} )
		end
	end
	
	local money_ = self.last_score + score_
	if money_ > self.max_score_ then
		local FailMsg = {
			result = pb.get_ev("Bet_Result","BET_MAX"),
		}
		post_msg_to_client_pb(player, "SC_OxBetCoin", FailMsg)
		return
	else
		self.last_score = money_
	end

	

	local this_area_player_bet_total = self:add_area_score(player.guid,score_area_,score_)

	if player.is_player == true then
		player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = score_}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_OX"))
	else 
		brnn_robot:cost_money_robot(player,score_)
		self.this_game_robot_bets = self.this_game_robot_bets + score_
	end
	
	local msg = {
		add_score_chair_id = player.guid, 
		score_area = score_area_,         
		score = score_,                  
		player_bet_this_area_money = this_area_player_bet_total,
		money = player_money - score_,  
	}
	self.chip_count = self.chip_count + 1
	if self.chip_count < 100 then
		self:broadcast_msg_to_client("SC_OxAddScore", msg)
	else
		post_msg_to_client_pb(player, "SC_OxAddScore", msg)
	end

	self:count_area_bet_money(score_area_,score_)
end

function brnn_table:count_area_bet_money(_area, betmoney)
	self.max_score_ = self.cur_banker_info.max_score
	if 1 == _area then
		self.area_score_total.bet_tian_total = self.area_score_total.bet_tian_total + betmoney
	elseif 2 == _area then
		self.area_score_total.bet_di_total = self.area_score_total.bet_di_total + betmoney
	elseif 3 == _area then
		self.area_score_total.bet_xuan_total = self.area_score_total.bet_xuan_total + betmoney
	elseif 4 == _area then
		self.area_score_total.bet_huang_total = self.area_score_total.bet_huang_total + betmoney
	end
	self.area_score_total.total_all_area_bet_money = self.area_score_total.bet_tian_total + self.area_score_total.bet_di_total + self.area_score_total.bet_xuan_total + self.area_score_total.bet_huang_total
	local left_bet_max = self.max_score_ - self.last_score
	self.area_score_total.left_money_bet = left_bet_max
end

function brnn_table:GetCardMaxOrMinIndex(index_type)
	
	local card_result = self:analyse_cards()
	local max_index = 1
	local min_index = 1
	local tempCard = card_result[1]
	for i =2,MAX_SCORE_AREA+1 do
		local win = compare_cards(tempCard,card_result[i])
		if index_type == MAX_CARDS_INDEX then
			if win == false then
				tempCard = card_result[i]
				max_index = i
			end
		else
			if win == true then
				tempCard = card_result[i]
				min_index = i
			end
		end
	end
	if index_type == MAX_CARDS_INDEX then
		return max_index
	else
		return min_index
	end
end

function brnn_table:GetSortCardIndex(index)
	local card_result = self:analyse_cards()
	local card_sort = {0,0,0,0,0}
	for i =1,MAX_SCORE_AREA+1 do
		for j =1,MAX_SCORE_AREA+1 do
			if i ~= j then
				local win = compare_cards(card_result[i],card_result[j])
				if win then
					card_sort[i] = card_sort[i] + 1
				end
			end
		end
	end

	for k,v in pairs(card_sort) do
		if v == (5-index) then
			return k
		end
	end
	return 1
end



function brnn_table:analyse_cards()
	local ret ={}
	for i=1,MAX_SCORE_AREA+1 do
		local ox_type_,value_list_,color_,extro_num_ = get_cards_type(self.area_cards_[i])
		local times = get_type_times(ox_type_,extro_num_)
		ret[i] = {ox_type = ox_type_,val_list = value_list_,color = color_, extro_num = extro_num_, cards_times = times}
	end
	
	return ret
	
end
function brnn_table:has_real_player_bet()
	for i, v in pairs (self.player_bet_all_info) do
		if v and v.is_player and v.bet_total > 0 then
			return true
		end
	end
	return false
end
function brnn_table:has_robot_player_bet()
	for i, v in pairs (self.player_bet_all_info) do
		if v and (v.is_player == false) and v.bet_total > 0 then
			return true
		end
	end
	return false
end

function brnn_table:randcardlist( ... )
	if CLOWN_EXSITS then
		local tempcard = {}
		for k,v in pairs(self.cards) do
			table.insert(tempcard,v)
		end
		local rand_joker = math.random(1,100)
		if rand_joker > 90 then
			if #self.cards == 52 then
				if rand_joker > 95 then
					table.insert(self.cards,53)
				else
					table.insert(self.cards,52)
				end
			end
			--log_info("add joker")
		else
			if #self.cards > 52 then
				for k,v in pairs(tempcard) do
					if v == 53 or v == 52 then
						table.remove(tempcard,k)
					end
				end
				self.cards = {}
				for k,v in pairs(tempcard) do
					table.insert(self.cards,v)
				end
			end		
		end
	end





	local cbCardData = {}
	local cbBufferCount = #self.cards

	for i=1,cbBufferCount do
		table.insert(cbCardData,self.cards[i])
	end

	local cbRandCount = 0
	local cbPosition = 0
	while cbRandCount < cbBufferCount do
		cbPosition = (win_random_int(1,100000)%(cbBufferCount - cbRandCount))
		self.cards[cbRandCount+1] = cbCardData[cbPosition+1]
		--log_info("randcardlist "..cbPosition.."  count "..cbRandCount)
		cbCardData[cbPosition+1]=cbCardData[cbBufferCount-cbRandCount]
		cbRandCount = cbRandCount + 1
	end

end


function brnn_table:detect_card()
	local niuniu_count = 0
	for i=1,MAX_SCORE_AREA+1 do
		local card_type = get_cards_type(self.area_cards_[i])
		if card_type > pb.get_ev("OX_CARD_TYPE","OX_CARD_TYPE_OX_ONE") then
			niuniu_count = niuniu_count + 1
		end
	end

	local rand_niuniu = math.random(1,10000)

	if niuniu_count == 0 then
		return 
	end

	if niuniu_count == 1 then
		if rand_niuniu < 8500 then
			self:randcardlist()
			self:send_card()
			self:detect_card()
		end
	elseif niuniu_count == 2 then
		if rand_niuniu < 9300 then
			self:randcardlist()
			self:send_card()
			self:detect_card()
		end
	else
		self:randcardlist()
		self:send_card()
		self:detect_card()
	end

--	log_info("detect_niuniu "..niuniu_count)
	
end

function brnn_table:send_card()
	for i=1,MAX_SCORE_AREA+1 do
		local cards ={}
		for j = 1, 5 do
			--log_info("card index"..(i+5*(j-1)))
		 	table.insert(cards, self.cards[i+5*(j-1)])
		end	
		self.area_cards_[i] = cards
	end
end

function brnn_table:shuffle_card()
	local k = #self.cards
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))

	if def_game_id == 50 then --高倍場
		for i=1,MAX_SCORE_AREA+1 do
			local cards ={}
			for j=1,5 do
				local r = win_random_int(1,k)
				cards[j] = self.cards[r]
				if r~=k then
					self.cards[r],self.cards[k] = self.cards[k],self.cards[r]
				end
				k = k-1
			end
			self.area_cards_[i] = cards
		end
		--[[
		self:randcardlist()
		for i=1,MAX_SCORE_AREA+1 do
			local cards ={}
			for j = 1, 5 do
				 table.insert(cards, self.cards[i+5*(j-1)])
			end	
			self.area_cards_[i] = cards
		end
		]]
	elseif def_game_id == 51 then --低倍場
		self:randcardlist()
		for i=1,MAX_SCORE_AREA+1 do
			local cards ={}
			for j = 1, 5 do
				 table.insert(cards, self.cards[i+5*(j-1)])
			end	
			self.area_cards_[i] = cards
		end
		self:detect_card()
	end

	if false then
		self.random_list = self.random_list or {1,2,3,4,5,1,2,3,4,5,1,2,3,4,5}
		local tt_index = {}
		tt_index[1] = self:GetSortCardIndex(1)
		tt_index[2] = self:GetSortCardIndex(2)
		tt_index[3] = self:GetSortCardIndex(3)
		tt_index[4] = self:GetSortCardIndex(4)
		tt_index[5] = self:GetSortCardIndex(5)
		local rnnnn = win_random_int(1,#self.random_list)
		self.area_cards_[tt_index[self.random_list[rnnnn]]],self.area_cards_[1] = self.area_cards_[1],self.area_cards_[tt_index[self.random_list[rnnnn]]]
		table.remove(self.random_list,rnnnn)
		if #self.random_list == 0 then self.random_list = nil end

		local index_1_tmp = self:GetSortCardIndex(1)
		local index_2_tmp = self:GetSortCardIndex(2)
		local index_3_tmp = self:GetSortCardIndex(3)
		local index_4_tmp = self:GetSortCardIndex(4)
		local index_5_tmp = self:GetSortCardIndex(5)

		self.ying = self.ying or 0
		self.shu = self.shu or 0
		if index_1_tmp == 1 then
			self.ying = self.ying + 0
			self.shu = self.shu + 4
		elseif index_2_tmp == 1 then
			self.ying = self.ying + 1
			self.shu = self.shu + 3
		elseif index_3_tmp == 1 then
			self.ying = self.ying + 2
			self.shu = self.shu + 2
		elseif index_4_tmp == 1 then
			self.ying = self.ying + 3
			self.shu = self.shu + 1
		elseif index_5_tmp == 1 then
			self.ying = self.ying + 4
			self.shu = self.shu + 0
		end

		if self.ying > 100  or self.shu > 100 then
			self.ying = 0
			self.shu = 0
		end

		log_info(string.format("rnnnn %d-----ying   %d------shu   %d-------",rnnnn,self.ying,self.shu))

	end
	
	local max_index = self:GetCardMaxOrMinIndex(MAX_CARDS_INDEX)
	local min_index = self:GetCardMaxOrMinIndex(MIN_CARDS_INDEX)
	local index_1 = self:GetSortCardIndex(1)
	local index_2 = self:GetSortCardIndex(2)
	local index_3 = self:GetSortCardIndex(3)
	local index_4 = self:GetSortCardIndex(4)
	local index_5 = self:GetSortCardIndex(5)
	if max_index == min_index then
		return false
	end

	
	local tempCards = {}
	local rand_coeff = math.random(1,SYSTEM_COEFF)
	local float_coeff = math.random(1,SYSTEM_FLOAT_PROB)
	local this_time_coeff = (SYSTEM_MUST_WIN_PROB + float_coeff) * OX_EXCHANGE_RATE
	log_info("self.this_game_robot_bets is " .. self.this_game_robot_bets)
	log_info("ly_robot_storage is " .. ly_robot_storage)
	
	local change_flag = false
	local real_storage = ly_robot_storage + self.this_game_robot_bets
	--if ((ly_robot_storage + self.this_game_robot_bets) < 0) or (rand_coeff < this_time_coeff)  then
	local cheat = 0
	local chi_r_num = math.random(1,100)
	for k,v in pairs(ly_brnn_chi_cfg) do
		if real_storage < v.endr and chi_r_num < v.prob and real_storage > v.beginr then
			cheat = 1
			break
		end
	end
	log_info("cheat is " .. cheat)
	
	if (real_storage < 0) or (ly_robot_smart_lv > 0 and (math.random(1,100) <= ly_robot_smart_lv)) or cheat == 1 then		
		if self.flag_banker_robot == 1 then
			if max_index ~= 1 and self:has_real_player_bet() then
				self.area_cards_[index_2],self.area_cards_[1] = self.area_cards_[1],self.area_cards_[index_2]
				change_flag = true
			end
		else
			if min_index ~= 1 and self:has_robot_player_bet() then
				self.area_cards_[min_index],self.area_cards_[1] = self.area_cards_[1],self.area_cards_[min_index]
				change_flag = true
			end
		end
	elseif (real_storage > 0) and ly_robot_smart_lv < 0 then -- 机器人赢钱了,要输钱出去 
		local rich_line = 0
		if def_game_id == 50 then
			rich_line = 10000*100
		elseif def_game_id == 51 then
			rich_line = 10000*100
		end

		if (real_storage > rich_line) and math.random(1,100) <= math.abs(ly_robot_smart_lv) then 
			if self.flag_banker_robot == 1 then	 
				if min_index ~= 1 and self:has_real_player_bet() then
					self.area_cards_[index_4],self.area_cards_[1] = self.area_cards_[1],self.area_cards_[index_4]
					change_flag = true
				end
			end
		else
			--local rr = math.random(2,4)
			--self.area_cards_[rr],self.area_cards_[1] = self.area_cards_[1],self.area_cards_[rr]
		end
	else
		--local rr = math.random(2,4)
		--self.area_cards_[rr],self.area_cards_[1] = self.area_cards_[1],self.area_cards_[rr]
	end	

	if ly_kill_list and (not change_flag) then
		for k_guid,k_time in pairs(ly_kill_list) do
			if k_time > 0 then
				local k_area_info = {0,0,0,0}
				for j =1,MAX_SCORE_AREA do
					local area_info = (self.area_score_[j] == nil ) and {} or self.area_score_[j]
					for uid,score in pairs(area_info) do
						if uid == k_guid then
							k_area_info[j] = k_area_info[j] + score
						end
					end
				end

				local big_val = 0
				local big_index = 0
				for i,s in pairs(k_area_info) do
					if s > big_val then
						big_val = s
						big_index = i
					end
				end

				if big_val ~= 0 then
					self.area_cards_[min_index],self.area_cards_[big_index+1] = self.area_cards_[big_index+1],self.area_cards_[min_index]
					ly_kill_list[k_guid] = ly_kill_list[k_guid] - 1
					break
				end
			end
		end

		local left_task = 0
		for k_guid,k_time in pairs(ly_kill_list) do
			left_task = left_task + k_time
			if k_time > 0 then
				log_info("-------------------------left task guid " .. k_guid)
			end
		end
		if left_task > 0 then
			log_info("----------------------left task " .. left_task)
		end
	end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

		local ret ={}
		local result_ret ={}
		local player_score = {}
		local banker_uid = self.cur_banker_info.guid

		for i=1,MAX_SCORE_AREA+1 do
			local ox_type_,value_list_,color_,extro_num_ = get_cards_type(self.area_cards_[i])
			local times = get_type_times(ox_type_,extro_num_)
			ret[i] = {ox_type = ox_type_,val_list = value_list_,color = color_, extro_num = extro_num_, cards_times = times}
		end
	
		for i =2,MAX_SCORE_AREA+1 do
			local win = compare_cards(ret[1],ret[i])
			if win == true then
				if self.which_type == 2 then
					local odds_banker = get_cards_odds(ret[1].cards_times)
					table.insert(result_ret,{win,odds_banker})
				else
					table.insert(result_ret,{win,ret[1].cards_times})
				end
				
			else
				if self.which_type == 2 then
					local odds_player = get_cards_odds(ret[i].cards_times)
					table.insert(result_ret,{win,odds_player})
				else
					table.insert(result_ret,{win,ret[i].cards_times})
				end
			end
		end

		for j =1,MAX_SCORE_AREA do
			local area_info = (self.area_score_[j] == nil ) and {} or self.area_score_[j]
			for uid,score in pairs(area_info) do
				local win_flag = result_ret[j][1]
				local win_times = result_ret[j][2]
				local old_banker_score = (player_score[banker_uid] == nil) and 0 or player_score[banker_uid]

				for i,v in pairs (self.ox_game_player_list) do
					if v and v.guid == uid and v.is_player == true then
						if win_flag then
							local old_score = (player_score[uid] == nil) and 0 or player_score[uid]
							player_score[uid] = old_score - score*(win_times - 1)
							player_score[banker_uid] = old_banker_score + score *win_times
						else
							local old_score = (player_score[uid] == nil) and 0 or player_score[uid]
							player_score[uid] = old_score + score*(win_times+1)
							player_score[banker_uid] = old_banker_score - score*win_times
						end
					end
				end
			end
		end

		player_score[banker_uid] = player_score[banker_uid] or 0
		if real_storage >= 0 and (player_score[banker_uid] + real_storage) < 0 then
			log_info("--------storage < 0, re_calc-----------------------")
			return false
		end

		--[[ 新手保护机制
		if (real_storage > 1000*100) and ly_robot_smart_lv < 0 then
			for uid,score in pairs(player_score) do
				for _,v in pairs (self.player_list_) do
					if v and (v.is_player == true) and (uid == v.guid) then
						if (v:get_money() + v:get_bank() + score) < self.room_:get_room_limit() then
							log_info(string.format("--------baohuwanjia %d %d-----------------------",v.guid,v:get_money()))
							return false
						end
					end
				end
			end
		end
		]]
			
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

	if self.flag_banker_robot == 1 then
		ly_niuniu_banker_times = ly_niuniu_banker_times + 1
	end
	
	return true
end

function brnn_table:get_curBanker_type()
	for i,v in ipairs(self.ox_game_player_list) do
		if v and v.guid == self.cur_banker_info.guid and v.is_player == false then --机器人当庄
			self.flag_banker_robot = 1
			break
		end
	end 
end

function brnn_table:count_player_total()
	local total_player_count = 0
	for i, v in pairs (self.ox_game_player_list) do
		if v and v.is_player == true then
			total_player_count = total_player_count + 1
		end
	end
	return total_player_count
end
function brnn_table:test_card()
	local testcard = {52,53}
	local k = #self.cards
	for i=1,MAX_SCORE_AREA+1 do
		local cards ={}
		for j=1,5 do
			local r = math.random(1,k)
			cards[j] = self.cards[r]
			if r~=k then
				self.cards[r],self.cards[k] = self.cards[k],self.cards[r]
			end
			k = k-1
		end
		self.area_cards_[i] = cards
	end
	if self.which_type == 2 then
		for i=1,2 do
			local num = math.random(1,5)
			local index_bomb = math.random(1,5)
			self.area_cards_[num][index_bomb] = 52+i-1
		end
		
	end
end

function brnn_table:control_with_hand_file()
	local file_name = string.format("hand_file_%d.txt",def_game_id)
	local file = io.open(file_name, "r")
	if file then
		local content = file:read("*a")
		io.close(file)
		print("----------")
		log_info("control_with_hand_file load " .. content)
		print("----------")
		local function string_split(s, p)
			local rt= {}
			string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
			return rt
		end
		local param = string_split(content,",")
		if #param > 0 then
			if param[1] and param[1] == "kill" and param[2] and param[3]then
				local guid = tonumber(param[2])
				local time = tonumber(param[3])
				if guid > 0 and time > 0 then
					ly_kill_list[guid] = ly_kill_list[guid] or 0
					ly_kill_list[guid] = ly_kill_list[guid] + time
				end
			end
		end

		file=io.open(file_name,"w") 
		file:write("")
		file:close()
	end		
end
	
function brnn_table:send_cards_to_client()
	self.table_game_id = self:get_now_game_id()
	self.gamelog.table_game_id = self.table_game_id 
	self.gamelog.banker_id = self.cur_banker_info.guid
	self.gamelog.cell_money = self.cell_money
	self.gamelog.player_count = self:count_player_total() 
	
	self:next_game()
	self.gamelog.system_banker_flag = self.flag_banker_robot 
	local msg = {}
	local shuffle_cards_times = 0
	self:control_with_hand_file()
	while(true)
	do
		if self:shuffle_card() then
			break
		end
		shuffle_cards_times = shuffle_cards_times + 1
		if shuffle_cards_times > 100 then
			break
		end
	end

	local all_cards = {}
	for i =1,MAX_SCORE_AREA+1 do
		local cards = {}
		cards.score_area = i
		cards.card = self.area_cards_[i]
		table.insert(all_cards,cards)
	end
	msg.pb_cards = all_cards
	for i,v in ipairs(self.ox_game_player_list) do
		if v and v.is_player == true then
			post_msg_to_client_pb(v,"SC_OxDealCard",msg)
		end
	end

	self:send_result()

end

function brnn_table:calc_result()

	local ret ={}
	local cardResult = {}
	for i=1,MAX_SCORE_AREA+1 do
		local ox_type_,value_list_,color_,extro_num_ = get_cards_type(self.area_cards_[i])
		local times = get_type_times(ox_type_,extro_num_)
		ret[i] = {ox_type = ox_type_,val_list = value_list_,color = color_, extro_num = extro_num_, cards_times = times}
		local result = {}
		result.score_area = i
		result.card_type = ox_type_
		result.card_times = times
		table.insert(cardResult, result)
		local card_msg = {
			score_area = i,
			cards = string.format("%s",table.concat(self.area_cards_[i],',')),
			card_type = ox_type_,
			card_times = times
		}
		table.insert(self.gamelog.CardTypeInfo,card_msg)
	end
	local msg = {pb_result = cardResult}
	self.cardResult = cardResult
	self:broadcast_msg_to_client("SC_CardResult", msg)

	return ret
end

function brnn_table:add_scorebord(results)
	table.insert(self.scoreboard,results)
	if #self.scoreboard > MAX_SCOREBORD_LEN then
		table.remove(self.scoreboard,1)
	end
end
function brnn_table:clear_scorebord()
	self.scoreboard ={}
end

function brnn_table:send_ox_record(player)
	local msg = {
		pb_recordresult ={}				
	}
	for i, v in pairs(self.scoreboard) do
		local ret ={}
		ret.result =v
		table.insert(msg.pb_recordresult,ret)
	end
	post_msg_to_client_pb(player,"SC_OxRecord",msg)
end

function brnn_table:broadcas_record_result()
	local msg = {
		pb_recordresult ={}				
	}
	local record_len = #self.scoreboard
	for i, v in pairs(self.scoreboard) do
		if i == record_len then
			local ret ={}
			ret.result =v
			table.insert(msg.pb_recordresult,ret)
		end
		
	end
	self:broadcast_msg_to_client("SC_OxRecord", msg)
end

function brnn_table:send_result()
	local ret = self:calc_result()
	local player_score = {}
	local player_pay_score ={}

	local result_ret ={}
	local record_ret ={}
	local all_win_times = 0 
	local all_lose_times = 0 
	local flag_all_win_or_lose = 0 

	self.gamelog.Area_bet_all_count = self.area_score_total
	
	for i =2,MAX_SCORE_AREA+1 do
		local win = compare_cards(ret[1],ret[i])
		local record_flag = false
		if win == true then
			all_win_times = all_win_times + 1
			record_flag = false
			if self.which_type == 2 then
				local odds_banker = get_cards_odds(ret[1].cards_times)
				table.insert(result_ret,{win,odds_banker})
			else
				table.insert(result_ret,{win,ret[1].cards_times})
			end
			
		else
			all_lose_times = all_lose_times + 1
			record_flag = true
			if self.which_type == 2 then
				local odds_player = get_cards_odds(ret[i].cards_times)
				table.insert(result_ret,{win,odds_player})
			else
				table.insert(result_ret,{win,ret[i].cards_times})
			end
			
		end
		table.insert(record_ret,record_flag)
		local msg = {
			area_ = i - 1,
			result = record_flag
		}
		table.insert(self.gamelog.Record_result,msg)
	end

	local msg = {pb_CompareResult = self.gamelog.Record_result}
	self:broadcast_msg_to_client("SC_CardCompareResult", msg)
	
	if all_win_times == 4 then
		flag_all_win_or_lose = 1
	elseif all_lose_times == 4 then
		flag_all_win_or_lose = 2
	end
	

	local curtime = get_second_time()
	local banker_uid = self.cur_banker_info.guid

	for j =1,MAX_SCORE_AREA do
		local area_info = (self.area_score_[j] == nil ) and {} or self.area_score_[j]
		for uid,score in pairs(area_info) do
			local win_flag = result_ret[j][1]
			local win_times = result_ret[j][2]
			local old_banker_score = (player_score[banker_uid] == nil) and 0 or player_score[banker_uid]

			local old_pay = player_pay_score[uid] == nil and 0 or player_pay_score[uid]
			local new_pay = old_pay + score
			player_pay_score[uid] = new_pay
			local msg = {
				area = j,
				guid = uid,
				score = score
			}
			table.insert(self.gamelog.Area_bet_info,msg)
			if win_flag then
				local old_score = (player_score[uid] == nil) and 0 or player_score[uid]
				player_score[uid] = old_score - score*(win_times - 1)
				player_score[banker_uid] = old_banker_score + score *win_times
				
			else
				local old_score = (player_score[uid] == nil) and 0 or player_score[uid]
				player_score[uid] = old_score + score*(win_times+1)
				player_score[banker_uid] = old_banker_score - score*win_times
			end
		end
	end

	local notify = {
		pb_conclude = {},
	}


	local banker_earn_score = 0
	local banker_tax = 0
	for i,v in pairs (self.ox_game_player_list) do
		if v and v.guid == self.cur_banker_info.guid then
			local old_money = 0
			local s_type = 1
			if v.is_player == true then 
				old_money = v.pb_base_info.money
			else	
				old_money = v.money
			end
			banker_earn_score = player_score[banker_uid] == nil and 0 or player_score[banker_uid] --庄家总收入			
			if banker_earn_score > 0 then
				if self.room_.tax_open_ == 1 then
					banker_tax = banker_earn_score * OX_PLAYER_TAX
				end	
				if banker_tax >= MIN_TAX_LIMIT then
					banker_tax = math.floor(banker_tax + 0.5)
				else
					banker_tax = 0
				end
				if v.is_player == true then self:tax_channel_invite(v.channel_id,v.guid,v.inviter_guid,banker_tax) end
				if v.is_player == false then
					banker_tax = 0
				end
				self.tax_total = self.tax_total + banker_tax
				banker_earn_score = banker_earn_score - banker_tax
				if v.is_player == false then
					brnn_robot:add_money_robot(v,banker_earn_score,banker_tax)
				else 
					v:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = banker_earn_score}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_OX"))
					notify_win_big_money(v.nickname, def_game_id, banker_earn_score)
					self:update_player_bet_total(math.abs(banker_earn_score),v)
				end
				s_type = 2
			elseif banker_earn_score < 0 then
				if v.is_player == false then 				
					brnn_robot:cost_money_robot(v,-banker_earn_score)
				else
					v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = -banker_earn_score}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_OX"))
					self:update_player_bet_total(math.abs(banker_earn_score),v)
				end
				
			end
		
			if v.is_player == true then
				self:user_log_money(v,s_type,old_money,banker_tax,banker_earn_score,self.table_game_id)
			else
				self:user_log_money_robot(v,1,s_type,old_money,banker_tax,banker_earn_score,self.table_game_id)
			end

			local new_max_score = self:get_max_score(self.cur_banker_info.money + banker_earn_score)
			self.cur_banker_info = {
				guid = self.cur_banker_info.guid,
				nickname = self.cur_banker_info.nickname,
				money = self.cur_banker_info.money + banker_earn_score,
				bankertimes = self.cur_banker_info.bankertimes,
				max_score = new_max_score,
				banker_score = self.cur_banker_info.banker_score + banker_earn_score,
				left_score = new_max_score,
				header_icon = self.cur_banker_info.header_icon,
			}
			self:send_cur_banker_to_client()
	
			local result_info = {
				guid = v.guid,
				is_android = v.is_player == false and 1 or 0,
				table_id = curtime,
				banker_id = v.guid,
				nickname = v.nickname,
				money = self.cur_banker_info.money,
				win_money = banker_earn_score,
				bet_money = 0,
				tax = banker_tax,
				curtime = curtime,
			}
			
			break
		end
	end
	
	self.t_player_SC_OxResult_map = {}
	for i,v in pairs (self.ox_game_player_list) do
		local result = {}
		if v then
			if v.guid == self.cur_banker_info.guid then
				result = {
				chair_id = v.guid,
				pay_score = 0 ,
				earn_score = banker_earn_score,
				system_tax = banker_tax,
				banker_score = banker_earn_score,
				all_win_or_lose_flag = flag_all_win_or_lose,
				money = self.cur_banker_info.money,
				tax_show_flag = self.tax_show_ 
			}
			else
				local old_money = 0
				local s_type = 1
				local player_earn_score = player_score[v.guid] == nil and 0 or player_score[v.guid] 
				local player_bet_money = player_pay_score[v.guid] == nil and 0 or player_pay_score[v.guid]
				if v.is_player == true then
					old_money = v.pb_base_info.money + player_bet_money
				else	
					old_money = v.money + player_bet_money
				end
				local player_tax = 0
				if player_earn_score > 0 then 
					if self.room_.tax_open_ == 1 then
						player_tax = (player_earn_score - player_bet_money) * OX_PLAYER_TAX
					end
					if player_tax >= MIN_TAX_LIMIT then
						player_tax = math.floor(player_tax + 0.5)
					else
						player_tax = 0
					end
					if v.is_player == true then self:tax_channel_invite(v.channel_id,v.guid,v.inviter_guid,player_tax) end
					if v.is_player == false then 
						player_tax = 0
					end
					self.tax_total = self.tax_total + player_tax
					player_earn_score = player_earn_score - player_tax
					if v.is_player == false then
						brnn_robot:add_money_robot(v,player_earn_score,player_tax)
					else 
						v:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = player_earn_score}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_OX"))
						notify_win_big_money(v.nickname, def_game_id, player_earn_score)
						self:update_player_bet_total(math.abs(player_earn_score),v)
					end
					s_type = 2
				elseif player_earn_score < 0 then
					if v.is_player == false then
						brnn_robot:cost_money_robot(v,-player_earn_score) 
					else

					v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = -player_earn_score}}, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_OX"))
					self:update_player_bet_total(math.abs(player_earn_score),v)

					end
				end
				player_earn_score = player_earn_score -  player_bet_money
				local cur_money = 0
				if v.is_player == false then 
					cur_money = v.money
					self:user_log_money_robot(v,0,s_type,old_money,player_tax,player_earn_score,self.table_game_id)
				else
					cur_money = v.pb_base_info.money
					if player_bet_money > 0 then
						self:user_log_money(v,s_type,old_money,player_tax,player_earn_score,self.table_game_id)
					end
				end
				
				result = {
					chair_id = v.guid,                
					pay_score = player_bet_money ,    
					earn_score = player_earn_score,   
					system_tax = player_tax,		  
					banker_score = banker_earn_score, 
					all_win_or_lose_flag = flag_all_win_or_lose, 
					money = cur_money,
					tax_show_flag = self.tax_show_       
					
				}	
				
				local result_info = {
					guid = v.guid,
					is_android = v.is_player == false and 1 or 0,
					table_id = curtime,
					banker_id = banker_uid,
					nickname = v.nickname,
					money = cur_money,
					win_money = player_earn_score,
					bet_money = player_bet_money,
					tax = player_tax,
					curtime = curtime,
				}

				if v.is_player == true then
					self:update_bankerlist_info(v.guid,cur_money)
				end
						
			end
			local msg = {pb_player_result = result}
			post_msg_to_client_pb(v,"SC_OxResult", msg)
			self.t_player_SC_OxResult_map[v.guid] = tableCloneSimple(msg)
			
			table.insert(notify.pb_conclude, result)
			self:update_player_last_recharge_game_total(v)
		end
	end

	self:add_scorebord(record_ret)

	self.gamelog.Game_Conclude = notify.pb_conclude
	self.conclude = notify.pb_conclude
	
	local real_num = self:update_online_player_list()
	self.all_player_list = self.all_player_list or {}
	local msg = {top_player_total = real_num,pb_player_info_list = self.all_player_list}
	self:broadcast_msg_to_client("SC_OxPlayerList", msg)

	local Game_total_time = OX_TIME_READY + OX_TIME_ADD_SCORE + OX_TIME_OPEN_CARD
	self.gamelog.end_game_time = self.gamelog.start_game_time + Game_total_time
	self.gamelog.system_tax_total = self.tax_total
	local s_log = lua_to_json(self.gamelog)
	if self:has_real_player_bet() then
		log_info("running_game_log")
		log_info(s_log)
		self:write_game_log_to_mysql(self.gamelog.table_game_id,self.def_game_name,s_log,self.gamelog.start_game_time,self.gamelog.end_game_time)
	end
	
	self:send_latest_bankerlist_info()

	for i,v in pairs (self.tb_bet_robot) do
		if v then
			self:del_robot(v.guid)
		end
	end
	
	if ly_game_switch == 1 then
		for i,v in pairs (self.ox_game_player_list) do
			if  v and v.is_player == true and v.vip ~= 100 then 
				table.remove(self.ox_game_player_list,i)
			end
		end
	end

	if self.flag_banker_robot == 1 then
		self:del_robot(banker_uid)
		self.change_banker_flag = 1
		return
	end

	if self.cur_banker_info.bankertimes == DEFAULT_CONTINUOUS_BANKER_TIMES  or self.cur_banker_info.money < OX_BANKER_LIMIT then
		self.change_banker_flag = 1
		return
	end

	if self.curbankerleave_flag == 1 then
		self.change_banker_flag = 1
		return
	end
	self.cur_banker_info.bankertimes = self.cur_banker_info.bankertimes + 1
	self.cur_banker_info = {
		guid = self.cur_banker_info.guid,
		nickname = self.cur_banker_info.nickname,
		money = self.cur_banker_info.money,
		bankertimes = self.cur_banker_info.bankertimes,
		max_score = self.cur_banker_info.max_score,
		banker_score = self.cur_banker_info.banker_score,
		left_score = self.cur_banker_info.max_score,
		header_icon = self.cur_banker_info.header_icon,
	}
	self:send_cur_banker_to_client()
	self:check_game_maintain()
	
end


function brnn_table:client_connection_brnn(player)
	player.brnn_in_table = true
	player.is_offline = false
	virtual_table.reconnection_client_msg(self,player)
	local chip_info = {}
	for i = 1, ox_bet_num do	
		local info_chip = {}
		info_chip.chip_index = i
		info_chip.chip_money = robot_money_option[i]
		table.insert(chip_info,info_chip)
	end
	local config_msg = {banker_limit = OX_BANKER_LIMIT,pb_info_chip = chip_info,bet_min_limit_money = OX_PLAYER_MIN_LIMIT}
	post_msg_to_client_pb(player, "SC_Ox_config_info", config_msg)
	
	local notify = {
		pb_player_info = {}
		}
	
	local v = {
			guid = player.guid,
			nickname = player.nickname,
			money = player:get_money(),
			header_icon = player:get_avatar()
		}
	table.insert(notify.pb_player_info, v)
	
	post_msg_to_client_pb(player, "SC_OxPlayerConnection", notify)
	
	local msg = {
		
			}

	local reconnect_flag = 0 
	for i, v in pairs (self.ox_game_player_list) do
		if v and player.guid == v.guid then
			self.ox_game_player_list[i] = player
			reconnect_flag = 1 
		end
	end
	if reconnect_flag == 0 then
		for i, v in pairs (self.ox_game_player_list) do
			if not v then
				self.ox_game_player_list[i] = player
				break
			end
		end
	end

	if self.status == OX_STATUS_READY then
		local curtime = get_second_time()
		local down_time  =  self.time0_ + OX_TIME_READY - curtime
		msg["status"] = OX_STATUS_READY
		msg["count_down_time"] = down_time
		msg["pb_curBanker"] = self.cur_banker_info or {} 
		msg["pb_player_info_list"] = self.all_player_list or {} 
		msg["pb_banker_list"] = self.bankerlist or {} 
		
	elseif self.status == OX_STATUS_PLAY then
	
		local player_bet = {}
		local player_bet_info = {}
		for k = 1,MAX_SCORE_AREA do
			local area_info = (self.area_score_[k] == nil ) and {} or self.area_score_[k]
			for uid,score in pairs(area_info) do
				if player.guid == uid then
					local bet_money = (area_info[uid] == nil) and 0 or area_info[uid]
					local player_bet_area = {which_area = k, bet_money =bet_money}
					table.insert(player_bet_info, player_bet_area)
					break
				end				
			end
		end
		local curtime = get_second_time()
		local down_time  = self.time0_ + OX_TIME_ADD_SCORE - curtime
		msg["status"] = OX_STATUS_PLAY 
		msg["count_down_time"] = down_time 
		msg["pb_curBanker"] = self.cur_banker_info or {}   
		msg["pb_player_info_list"] = self.all_player_list or {}  
		msg["pb_banker_list"] = self.bankerlist or {} 
		msg["pb_AreaInfo"] = self.area_score_total or {} 
		msg["pb_player_area_bet_info"] = player_bet_info or {}  
	
	elseif self.status == OX_STATUS_OVER then
		local result = {}
		for _,v in ipairs(self.conclude) do
			if v and v.chair_id == player.guid then
				result = v
				break
			end
		end 
		
		local player_bet_info = {}
		for k = 1,MAX_SCORE_AREA do
			local area_info = (self.area_score_[k] == nil ) and {} or self.area_score_[k]
			for uid,score in pairs(area_info) do
				if player.guid == uid then
					local bet_money = (area_info[uid] == nil) and 0 or area_info[uid]
					local player_bet_area = {which_area = k, bet_money =bet_money}
					table.insert(player_bet_info, player_bet_area)
					break
				end				
			end
		end

		local cardInfo = {}
		local cardResult = {}
		for i=1,MAX_SCORE_AREA+1 do
			table.insert(cardInfo,{score_area = i,card = self.area_cards_[i]})
		end
		local curtime = get_second_time()
		local down_time  = self.time0_ + OX_TIME_OPEN_CARD - curtime
		msg["status"] = OX_STATUS_OVER
		msg["count_down_time"] = down_time
		msg["pb_curBanker"] = self.cur_banker_info or {} 
		msg["pb_player_info_list"] = self.all_player_list or {}
		msg["pb_banker_list"] = self.bankerlist or {} 
		msg["pb_AreaInfo"] = self.area_score_total or {} 
		msg["pb_player_area_bet_info"] = player_bet_info or {} 
		msg["pb_cards"] = cardInfo or {} 
		msg["pb_result"] = self.cardResult or {} 
		msg["pb_conclude"] = result or {} 
		
		for kkk,vvv in pairs(self.t_player_SC_OxResult_map) do
			if kkk == player.guid then
				post_msg_to_client_pb(player,"SC_OxResult", vvv)
			end
		end
	end
	post_msg_to_client_pb(player, "SC_OxTableInfo", msg)
	self:send_player_list() 
	self:send_ox_record(player)
end


function brnn_table:robot_bet_money(bet_robot)
	
	if bet_robot.money <= 0 then
		return
	end
	
	local bet_times = math.random(1,ROBOT_BET_TIMES_COEFF)
	local cur_bet_money = 0
	for i=1,bet_times,1
	do
		local bet_area = math.random(1,MAX_SCORE_AREA)
		local bet_index_money =  math.random(1,ROBOT_BET_MONEY_OPTION_TOTAL)
		cur_bet_money = cur_bet_money + robot_money_option[bet_index_money]
		if cur_bet_money * OX_MAX_TIMES > bet_robot.money then 
			break
		end
		table.insert(self.robot_bet_info,{bet_robot = bet_robot, bet_area = bet_area, bet_money = robot_money_option[bet_index_money]})
	end
end

function brnn_table:shuffle_robot_betinfo_table()
	
	local len = #self.robot_bet_info
	for i=1,len do
		local info_bet = {}
		local x = math.random(1,len)
		local y = math.random(1,len)
		if x ~= y then
			self.robot_bet_info[x], self.robot_bet_info [y] = self.robot_bet_info[y], self.robot_bet_info[x]
		end
		len = len - 1
	end
end


function brnn_table:start_bet_money_robot()

	--if self.flag_banker_robot == 1 then
		local rand_num = BET_ROBOT_RAND_COEFF + math.random(1,BET_ROBOT_RAND_COEFF)	
		self.tb_bet_robot = self:creat_rand_bet_robot(TYPE_ROBOT_BET,rand_num,BET_ROBOT_INIT_UID,BET_ROBOT_START_MONEY)
	--end

	for i, v in pairs (self.tb_bet_robot) do
		if v then
			self:robot_bet_money(v)
		end
	end	
	self:shuffle_robot_betinfo_table()
end

function brnn_table:playerLeaveOxGame(player)
	for i,v in pairs (self.ox_game_player_list) do
		if v and v.guid == player.guid then
			self.ox_game_player_list[i] = false
			break
		end
	end
	
	for i, v in pairs(self.bankerlist) do
		if v and v.guid == player.guid then
			table.remove(self.bankerlist,i)
			break
		end
	end
	self:send_player_list()
	self:send_latest_bankerlist_info()
end

function brnn_table:del_offline_player()
	for i, v in pairs (self.player_list_) do
		if v and v.is_player == true and v.is_offline == true then
			self:del_player(v.guid)
			self:playerLeaveOxGame(v)
			v:forced_exit()
		end
		if v and v.is_player == true and (not v.brnn_in_table) then
			self:del_player(v.guid)
			self:playerLeaveOxGame(v)
			v:forced_exit()
		end
	end
end


function brnn_table:tick()
	if self.status == OX_STATUS_READY then
		local curtime = get_second_time()
		if curtime - self.time0_ >= OX_TIME_READY then
			if self:count_player_total() > 0 then
				local msg = {status = OX_STATUS_PLAY,count_down_time = OX_TIME_ADD_SCORE}
				self:broadcast_msg_to_client("SC_OxSatusAndDownTime", msg)	
		
				self.time0_ = curtime
				self.status = OX_STATUS_PLAY
				self:init_global_val()
			else
				self.time0_ = curtime
				self.status = OX_STATUS_READY
			end
			
		end
	elseif self.status == OX_STATUS_PLAY then
		if self.robot_start_bet_flag == 0 then
			if SWITCH_BET_ROBOT == 1 then
				self:start_bet_money_robot()
				self.last_bet_time = get_second_time()
				self:send_player_list()
			end
			self.robot_start_bet_flag = 1
		end
		
				
		local curtime = get_second_time()
		local bet_info_table_len = #self.robot_bet_info
		if bet_info_table_len > 0 then
			local rand_seconds = math.random(1,3)
			if curtime - self.last_bet_time >= rand_seconds then
				local rand_bet_robot_num = 1
				if bet_info_table_len > ROBOT_BET_MAX_NUM then
					rand_bet_robot_num = math.random(1,ROBOT_BET_MAX_NUM)
				else
					rand_bet_robot_num = math.random(1,bet_info_table_len)
				end
				
				bet_info_table_len = bet_info_table_len - rand_bet_robot_num
				for i,v in pairs (self.robot_bet_info) do
					local tempTable = {}
					tempTable = self.robot_bet_info[1]
					self:add_score(tempTable.bet_robot, tempTable.bet_area,tempTable.bet_money)
					table.remove(self.robot_bet_info,1)
					if i == rand_bet_robot_num then
						break
					end
				end
				self.last_bet_time = curtime
			end
		end
		
		if curtime - time_last >= 1 then
			local nodify = {
				max_bet_score = self.max_score_,              
				bet_tian_total = self.area_score_total.bet_tian_total,
				bet_di_total = self.area_score_total.bet_di_total,
				bet_xuan_total = self.area_score_total.bet_xuan_total,
				bet_huang_total = self.area_score_total.bet_huang_total,
				left_money_bet = self.area_score_total.left_money_bet, 
				total_all_area_bet_money = self.area_score_total.total_all_area_bet_money,   
			}
	
			local msg = {pb_AreaInfo = nodify}
			self:broadcast_msg_to_client("SC_OxEveryArea", msg)
			time_last = curtime
		end
		
		if curtime - self.time0_ >= OX_TIME_ADD_SCORE - ROBOT_BET_LAST_TIME and bet_info_table_len > 0 then
			for i,v in pairs (self.robot_bet_info) do
				local tempTable = {}
				tempTable = self.robot_bet_info[1] 
				self:add_score(tempTable.bet_robot, tempTable.bet_area,tempTable.bet_money)
				table.remove(self.robot_bet_info,1)
			end
		
		end
		
		if curtime - self.time0_ >= OX_TIME_ADD_SCORE then
			local msg = {status = OX_STATUS_OVER,count_down_time = OX_TIME_OPEN_CARD}
			self:broadcast_msg_to_client("SC_OxSatusAndDownTime", msg)
			self.time0_ = curtime
			self.status = OX_STATUS_OVER
			self:send_cards_to_client()	
			self:del_offline_player()
		end
	elseif self.status == OX_STATUS_OVER then
		local curtime = get_second_time()
		if curtime - self.time0_ >= OX_TIME_OPEN_CARD then
			self:del_offline_player()

			for k,v in pairs(self.player_list_) do
				if v and v.guid == self.cur_banker_info.guid and (not v.brnn_in_table) then
					self:playerLeaveOxGame(v)
					v:forced_exit()
					self.change_banker_flag = 1
					break
				end
			end

			if self.change_banker_flag == 1 then
				self:change_banker()
			end
			self:broadcas_record_result()
			local msg = {status = OX_STATUS_READY,count_down_time = OX_TIME_READY}
			self:broadcast_msg_to_client("SC_OxSatusAndDownTime", msg)
			self.time0_ = curtime
			self.status = OX_STATUS_READY	
			self:init_global_val()
		end

	end
	if not is_same_day(get_second_time(),self.last_tick_time) then
		self:clear_scorebord()
		local curtime = get_second_time()
		self.last_tick_time = curtime
	end
end

function brnn_table:isPlay(player)
	if player then 
		if self.status == OX_STATUS_PLAY then 
			for i, v in pairs (self.player_bet_all_info) do
				if v and v.is_player and v.bet_total > 0 and player.guid == v.guid then
					return true
				end
			end
			if player.guid == self.cur_banker_info.guid then
				return true
			end
		end
		return false
	end
	return self.status == OX_STATUS_PLAY
end
function brnn_table:notify_offline(player)
    if self:isPlay(player) then
		player.is_offline = true
		player.brnn_in_table = false
	else
		self:playerLeaveOxGame(player)
		self:del_player(player.guid)
		self:playeroffline(player)
		self.room_:player_exit_room(player)
		self:send_player_list()
    end
end
function brnn_table:reconnect(player)
    player.is_offline = false
end
function brnn_table:player_stand_up(player, is_offline)
	local ret = virtual_table.player_stand_up(self,player, is_offline)
	if ret then
		self:playerLeaveOxGame(player)
		self:del_player(player.guid)
		self.room_:player_exit_room(player)
		self:send_player_list()
		if player.guid == self.cur_banker_info.guid then
			self:change_banker()
		end
	end
end
function brnn_table:check_cancel_ready(player, is_offline)
	virtual_table.check_cancel_ready(self,player,is_offline)
	player:setStatus(is_offline)
	
	if self:isPlay(player) then
		return false
	end
	return true
end
