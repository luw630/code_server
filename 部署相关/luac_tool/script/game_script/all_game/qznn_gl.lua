local pb = require "extern/lib/lib_pb"

function get_value(card) return math.floor(card / 4) end
function get_value_ox(val)
	if val >= 9 then return 10 end
	return val + 1
end
function get_color(card) return card % 4 end
function get_type_times(cards_type, max_value)
	if cards_type >= pb.get_ev("BANKER_CARD_TYPE", "BANKER_CARD_TYPE_TEN") then
		return 10
	elseif cards_type == pb.get_ev("BANKER_CARD_TYPE","BANKER_CARD_TYPE_ONE") then
		return max_value
	end
	return 1
end

function get_cards_type(cards)
	local list = {}
	for i=1,5 do
		list[i] = cards[i]
	end
	table.sort(list, function (a, b)
		return a > b
	end)
	local king_ox = 0
	local is_ten = false
	local repeat_times =0
	local last_value = nil
	local val_list = {}
	local four_same = false
	local same_value = nil
	local sum_value =0
	for i =1,5 do
		local  val = math.floor(list[i]/4)
		sum_value = sum_value + val +1
		val_list[i] = val
		if val > 9 then
			king_ox = king_ox + 1
		elseif val == 9 then
			is_ten = true
		end
		if not last_value then
			last_value = val
			repeat_times = 1
		elseif last_value ~= val then
			if repeat_times ==4 then
				four_same = true
				same_value = list[i]
			end
			last_value = val
			repeat_times = 1
		else
			repeat_times = repeat_times +1
			same_value = list[i]
		end
	end
	if sum_value <= 10 then
		return pb.get_ev("BANKER_CARD_TYPE","BANKER_CARD_TYPE_FIVE_SAMLL"),val_list,get_color(list[1])
	end
	if repeat_times == 4 or four_same then
		return pb.get_ev("BANKER_CARD_TYPE", "BANKER_CARD_TYPE_FOUR_SAMES"),same_value,get_color(list[1])
	end
	
	if king_ox == 5 then
		return pb.get_ev("BANKER_CARD_TYPE", "BANKER_CARD_TYPE_FIVE_KING"),val_list,get_color(list[1])
	end
	if king_ox == 4 and is_ten then
		return pb.get_ev("BANKER_CARD_TYPE", "BANKER_CARD_TYPE_FOUR_KING"),val_list,get_color(list[1])
	end
	local is_three_eq_ten, is_ox_ox, ox_num, sort_cards = cal_ox_normal_type(val_list, list)
	if is_ox_ox then
		return pb.get_ev("BANKER_CARD_TYPE", "BANKER_CARD_TYPE_TEN"),val_list,get_color(list[1]), 10, sort_cards
	end

	if is_three_eq_ten then
		return pb.get_ev("BANKER_CARD_TYPE","BANKER_CARD_TYPE_ONE"),val_list,get_color(list[1]),ox_num, sort_cards
	end
	return pb.get_ev("BANKER_CARD_TYPE","BANKER_CARD_TYPE_NONE"), val_list, get_color(list[1])
end
function get_type_times_classic(ox_type_, extro_num_)
	if ox_type_ >= pb.get_ev("BANKER_CARD_TYPE", "BANKER_CARD_TYPE_TEN") then
		return 3
	elseif  ox_type_ == pb.get_ev("BANKER_CARD_TYPE","BANKER_CARD_TYPE_ONE") and  extro_num_ >= 7 then
		return 2
	else
		return 1
	end
end
function cal_ox_normal_type(val_list, list)
	local val_ox = {}
	for i=1,5 do
		val_ox[i] = get_value_ox(val_list[i])
	end
	local is_three_eq_ten =false 
	local is_ox_ox = false 
	local ox_num = 0 
	local sort_cards = {}
	for i=1,3 do
		for j =i+1,4 do
			for k=j+1,5 do
				if (val_ox[i] + val_ox[j] + val_ox[k]) %10 ==0 then
					is_three_eq_ten = true
					sort_cards = {list[i], list[j], list[k]}
					for x=1,5 do
						local same_flag = 0
						for y=1,3 do
							if list[x] == sort_cards[y] then
								same_flag = 1
								break
							end
						end
						if same_flag == 0 then
							table.insert(sort_cards, list[x])
						end						
					end
					local other_sum =0
					for m=1,5 do
						if m ~=i and m ~=j and m~=k then
							other_sum = other_sum + val_ox[m]
						end
					end
					if(other_sum)%10 ==0 then
						is_ox_ox = true
					else
						ox_num = other_sum %10
					end
					return is_three_eq_ten, is_ox_ox, ox_num, sort_cards
				end
			end
		end
	end
	return is_three_eq_ten, is_ox_ox, ox_num, {}
end
function compare_cards(first, second)
	if first.ox_type ~= second.ox_type then
		return first.ox_type > second.ox_type
	end
	if first.ox_type == pb.get_ev("BANKER_CARD_TYPE","BANKER_CARD_TYPE_ONE") then
		if first.cards_times ~= second.cards_times then
			return first.cards_times > second.cards_times
		end
	end
	if first.ox_type == pb.get_ev("BANKER_CARD_TYPE", "BANKER_CARD_TYPE_FOUR_SAMES") then
		return first.val_list > second.val_list
	end
	for i=1,5 do
		local v1 = first.val_list[i]
		local v2 = second.val_list[i]
		if v1 > v2 then
			return true
		elseif v1 < v2 then
			return false
		else
			return first.color > second.color
		end
	end
	return first.color > second.color
end

