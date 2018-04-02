require "game_script/virtual/virtual_player"
local pb = require "extern/lib/lib_pb"
local zjh_robot = {}
setmetatable(zjh_robot, {__index = virtual_player})

function ly_robot_mgr.check_table(tb)
    local ZHAJINHUA_STATUS_FREE = 1
    local ZHAJINHUA_STATUS_READY =  2
    if def_second_game_type ~= 99  then
        local p_count = tb:get_player_count() 
        if tb.robot_count == nil then
        	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
        	tb.robot_count = math.random(2,3)
        	if tb.random_addtime == nil then
        		tb.random_addtime = 0
        	end
        end

        if  p_count < tb.robot_count + 1 and tb:get_real_player_count() == 1 then --and tb:has_real_player()
            if math.random(ly_add_robot_random_time+tb.random_addtime) == 1 then
				math.randomseed(tostring(os.time()):reverse():sub(1, 6))
				tb.random_addtime = math.random(50,100)

                --local robotnum_once = math.random(1,tb.robot_count+1-p_count)
                for i=1,tb.robot_count  do
					 local player = zjh_robot.new()
				
				local chair_id_list = {}
                for k,v in pairs(tb.player_list_) do
                    if not v then
						chair_id_list[#chair_id_list + 1] = k
                    end
				end
				player.chair_id = chair_id_list[math.random(#chair_id_list)]
				
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
                player.pb_base_info = {money = 20*100 + math.random(100,Rich_tag)*tb.cell_score_,header_icon = math.random(1,10),level=math.random(1,30)}
                player.callnum =0           
                player.maxcard_sign =false    
                player.mincard_sign =false     
                player.pattern = 1          
                player.pattern_sign =10     
                player.is_win_money = false  
                player.is_giveup= false 
				tb:player_sit_down(player, player.chair_id)
				
              
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
                tb:ready(player)

                end 
            end
        elseif p_count > 0 and (not tb:has_real_player()) then
            for i,v in ipairs(tb.player_list_) do
                if v and v.is_android and not(tb:isPlay()) then
                    v:forced_exit()
                end
            end
            if tb:get_player_count() == 0 and tb.robot_count ~= nil then
            	tb.robot_count = nil
            	tb.random_addtime = math.random(50,150)
            end
          
        end
    end
end
function zjh_robot:forced_exit()
	for k,v in pairs(self.timer) do
		v.delete = true
    end
	virtual_player.forced_exit(self)
    ly_robot_mgr.robot_list[self.guid] = false
    self:del()
end
function zjh_robot:forced_exit_delay()
    local act = {}
    act.dead_line = os.time() + math.random(6,8)
    act.execute = function()
        self:forced_exit()
    end
    self.timer[#self.timer + 1] = act
end

function zjh_robot.new()
	local o = {}
    setmetatable(o, {__index = zjh_robot})
    o.timer = {}
    return o 
end
function zjh_robot:getcard_type(player)
	return self.tb.player_cards_type_[player.chair_id].cards_type
end 
function zjh_robot:changecallnum() 
    local card_type = self.tb.player_cards_type_[self.chair_id].cards_type
	if ((card_type == 0) or (card_type == 1) or (card_type == 2) ) then 
        self.callnum =1
    elseif (card_type == 3) then 
         self.callnum =2
    elseif (card_type == 4) then 
         self.callnum =3
    elseif (card_type == 5) then 
        self.callnum =5
    elseif (card_type == 6) then 
        self.callnum =10
    elseif (card_type == 7) then 
        self.callnum =18
    end       	
end
function  zjh_robot:if_maxcard()
             local curbj = true   
        for i,v in ipairs(self.tb.player_list_) do   -- 看看最大牌 是否是自己手上 
				if v and  (not self.tb.is_dead_[i]) and v.chair_id ~= self.chair_id and  not self.tb:compare_cards(self.tb.player_cards_type_[self.chair_id], self.tb.player_cards_type_[i]) then
					 curbj =false   
					 break 
				end         
        end	
		if  curbj then 
			self.maxcard_sign =true 
		else	
			self.maxcard_sign = false
		end 
 end 
 function  zjh_robot:if_mincard() --
       
         for i,v in pairs(self.tb.player_list_) do    --判断最大牌是不是在 真人手上 是的话就直接跳出函数
            if v and (not self.tb.is_dead_[i])  and (not v.is_android )then    
                 local curbj =true 
                 for ii,vv in pairs(self.tb.player_list_) do
                    if vv and (not self.tb.is_dead_[ii]) and vv.is_android then 
                        if not self.tb:compare_cards(self.tb.player_cards_type_[i], self.tb.player_cards_type_[ii]) then
                             curbj =false 
                             break 
                        end
                    end 
                 end  
                 if  curbj  then 
                    self.mincard_sign  = true 
                    return
                 end   
            end     
        end	
        self.mincard_sign  = true 
        for i,v in pairs(self.tb.player_list_) do  -- 如果最大牌没在真人手上 那么比真人牌大的电脑做处理 小的不改变
            if v and (not self.tb.is_dead_[i])  and (not v.is_android )then
                if not self.tb:compare_cards(self.tb.player_cards_type_[i], self.tb.player_cards_type_[self.chair_id]) then
                            self.mincard_sign  = false 
                            return 
                end
            end 
        end
 end 
function  zjh_robot:give_up_check () -- 弃牌检测
	local live_count = 0
	local chair_id_not_self = 1
	for k,v in pairs(self.tb.ready_list_) do
		if v and (not self.tb.is_dead_[k]) then
			live_count = live_count + 1
			if k ~= self.chair_id then chair_id_not_self = k end
		end
	end
	local rich_mode = false
	if (ly_robot_smart_lv < 0) and (ly_robot_storage > self.tb.cell_score_*100) and math.random(1,100) < 40 then 
		rich_mode = true
	end
	local r_n = math.random(1,100)

	if self.maxcard_sign then --如果是最大牌不弃牌
		if self.tb.ball_begin and rich_mode then
			self.tb:give_up(self)
		elseif live_count == 2 then
			if r_n < 50 then
				self.tb:add_score(self,self:add_score_multiple())
			else
				local cardtype,cnum = self.tb:get_cards_type(self.tb.player_cards_[self.chair_id])
				if cardtype == pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SINGLE") then
					if cnum > 11 then
						self.tb:compare_card(self,chair_id_not_self)
					else
						self.tb:give_up(self)
					end
					return
				end
				self.tb:compare_card(self,chair_id_not_self)
			end
		else
			self.tb:add_score(self,self:add_score_multiple())
		end
	else
		if live_count == 2 and (r_n < 40) then
			if self.tb.ball_begin then
				if rich_mode then
					--self.tb:compare_card(self,chair_id_not_self)
					self.tb:give_up(self)
				else
					self.tb:give_up(self)
				end
			else
				local cardtype,cnum = self.tb:get_cards_type(self.tb.player_cards_[self.chair_id])
				if cardtype == pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SINGLE") then
					if cnum > 11 then
						self.tb:compare_card(self,chair_id_not_self)
					else
						self.tb:give_up(self)
					end
					return
				end
				self.tb:compare_card(self,chair_id_not_self)
			end
		elseif live_count == 2 and (r_n < 50) then
			if self.tb.last_score == self.tb.cell_score_ then
				--log_error("hehe............01")
				self.tb:add_score(self,self:add_score_multiple())
			else 
				--log_error("gg............01")
				self.tb:give_up(self) 
			end 
		elseif live_count == 2 and (r_n <= 100) then
			self.tb:give_up(self)
		else
			if rich_mode then 
				if self.tb.last_score == self.tb.cell_score_ then
					--log_error("hehe............02")
					self.tb:add_score(self,self:add_score_multiple())
				else 
					--log_error("gg............02")
					self.tb:give_up(self) 
				end 
			else
				self.tb:give_up(self)
			end
		end		
	end		
end 

function  zjh_robot:add_score_multiple (flag)
	self.callnum = self.callnum -1
	if flag then 
		if flag == 1 then 
			return self.tb.cell_score_*10
		else
			local dizhu= self.tb.last_score / self.tb.cell_score_
			if  dizhu == 1	then
				return 	self.tb.cell_score_ *2
			elseif dizhu ==2   then 
				return 	self.tb.cell_score_ *5
			elseif dizhu ==5   then 
				return 	self.tb.cell_score_ *8
			elseif dizhu ==8   then 
				return 	self.tb.cell_score_ *10
			else  
				return self.tb.last_score
			end
		end
		
	else
        return  self.tb.last_score
	end 

end 
function zjh_robot:game_msg(msg_name, msg) 
    if "SC_ZhaJinHuaStart" == msg_name then
		--if not self.tb.storage_callnum  then -- 没有开启库存控制机器人赢钱的时候
			--self.callnum = math.random(3,4)   --  机器人自己一般都要下注的基本次數 
		--else 
		self.callnum = math.random(3,5) 
		self:if_maxcard() --判断自己是否为最大牌
		--end 
        			
		local act = {}
        act.dead_line = os.time() + math.random(3,5)
			act.execute = function() 
             --库存控制--1
            --[[if  ly_robot_stores_mode then 
                        if ly_use_robot then
                            if ly_robot_storage < 0 or (ly_robot_smart_lv > 0 and (math.random(1,100) <= ly_robot_smart_lv)) then   -- 机器人输钱了 要赢钱回来
                                self.pattern = 2
                                self.pattern_sign = math.random(1,3)
                            elseif ly_robot_storage > 0 and ly_robot_smart_lv <0 then             -- 机器人赢钱了        要输钱出去 
                                self.pattern = 3   
                                self.pattern_sign = math.random(1,3)    
                            end
                        end
			end--]]
                        
                    if(msg.banker_chair_id == self.chair_id )then
                        self.tb:add_score(self, self.tb.last_score)
                        self.callnum = self.callnum -1 
					end	
            end 
         
        self.timer[#self.timer + 1] = act  
    elseif msg_name == "SC_ZhaJinHuaAddScore" then   -- 用户加注 
            local act = {}
			local delay = math.random(1,2)
			if  msg.is_all == 2 then  
				delay = math.random(2,3)
			end
			act.dead_line = os.time() + delay
			act.execute = function() 
				if self.chair_id == msg.cur_chair_id  and not self.tb.is_dead_[self.chair_id] then  
					if self.tb.Round >1 then 
						if self.callnum < 0 then
							self.callnum =0
						end 	
						if self.callnum == 0 and  msg.is_all ~= 2 then  --下注次数到了比牌
								if not self.tb.is_look_card_[self.chair_id] then 
									--log_info("111111111111")
									self.tb:look_card(self)
								else
									for i,v in ipairs(self.tb.player_list_) do
										if v and (not self.tb.is_dead_[v.chair_id]) and (i ~= self.chair_id) then
											local cardtype,cnum = self.tb:get_cards_type(self.tb.player_cards_[self.chair_id])
											if cardtype == pb.get_ev("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SINGLE") then
												if cnum > 11 then
													self.tb:compare_card(self,v.chair_id,false,1)
												else
													self.tb:give_up(self)
												end
												self.callnum = self.callnum -1 
												return
											end
											self.tb:compare_card(self,v.chair_id,false,1)
											self.callnum = self.callnum -1 
											return 
									end 
								end 
								
							end	
						end
						if self.tb.Round >3 and not self.maxcard_sign and self.tb.player_cards_type_[self.chair_id].cards_type <3then  -- 机器人牌小不能跟注太多回合
								if  not self.tb.is_look_card_[self.chair_id] then
									--log_info("22222222222")
									self.tb:look_card(self)
								else
									self:give_up_check()
								end 
								self.is_giveup = true
								return 
						end
						if msg.is_all == 2 then  --如果上家全压
							-- 如果 机器人是牌最大
							if self.tb:compare_cards(self.tb.player_cards_type_[self.chair_id], self.tb.player_cards_type_[msg.add_score_chair_id]) then			
										self.tb:add_score(self, 1)							
							else
										self:give_up_check()
							end					   
						else   
							if  self.tb.is_look_card_[self.chair_id] then   --机器人看牌了的话
									self.tb:add_score(self, self:add_score_multiple())
							else
								if self.tb.is_look_card_[msg.add_score_chair_id] then --如果加注玩家看牌了
									local d=math.random(1,10)
									if self.maxcard_sign   then  -- 机器人是最大牌就50几率看牌 50 几率不看
										if d<4 then 
											--log_info("3333333333")
											self.tb:look_card(self)
											return
										else
											local a =math.random(1,20)
											if a==1 then 
												self.tb:add_score(self,self:add_score_multiple(1))
											elseif a < 13 then 
												self.tb:add_score(self,self:add_score_multiple(true))
											else 
												self.tb:add_score(self,self:add_score_multiple())
											end 
										end
									else  -- 不是最大牌 70 看牌 30不看牌
										if d<4 then 
											--log_info("4444444444")
											self.tb:look_card(self)
											return
										else 
											local a =math.random(1,20)
											if a==1 then 
												self.tb:add_score(self,self:add_score_multiple(true))
											elseif a < 7 then 
												self.tb:add_score(self,self:add_score_multiple())
											else 
												--log_info("5555555555555555")
												self.tb:look_card(self)
												self.is_giveup = true
												return
											end
										end
									end 
								else
									local d=math.random(1,10)
									if self.maxcard_sign   then 
										if d<3 then 
											--log_info("66666666666666")
											self.tb:look_card(self)
											return
										else
											local a =math.random(1,20)
											if a==1 then 
												self.tb:add_score(self,self:add_score_multiple(1))
											elseif a < 13 then 
												self.tb:add_score(self,self:add_score_multiple(true))
											else 
												self.tb:add_score(self,self:add_score_multiple())
											end 
										end
									else
										if d<3 then 
											--log_info("7777777777")
											self.tb:look_card(self)
											return
										else 
											local a =math.random(1,20)
											if a==1 then 
												self.tb:add_score(self,self:add_score_multiple(true))
											elseif a < 7 then 
												self.tb:add_score(self,self:add_score_multiple())
											else 
												--log_info("888888888888888888")
												self.tb:look_card(self)
												self.is_giveup = true
												return
											end
										end
									end 	
								end                             
							end                  
						end 
					else 
						self.tb:add_score(self,self:add_score_multiple())
					end 
				end
			end                              
			self.timer[#self.timer + 1] = act
    elseif msg_name == "SC_ZhaJinHuaGiveUp" then -- 放弃跟注
            local act = {}
			act.dead_line = os.time() + math.random(1,2)
			act.execute = function()
				if self.tb.player_count_ -self.tb.dead_count_ <=1 then 
					return 
				end
              if msg.giveup_chair_id ~=self.chair_id and  self.chair_id == msg.cur_chair_id  and not self.tb.is_dead_[self.chair_id]   then 
					if  self.tb.Round > 1 then 
						if self.tb.is_look_card_[self.chair_id] then  
							self.tb:add_score(self, self:add_score_multiple())		
						else
							local d=math.random(1,10)
							if self.maxcard_sign   then 
								if d<3 then 
									--log_info("99999999999999999999")
									self.tb:look_card(self)
									return 
								else
									local a =math.random(1,20)
									if a==1 then 
										self.tb:add_score(self,self:add_score_multiple(1))
									elseif a < 7 then 
										self.tb:add_score(self,self:add_score_multiple(true))
									else 
										self.tb:add_score(self,self:add_score_multiple())
									end 
								end
							else
								if d<3 then 
									--log_info("aaaaaaaaaaaaaaaaaa")
									self.tb:look_card(self)
									return
								else 
									local a =math.random(1,20)
									if a==1 then 
										self.tb:add_score(self,self:add_score_multiple(true))
									elseif a < 7 then 
										self.tb:add_score(self,self:add_score_multiple())
									else 
										--log_info("bbbbbbbbbbbbbbbbbbb")
										self.tb:look_card(self)
										self.is_giveup = true
										return
									end
								end
							end 
						end 
					else 
						self.tb:add_score(self,self:add_score_multiple())
					end 
                end
            end
            self.timer[#self.timer + 1] = act     
    elseif msg_name == "SC_ZhaJinHuaLookCard" then -- 看牌
            local act = {}
			act.dead_line = os.time() + 1
			act.execute = function()
				if self.tb.player_count_ -self.tb.dead_count_ <=1 then 
					return 
				end
			    if msg.lookcard_chair_id ==self.chair_id and not self.tb.is_dead_[self.chair_id]  then 
					self:changecallnum()
					
					if  self.is_win_money or self.maxcard_sign then --必赢或者最大牌
						local a =math.random(1,20)
						if a==1 then 
							self.tb:add_score(self,self:add_score_multiple(1))
						elseif a < 13 then 
							self.tb:add_score(self,self:add_score_multiple(true))
						else 
							self.tb:add_score(self,self:add_score_multiple(2))
						end 
					elseif self.is_giveup  then  --放弃
						self:give_up_check()
					else
						local a =math.random(1,20)
						if a==1 then 
							self.tb:add_score(self,self:add_score_multiple(true))
						elseif a < 7 then 
							self.tb:add_score(self,self:add_score_multiple())
						else 
							self:give_up_check()
						end
					end
			    end 
            end 
			self.timer[#self.timer + 1] = act
    elseif msg_name == "SC_ZhaJinHuaCompareCard" then -- 比牌
           local delay = math.random(5,6)
             local act = {}
			act.dead_line = os.time() + delay
			act.execute = function()
				if self.tb.player_count_ -self.tb.dead_count_ <=1 then 
					return 
				end 
                if msg.cur_chair_id == self.chair_id and not  self.tb.is_dead_[self.chair_id] then
                    if msg.win_chair_id == self.chair_id then 
							self.tb:add_score(self,self:add_score_multiple())  
                    elseif(msg.win_chair_id ~= self.chair_id and msg.lost_chair_id ~= self.chair_id)  then 
                            if (not self.tb.is_look_card_[msg.win_chair_id]) and  (not self.tb.is_look_card_[msg.lost_chair_id]) then 
                                         self.tb:add_score(self, self:add_score_multiple())             
                            else
                                    if not self.tb.is_look_card_[self.chair_id] then 
												local d=math.random(1,10)
												if self.maxcard_sign   then 
													if d<3 then 
														--log_info("ccccccccccccccccccccccccc")
														self.tb:look_card(self)
														return
													else
														local a =math.random(1,20)
														if a==1 then 
															self.tb:add_score(self,self:add_score_multiple(1))
														elseif a < 7 then 
															self.tb:add_score(self,self:add_score_multiple(true))
														else 
															self.tb:add_score(self,self:add_score_multiple())
														end 
													end
												else
													if d<3 then 
														--log_info("dddddddddddddddddddddddddddd")
														self.tb:look_card(self)
														return
													else 
														local a =math.random(1,20)
														if a==1 then 
															self.tb:add_score(self,self:add_score_multiple(true))
														elseif a < 7 then 
															self.tb:add_score(self,self:add_score_multiple())
														else 
															--log_info("eeeeeeeeeeeeeeeeeeeeeeeeee")
															self.tb:look_card(self)
															self.is_giveup = true
															return
														end
													end
												end 

                                    else 
                                         self.tb:add_score(self, self:add_score_multiple())
                                    end 

                            end 
                    end 
               
                                
                end 
            end
			self.timer[#self.timer + 1] = act        
    elseif msg_name == "SC_ZhaJinHuaEnd" then -- 游戏结束
        local act = {}
		act.dead_line = os.time() + math.random(9,12)
		act.execute = function()
			self.tb:ready(self)
		end
		self.timer[#self.timer + 1] = act
    end

end
function zjh_robot:tick()
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

return zjh_robot