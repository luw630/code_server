require "game_script/virtual/virtual_player"
local hhdz_robot = {}
setmetatable(hhdz_robot, {__index = virtual_player})
local robot_num= 25
local def_robot_num = 30
function ly_robot_mgr.check_table(tb)
    -- local player_count_tmp = virtual_player.player_count or 0
    -- if player_count_tmp >= 600 then 
    --     return
    -- end
    local all_count = tb:get_player_count()
    if all_count >= 300 then
        return
    end
    
    if def_second_game_type ~= 99 then
        local p_count = tb:get_real_player_count()
        if tb.robot_num < p_count *2 or tb.robot_num < def_robot_num  then
            if p_count * 2 > def_robot_num then
                robot_num = p_count * 2 - robot_num
            else
                robot_num = def_robot_num - robot_num
            end
           
           -- robot_num = 999
             if math.random(ly_add_robot_random_time/2) == 1 then
                for i=1,robot_num do
                    local player = hhdz_robot.new()
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
                        Rich_tag =500000
                    else 
                        Rich_tag =80000
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
                    tb.robot_num = tb.robot_num + 1
                end
             end      
        elseif (not tb:has_real_player()) and tb:get_player_count() > 0 then
            -- for i,v in ipairs(tb.player_list_) do
            --     if v and v.is_android and not(tb:isPlay(v)) then
            --         v:forced_exit()
            --     end
            -- end
        end
    end
end

function hhdz_robot:new()  
	local o = {}
    setmetatable(o, {__index = hhdz_robot})
    o.timer = {}
    return o 
end

function hhdz_robot:forced_exit()
    if ly_robot_mgr.robot_list[self.guid] then
        for k,v in pairs(self.timer) do
            v.delete = true
        end
        virtual_player.forced_exit(self)
        ly_robot_mgr.robot_list[self.guid] = false
        self:del()
        self.tb.robot_num =  self.tb.robot_num - 1
    end

end

function hhdz_robot:game_msg( msg_name, msg )
	if msg_name == "SC_HongHeiStart" then
        -- if  self.tb.cheat_table.cheatmode > 0 then
        --     return
        -- end
        math.randomseed(get_second_time()+self.guid+self:get_money())
        local act = {}
        act.dead_line = os.time() + math.random(3,12)
        act.execute = function()
            self:robot_bet(self)
        end
        self.timer[#self.timer + 1] = act   
	end
end

function hhdz_robot:robot_bet( )
    math.randomseed(get_second_time()+self.guid+self:get_money())
    local bet = self.tb.bet_base
    local betmoney = 2
    local random_bet = math.random(1,100)
    local random_money = math.random(1,100)
    if random_bet < 45 then
        bettype = 1
    elseif random_bet < 90 then
        bettype = 2
    else
        bettype = 3
    end

    if random_money < 10 then
        betmoney = 2
    elseif random_money < 40 then
        betmoney = 3
    elseif random_money < 70 then
        betmoney = 4
    elseif random_money < 100 then
        betmoney = 5
    end


    
    if self:get_money() >= bet[betmoney] then
        self.tb:player_bet(self,bet[betmoney],bettype) 
    else
        self.tb:player_bet(self,self:get_money(),bettype)
    end
end

function hhdz_robot:robot_cheatbet(bettype,betmoney )
    while 1 do
        for i=5,1,-1 do
            if betmoney > self.tb.bet_base[i] then
                self.tb:player_bet(self,self.tb.bet_base[i],bettype) 
                betmoney = betmoney - self.tb.bet_base[i]
                break
            end
        end

        if betmoney < 100 then
            break
        end
    end
end


function hhdz_robot:tick()
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

return hhdz_robot