require "game_script/all_game/hhdz_enum"
local hhdz_gamehelp = {}

function hhdz_gamehelp:new( ... )
    local o = {}  
    setmetatable(o, {__index = self})
    return o 
end


function hhdz_gamehelp.compare(redCard, blackCard)
    local type1, huase1, value1, single1 = hhdz_gamehelp.getCardType(redCard)
    local type2, huase2, value2, single2 = hhdz_gamehelp.getCardType(blackCard)
    if type1 > type2 then
        return 1, type1, type2
    elseif type1 < type2 then
        return 2, type1, type2
    else
        if type1 == HONGHEITYPE.HONGHEI_SHUNJIN 
        or type1 == HONGHEITYPE.HONGHEI_JINHUA then
            if value1 == value2 then
                return (huase1 > huase2 and 1 or 2), type1, type2
            else
                return (value1 > value2 and 1 or 2), type1, type2
            end
        elseif type1 == HONGHEITYPE.HONGHEI_BAOZI then
            return (huase1 > huase2 and 1 or 2), type1, type2 --豹子特殊处理 返回的huase就是值
        elseif type1 == HONGHEITYPE.HONGHEI_DUIZI then
            if value1 == value2 then
                if single1 == single2 then
					return (value1 > value2 and 1 or 2), type1, type2
                else
                    return (single1 > single2 and 1 or 2), type1, type2
                end
            else
                return (value1 > value2 and 1 or 2), type1, type2
            end
        elseif type1 == HONGHEITYPE.HONGHEI_SHUNZI then
            if value1 == value2 then
                return (huase1 > huase2 and 1 or 2), type1, type2
            else
                return (value1 > value2 and 1 or 2), type1, type2
            end
        elseif type1 == HONGHEITYPE.HONGHEI_GAOPAI then
            if value1 == value2 then
				if value1 == 14 then -- 对A做特殊处理
					if single1[3] == single2 [3] then 
						if single1[2] == single2 [2] then 
							return (huase1 > huase2 and 1 or 2), type1, type2				
						else	
							return (single1[2] > single2 [2]  and 1 or 2), type1, type2
						end 		
					
					else
						return (single1[3] > single2 [3]  and 1 or 2), type1, type2
					end
					
				else 
					
					if single1[2] == single2 [2] then 
						if single1[1] == single2 [1] then 
							return (huase1 > huase2 and 1 or 2), type1, type2				
						else	
							return (single1[1] > single2 [1]  and 1 or 2), type1, type2
						end 		
					
					else
						return (single1[2] > single2 [2]  and 1 or 2), type1, type2
					end
				end 
					
            else
                return (value1 > value2 and 1 or 2), type1, type2
            end
        end
    end
end

function hhdz_gamehelp.getCardType(card)
    -- 点数排序
    local point = {}
    point[1]    = math.floor(card[1] % 13) == 0 and 13 or math.floor(card[1] % 13)
    point[2]    = math.floor(card[2] % 13) == 0 and 13 or math.floor(card[2] % 13)
    point[3]    = math.floor(card[3] % 13) == 0 and 13 or math.floor(card[3] % 13)
    table.sort(point)

    -- 取出花色
	local   curcard = card
	table.sort(curcard)
    local   huase_1   = math.floor((curcard[1]-1) / 13)
    local   huase_2   = math.floor((curcard[2]-1) / 13)
    local   huase_3   = math.floor((curcard[3]-1) / 13)

    if huase_1 == huase_2 and huase_1 == huase_3 then
        if point[1] + 1 == point[2] and point[2] + 1 == point[3] then -- 顺金
            return HONGHEITYPE.HONGHEI_SHUNJIN, huase_1, point[3], nil
        elseif point[1] == 1 and point[2] == 12 and point[3] == 13 then
            return HONGHEITYPE.HONGHEI_SHUNJIN, huase_1, 14, nil
        else    -- 金花
            return HONGHEITYPE.HONGHEI_JINHUA, huase_1, (point[1] == 1 and 14 or point[3]), nil
        end
    else
        if point[1] == point[2] and point[2] == point[3] then -- 豹子
            return HONGHEITYPE.HONGHEI_BAOZI, (point[1] == 1 and 14 or point[1]), nil, nil  --豹子特殊处理返回的huase就是值
        else
            if point[1] == point[2] or point[1] == point[3] or point[2] == point[3] then -- 对子
                if point[1] == point[2] then
                    return HONGHEITYPE.HONGHEI_DUIZI, huase_3 , (point[1] == 1 and 14 or point[1]) , (point[3] == 1 and 14 or point[3])
                elseif point[1] == point[3] then
                    return HONGHEITYPE.HONGHEI_DUIZI, huase_2 , (point[1] == 1 and 14 or point[1]) , (point[2] == 1 and 14 or point[2])
                elseif point[2] == point[3] then
                    return HONGHEITYPE.HONGHEI_DUIZI,huase_1 ,(point[2] == 1 and 14 or point[2])  , (point[1] == 1 and 14 or point[1])
                end
            elseif point[1] + 1 == point[2] and point[2] + 1 == point[3] then -- 顺子
                return  HONGHEITYPE.HONGHEI_SHUNZI, huase_3, point[3], nil
            elseif point[1] == 1 and point[2] == 12 and point[3] == 13 then
                return  HONGHEITYPE.HONGHEI_SHUNZI, huase_1, 14, nil
            else
                if point[1] == 1 then
                    return  HONGHEITYPE.HONGHEI_GAOPAI, huase_3, 14, point
                else
                    return  HONGHEITYPE.HONGHEI_GAOPAI, huase_3, point[3], point
                end
                
            end
        end
    end
end


return hhdz_gamehelp