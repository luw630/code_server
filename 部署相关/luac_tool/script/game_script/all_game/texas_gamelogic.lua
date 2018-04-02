
local pb = require "extern/lib/lib_pb"


--扑克类型
CT_HIGH_CARD		= pb.get_ev("TexasCardsType","CT_HIGH_CARD")			--1  单牌类型
CT_ONE_PAIR			= pb.get_ev("TexasCardsType","CT_ONE_PAIR")			--2  对子类型	2
CT_TWO_PAIRS		= pb.get_ev("TexasCardsType","CT_TWO_PAIRS")			--3  两对类型	4
CT_THREE_OF_A_KIND	= pb.get_ev("TexasCardsType","CT_THREE_OF_A_KIND")		--4  三条类型	3
CT_STRAIGHT			= pb.get_ev("TexasCardsType","CT_STRAIGHT")			--5  顺子类型	5
CT_FLUSH			= pb.get_ev("TexasCardsType","CT_FLUSH")				--6  同花类型 	5
CT_FULL_HOUSE		= pb.get_ev("TexasCardsType","CT_FULL_HOUSE")			--7  葫芦类型	5
CT_FOUR_OF_KIND		= pb.get_ev("TexasCardsType","CT_FOUR_OF_KIND")		--8  铁支类型	4
CT_STRAIT_FLUSH		= pb.get_ev("TexasCardsType","CT_STRAIT_FLUSH")		--9  同花顺型 	5
CT_ROYAL_FLUSH		= pb.get_ev("TexasCardsType","CT_ROYAL_FLUSH")			--10 皇家同花顺 5


--检查action
function check_action(value)
	if value == 0 then
		return false
	end
	return true
end

--获取win player
function get_win_player(user)
	if #user == 0 then
		return nil
	end

	if #user == 1 then
		return user[1].card_type, {user[1].guid}
	end

	local win_array = {}
	local l_card_type = 0
	local biggest_player = tablex.copy(user[1])

	for i = 2, #user do
		--牌型比较
		if biggest_player.card_type < user[i].card_type then
			biggest_player = tablex.copy(user[i])
			l_card_type = user[i].card_type
		--牌型相等，牌大小比较分析
		elseif biggest_player.card_type == user[i].card_type then
		    if t_compare_cards(user[i].cards, biggest_player.cards) > 1  then  --biggest_player.cards
				biggest_player = tablex.copy(user[i])
				l_card_type = user[i].card_type
			end
		end
	end

	--两人牌型、大小完全一样，两个赢家
	for i = 1,#user do
		if biggest_player.guid ~= user[i].guid and 
			biggest_player.card_type == user[i].card_type and
			t_compare_cards(user[i].cards, biggest_player.cards) == 0 then
			table.insert(win_array, user[i].guid)
			l_card_type = user[i].card_type
		end
	end

	table.insert(win_array, biggest_player.guid)
	return l_card_type, win_array
end

--获取牌值
function t_get_value(card,isOne)
	local value = card&0x0F
	if value == 1 then
		if not isOne then
			return 14
		end
	end
	return value
end

--获取花色
function t_get_color(card)
	local value = card&0xF0
	return value
end

function t_get_highlight_cards(analysisResult, cards, l_type)
	if l_type == CT_ONE_PAIR or l_type == CT_TWO_PAIRS then 
		return analysisResult.cbPairCardData
	elseif l_type == CT_THREE_OF_A_KIND	then
		return analysisResult.cbThreeCardData
	elseif l_type == CT_FOUR_OF_KIND then
		return analysisResult.cbFourCardData
	end
 	return cards
end

