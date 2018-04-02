local pb = require "extern/lib/lib_pb"
local function get_value(card)
	return math.floor(card / 4)
end
local function is_king(card)
	return card == 52 or card == 53
end
ddz_sf = {}
function ddz_sf:new()
    local o = {}  
    setmetatable(o, {__index = self})
	
    return o 
end
function ddz_sf:init(cards)
    self.cards_ = cards
    self.bomb_count_ = 0
end
function ddz_sf:add_cards(cards)
	for i,v in ipairs(cards) do
    	table.insert(self.cards_, v)
    end
end
function ddz_sf:add_bomb_count()
	self.bomb_count_ = self.bomb_count_ + 1
end
function ddz_sf:get_bomb_count()
	return self.bomb_count_
end
function ddz_sf:find_card(card)
	for i,v in ipairs(self.cards_) do
		if v == card then
			return true
		end
	end
	return false
end
function ddz_sf:remove_card(card)
for i,v in ipairs(self.cards_) do
		if v == card then
			table.remove(self.cards_, i)
			return true
		end
	end
	return false
end
function ddz_sf:check_cards(cards)
	if not cards or #cards == 0 then
		return false
	end
	local set = {} 
	for i,v in ipairs(cards) do
		if v < 0 or v > 53 or set[v] then
			return false
		end
		if not self:find_card(v) then
			return false
		end
		set[v] = true
	end
	return true
end
function ddz_sf:analyseb_cards(cards)
	local ret = {{}, {}, {}, {}} 
	local last_val = nil
	local i = 0
	for _, card in ipairs(cards) do
		if is_king(card) then
			table.insert(ret[1], card)
		else
			local val = get_value(card)
			if last_val == val then
				i = i + 1
			else
				if i > 0 and i <= 4 then
					table.insert(ret[i], last_val)
				end
				last_val = val
				i = 1
			end
		end
	end
	if i > 0 and i <= 4 then
		table.insert(ret[i], last_val)
	end
	return ret
end
function ddz_sf:get_cards_type(cards)
	local count = #cards
	if count == 1 then
		return pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_SINGLE"), get_value(cards[1]) 
	elseif count == 2 then
		if is_king(cards[1]) and is_king(cards[2]) then
			return pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_MISSILE")
		elseif get_value(cards[1]) == get_value(cards[2]) then
			return pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_DOUBLE"), get_value(cards[1])
		end
		return nil
	end
	local ret = self:analyseb_cards(cards)
	if #ret[4] == 1 then
		if count == 4 then
			return pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_BOMB"), ret[4][1] 
		elseif count == 6 then
			return pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_FOUR_TAKE_ONE"), ret[4][1]
		elseif count == 8 and #ret[2] == 2 then
			return pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_FOUR_TAKE_TWO"), ret[4][1]
		elseif count >= 8 then
			table.insert(ret[3], ret[4][1])
			table.insert(ret[1], ret[4][1])
			table.sort(ret[3], function(a, b) return a < b end)
			table.sort(ret[1], function(a, b) return a < b end)
		else
			return nil
		end
	end
	local three_count = #ret[3] 
	if three_count > 0 then
		if three_count > 1 then
			if ret[3][1] >= 12 then
				return nil
			end
			local cur_val = nil
			for _, card in ipairs(ret[3]) do
				if not cur_val then
					cur_val = card + 1
				elseif cur_val == card then
					cur_val = cur_val + 1
				else
					return nil
				end
			end
		elseif count == 3 then
			return pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE"), ret[3][1]	-- 三条
		end
		if count == three_count * 3 then
			return pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE_LINE"), ret[3][1] -- 三连
		elseif count == three_count * 4 then
			return pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE_TAKE_ONE"), ret[3][1] -- 三带一单
		elseif count == three_count * 5 and #ret[2] == three_count then
			return pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE_TAKE_TWO"), ret[3][1] -- 三带一对
		end
		return nil
	end
	local two_count = #ret[2]
	if two_count >= 3 then
		if ret[2][1] >= 12 then
			return nil
		end
		local cur_val = nil
		for _, card in ipairs(ret[2]) do
			if not cur_val then
				cur_val = card + 1
			elseif cur_val == card then
				cur_val = cur_val + 1
			else
				return nil
			end
		end
		if count == two_count * 2 then
			return pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_DOUBLE_LINE"), ret[2][1]
		end
		return nil
	end
	local one_count = #ret[1]
	if one_count >= 5 and count == one_count then
		if ret[1][1] >= 12 then
			return nil
		end
		local cur_val = nil
		for _, card in ipairs(ret[1]) do
			if not cur_val then
				cur_val = card + 1
			elseif cur_val == card then
				cur_val = cur_val + 1
			else
				return nil
			end
		end
		return pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_DOUBLE_LINE"), ret[1][1] -- 单连
	end
	return nil
end
function ddz_sf:compare_cards(cur, last)
	if not last then
		return true
	end
	if cur.cards_type == pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_MISSILE") then
		return true
	end
	if last.cards_type == pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_BOMB") then
		return cur.cards_type == pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_BOMB") and cur.cards_val > last.cards_val
	elseif cur.cards_type == pb.get_ev("LAND_CARD_TYPE", "LAND_CARD_TYPE_BOMB") then
		return true
	end
	return cur.cards_type == last.cards_type and cur.cards_count == last.cards_count and cur.cards_val > last.cards_val
end
function ddz_sf:out_cards(cards)
	for i,v in ipairs(cards) do
		self:remove_card(v)
	end
	return #self.cards_ > 0
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local transform_to_local_value = 
{
	0x03, 0x13, 0x23, 0x33, 0x04, 0x14, 0x24, 0x34, 0x05, 0x15, 0x25, 0x35,
	0x06, 0x16, 0x26, 0x36, 0x07, 0x17, 0x27, 0x37,
	0x08, 0x18, 0x28, 0x38, 0x09, 0x19, 0x29, 0x39,
	0x0A, 0x1A, 0x2A, 0x3A, 0x0B, 0x1B, 0x2B, 0x3B,
	0x0C, 0x1C, 0x2C, 0x3C, 0x0D, 0x1D, 0x2D, 0x3D,
	0x01, 0x11, 0x21, 0x31, 0x02, 0x12, 0x22, 0x32,
	0x4E, 0x4F
}

function ddz_sf:getCardLogicValue(card)
	local cbCardColor = card & 0xf0
	local cbCardValue = card & 0x0f
	if (cbCardColor==0x40) then
	 	return cbCardValue+2
	end

	if cbCardValue<=2 then
		return cbCardValue+13
	end
	return cbCardValue
end

function ddz_sf:getAllThreeCard(cards)
	local tempcard = {}
	for i=1,#cards do
		table.insert(tempcard,transform_to_local_value[cards[i]])
	end
	--tempcard = deepcopy(cards)
	table.sort(tempcard,function (a,b)
		return a < b
	end)

	local 	cbThreeCardCount = 0 
	local itemp = 1
	while 1 do
		if itemp <= #tempcard then
			local  cbLogicValue=self:getCardLogicValue(tempcard[itemp])
			local cbSameCount = 1

			for  j=itemp+1,#tempcard do
				if (self:getCardLogicValue(tempcard[j]) ~= cbLogicValue) then
					break
				end
				cbSameCount = cbSameCount + 1
			end

			if(cbSameCount>=3) then
				cbThreeCardCount = cbThreeCardCount + 3
			end	

			itemp = itemp + cbSameCount - 1
		else
			break
		end
		itemp = itemp + 1
	end

	return cbThreeCardCount
end