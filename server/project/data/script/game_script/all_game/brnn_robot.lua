
local pb = require "extern/lib/lib_pb"
require "game_script/virtual/virtual_gamer"
require "game_script/virtual/virtual_table"
require "extern/lib/lib_table"
require "game_script/virtual/virtual_player"
require "game_script/virtual/virtual_robot"
require "game_script/virtual/virtual_robot_mgr"
brnn_robot = {}
local TYPE_ROBOT_BET = 2
local BANKER_ROBOT_START_MONEY = 10000000
local BET_ROBOT_START_MONEY = 100000
local RAND_MONEY = 20000
local BET_AREA_TOTAL = 4
local TYPE_ROBOT_BANKER = 1
local BANKER_ROBOT_INIT_UID = 1000000
local BET_ROBOT_INIT_UID = 2000000
local ROBOT_UID_COEFF = 100000


function brnn_robot:cost_money_robot(robot,robot_earn_money)
	local old_money = robot.money
	if robot_earn_money <= 0 then
		return false
	end
	local new_money = old_money - robot_earn_money
	robot.money = new_money
	ly_robot_storage = ly_robot_storage - robot_earn_money
	post_msg_to_mysql_pb("SD_Save_Storage", {
			game_id = def_game_id,
			storage = ly_robot_storage
		})
	return true
end
temp_number = 0
function brnn_robot:get_one_robot(robot_type, robot_num, uid, money)
	if TYPE_ROBOT_BANKER == robot_type then 
		local banker_robot = brnn_robot:new()
        local robot_uid = 0
        repeat
           robot_uid = math.random(g_robot_guid_cfg.begin,g_robot_guid_cfg.last)
        until (not ly_robot_mgr.robot_list[robot_uid])
        ly_robot_mgr.robot_list[robot_uid] = true

		--local robot_uid = uid + math.random(ROBOT_UID_COEFF)
		banker_robot:init(robot_uid, "test_banker_robot", "system_banker")
		banker_robot.money = money
		return banker_robot
	elseif TYPE_ROBOT_BET == robot_type then 
		local tb_bet_robot = {}
		local robot_ret_uid = uid + math.random(ROBOT_UID_COEFF)
		for i=1,robot_num,1
		do
			local bet_robot = brnn_robot:new()

		    repeat
	        robot_ret_uid = math.random(g_robot_guid_cfg.begin,g_robot_guid_cfg.last)
	        until (not ly_robot_mgr.robot_list[robot_ret_uid])
	        ly_robot_mgr.robot_list[robot_ret_uid] = true

			bet_robot:init(robot_ret_uid, "test_bet_robot", "bet_robot")
			math.randomseed(os.time() + temp_number)
			local rand_num = math.random(RAND_MONEY)
			temp_number = temp_number + math.random(10)
			bet_robot.money = money + math.random(rand_num+1)
			table.insert(tb_bet_robot,bet_robot)
			--robot_ret_uid = robot_ret_uid + 1
		end
		return tb_bet_robot
	else
		return	
	end	
	
	return
end
function brnn_robot:new()  
    local o = {}  
    setmetatable(o, {__index = self})
    return o 
end
function brnn_robot:init(guid_, account_, nickname_)
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	self.guid = guid_
	self.is_player = false
	self.is_android = true
	self.nickname = nickname_
	self.chair_id = 0
	self.money = 0
	self.header_icon = -1
end
function brnn_robot:get_money(robot_type)
	if TYPE_ROBOT_BANKER == robot_type then
		return BANKER_ROBOT_START_MONEY
	elseif TYPE_ROBOT_BET == robot_type then 
		return BET_ROBOT_START_MONEY + math.random(RAND_MONEY)
	else 
		return 0
	end
end
function brnn_robot:add_money_robot(robot,robot_earn_money,tax)
	local old_money = robot.money
	if robot_earn_money <= 0 then
		return false
	end
	local new_money = old_money + robot_earn_money
	robot.money = new_money
	ly_robot_storage = ly_robot_storage + robot_earn_money + tax
	post_msg_to_mysql_pb("SD_Save_Storage", {
			game_id = def_game_id,
			storage = ly_robot_storage
		})
	return true
end


