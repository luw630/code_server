require "game_script/virtual/virtual_player"
local print_table = require "extern/lib//lib_print_r"


local texas_robot = {}

setmetatable(texas_robot, {__index = virtual_player})
function ly_robot_mgr.check_table(tb)
    local player_count_tmp = virtual_player.player_count or 0
    if player_count_tmp >= 600 then --至少有300 真实玩家  不再使用机器人
        return
    end

    if def_second_game_type ~= 99 then
        local p_count = tb:get_player_count() 
        if  p_count < 4 and tb:has_real_player() then
            if math.random(ly_add_robot_random_time) == 1 then
                local player = texas_robot.new()
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
                tb:sit_on_chair(player,player.chair_id)
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
function texas_robot:forced_exit()
	for k,v in pairs(self.timer) do
		v.delete = true
    end
    log_info("robot forced_exit "..self.guid)
	virtual_player.forced_exit(self)
    ly_robot_mgr.robot_list[self.guid] = false
    self:del()
end

function texas_robot.new()
	local o = {}
    setmetatable(o, {__index = texas_robot})
    o.timer = {}

    return o 
end

function texas_robot:game_msg(msg_name, msg)
    --print("texas_robot msg_name "..msg_name)
   
    if "SC_TexasSendPublicCards" == msg_name then --开始
    elseif "SC_TexasSendUserCards" == msg_name then 
        for k, p in pairs(msg.pb_user) do
            if p.action == 7 and p.chair == self.chair_id then
                local act = {}
                act.dead_line = os.time() + math.random(1,3)
                act.execute = function()
                    self.act_call(self)
                end
                self.timer[#self.timer + 1] = act   
            end
        end
    elseif "SC_TexasUserAction" == msg_name then
        if msg.chair == self.chair_id and msg.action == 7 then
            local act = {}
            act.dead_line = os.time() + math.random(1,3)
            act.execute = function()
                self.act_call(self)
            end
            self.timer[#self.timer + 1] = act   
        end
    end
end


function texas_robot:act_call()
    local xmax = 4
    if self.is_follow == true then  --不会弃牌
        xmax = 3
    end
    local randindex =  math.random(1,xmax)
    local money = math.random(1,self.tb.t_pot)
    if  self.tb:player_action(self,self.tb,randindex,money) ~= 0 then
        for i=1,xmax do
            if  self.tb:player_action(self,self.tb,i,money) == 0 then
                break
            end
        end
    end

end

function texas_robot:tick()
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


return texas_robot