require "game_script/virtual/virtual_player"

local sangong_robot = {}

setmetatable(sangong_robot, {__index = virtual_player})

function ly_robot_mgr.check_table(tb)
    local player_count_tmp = virtual_player.player_count or 0
    if player_count_tmp >= 600 then 
        return
    end

    if def_second_game_type ~= 99 then
        local p_count = tb:get_player_count() 
       if  p_count < 4 and tb:has_real_player() then
       --if  p_count < 4  then
            if math.random(ly_add_robot_random_time/2) == 1 then
                math.randomseed(tostring(os.time()):reverse():sub(1, 6))
                local robotnum = math.random(1,4-p_count)
                for i=1,robotnum do
                    local player = sangong_robot.new()
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
       
                    player:init(guid_p, "用户" .. guid_p, "用户" .. guid_p)
                    player.tb = tb
                    player.session_id = 10000 + tb.table_id_
                    player.is_android = true
                    player.room_id = 1
                    player.table_id = tb.table_id_
                    player.ip_area = ly_robot_mgr.ip_table[math.random(#ly_robot_mgr.ip_table)]
                    player.ip = string.format("%d.%d.%d.%d",guid_p,guid_p,guid_p,guid_p)
                    local  Rich_tag=math.random(1,10)
                    if Rich_tag == 1 then 
                        Rich_tag =5000
                    else 
                        Rich_tag =800
                    end 
                    player.pb_base_info = {money = math.random(100,Rich_tag)*tb.cell_score_,header_icon = math.random(1,10),}
                    
                    tb:player_sit_down(player, player.chair_id) 
                    -- 通知消息
                    local notify = {
                        table_id = tb.table_id_,
                        pb_visual_info = {
                        chair_id = player.chair_id,
                        guid = player.guid,
                        account = player.account,
                        nickname = "用户" .. guid_p,
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
                    tb:ready(player) 
                end
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
function sangong_robot:forced_exit()
    if ly_robot_mgr.robot_list[self.guid] then
        for k,v in pairs(self.timer) do
            v.delete = true
        end
        virtual_player.forced_exit(self)
        ly_robot_mgr.robot_list[self.guid] = false
        self:del()
    end

end

function sangong_robot.new()
	local o = {}
    setmetatable(o, {__index = sangong_robot})
    o.timer = {}
    return o 
end

function sangong_robot:game_msg(msg_name, msg)
    if "SC_SanGong_AskBanker" == msg_name then 
        if msg.chair_id == self.chair_id then
            math.randomseed(os.clock())
            local act = {}
            act.dead_line = os.time() + math.random(0,2)
            act.execute = function()
                self.robot_getbanker(self)
            end
            self.timer[#self.timer + 1] = act 
        end
    elseif "SC_SanGong_TalkBanker" == msg_name then 
        if self.chair_id == self.tb.zhuang then
            self.is_zhuang = true
        end  
    elseif "SC_SanGong_AskBet" == msg_name then 
        if msg.chair_id == self.chair_id then
            local act = {}
            act.dead_line = os.time() + math.random(1,2)
            act.execute = function()
                self.robot_bet(self)
            end
            self.timer[#self.timer + 1] = act    
        end
	elseif "SC_SanGong_PostResult" == msg_name then
		local rt =  math.random(1,100)
		
        if rt < 20 then
			self:forced_exit()
		else
            --self.tb:ready(self)
            local act = {}
            act.dead_line = os.time() + math.random(5,10)
            act.execute = function()
                self.tb:ready(self)
            end
            self.timer[#self.timer + 1] = act   
        end    
    end
end

function sangong_robot:robot_getbanker( )
    local robotmsg = {}
    robotmsg.brequest = false 
    math.randomseed(os.clock())
    local rt =  math.random(1,100)
    if rt < 30 then
        robotmsg.brequest = true
    end
    self.tb:player_getbanker(self,robotmsg)
end

function sangong_robot:robot_bet( )
    local robotmsg = {}
    math.randomseed(os.clock())
    local rt =  math.random(1,#self.tb.bet_base)
    robotmsg.target = self.tb.bet_base[rt] 
   self.tb:player_bet(self,robotmsg) 
end


function sangong_robot:tick()
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


return sangong_robot