--顺子和同花
function _do_get_card_type(cbCardData, isOne)	
	table.sort(cbCardData,function (a,b) return t_get_value(a,isOne) > t_get_value(b,isOne) end)
	--变量定义
	local cbSameColor = true
	local bLineCard = true
	local cbFirstColor = t_get_color(cbCardData[1])
	local cbFirstValue = t_get_value(cbCardData[1],isOne)

	--牌形分析
	for i = 2,5 do
		--数据分析
		if t_get_color(cbCardData[i]) ~= cbFirstColor then
			cbSameColor = false
		end
		if cbFirstValue ~= t_get_value(cbCardData[i],isOne) + i - 1 then
			bLineCard = false
		end

		--结束判断
		if cbSameColor == false and bLineCard == false then
			break
		end
	end

	--最小同花顺
	if bLineCard == false and cbFirstValue == 14 then
		local i=1;
		for i=2,5 do
			if cbFirstValue ~= t_get_value(cbCardData[i],isOne)+i+7 then
				break
			end
		end
		if i == 5 then
			bLineCard =true;
		end
	end

	--皇家同花顺
	if cbSameColor == true and bLineCard == true and t_get_value(cbCardData[2],isOne) == 13 then
		return CT_ROYAL_FLUSH
	end
	--顺子类型
	if cbSameColor == false and bLineCard == true then
		return CT_STRAIGHT
	end
	--同花类型
	if cbSameColor == true and bLineCard == false then
		return CT_FLUSH
	end
	--同花顺类型
	if cbSameColor == true and bLineCard == true then
		return CT_STRAIT_FLUSH
	end
	
	return nil
end

--获取牌类型
function t_get_card_type(cbCardData)	
	--检测是否有A牌
	local isA = false
	for k,v in pairs(cbCardData) do
		if t_get_value(v) == 14 then
			isA = true
			break
		end
	end
	--处理A的特殊情况
	local l_card_type = _do_get_card_type(cbCardData)
	if isA then
		--处理A为1点的情况
		local ktypeOne = _do_get_card_type(cbCardData,true)
		if ktypeOne and not l_card_type then
			return ktypeOne, {}
		end
		if ktypeOne and l_card_type and ktypeOne > l_card_type then
			return ktypeOne, {}
		end
	end

	if l_card_type then
		return l_card_type, {}
	end

	--扑克分析
	local AnalyseResult = t_analyseb_cards(cbCardData)

	--类型判断
	if AnalyseResult.cbFourCount == 1 then
		return CT_FOUR_OF_KIND, AnalyseResult
	end
	if AnalyseResult.cbPairCount == 2 then
		return CT_TWO_PAIRS, AnalyseResult
	end
	if AnalyseResult.cbPairCount == 1 and AnalyseResult.cbThreeCount == 1 then
		return CT_FULL_HOUSE, AnalyseResult
	end
	if AnalyseResult.cbThreeCount == 1 and AnalyseResult.cbPairCount == 0 then
		return CT_THREE_OF_A_KIND, AnalyseResult
	end
	if AnalyseResult.cbPairCount == 1 and AnalyseResult.cbSingleCount == 3 then
		return CT_ONE_PAIR, AnalyseResult
	end
	return CT_HIGH_CARD, {}
end

