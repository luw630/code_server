

require "game_script/virtual/virtual_player"
pb = require "extern/lib/lib_pb"

g_android_players = g_android_players or {}

fishing_android = class("fishing_android",virtual_player)

function ly_robot_mgr.check_table(tb)
    local player_count_tmp = virtual_player.player_count or 0
    if player_count_tmp >= 600 then 
        return
    end

    if def_second_game_type ~= 99 then
        local p_count = tb:get_player_count() 
        if  p_count < 3 and tb:has_real_player() then
            if math.random(100) == 1 then
                local player = fishing_android.new()
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
        elseif (not tb:has_real_player()) and p_count > 0 then
            for i,v in ipairs(tb.player_list_) do
                if v and v.is_android and not(v.tb:isPlay()) then
                   -- v:forced_exit()
                end
            end
           
        end
    end
end

function fishing_android:ctor()
    self.is_android = true
    self.last_fire_tick = os.clock()
    self.client_id = 0
    self.fire_count = 0
    self.fish_ids = {}
    self.bullet_ids = {}
    self.is_allow_fire = false
    self.max_bullet_count = 20
    self.msgs = {}
    self.fire_count = 0
    self.catch_count = 0

    math.randomseed(os.time())
end

function fishing_android:init(guid_, account_, nickname_)
    self.super.init(self,guid_,account_,nickname_)
    g_android_players[guid_] = self
end

function fishing_android:forced_exit()
    if ly_robot_mgr.robot_list[self.guid] then
        for k,v in pairs(self.timer) do
            v.delete = true
        end
        virtual_player.forced_exit(self)
        ly_robot_mgr.robot_list[self.guid] = false
        self:del()
    end

end

function fishing_android.new()
    local o = {}
    setmetatable(o, {__index = fishing_android})
    o.timer = {}
    return o 
end


function fishing_android:fire()
    if not self.is_allow_fire then
        return
    end

    if #self.bullet_ids >= self.max_bullet_count then
        return
    end

    local tb = g_room_mgr:get_user_table(self)
    if not tb then
        return
    end

    tb.cpp_table:OnFire(self,
        {
            chair_id = self.chair_id,
            direction = 3,
            client_id = self.client_id + self.chair_id * 10000,
            fire_time = os.clock(),
            pos_x = 0,pos_y = 0
        })

    table.insert(self.bullet_ids,self.client_id + self.chair_id * 10000)
    self.client_id = ((self.client_id + 1) % 10000) == 0 and 0 or self.client_id + 1
    self.fire_count = self.fire_count + 1
--    print("firecount",self.fire_count)
end

function fishing_android:proc_msg()
    local tb = g_room_mgr:get_user_table(self)
    if not tb then
        print("proc msg,cannot find table")
        return
    end

    local msgname = ""
    local msg = {}
    local msgs = self.msgs
    self.msgs = {}
    for _,v in pairs(msgs) do
        msgname = v.msgname
        msg = v.msg

        if msgname == "SC_SendFish" then
--            print("SC_SendFish",msg.fish_id)
            table.insert(self.fish_ids,msg.fish_id)
        elseif msgname == "SC_AllowFire" then
            self.is_allow_fire = msg.allow_fire == 1 and true or false
        elseif msgname == "SC_GameConfig" then
            self.max_bullet_count = msg.max_bullet_count
        elseif msgname == "SC_KillFish" then
            for i,v in pairs(self.fish_ids) do
                if v == msg.fish_id then
--                    print("kill fish",tb.table_id_,v)
                    table.remove(self.fish_ids,i)
                    break
                end
            end
        elseif msgname == "SC_KillBullet" then
            for i,v in pairs(self.bullet_ids) do
                if v == msg.bullet_id then
--                    print("kill bullet:",tb.table_id_,v)
                    table.remove(self.bullet_ids,i)
                    break
                end
            end
        elseif msgname == "SC_SwitchScene" then
            if msg.switching == 1 then
                self.fish_ids = {}
            end
        elseif msgname == "SC_SendFishList" then
            for k,v in pairs(msg.pb_fishes) do
                table.insert(self.fish_ids,v.fish_id)
            end
        end
    end
end

function fishing_android:tick()
    self:proc_msg()

    local tb = g_room_mgr:get_user_table(self)
    if not tb then
        return
    end
    --print("allow fire:",tb.table_id_,self.guid)
    if self.is_allow_fire then
        if os.clock() - self.last_fire_tick >= 0.1 then
            self.last_fire_tick = os.clock()
            self:fire()
        end
    end

    if #self.fish_ids > 0 and #self.bullet_ids > 0 then
        math.randomseed(os.time())
        local fish_i = math.random(#self.fish_ids)
        local bullet_i = math.random(#self.bullet_ids)
--        print(tb.table_id_,#self.fish_ids,#self.bullet_ids)
        tb.cpp_table:OnNetCast(self,self.bullet_ids[bullet_i],0,self.fish_ids[fish_i])
        self.catch_count = self.catch_count + 1
    end
end

function fishing_android:on_msg(msgname,msg)
    table.insert(self.msgs,{msgname = msgname,msg = msg})
end

function fishing_android:on_msg_str(msgid,msg_str)
    local msgname = ""
    if msgid == 12107 then
        msgname = "SC_AllowFire"
    elseif msgid == 12115 then
        msgname = "SC_SendFish"
    elseif msgid == 12117 then
        msgname = "SC_GameConfig"
    elseif msgid == 12110 then
        msgname = "SC_KillFish"
    elseif msgid == 12109 then
        msgname = "SC_KillBullet"
    elseif msgid == 12108 then
        msgname = "SC_SwitchScene"
    elseif msgid == 12116 then
        msgname = "SC_SendFishList"
    end

    if msgname ~= "" then
        local msg = pb.decode(msgname,msg_str,string.len(msg_str))
        table.insert(self.msgs,{msgname = msgname,msg = msg})
    end
end

function fishing_android:on_fish_dead(fish_id)
    for i,v in pairs(self.fish_ids) do
        if v == fish_id then
--            print("fish out of screen:",fish_id)
            table.remove(self.fish_ids,i)
        end
    end
end

function on_fish_removed(room_id,table_id,fish_id)
    local tb = {}
    local room = g_room_mgr:find_room(room_id)
    if not room then
        return
    end

    tb = room:find_table(table_id)
    if not tb then
        return
    end

    tb:on_fish_dead(fish_id)
end