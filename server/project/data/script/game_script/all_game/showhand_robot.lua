require "game_script/virtual/virtual_player"
local print_table = require "extern/lib//lib_print_r"


local showhand_robot = {}

setmetatable(showhand_robot, {__index = virtual_player})
function ly_robot_mgr.check_table(tb)
    local player_count_tmp = virtual_player.player_count or 0
    if player_count_tmp >= 600 then --至少有300 真实玩家  不再使用机器人
        return
    end

    if def_second_game_type ~= 99 then
        local p_count = tb:get_player_count() 
        if  p_count < 2 and tb:has_real_player() then
            if math.random(100) == 1 then
                local player = showhand_robot.new()
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
                    Rich_tag =5000
                else 
                    Rich_tag =800
                end 
                player.pb_base_info = {money = math.random(100,Rich_tag)*tb.cell_score_,header_icon = math.random(1,10),}
                
                tb:ready(player)

                -- 通知消息
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
function showhand_robot:forced_exit()
	for k,v in pairs(self.timer) do
		v.delete = true
    end
	virtual_player.forced_exit(self)
    ly_robot_mgr.robot_list[self.guid] = false
    self:del()
end

function showhand_robot.new()
	local o = {}
    setmetatable(o, {__index = showhand_robot})
    o.timer = {}
    return o 
end

function showhand_robot:game_msg(msg_name, msg)
    if "SC_ShowHand_Desk_Enter" == msg_name then --开始
        self.is_zhuang = false
        self.is_big = false
        if self.chair_id == self.tb.zhuang then
            self.is_zhuang = true
        end  
        if self.chair_id == self.tb:get_bigest_player_chair_id() then
            self.is_big = true
        end 
        
    elseif "SC_ShowHand_NextTurn" == msg_name then 
        if msg.chair_id == self.chair_id then
            local tmp_type = msg.type
            local can_add       = ((0x00001 & tmp_type) > 0)  --加注
            local can_allin     = ((0x00002 & tmp_type) > 0)  --allin
            local can_follow    = ((0x00004 & tmp_type) > 0)  --跟注
            local can_pass      = ((0x00008 & tmp_type) > 0)  --让牌
            local can_giveup    = ((0x00010 & tmp_type) > 0) --弃牌
            local must_win      = self.tb.must_win

            local act = {}
            act.dead_line = os.time() + math.random(2,4)
            if self.tb.cur_game_round == 1 then
                act.dead_line = act.dead_line + 2
            end
            act.execute = function()
                local act_count = 0
                if can_add then act_count = act_count + 1 end
                if can_allin then act_count = act_count + 1 end
                if can_follow then act_count = act_count + 1 end
                if can_pass then act_count = act_count + 1 end
                local act_rise = {}
                for i=1,act_count do
                    local rise_t = 90
                    if self.tb.must_win then rise_t = 100 end
                    act_rise[i] = rise_t/act_count*i
                end

                local r_val = math.random(1,100)
                local done = false
                local act_index = 1
                if can_add and (not done) then
                    if r_val <= act_rise[act_index] then
                        done = true
                        local baseBet = self.tb.cell_score_
                        local maxAdd = baseBet*self.tb.max_call
                        local roundBet = 0
                        for k,v in pairs(self.tb.player_list_) do
                            if v and not v.is_dead then
                                if roundBet < v.cur_round_add then
                                    roundBet = v.cur_round_add
                                end
                            end
                        end

                        local curTimes = math.ceil(roundBet/baseBet) --当前是多少倍了
                        if curTimes<=0 then
                            curTimes = 1 --默认从1开始
                        else
                            curTimes = curTimes*2
                        end
                    
                        local add_list = {}
                        for i=1,4 do
                            add_list[i] = curTimes * baseBet*math.pow(2,i-1)
                        end
                        local add_rise = math.random(1,4)
                        self.tb:add_score(self, {target = add_list[add_rise]})
                    end
                    act_index = act_index + 1
				end
                if can_allin and (not done) then
                    if r_val <= act_rise[act_index] then
                        done = true
                        self.tb:add_score(self, {target = -1})
                    end
                    act_index = act_index + 1
				end
                if can_follow and (not done) then
                    if r_val <= act_rise[act_index] then
                        done = true
                        self.tb:add_score(self, {target = -2})
                    end
                    act_index = act_index + 1
				end
                if can_pass and (not done) then
                    if r_val <= act_rise[act_index] then
                        done = true
                        self.tb:pass(self)
                    end
                    act_index = act_index + 1
				end
                if can_giveup and (not done) then
                    self.tb:give_up(self)
                end 
            end
            self.timer[#self.timer + 1] = act     
        end

    elseif "SC_ShowHandPass" == msg_name then
    elseif "SC_ShowHandGiveUp" == msg_name then
    elseif "SC_ShowHandAddScore" == msg_name then
    elseif "SC_ShowHand_Next_Round" == msg_name then
    elseif "SC_ShowHand_Desk_State" == msg_name then

    elseif "SC_ShowHand_Game_Finish" == msg_name then
	elseif "GAME_CLOSE" == msg_name then
		local rt =  math.random(1,100)
        if rt < 20 then
			self:forced_exit()--机器人退出
		else
            local act = {}
            act.dead_line = os.time() + math.random(3,6)
            act.execute = function()
                self.tb:ready(self)
            end
            self.timer[#self.timer + 1] = act   
        end    
    end
end

function showhand_robot:tick()
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


return showhand_robot