--值相同的多张牌
function t_analyseb_cards(cbCardData)
	table.sort(cbCardData,function (a,b) return t_get_value(a) > t_get_value(b) end)
	local AnalyseResult = {cbSingleCount = 0,cbPairCount = 0,cbThreeCount = 0,cbFourCount = 0}
	AnalyseResult.cbSingleCardData = {}
	AnalyseResult.cbSingleLogicVolue = {0,0,0,0,0}
	AnalyseResult.cbPairCardData = {}
	AnalyseResult.cbPairLogicVolue = {0,0}
	AnalyseResult.cbThreeCardData = {}
	AnalyseResult.cbThreeLogicVolue = {0}
	AnalyseResult.cbFourCardData = {}
	AnalyseResult.cbFourLogicVolue = {0}
	--扑克分析
	for i = 1,5 do
		--变量定义
		local cbSameCount = 1
		local cbSameCardData = {cbCardData[i],0,0,0}
		local cbLogicValue = t_get_value(cbCardData[i])

		--获取同牌
		for j = i+1,5 do
			--逻辑对比
			if t_get_value(cbCardData[j]) ~= cbLogicValue then
				break
			end

			--设置扑克
			cbSameCount = cbSameCount + 1
			cbSameCardData[cbSameCount]=cbCardData[j]
		end

		--保存结果
		if cbSameCount == 1 then --单张
			local kSameFlag = 0
			for k = i-1,1,-1 do
				if t_get_value(cbCardData[k]) == cbLogicValue then
					kSameFlag = 1
				end
			end
			if kSameFlag == 0 then			
				AnalyseResult.cbSingleCount = AnalyseResult.cbSingleCount + 1
				AnalyseResult.cbSingleCardData[AnalyseResult.cbSingleCount] = cbCardData[i]
				AnalyseResult.cbSingleLogicVolue[AnalyseResult.cbSingleCount] = cbLogicValue
			end
		elseif cbSameCount == 2 then --两张
			local iCheck = 0
			for j = 1,cbSameCount do
				--检查是否是三张中的两张
				for k,v in ipairs(AnalyseResult.cbThreeCardData) do
					if cbSameCardData[j] == v then
						iCheck = iCheck + 1
					end
				end
				
			end
			if iCheck ~= cbSameCount then
				for j = 1,cbSameCount do
					AnalyseResult.cbPairCardData[AnalyseResult.cbPairCount * cbSameCount + j] = cbSameCardData[j]
				end
				AnalyseResult.cbPairCount = AnalyseResult.cbPairCount + 1
				AnalyseResult.cbPairLogicVolue[AnalyseResult.cbPairCount] = cbLogicValue
			end
		elseif cbSameCount == 3 then --三张
			local iCheck = 0
			for j = 1,cbSameCount do
				--检查是否是三张中的两张
				for k,v in ipairs(AnalyseResult.cbFourCardData) do
					if cbSameCardData[j] == v then
						iCheck = iCheck + 1
					end
				end
			end
			if iCheck ~= cbSameCount then
				for j = 1,cbSameCount do
					AnalyseResult.cbThreeCardData[AnalyseResult.cbThreeCount * cbSameCount + j] = cbSameCardData[j]
				end
				AnalyseResult.cbThreeCount = AnalyseResult.cbThreeCount + 1
				AnalyseResult.cbThreeLogicVolue[AnalyseResult.cbThreeCount] = cbLogicValue
			end
		elseif cbSameCount == 4 then --四张
			for j = 1,cbSameCount do
				AnalyseResult.cbFourCardData[AnalyseResult.cbFourCount * cbSameCount + j] = cbSameCardData[j]
			end
			AnalyseResult.cbFourCount = AnalyseResult.cbFourCount + 1
			AnalyseResult.cbFourLogicVolue[AnalyseResult.cbFourCount] = cbLogicValue
		end
		--设置递增
		--checked
		i = i + cbSameCount - 1
	end
	return AnalyseResult
end

