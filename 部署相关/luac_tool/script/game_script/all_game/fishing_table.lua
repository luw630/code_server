require "game_script/virtual/virtual_table"
require "game_script/virtual/virtual_player"
require "game_script/virtual/virtual_room"
require "extern/lib/lib_functions"
require "catchfish"

local ly_robot_storage_param = {}
fishing_table = class("fishing_table",virtual_table)
function fishing_table:ctor( ... )
	self.cpp_table = FishingTable()
end

function fishing_table:init(room, table_id, chair_count)
	fishing_table.super.init(self,room, table_id, chair_count)
	self.cpp_table:Initialization(self)
end

function fishing_table:on_fish_dead(fish_id)
    for i,v in pairs(self.player_list_) do
        if v and v.is_android then
            v:on_fish_dead(fish_id)
        end
    end
end

function fishing_table:check_cancel_ready(player, is_offline)
	fishing_table.super.check_cancel_ready(self,player,is_offline)
	player:setStatus(is_offline)
	return true
end

function fishing_table:load_lua_cfg()
	local funtemp = load(self.room_.lua_cfg_)
	ly_robot_storage_param = funtemp()
	ly_robot_storage_param.room_tax = self.room_:get_room_tax()
end

function fishing_table:isPlay( ... )
	return false
end

function fishing_table:player_sit_down(player, chair_id_)
	fishing_table.super.player_sit_down(self,player,chair_id_)
	if self:get_player_count() == 1 then
		self.cpp_table:OnEventGameStart()
	end
	self.cpp_table:OnActionUserSitDown(chair_id_,player)
end

function virtual_table:player_sit_down_finished(player)
	self.cpp_table:OnEventSendGameScene(player,100,false)
end


function fishing_table:player_stand_up(player, is_offline)
	--fishing_table.super.player_stand_up(self,player,is_offline)
	self.cpp_table:OnActionUserStandUp(player,is_offline)
	local ret = fishing_table.super.player_stand_up(self,player,is_offline)
	if self:get_player_count() == 0 then
		self.cpp_table:OnEventGameConclude(player,0)
	end
	return ret
end

function fishing_table:ready(player)
	fishing_table.super.ready(self,player)
	self.cpp_table:OnReady(player.chair_id)
end

function fishing_table:playeroffline(player)
	fishing_table.super.playeroffline(self,player)
end

function fishing_table:reconnect(player)
end

function fishing_table:tick()
	self.cpp_table:OnGameUpdate()
	--if g_Use_Robot then

	--end
	-- for _,v in ipairs(self.player_list_) do		
	-- 	if v and v.is_android then
	-- 		v:tick()
	-- 	end
	-- end
end


math.randomseed(os.time())
last_save_time = os.clock()
last_print_time = os.clock()
last_revenue = 0

