require "game_script/virtual/virtual_player"
require "ailib"
local print_table = require "extern/lib//lib_print_r"
local ddz_robot = {}
setmetatable(ddz_robot, {__index = virtual_player})

function ly_robot_mgr.check_table(tb)
    local player_count_tmp = virtual_player.player_count or 0
    if player_count_tmp >= 600 then
        --return
    end
	local LAND_STATUS_FREE = 1
    if def_second_game_type ~= 99 and tb.status == LAND_STATUS_FREE then
        local p_count = tb:get_player_count() 
        if  p_count < 3 and tb:has_real_player() then
            if math.random(ly_add_robot_random_time) == 1 then
                local player = ddz_robot.new()
                for k,v in pairs(tb.player_list_) do
                    if not v then
                        tb.player_list_[k] = player
                        player.chair_id = k 
                        break
                    end
                end
                local guid_p = 0
                repeat
                   guid_p = math.random(g_robot_guid_cfg.begin,g_robot_guid_cfg.last)
                until (not ly_robot_mgr.robot_list[guid_p])
                ly_robot_mgr.robot_list[guid_p] = true
   
                player:init(guid_p, "玩家" .. guid_p, "玩家" .. guid_p)
                player.tb = tb
                player.session_id = 10000 + tb.table_id_
                player.is_android = true
                player.room_id = 1
                player.table_id = tb.table_id_
                player.ip_area = ly_robot_mgr.ip_table[math.random(#ly_robot_mgr.ip_table)]
                player.ip = string.format("%d.%d.%d.%d",guid_p,guid_p,guid_p,guid_p)
				local  Rich_tag=math.random(1,10)
                if Rich_tag == 1 then 
                    Rich_tag =500
                else 
                    Rich_tag =200
                end 
                player.pb_base_info = {money = math.random(100,Rich_tag)*tb.cell_score_,header_icon = math.random(1,10),}
                
                tb:ready(player)

				local notify = {
					table_id = tb.table_id_,
					pb_visual_info = {
					chair_id = player.chair_id,
					guid = player.guid,
					account = player.account,
					nickname = "玩家" .. guid_p,
					level = player:get_level(),
					money = player:get_money(),
					header_icon = player:get_avatar(),
					ip_area = player.ip_area,
					is_ready = (tb.ready_list_ and tb.ready_list_[player.chair_id] or false)
					}
				}
				
				tb:foreach(function (p)
					p:on_notify_sit_down(notify)
				end)

            end
        elseif (not tb:has_real_player()) and p_count > 0 then
            for i,v in ipairs(tb.player_list_) do
                if v and v.is_android and not(tb:isPlay()) then
                    v:forced_exit()
                end
            end
        end
    end
end
function ddz_robot:forced_exit()
	for k,v in pairs(self.timer) do
		v.delete = true
    end
	virtual_player.forced_exit(self)
    ly_robot_mgr.robot_list[self.guid] = false
    self:del()
end

function ddz_robot.new()
	local o = {}
    setmetatable(o, {__index = ddz_robot})
    o.timer = {}
    o.cpp_robot = cpp_robot()
    o.cpp_robot:Initialization()
    o.game_msg_check = 0
    o.game_msg_last = ""
    return o 
end

function ddz_robot:game_msg(msg_name, msg)
	--log_info("begin game_msg: " .. msg_name)
    if self.game_msg_check ~= 0 then
        log_error("ddz  cpp  excption ...")
        log_error("last excption msg  is " .. self.game_msg_last)
    end
    self.game_msg_last = msg_name
    self.game_msg_check = 1
    self.cpp_robot:set_self_ChairID(self.chair_id - 1)
    local msg_back = {}
    if "GAME_START" == msg_name then
        self.cpp_robot:OnEventGameMessage(msg_name, msg,msg_back)
    elseif msg_name == "SC_LandCallScore" then 
        self.cpp_robot:OnEventGameMessage(msg_name, msg,msg_back)
        if msg_back.score then
            local act = {}
			local delay = math.random(2,4)
			if not msg.call_chair_id then
				delay = math.random(7,9)
			end
			act.dead_line = os.time() + delay
			act.execute = function()
           -- self.tb:call_score(self, 0)
			self.tb:call_score(self, msg_back.score)
			end
			self.timer[#self.timer + 1] = act
        end
    elseif msg_name == "SC_LandInfo" then 
        self.cpp_robot:OnEventGameMessage(msg_name, msg,msg_back)
        if msg.land_chair_id ~= self.chair_id then
            local act = {}
			act.dead_line = os.time() + math.random(1,2)
			act.execute = function()
                --local d = math.random(1,2)
				self.tb:call_double(self, false) --d == 1
			end
			self.timer[#self.timer + 1] = act
        end
    elseif msg_name == "SC_LandCallDoubleFinish" then 
         msg_back = {
            cbCardCount = 0,
		    cbCardData = {},
            give_up = false 
        }
        self.cpp_robot:OnEventGameMessage(msg_name, msg,msg_back)
        if (not msg_back.give_up) and (msg_back.cbCardCount > 0) then
            local act = {}
			act.dead_line = os.time() + math.random(2,3)
			act.execute = function()
                self.tb:out_card(self, msg_back.cbCardData)
			end
			self.timer[#self.timer + 1] = act
        end
    elseif msg_name == "SC_LandOutCard" then 
        msg_back = {
            cbCardCount = 0,
		    cbCardData = {},
            give_up = false 
        }
        self.cpp_robot:OnEventGameMessage(msg_name, msg,msg_back)
        if (not msg_back.give_up) and (msg_back.cbCardCount > 0) then
            local act = {}
			act.dead_line = os.time() + math.random(2,3)
			act.execute = function()
                self.tb:out_card(self, msg_back.cbCardData)
			end
			self.timer[#self.timer + 1] = act
        elseif msg_back.give_up then
            local act = {}
			act.dead_line = os.time() + math.random(1,2)
			act.execute = function()
                self.tb:pass_card(self)
			end
			self.timer[#self.timer + 1] = act
        end
    elseif msg_name == "SC_LandPassCard" then
        msg_back = {
            cbCardCount = 0,
		    cbCardData = {},
            give_up = false 
        }
        self.cpp_robot:OnEventGameMessage(msg_name, msg,msg_back)
        if (not msg_back.give_up) and (msg_back.cbCardCount > 0) then
            local act = {}
            act.dead_line = os.time() + math.random(2,4)
			act.execute = function()
                self.tb:out_card(self, msg_back.cbCardData)
			end
			self.timer[#self.timer + 1] = act
        elseif msg_back.give_up then
            local act = {}
			act.dead_line = os.time() + math.random(1,2)
			act.execute = function()
                self.tb:pass_card(self)
			end
			self.timer[#self.timer + 1] = act
        end
    elseif msg_name == "SC_LandConclude" then
        self.cpp_robot:OnEventGameMessage(msg_name, msg,msg_back)
        local act = {}
		act.dead_line = os.time() + math.random(5,8)
		act.execute = function()
			self.tb:ready(self)
		end
		self.timer[#self.timer + 1] = act
    end
    self.game_msg_check = 0
	--log_info("end game_msg: " .. msg_name)
end

function ddz_robot:tick()
    local dead_list = {}
    for k,v in pairs(self.timer) do
		if os.time() > v.dead_line then
			if not v.delete then
                v.execute()
            end
			dead_list[#dead_list + 1] = k
        end
    end
    for k,v in pairs(dead_list) do
		self.timer[v] = nil
    end
end


return ddz_robot