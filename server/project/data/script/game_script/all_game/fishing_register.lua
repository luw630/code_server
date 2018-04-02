require "game_script/virtual/handler_in_out_action"
require "game_script/virtual/handler_money_stroage"
require "game_script/virtual/handler_award"
require "game_script/virtual/handler_room"
require "game_script/virtual/handler_chat"
require "game_script/virtual/handler_mail"
require "game_script/handler_net"
require "game_script/all_game/fishing_robot"
require "game_script/handler_net"
require "game_script/virtual/virtual_player"
require "game_script/all_game/fishing_room_mgr"
require "catchfish"
require "game_script/virtual/virtual_table"
local pb = require "extern/lib/lib_pb"

local LOG_MONEY_OPT_TYPE_BUYU = pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_BUYU")
local virtual_player = virtual_player
local room_manager = g_room_mgr



function on_catch_fish(catch_info)
	if not catch_info then
		return
	end

	player = virtual_player:find(catch_info.player_guid)
	if not player then
		return
	end

	local fish_id = catch_info.fish_id
	if (fish_id ==  29 or fish_id == 23 or fish_id == 601 or fish_id == 602 or
		fish_id ==  603 or fish_id == 604 or fish_id == 605 or fish_id == 606 or
		fish_id == 607 or fish_id == 608 or fish_id == 608 or fish_id == 609 or fish_id == 610
		) and  catch_info.score >= 20000 and catch_info.multi >= 200
	then
		notify_win_big_money(player.nickname, def_game_id, catch_info.score)
	end
end

-- function sendfishmsg( guid,gate_id,id,msgstr )
-- 	local fishrobot = virtual_player:find(guid)
-- 	if not fishrobot then
-- 		return
-- 	end
-- 	if fishrobot.is_android then
-- 		fishrobot:on_msg_str(id,msgstr)
-- 	end

-- end

-- 回存
function write_player_money(guid, money)
	local player = virtual_player:find(guid)	
	if not player then
		log_error(string.format("write_player_money guid[%d] not find in game" , guid))
		return
	end

	if player.is_android or money == 0 then
		return
	end

	
	if money > 0 then
		local old_m = player:get_money()
		player:add_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = money}}, LOG_MONEY_OPT_TYPE_BUYU) 
		virtual_table:user_log_money(player,2,old_m,0, money,"")
	else
		local old_m = player:get_money()
		player:cost_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = -money}}, LOG_MONEY_OPT_TYPE_BUYU) 
		virtual_table:user_log_money(player,1,old_m,0, money,"")
	end
	virtual_table:update_player_bet_total(math.abs(money),player)
	--player:change_money(money, 0,true,nil)
end
function player_exit_fish(guid)
	local player = virtual_player:find(guid)	
	if not player then
		log_error(string.format("player_exit_fish guid[%d] not find in game" , guid))
		return
	end
	virtual_table:update_player_last_recharge_game_total(player)
end

--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
-- 打开宝箱
function handler_fishing_treasureend(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		tb.cpp_table:CSTreasureEnd()
	end
end

-- 改变大炮集
function handler_fishing_changecannonset(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb and msg ~= nil and type(msg)=="table" then
		tb.cpp_table:OnChangeCannonSet(player,msg.add)
	end
end

-- 网鱼
function handler_fishing_netcast(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb and msg ~= nil and type(msg)=="table" then
		tb.cpp_table:OnNetCast(player,msg.bullet_id,msg.data,msg.fish_id)
	end
end

-- 锁定鱼
function handler_fishing_lockfish(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb and msg ~= nil and type(msg)=="table" then
		tb.cpp_table:OnLockFish(player,msg.lock)
	end
end

--锁定指定鱼
function handler_fishing_lockspecfish(player,msg)
	local tb = room_manager:get_user_table(player)
	if tb and msg ~= nil and type(msg)=="table" then
		tb.cpp_table:OnLockSpecFish(player,msg.fish_id)
	end
end

-- 开火
function handler_fishing_fire(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb and msg ~= nil and type(msg)=="table" then
		--print_r(msg)
		tb.cpp_table:OnFire(player,msg)
	end
end

-- 变换大炮
function handler_fishing_changecannon(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb and msg ~= nil and type(msg)=="table" then
		tb.cpp_table:OnChangeCannon(player,msg.add)
	end
end

-- 获取系统时间
function handler_fishing_timesync(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb and msg ~= nil and type(msg)=="table" then
		tb.cpp_table:OnTimeSync(player,msg.client_tick)
	end
end



client_handler_reg("CS_TreasureEnd", "handler_fishing_treasureend")
client_handler_reg("CS_ChangeCannonSet", "handler_fishing_changecannonset")
client_handler_reg("CS_Netcast", "handler_fishing_netcast")
client_handler_reg("CS_LockFish", "handler_fishing_lockfish")
client_handler_reg("CS_LockSpecFish", "handler_fishing_lockspecfish")
client_handler_reg("CS_Fire", "handler_fishing_fire")
client_handler_reg("CS_ChangeCannon", "handler_fishing_changecannon")
client_handler_reg("CS_TimeSync", "handler_fishing_timesync")


