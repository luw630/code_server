require "extern/g_value"
require "game_script/common_register"
require "game_script/virtual/virtual_player"
require "game_script/virtual/virtual_robot"
require "game_script/virtual/handler_web_cmd"
log_info("Lua Game Server Start ...")
local bp = virtual_player
local bpa = virtual_passive_android
local rm = g_room_mgr				 								 
local msg_id = 0
local auto_broadcast_money_limit = auto_broadcast_money_limit
local notify_win_big_money_str = notify_win_big_money_str
local ly_game_name_switch = ly_game_name_switch
local ly_game_name = ly_game_name
function notify_win_big_money(nickname, game_index, money_value)
	if game_index >=20 and game_index <= 22 then return end --ddz
	if game_index >=150 and game_index <= 153 then return end --sangong
	if ly_game_switch == 1 then return end
	if not ly_game_name[game_index] then return end
	if not nickname then return end
	if money_value < auto_broadcast_money_limit then return end
	
	local content = string.format(notify_win_big_money_str[math.random(#notify_win_big_money_str)], nickname, ly_game_name[game_index], math.floor(money_value/100))
	post_msg_to_login_pb("LS_NewNotice",{id = msg_id,msg_type = 3,is_read = 1,content = content,retID = 0,number = 1,interval_time = 0})
	msg_id = msg_id + 1
end
local last_mt = os.clock()
local t_i = 20

local function broadcast_world_in_tick()
	if def_game_id == 1 then
		if os.clock() - last_mt > t_i then
			last_mt = os.clock()
			t_i = math.random(30) + 20
			notify_win_big_money(ly_robot_name[math.random(#ly_robot_name)], ly_game_name_switch[math.random(#ly_game_name_switch)], math.random(1000*100)+ auto_broadcast_money_limit)
		end
	end
end
function do_update()
	bp:do_save() bpa:do_update() rm:tick() broadcast_world_in_tick()
end

--每日凌晨
function game_server_daily_callback()
	log_info("game_server_daily_callback")
	ly_niuniu_banker_times = 0
end




