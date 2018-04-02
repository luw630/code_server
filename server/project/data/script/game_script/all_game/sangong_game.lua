local tabletool = require "extern/lib/lib_tablex"
require "game_script/all_game/sangong_enum"

local sangong_game = {}


function sangong_game:new( ... )
	local o = {}  
    setmetatable(o, {__index = self})
    return o 
end

function sangong_game:init( ... )
	self.cards = {}
	self.allcards = {}
	self.cheatmode = 0
	self.playercount = 0
end

function sangong_game:initialization()
	self.cheatmode = 0
	for i = 1, 52 do
		self.cards[i] = i
	end
	--洗牌
	for i = 1,#self.cards do
        local ranOne = win_random_int(1,#self.cards+1-i)
        self.cards[ranOne], self.cards[#self.cards+1-i] = self.cards[#self.cards+1-i],self.cards[ranOne]
    end

end


function sangong_game:postcards( index)
	local postcards = {}
	local cardindex = (index-1)*3+1
	for i=cardindex,cardindex+2 do
		table.insert(postcards,self.cards[i])
	end
	return postcards
end

function sangong_game:generatecards(tb )
	local count = tb.player_count
	for i = 1, count do
		self.allcards[i] = {}
		self.allcards[i] = self:postcards(i)
	end
	self.playercount = count
	
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	if ly_use_robot then
		if ly_robot_storage < 0 or (ly_robot_smart_lv > 0 and (math.random(1,100) <= ly_robot_smart_lv)) then
			self.cheatmode = 1
		elseif ly_robot_storage > 0 and ly_robot_smart_lv < 0 then
			if (ly_robot_storage > tb.bet_base[1]*50) and (math.random(1,100) < 40) then
				self.cheatmode = 2
			end
		end
	end

	if self.cheatmode > 0 then
		for i=1,count-1 do
			for j=i+1,count do
				if not(self:compare(self.allcards[i],self.allcards[j])) then
					self.allcards[i],self.allcards[j] = self.allcards[j],self.allcards[i]
				end
			end
		end	
	end

	
	--log_info("cheatmode "..self.cheatmode )

end

function sangong_game:getcards(is_android,guid,pcards )
	
	local removepos = 1


	if self.playercount <= 0 then
		log_info("playercount == "..self.playercount)
	end

	if self.cheatmode == 1 then
		if not(is_android) then
			removepos = #self.allcards
		end
	elseif self.cheatmode == 2 then
		if is_android then
			removepos = #self.allcards
		end
	end
	pcards = tabletool.copy(self.allcards[removepos])
	table.remove(self.allcards,removepos)
	self.playercount = self.playercount  - 1

	--log_info(" guid = "..guid.." getcards")
	return pcards
end



function sangong_game:compare(cards_1,cards_2,guid_1,guid_2 )
	if self:getcardsnum(cards_1) == 0 or self:getcardsnum(cards_1) ~= 3  then
		log_error("cards_1 error guid = "..guid_1)
		return 
	end

	if self:getcardsnum(cards_2) == 0 or self:getcardsnum(cards_2) ~= 3  then
		log_error("cards_2 error guid = "..guid_2)
		return 
	end

	local ptype_1,psum_1 = self:sangongtype(cards_1)
	local ptype_2,psum_2 = self:sangongtype(cards_2)

	if ptype_1 > ptype_2 then
		return true,ptype_1,psum_1
	elseif ptype_1 == ptype_2 then
		if ptype_1 == CardType.SANGONG_DA or ptype_1 == CardType.SANGONG_XIAO then
			return psum_1 > psum_2,ptype_1,psum_1
		else
			if psum_1 > psum_2 then
				return true,ptype_1,psum_1
			elseif psum_1 == psum_2 then
				if ptype_1 == CardType.SANGONG_HUN then
					local _,color_1 = self:getbigcolor(cards_1)
					local _,color_2 = self:getbigcolor(cards_2)
					return color_1 > color_2,ptype_1,psum_1
				else
					local big_1,color_1 = self:getbigcolor(cards_1)
					local big_2,color_2 = self:getbigcolor(cards_2)
					if big_1 > big_2 then
						return true,ptype_1,psum_1
					elseif big_1 == big_2 then
						return color_1 > color_2,ptype_1,psum_1
					end
				end

			end
		end
	end
	return false,ptype_2,psum_2

end

function sangong_game:getbigcolor( cards ) --获取最大的牌和花色
	local big = (cards[1] - 1)%13
	local color = (cards[1] - 1)/13
	for i=2,3 do
		if big < (cards[i] - 1)%13 then
			big = (cards[i] - 1)%13
			color = (cards[i] - 1)/13
		end
	end
	return big+1,color+1
end

-- CardType = {
-- 	SANGONG_DI = 1,		--低点牌 0-7 点
-- 	SANGONG_GAO = 2,	--高点牌 8，9点
-- 	SANGONG_HUN = 3,	--混三公
-- 	SANGONG_XIAO = 4,	--小三公
-- 	SANGONG_DA = 5,		--大三公
-- }

-- CardColor={
-- 	COLOR_DIAMOND 	= 1,	--方块
-- 	COLOR_CLUB 		= 2,	--梅花
-- 	COLOR_HEARTS 	= 3,	--红桃
-- 	COLOR_SPADES 	= 4,	--黑桃
-- }

function sangong_game:getcardsnum( tablecard )
	if tablecard == nil then
		return 0
	end
	local x = 0
	for k,v in pairs(tablecard) do
		x = x + 1
	end
	return x
end 

function sangong_game:sangongtype( cards ) -- 三公牌型,点数，花色
	if (cards[1] - 1)%13 == (cards[2] - 1)%13 == (cards[3] - 1)%13 then
		if cards[1] == 11 or cards[1] == 12 or cards[1] == 13 then
			return CardType.SANGONG_DA,cards[1]
		else
			return CardType.SANGONG_XIAO,cards[1]
		end
	elseif (cards[1] - 1)%13 > 9 and (cards[2] - 1)%13 > 9 and (cards[3] - 1)%13 > 9 then  --点数最大的
		local big = (cards[1] - 1)%13
		for i=2,3 do
			if big < (cards[i] - 1)%13 then
				big = (cards[i] - 1)%13
			end
		end
		return CardType.SANGONG_HUN,big+1
	end

	local sum = 0
	for i=1,3 do
		local pokervalue = ((cards[i] -1)%13) + 1
		if pokervalue < 10  then
			sum = sum + pokervalue
		end	
	end
	--log_info("sangongtype sum = "..sum)
	sum = sum%10
	if sum > 7 then
		return CardType.SANGONG_GAO,sum
	else
		return CardType.SANGONG_DI,sum
	end
	
end



function sangong_game:sangongpoint(cardtype,cardnum ) --牌型对应的分数
	if cardtype == nil then
		cardtype = CardType.SANGONG_DI
	end
	local point = cardtype*2 -1
	if cardtype == CardType.SANGONG_DI and cardnum == 7 then
		point = point + 1
	elseif cardtype == CardType.SANGONG_GAO  and cardnum == 9 then
		point = point + 1
	end
	return point
end


return sangong_game