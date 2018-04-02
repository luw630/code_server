local function copy_table_(src, dest)
	dest = dest or {}
    for k, v in pairs(src or {}) do
        if type(v) ~= "table" then
            dest[k] = v
        else
            dest[k] = copy_table_(v)
        end
    end
    return dest
end
copy_table = copy_table_


function print_table(tb, sp)
	print ((sp or "") .. "{")
	for k, v in pairs(tb or {}) do
        if type(v) ~= "table" then
			if type(v) == "string" then
				print (sp or "", k .. ' = "' .. v .. '"')
			elseif type(v) == "boolean" then
				print (sp or "", k .. ' = "' .. tostring(v) .. '"')
			elseif type(v) ~= "userdata" then
				print (sp or "", k .. " = " .. v)
			end
        else
			print (sp or "", k .. " = ")
            print_table(v, (sp or "") .. "\t")
        end
    end
	print ((sp or "") .. "}")
end

function serialize_table(t)
	local mark={}
	local assign={}
	
	local function ser_table(tbl,parent)
		mark[tbl]=parent
		local tmp={}
		for k,v in pairs(tbl) do
			local key= type(k)=="number" and "["..k.."]" or k
			if type(v)=="table" then
				local dotkey= parent..(type(k)=="number" and key or "."..key)
				if mark[v] then
					table.insert(assign,dotkey.."="..mark[v])
				else
					table.insert(tmp, key.."="..ser_table(v,dotkey))
				end
			else
				if type(v) == "number" then 
					table.insert(tmp, key.."="..v)
				elseif type(v) == "string" then 
					table.insert(tmp, key..'="'..v..'"')
				elseif type(v) == "boolean" then 
					table.insert(tmp, key.."="..tostring(v))
				end
			end
		end
		return "{"..table.concat(tmp,",").."}"
	end
 
	return "do local ret="..ser_table(t,"ret")..table.concat(assign," ").." return ret end"
end

function parse_table(str)
	--return assert(loadstring(str))() -- lua 5.1
	return assert(load(str))()
end

local cjson = require "cjson"
function load_json_file(filename)
	local f = assert(io.open(filename , "rb"))
	local buffer = f:read "*a"
	local tb = cjson.decode(buffer)
	f:close()
	return tb
end
function load_json_buffer(buffer)
	return cjson.decode(buffer)
end
function lua_to_json(tb)
	cjson.encode_sparse_array(true,1) --防止json的极度稀疏数组 报错
    return cjson.encode(tb)
    -- body
end








--------
bs_helper={}
--------从有序数组中取随机元素
function bs_helper.randomValueInTb(tbl,b_num,e_num)
	tb1=tb1 or {}
	if #tbl==0 then
		return nil
	end
	b_num=b_num or 1
	e_num=e_num or #tbl
	
	if b_num<0 then
		return nil
	end
	if e_num>#tbl then
		return nil
	end
	if e_num<b_num then
		return nil
	end
	
    --math.randomseed(os.time())
	local random_num=math.random(b_num,e_num)
    return tbl[random_num],random_num
end


--------从哈希表中取随机元素
function bs_helper.randomValueInTb_H(tbl)
	tb1=tb1 or {}
	
    local tmpKeyT={}
    local n=1
    for k in pairs(tbl) do
        tmpKeyT[n]=k
        n=n+1
    end
	if #tmpKeyT==0 then
		return nil
	end
	--math.randomseed(os.time())
    return tbl[tmpKeyT[math.random(1,n-1)]]
end

--------从哈希表中取随机元素,排除key在delek
function bs_helper.randomValueInTb_H2(tbl,delek)
	tb1=tb1 or {}
	delek=delek or {}

    local tmpKeyT={}
    local n=1
    for k in pairs(tbl) do
		local b_delk=false
		for i,kv in ipairs(delek) do
			if k==kv then
				b_delk=true
				break
			end
		end
		if not b_delk then
			tmpKeyT[n]=k
			n=n+1
		end
    end
	if #tmpKeyT==0 then
		return nil
	end
    --math.randomseed(os.time())
    return tbl[tmpKeyT[math.random(1,n-1)]]
end

--------深度复制tb
function bs_helper.copy_tb(src, dest)
	src =src or {}
	dest = dest or {}
    for k, v in pairs(src) do
        if type(v) ~= "table" then
            dest[k] = v
        else
            dest[k] = copy_tb(v)
        end
    end
    return dest
end

--------指定key删除table中的元素  
function bs_helper.removeByKey(tbl,key)  
	tb1=tb1 or {}

    --新建一个临时的table  
    local tmp ={}  
  
    --把每个key做一个下标，保存到临时的table中
    --组成一个有顺序的table，才能在while循环准备时使用#table  
    for i in pairs(tbl) do  
        table.insert(tmp,i)  
    end  
  
    local newTb = {}  
    --使用while循环剔除不需要的元素  
    local i = 1  
    while i <= #tmp do  
        local val = tmp [i]  
        if val == key then  
            --如果是需要剔除则remove   
            table.remove(tmp,i)  
         else  
            --如果不是剔除，放入新的tabl中  
            newTb[val] = tbl[val]  
            i = i + 1  
         end  
     end  
    return newTb  
end  

--------从tb1中得到满足func函数的上下限成员
function bs_helper.getFCItem(tb1,func)
	tb1=tb1 or {}
	func=func or (function(_a,_b) return _a>_b  end)
	local f_item=nil
	local c_item=nil
	for k,v in pairs(tb1) do
		if f_item==nil  then
			f_item=v
			c_item=v
		else
			if func(v,c_item) then
				c_item=v
			else	
				f_item=v
			end	
		end	
	end
	
	return f_item,c_item
end


--------遍历有序数组所有的排序，存到返回的table中
function bs_helper.permgenTb(tb1)

	local temp_s={}
	function recurfunc(tb1,n)
		n=n or #tb1
		if n<=1  then
			local temp={}
			for i=1,#tb1 do
				table.insert(temp,tb1[i])
			end
			table.insert(temp_s,temp)
		else
			for i=1,n do
				tb1[n],tb1[i]=tb1[i],tb1[n]
				recurfunc(tb1,n-1)
				tb1[n],tb1[i]=tb1[i],tb1[n]
			end
		end
	end
	recurfunc(tb1)

	return temp_s
end