--对比扑克
function t_compare_cards(cbFirstData,cbNextData)
	--获取类型
	local cbNextType, AnalyseResult = t_get_card_type(cbNextData)
	local cbFirstType, AnalyseResult = t_get_card_type(cbFirstData)

	--类型判断
	--大
	if cbFirstType > cbNextType then
		return 2
	end
	--小
	if cbFirstType < cbNextType then
		return 1
	end
	if CT_HIGH_CARD == cbFirstType then 
		--单牌
		--简单类型
		--对比数值
		local i = 1
		for i = 1,5 do
			local cbNextValue = t_get_value(cbNextData[i])
			local cbFirstValue = t_get_value(cbFirstData[i])
			--大
			if cbFirstValue > cbNextValue then
				return 2
			--小
			elseif cbFirstValue < cbNextValue then
				return 1
			end
		end
		--平
		--checked
		return 0
	elseif CT_ONE_PAIR == cbFirstType or CT_TWO_PAIRS == cbFirstType or CT_THREE_OF_A_KIND == cbFirstType or CT_FOUR_OF_KIND == cbFirstType or CT_FULL_HOUSE == cbFirstType then
		--对子,两对,三条,铁支,葫芦
		--分析扑克
		local AnalyseResultNext = t_analyseb_cards(cbNextData)
		local AnalyseResultFirst = t_analyseb_cards(cbFirstData)

		--四条数值
		if AnalyseResultFirst.cbFourCount > 0  then
			local cbNextValue = AnalyseResultNext.cbFourLogicVolue[1]
			local cbFirstValue = AnalyseResultFirst.cbFourLogicVolue[1]

			--比较四条
			if cbFirstValue ~= cbNextValue then
				return cbFirstValue > cbNextValue and 2 or 1
			end

			--比较单牌
			cbFirstValue = AnalyseResultFirst.cbSingleLogicVolue[1]
			cbNextValue = AnalyseResultNext.cbSingleLogicVolue[1]
			if cbFirstValue ~= cbNextValue then
				return cbFirstValue > cbNextValue and 2 or 1
			end 
			return 0
		end

		--三条数值
		if AnalyseResultFirst.cbThreeCount > 0 then
			local cbNextValue = AnalyseResultNext.cbThreeLogicVolue[1]
			local cbFirstValue = AnalyseResultFirst.cbThreeLogicVolue[1]

			--比较三条
			if cbFirstValue ~= cbNextValue then
				return cbFirstValue > cbNextValue and 2 or 1
			end

			--葫芦牌型
			if CT_FULL_HOUSE == cbFirstType then
				--比较对牌
				cbFirstValue = AnalyseResultFirst.cbPairLogicVolue[1]
				cbNextValue = AnalyseResultNext.cbPairLogicVolue[1]
				if cbFirstValue ~= cbNextValue then
					return cbFirstValue > cbNextValue and 2 or 1
				end
				return 0
			else
				--三条带单
				--比较单牌
				--散牌数值
				local i = 1
				for i = 1,AnalyseResultFirst.cbSingleCount do
					local cbNextValue = AnalyseResultNext.cbSingleLogicVolue[i]
					local cbFirstValue = AnalyseResultFirst.cbSingleLogicVolue[i]
					--大
					if cbFirstValue > cbNextValue then
						return 2
					--小
					elseif cbFirstValue <cbNextValue then
						return 1
					--等
					end
				end
				if i == AnalyseResultFirst.cbSingleCount then
					return 0
				end
			end
		end
		--对子数值
		local i = 1
		for i = 1,AnalyseResultFirst.cbPairCount do
			local cbNextValue = AnalyseResultNext.cbPairLogicVolue[i]
			local cbFirstValue = AnalyseResultFirst.cbPairLogicVolue[i]
			--大
			if cbFirstValue > cbNextValue then
				return 2
			--小
			elseif cbFirstValue < cbNextValue then
				return 1
			end
			--平
		end

		--比较单牌
		--散牌数值
		for i = 1,AnalyseResultFirst.cbSingleCount do
			local cbNextValue = AnalyseResultNext.cbSingleLogicVolue[i]
			local cbFirstValue = AnalyseResultFirst.cbSingleLogicVolue[i] 
			--大
			if cbFirstValue > cbNextValue then
				return 2
			--小
			elseif cbFirstValue < cbNextValue then
				return 1
			end
			--等
		end
		--平
		if i == AnalyseResultFirst.cbSingleCount then
			return 0
		end
	elseif CT_STRAIGHT == cbFirstType or CT_STRAIT_FLUSH == cbFirstType then
		--顺子,同花顺
		--数值判断
		local cbNextValue = t_get_value(cbNextData[1])
		local cbFirstValue = t_get_value(cbFirstData[1])

		local bFirstmin = cbFirstValue == t_get_value(cbFirstData[2])+9
		local bNextmin = cbNextValue == t_get_value(cbNextData[2])+9

		--大小顺子
		if bFirstmin == true and bNextmin == false then
			return 1
		--大小顺子
		elseif bFirstmin == false and bNextmin == true then
			return 2
		--等同顺子
		else
		--平
			if cbFirstValue == cbNextValue then
				return 0
			end
			return cbFirstValue > cbNextValue and 2 or 1
		end
	elseif CT_FLUSH == cbFirstType then
		--同花
		--散牌数值
		for i = 1,5 do
			local cbNextValue = t_get_value(cbNextData[i])
			local cbFirstValue = t_get_value(cbFirstData[i])

			if cbFirstValue ~= cbNextValue then
				return cbFirstValue > cbNextValue and 2 or 1
			end
		end
		--平
		--checked
		return 0
	end
	return 0
