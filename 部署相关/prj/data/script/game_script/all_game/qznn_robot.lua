require "game_script/virtual/virtual_player"
local DEBUG_MODE = false
local DEBUG_ANDROID_NUM=0
local zjnn_robot = {}
setmetatable(zjnn_robot, {__index = virtual_player})
local CONTEND_DELAY_F=3
local CONTEND_DELAY_C=4
local BET_DELAY_F=0
local BET_DELAY_C=3
local SHOWCARDS_DELAY_F=3
local SHOWCARDS_DELAY_C=6
local REENTER_DELAY_F=1
local REENTER_DELAY_C=3
local REENTER_NUM=9
local REENTER_DEN=10
local SITONCHAIR_DELAY=4
local TB_PLAYER_LIMIT=5


function ly_robot_mgr.check_table(tb)
    if def_second_game_type ~= 99 then
		
        local p_count = tb:get_player_count()
	
		if  p_count < TB_PLAYER_LIMIT-1 and tb:has_real_player() then
			
			if (tb.robot_random_num or 0)==0 then
				tb.robot_random_num=math.random(1,3)
			end
			
			local real_count=tb:get_real_player_count()
			local android_count=p_count-real_count
			
			local new_robot_num=tb.robot_random_num-android_count
			if DEBUG_MODE then
				new_robot_num=DEBUG_ANDROID_NUM
			end

			if new_robot_num>0 then
				for i=1,new_robot_num do
					
					local player = zjnn_robot:new()

					local money_range = {
					{10000,20000},
					{20000,50000},
					{50000,100000},
					{200000,400000},
				}
					local money_type = money_range[def_second_game_type]
	
					-- local  Rich_tag=math.random(1,10)
					-- if Rich_tag == 1 then 
					-- 	Rich_tag =5000
					-- else 
					-- 	Rich_tag =800
					-- end 
					player.pb_base_info = {money = math.random(money_type[1],money_type[2]),header_icon = math.random(1,10),}
					
					
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
					
					
					--tb:ready(player)
					
					local act = {}
					local delay = SITONCHAIR_DELAY
					act.dead_line = os.time() + delay
					act.execute = function()
						if tb.b_table_busy == 1 then
							return
						end
						player.tb:sit_on_chair(player, player.chair_id)
					end
					player.timer[#player.timer + 1] = act
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


function zjnn_robot:forced_exit()
	for k,v in pairs(self.timer) do
		v.delete = true
    end
	virtual_player.forced_exit(self)
    ly_robot_mgr.robot_list[self.guid] = false
    self:del()
end


function zjnn_robot:new()
	local o = {}
    setmetatable(o, {__index = zjnn_robot})
    o.timer = {}
    return o
end



function zjnn_robot:game_msg(msg_name, msg)
	
	local act = {}
	if msg_name == "SC_BankerSendCards" then
		local point_list = {}
		for i = 1,4 do
			point_list[i] = get_value_ox(math.floor(msg.cards[i]/4))
		end

		self.niuniu = false
		self.youniu = false
		if ((point_list[1] + point_list[2] + point_list[3]) %10 ==0) or
		((point_list[1] + point_list[2] + point_list[4]) %10 ==0) or
		((point_list[1] + point_list[3] + point_list[4]) %10 ==0) or
		((point_list[2] + point_list[3] + point_list[4]) %10 ==0) then

			if ((point_list[1] + point_list[2] + point_list[3]+ point_list[4]) %10 ==0)  then 
				self.niuniu = true
			end
			self.youniu = true
		end



	elseif msg_name == "BeginToContend" then
			local delay =math.random(CONTEND_DELAY_F,CONTEND_DELAY_C)
			act.dead_line = os.time()+delay
			act.execute = function()
						
				local ratio=0	
				-- local random_num=math.random(1,100)
				-- if random_num<=30 then
				-- 	ratio=math.random(-1,0)	
				-- elseif random_num<=60 then
				-- 	ratio=1
				-- elseif random_num<=80 then	
				-- 	ratio=2
				-- elseif random_num<=95 then	
				-- 	ratio=3
				-- else	
				-- 	ratio=4
				-- end
				
				if self.youniu then
					ratio=4
				else
					ratio=0
				end
				self.tb:banker_contend(self, ratio)
			end
			self.timer[#self.timer + 1] = act
							
	
    elseif msg_name == "BeginToBet" then
		
							
			local delay=math.random(BET_DELAY_F,BET_DELAY_C)
			act.dead_line = os.time()+delay
			act.execute = function()	
				
				local cur_bet=0	
				-- local random_num=math.random(1,100)
				-- if random_num<=40 then
				-- 	cur_bet=math.random(0,1)			
				-- elseif random_num<=70 then
				-- 	cur_bet=2
				-- elseif random_num<=85 then	
				-- 	cur_bet=3
				-- elseif random_num<=95 then	
				-- 	cur_bet=4
				-- else
				-- 	cur_bet=5
				-- end

				math.randomseed(tostring(os.time()):reverse():sub(1, 6))
				local random = math.random(1,100)
				if self.niuniu then
					if random > 20 then
						cur_bet=5
					else
						cur_bet=4
					end
				elseif self.youniu then
					if random <= 60 then
						cur_bet = 1
					elseif random <= 90 then
						cur_bet = 2
					else
						cur_bet = 3
					end
				else
					cur_bet = 1
				end

				if self.tb.b_banker.ratio==nil then
					return
				end

				if self.tb.b_player[self.guid].ratio == -1 and  cur_bet > 1 then
					log_info(" cur_bet =  "..cur_bet)
					cur_bet = 1
				end

				if self.niuniu then
					if not(self.youniu) then
						log_info(" niuniu ~= youniu ")
					end
				end

				--local bet_money=self.tb.b_bottom_bet  * 5 * self.tb.b_banker.ratio 
				local bet_money=self.tb.b_bottom_bet  * cur_bet * self.tb.b_banker.ratio 
				self.tb:banker_bet(self, bet_money)
			end
			self.timer[#self.timer + 1] = act					
	

	elseif msg_name == "ShowCards" then 
		
		local delay=math.random(SHOWCARDS_DELAY_F,SHOWCARDS_DELAY_C)
		act.dead_line = os.time() + delay
		act.execute = function()
			self.tb:banker_guess_cards(self)
		end
		self.timer[#self.timer + 1] = act			

    
    elseif msg_name == "GameOver" then 
		if (math.random(REENTER_DEN) <= REENTER_NUM) then 
	
			local delay = math.random(REENTER_DELAY_F,REENTER_DELAY_C)
			act.dead_line = os.time() + delay
			act.execute = function()	
				if self.tb:has_real_player() then
					self.tb:check_reEnter(self, self.chair_id)

				end
			end
			self.timer[#self.timer + 1] = act	
			
		else	
		
			self:forced_exit()
		
		end
		
	end	
	
end



function zjnn_robot:tick()
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



return zjnn_robot
