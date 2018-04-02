local tabletool = require "extern/lib/lib_tablex"
require "game_script/all_game/hhdz_enum"


local hhdz_game = {}


function hhdz_game:new( ... )
	local o = {}  
    setmetatable(o, {__index = self})
    return o 
end

function hhdz_game:init( ... )
	self.cards = {}
	self.allcards = {}
	self.cheatmode = 0
	self.playercount = 0
	for i = 1, 52 do
		self.cards[i] = i
	end

end

function hhdz_game:initialization()
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	self.cheatmode = 0
	--洗牌
	for i = 1,#self.cards do
        local ranOne = win_random_int(1,#self.cards+1-i)
        self.cards[ranOne], self.cards[#self.cards+1-i] = self.cards[#self.cards+1-i],self.cards[ranOne]
    end

end


function hhdz_game:postcards( index)
	local postcards = {}
	local cardindex = (index-1)*3+1
	for i=cardindex,cardindex+2 do
		table.insert(postcards,self.cards[i])
	end
	-- if index == 1 then
	-- 	postcards = {5,18,6}
	-- elseif index == 2 then
	-- 	postcards = {4,17,9}
	-- end

	return postcards
end

function hhdz_game:generatecards()
	for i = 1, 2 do
		self.allcards[i] = {}
		self.allcards[i] = self:postcards(i)
	end
	self.playercount = 2
	
	
	--log_info("cheatmode "..self.cheatmode )

end

function hhdz_game:getsum(cards_1 )
	if (cards_1[1] - 1)%13 == 1 then
		return (cards_1[1] - 1)%13 + (cards_1[2] - 1)%13 + (cards_1[3] - 1)%13 + 13
	end
	return (cards_1[1] - 1)%13 + (cards_1[2] - 1)%13 + (cards_1[3] - 1)%13
end

--牌类型
-- HONGHEITYPE = {
-- 	HONGHEI_NULL = 1, --占位对应投注类型
-- 	HONGHEI_GAOPAI = 2, --高牌
-- 	HONGHEI_DUIZI = 3, --对子
-- 	HONGHEI_SHUNZI = 4, --顺子
-- 	HONGHEI_JINHUA = 5, --金花
-- 	HONGHEI_SHUNJIN = 6, --顺金
-- 	HONGHEI_BAOZI = 7, --豹子
-- }

--牌花色
-- CARDCOLOR={
-- 	COLOR_DIAMOND 	= 1,	--方块
-- 	COLOR_CLUB 		= 2,	--梅花
-- 	COLOR_HEARTS 	= 3,	--红桃
-- 	COLOR_SPADES 	= 4,	--黑桃
-- }

function hhdz_game:compare(cards_1,cards_2,guid_1,guid_2 )

	local ptype_1,psum_1 = self:cardtype(self.allcards[1])
	local ptype_2,psum_2 = self:cardtype(self.allcards[2])

	if ptype_1 > ptype_2 then
		return true,ptype_1,ptype_2
	elseif ptype_1 == ptype_2 then
		if ptype_1 == HONGHEITYPE.HONGHEI_BAOZI  then
			return psum_1 > psum_2,ptype_1,ptype_2
		elseif ptype_1 == HONGHEITYPE.HONGHEI_DUIZI then
			if (psum_1 - 1)%13 == 1 then
				psum_1 = psum_1 + 13
			end
			
			if (psum_2 - 1)%13 == 1 then
				psum_2 = psum_2 + 13
			end

			if psum_1 > psum_2 then
				return true,ptype_1,ptype_2
			elseif psum_1 < psum_2 then
				return false,ptype_1,ptype_2
			else
				return self:getsum(self.allcards[1]) > self:getsum(self.allcards[2]),ptype_1,ptype_2
			end
		else
			if self:getsum(self.allcards[1]) > self:getsum(self.allcards[2]) then
				return true,ptype_1,ptype_2
			elseif  self:getsum(self.allcards[1]) < self:getsum(self.allcards[2]) then
				return false,ptype_1,ptype_2
			else
				return (self.allcards[1][3] - 1)/13 > (self.allcards[2][3] - 1)/13,ptype_1,ptype_2
			end
		end
	end
	return false,ptype_1,ptype_2

end

function hhdz_game:getcard( type)
	return self.allcards[type] or nil
end

--牌类型
-- HONGHEITYPE = {
-- 	HONGHEI_NULL = 1, --占位对应投注类型
-- 	HONGHEI_GAOPAI = 2, --高牌
-- 	HONGHEI_DUIZI = 3, --对子
-- 	HONGHEI_SHUNZI = 4, --顺子
-- 	HONGHEI_JINHUA = 5, --金花
-- 	HONGHEI_SHUNJIN = 6, --顺金
-- 	HONGHEI_BAOZI = 7, --豹子
-- }


function hhdz_game:getcardsnum( tablecard )
	if tablecard == nil then
		return 0
	end
	local x = 0
	for k,v in pairs(tablecard) do
		x = x + 1
	end
	return x
end 

function hhdz_game:cardtype( cards ) -- 三公牌型,点数，花色
	table.sort(cards,function(a1,a2)return a1<a2 end)
	if (cards[1] - 1)%13 == (cards[2] - 1)%13 == (cards[3] - 1)%13 then --豹子
		return HONGHEITYPE.HONGHEI_BAOZI,cards[1]
	elseif (cards[1] - 1)/13 == (cards[2] - 1)/13 == (cards[3] - 1)/13 then  --同花
		if (cards[1] - 1)%13 == (cards[2] - 1)%13-1 == (cards[3] - 1)%13-2 then --顺子
			return HONGHEITYPE.HONGHEI_SHUNJIN   --顺金
		end

		if  (cards[2] - 1)%13 == (cards[3] - 1)%13-1 == (cards[1] - 1)%13-2+13 then --顺子 QKA
			return HONGHEITYPE.HONGHEI_SHUNJIN   --顺金
		end

		 return HONGHEITYPE.HONGHEI_JINHUA   --金花
	elseif (cards[1] - 1)%13 == (cards[2] - 1)%13-1 == (cards[3] - 1)%13-2 then --顺子
		return HONGHEITYPE.HONGHEI_SHUNZI
	elseif (cards[2] - 1)%13 == (cards[3] - 1)%13-1 == (cards[1] - 1)%13-2+13 then --顺子 QKA
		return HONGHEITYPE.HONGHEI_SHUNZI
	elseif (cards[1] - 1)%13 == (cards[2] - 1)%13 or  (cards[2] - 1)%13 == (cards[3] - 1)%13  then --对子
		return HONGHEITYPE.HONGHEI_DUIZI,cards[2] 
	else
		return HONGHEITYPE.HONGHEI_GAOPAI
	end	
end



return hhdz_game