end

--7找5
function t_get_type_five_from_seven(user_cards,public_cards)
	--临时变量
	local cbLastCardData = {}
	local cbTempCardData = tablex.copy(user_cards)
	local cbTempLastCardData = {0,0,0,0,0}

	--拷贝数据
	for k,v in pairs(public_cards) do
		table.insert(cbTempCardData,v)
	end

	--排列扑克
	table.sort(cbTempCardData,function (a,b) return t_get_value(a) > t_get_value(b) end)
	for i = 1,5 do
		table.insert(cbLastCardData,cbTempCardData[i])
	end

	local cbCardKind, AnalyseResult = t_get_card_type(cbLastCardData)
	local cbTempCardKind = 0

	--组合算法
	for i = 1,4 do
		for j = i + 1,4 do
			for k = j + 1,5 do
				for l = k + 1,6 do
					for m = l + 1,7 do
						--获取数据
						cbTempLastCardData[1] = cbTempCardData[i]
						cbTempLastCardData[2] = cbTempCardData[j]
						cbTempLastCardData[3] = cbTempCardData[k]
						cbTempLastCardData[4] = cbTempCardData[l]
						cbTempLastCardData[5] = cbTempCardData[m]
						
						--牌型大小 
						if t_compare_cards(cbTempLastCardData,cbLastCardData) == 2 then
							--获取牌型
							cbTempCardKind,AnalyseResult = t_get_card_type(cbTempLastCardData)
							cbCardKind = cbTempCardKind
							cbLastCardData = tablex.copy(cbTempLastCardData)
						end
					end
				end
			end
		end
	end
	return cbCardKind,cbLastCardData,AnalyseResult
end

--6找5
function t_get_type_five_from_six(user_cards,public_cards)
	--临时变量
	local cbLastCardData = {}
	local cbTempCardData = tablex.copy(user_cards)
	local cbTempLastCardData = {0,0,0,0,0}

	--拷贝数据
	for k,v in pairs(public_cards) do
		table.insert(cbTempCardData,v)
	end

	--排列扑克
	table.sort(cbTempCardData,function (a,b) return t_get_value(a) > t_get_value(b) end)
	for i = 1,5 do
		table.insert(cbLastCardData,cbTempCardData[i])
	end

	local cbCardKind,AnalyseResult = t_get_card_type(cbLastCardData)
	local cbTempCardKind = 0
	local tmpAnalyseResult = {}

	--组合算法
	for i = 1,4 do
		for j = i + 1,4 do
			for k = j + 1,4 do
				for l = k + 1,5 do
					for m = l + 1,6 do
						--获取数据
						cbTempLastCardData[1] = cbTempCardData[i]
						cbTempLastCardData[2] = cbTempCardData[j]
						cbTempLastCardData[3] = cbTempCardData[k]
						cbTempLastCardData[4] = cbTempCardData[l]
						cbTempLastCardData[5] = cbTempCardData[m]
						--获取牌型
						cbTempCardKind, tmpAnalyseResult = t_get_card_type(cbTempLastCardData)
						--牌型大小
						if t_compare_cards(cbTempLastCardData,cbLastCardData) == 2 then
							cbCardKind = cbTempCardKind
							AnalyseResult = tmpAnalyseResult
							cbLastCardData = tablex.copy(cbTempLastCardData)
						end
					end
				end
			end
		end
	end
	return cbCardKind,cbLastCardData,AnalyseResult
end
