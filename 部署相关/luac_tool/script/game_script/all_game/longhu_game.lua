local tabletool = require "extern/lib/lib_tablex"
require "game_script/all_game/longhu_enum"


local longhu_game = {}


function longhu_game:new( ... )
	local o = {}  
    setmetatable(o, {__index = self})
    return o 
end

function longhu_game:init( ... )
	self.cards = {}
	self.allcards = {}
	self.cheatmode = 0
	self.playercount = 0
	for i = 1, 52 do
		self.cards[i] = i
	end

end

function longhu_game:initialization()
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	self.cheatmode = 0
	--洗牌
	for i = 1,#self.cards do
        local ranOne = win_random_int(1,#self.cards+1-i)
        self.cards[ranOne], self.cards[#self.cards+1-i] = self.cards[#self.cards+1-i],self.cards[ranOne]
    end

end


function longhu_game:postcards( index)
	local postcards = {}
	table.insert(postcards,self.cards[index])
	-- if index == 1 then
	-- 	postcards = {5,18,6}
	-- elseif index == 2 then
	-- 	postcards = {4,17,9}
	-- end

	return postcards
end

function longhu_game:generatecards()
	for i = 1, 2 do
		self.allcards[i] = self.cards[i]
	end
	self.playercount = 2
	
	
	--log_info("cheatmode "..self.cheatmode )

end

function longhu_game:getsum(cards_1 )
	return (cards_1 - 1)%13 
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

-- LONGHUBET =  {
-- 	BET_DRAGON_WIN = 1,  --//龙赢
-- 	BET_TIGER_WIN = 2, -- //虎赢
-- 	BET_DRAW_WIN = 3,  --//和局
-- 	BET_DUI_WIN = 4,  --//对9-A赢
-- 	BET_SHUN_WIN = 5,  --//顺赢
-- 	BET_JINHUA_WIN = 6,  --//金花赢
-- 	BET_SHUNJIN_WIN = 7,  --//顺金赢
-- 	BET_BAOZI_WIN = 8,  --//豹子赢
-- }

function longhu_game:compare(cards_1,cards_2,guid_1,guid_2 )
	if self:getsum(cards_1) > self:getsum(cards_2) then
		return LONGHUBET.BET_DRAGON_WIN
	elseif self:getsum(cards_1) < self:getsum(cards_2) then
		return LONGHUBET.BET_TIGER_WIN
	else
		return LONGHUBET.BET_DRAW_WIN
	end
end

function longhu_game:getcard( type)
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


function longhu_game:getcardsnum( tablecard )
	if tablecard == nil then
		return 0
	end
	local x = 0
	for k,v in pairs(tablecard) do
		x = x + 1
	end
	return x
end 

function longhu_game:cardtype( cards ) -- 三公牌型,点数，花色
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



return longhu_game