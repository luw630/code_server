local pb = require "extern/lib/lib_pb"
require "game_script/handler_net"
local post_msg_to_client_pb = post_msg_to_client_pb
local room_manager = g_room_mgr
virtual_gamer = {}
function virtual_gamer:new()  
    local o = {}  
    setmetatable(o, {__index = self})
	
    return o 
end
function virtual_gamer:init(guid_, account_, nickname_)  
    self.guid = guid_
    self.account = account_
    self.nickname = nickname_
end
function virtual_gamer:del()
end
function virtual_gamer:check_room_limit(score)
	return false
end
function virtual_gamer:handler_enter_sit_down(room_id_, table_id_, chair_id_, result_, tb)
end
function virtual_gamer:handler_stand_exit_room(room_id_, table_id_, chair_id_, result_)
end
function virtual_gamer:on_change_chair(table_id_, chair_id_, result_, tb)
end
function virtual_gamer:on_enter_room(room_id_, result_)
end
function virtual_gamer:on_notify_enter_room(notify)
end
function virtual_gamer:on_exit_room(room_id_, result_)
end
function virtual_gamer:on_notify_exit_room(notify)
end
function virtual_gamer:on_sit_down(table_id_, chair_id_, result_)
end
function virtual_gamer:on_notify_sit_down(notify)
end
function virtual_gamer:on_stand_up()
end
function virtual_gamer:on_notify_stand_up(notify)
end
function virtual_gamer:on_notify_android_sit_down(room_id_, table_id_, chair_id_)
end
function virtual_gamer:check_forced_exit(score)
	if self:check_room_limit(score) then
		self:forced_exit()
	end
end
function virtual_gamer:forced_exit()
	local ret = 0
	if room_manager == nil then
		if g_room_mgr ~= nil then
			local ret = g_room_mgr:stand_up(self)
			if ret == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
			   g_room_mgr:exit_room(self)
			end
		end
	else
		local ret = room_manager:stand_up(self)
		if ret == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
		   room_manager:exit_room(self)
		end
	end
end
function virtual_gamer:get_level()
	return 1
end
function virtual_gamer:get_money()
	return 0
end
function virtual_gamer:get_avatar()
	return 0
end
function virtual_gamer:cost_money(price, opttype)
end
function virtual_gamer:add_money(price, opttype)
end