local state_chi = true
local check_ratiotime = os.time()
local state_tu = 0
function calc_storage_probability_ratio(storage,fish_multi,revenue,guid)

    local now = os.clock()
	if now - last_save_time > 10 then
        last_save_time = now
        ly_robot_storage = storage
        post_msg_to_mysql_pb("SD_Save_Storage", {
			game_id = def_game_id,
			storage = ly_robot_storage
		})
		
		local tax_add_in = revenue - last_revenue
		last_revenue = revenue
		if tax_add_in > 0 then
			post_msg_to_mysql_pb("SD_UpdateGameTotalTax", {
				game_id = def_game_id,
				first_game_type = def_first_game_type,
				second_game_type = def_second_game_type,
				tax_add = tax_add_in
			})

			--guid, phone_type,money, ip, s_type,s_old_money,s_tax,s_change_money,s_id,channel_id   做假数据，方便统计
			virtual_table:user_log_money_user_nil(1, "system_fish",0, "system_fish", 2,0,tax_add_in,0,"system_fish","system_fish")
		end
    end
    
    local ratio = 0
    if state_chi then
        if storage > ly_robot_storage_param.tu_line then
            state_chi = false
        end
		ratio =  math.random(6000,8000) / 10000
		if storage < ly_robot_storage_param.chi_line then
			if storage > ly_robot_storage_param.chi_line/4*3 then
				ratio = ratio * 0.85
			elseif storage > ly_robot_storage_param.chi_line/4*2 then
				ratio = ratio * 0.80
			elseif storage > ly_robot_storage_param.chi_line/4*1 then
				ratio = ratio * 0.75
			elseif storage > 0 then
				ratio = ratio * 0.75
			elseif storage > -ly_robot_storage_param.chi_line/4*1 then	
				ratio = ratio * 0.75
			elseif storage > -ly_robot_storage_param.chi_line/4*2 then	
				ratio = ratio * 0.75
			elseif storage > -ly_robot_storage_param.chi_line then	
				ratio = ratio * 0.65
			elseif storage > -ly_robot_storage_param.chi_line*2 then	
				ratio = ratio * 0.55
			elseif storage > -ly_robot_storage_param.chi_line*3 then	
				ratio = ratio * 0.50
			elseif storage > -ly_robot_storage_param.chi_line*4 then	
				ratio = ratio * 0.45
			elseif storage > -ly_robot_storage_param.chi_line*10 then	
				ratio = ratio * 0.20
			elseif storage > -ly_robot_storage_param.chi_line*20 then	
				ratio = ratio * 0.10
			elseif storage > -ly_robot_storage_param.chi_line*30 then	
				ratio = ratio * 0.05
			elseif storage > -ly_robot_storage_param.chi_line*40 then	
				ratio = ratio * 0.001
			else
				ratio = ratio * 0.00
			end

			local int_fish_multi = math.floor(fish_multi)
			if int_fish_multi > 100 then int_fish_multi = 100 end
			if int_fish_multi < 1 then int_fish_multi = 1 end
			local storage_danger_add_prop = 1.0
			if def_game_id == 5 or def_game_id == 6 then -- 高倍场做这个限制
				if int_fish_multi < 10 then
					storage_danger_add_prop = 1.0
				elseif int_fish_multi < 20 then
					storage_danger_add_prop = 0.8
				elseif int_fish_multi < 30 then
					storage_danger_add_prop = 0.8
				elseif int_fish_multi < 40 then
					storage_danger_add_prop = 0.7
				elseif int_fish_multi < 50 then
					storage_danger_add_prop = 0.7
				elseif int_fish_multi < 60 then
					storage_danger_add_prop = 0.7
				elseif int_fish_multi < 70 then
					storage_danger_add_prop = 0.7
				elseif int_fish_multi < 80 then
					storage_danger_add_prop = 0.7
				elseif int_fish_multi < 90 then
					storage_danger_add_prop = 0.7
				elseif int_fish_multi <= 100 then
					storage_danger_add_prop = 0.7
				end
			end
			ratio = ratio*storage_danger_add_prop
		end
    else
        if storage < ly_robot_storage_param.chi_line then
            state_chi = true
        end
		
		if def_game_id == 3 then
			ratio = 1.05
			if storage > ly_robot_storage_param.tu_line *4.0  then
				ratio = 2.0
			elseif storage > ly_robot_storage_param.tu_line *3.0  then
				ratio = 1.80
			elseif storage > ly_robot_storage_param.tu_line *2.0  then
					ratio = 1.65
			elseif storage > ly_robot_storage_param.tu_line *1.5 then
				ratio = 1.45
			elseif storage > ly_robot_storage_param.tu_line *1.3  then
				ratio = 1.35
			elseif storage > ly_robot_storage_param.tu_line  then
				ratio = 1.10
			end
		elseif def_game_id == 4 then
				ratio = 1.05
				if storage > ly_robot_storage_param.tu_line *4.0  then
					ratio = 2.0
				elseif storage > ly_robot_storage_param.tu_line *3.0  then
					ratio = 1.80
				elseif storage > ly_robot_storage_param.tu_line *2.0  then
						ratio = 1.65
				elseif storage > ly_robot_storage_param.tu_line *1.5 then
					ratio = 1.45
				elseif storage > ly_robot_storage_param.tu_line *1.3  then
					ratio = 1.25
				elseif storage > ly_robot_storage_param.tu_line  then
					ratio = 1.10
				end
		elseif def_game_id == 5 then
			ratio = 1.00
			if storage > ly_robot_storage_param.tu_line *2.0  then
				ratio = 1.20
			elseif storage > ly_robot_storage_param.tu_line *1.5 then
				ratio = 1.15
			elseif storage > ly_robot_storage_param.tu_line *1.3  then
				ratio = 1.10
			elseif storage > ly_robot_storage_param.tu_line  then
				ratio = 1.05
			end
		elseif def_game_id == 6 then
			ratio = 0.95
			if storage > ly_robot_storage_param.tu_line *2.0  then
				ratio = 1.15
			elseif storage > ly_robot_storage_param.tu_line *1.5 then
				ratio = 1.10
			elseif storage > ly_robot_storage_param.tu_line *1.3  then
				ratio = 1.05
			elseif storage > ly_robot_storage_param.tu_line  then
				ratio = 1.00
			end
		end 

		--[[
		if def_game_id == 3 or def_game_id == 4 then
			if storage > ly_robot_storage_param.tu_line*1.5  then
				if state_tu == 0 then
					state_tu = 1 
					check_ratiotime = os.time()
				end
			else
				state_tu = 2
			end
		
			if state_tu == 1 then
				if os.time() - check_ratiotime < math.random(1*60,2*60) then
					if os.time() - check_ratiotime < 15 then
						ratio = 2
					end
				else
					state_tu = 2
				end
			elseif state_tu == 2 and storage > ly_robot_storage_param.tu_line+ly_robot_storage_param.tu_line*0.1  then
				state_tu = 1 
				check_ratiotime = os.time()
			end
		end
		]]

    end

    for ii,vv in pairs(ly_black_list) do
		if vv== guid then 
			--log_info(string.format("old_ratio:%s",ratio..""))
			ratio= ratio * 0.6
			log_info(string.format("black list ratio:%s",ratio..""))
			break
		end
	end

    if os.clock() - last_print_time > 5 then
        last_print_time = os.clock()
        --log_info("storage:",storage,"probability:",ratio)
        log_info("storage: "..storage.."   probability: "..ratio)
    end
    return ratio
end

function get_revenue_ratio()
	return ly_robot_storage_param.room_tax
end
