
local tablex = {}

-- 复制table, 深拷贝
function tablex.copy(src)
    src = src or {}
    local dest = {}
    for k, v in pairs(src) do
        if type(v) ~= "table" then
            dest[k] = v
        else
            dest[k] = tablex.copy(v)
        end
    end
    return dest
end

-- 序列化为table代码
function tablex.serialize(tbl)
	local mark = {}
	local assign = {}
	
	local function tablex_serialize(tbl, parent)
		mark[tbl] = parent
		local tmp = {}
		for k, v in pairs(tbl) do
			local key = type(k) == "number" and "[" .. k .. "]" or k
			if type(v) == "table" then
				local dotkey = parent .. (type(k) == "number" and key or "." .. key)
				if mark[v] then
					table.insert(assign, dotkey .. "=" .. mark[v])
				else
					table.insert(tmp, key .. "=" .. tablex_serialize(v, dotkey))
				end
			else
				if type(v) == "number" then 
					table.insert(tmp, key .. "=" .. v)
				elseif type(v) == "string" then 
					table.insert(tmp, key .. '="' .. v .. '"')
				elseif type(v) == "boolean" then 
					table.insert(tmp, key .. "=" .. tostring(v))
				end
			end
		end
		return "{" .. table.concat(tmp, ",") .. "}"
	end
 
	return "do local ret=" .. tablex_serialize(tbl,"ret") .. table.concat(assign, " ") .. " return ret end"
end

-- 解析table代码
function tablex.parse(str)
	return assert(loadstring(str))()
end

-- 转换为字符串
function tablex.tostring(tbl, separator, indent)
    assert(type(tbl) == "table", "tbl must be a table")

    tbl = tbl or {}
    separator = separator or "  "
    indent = indent or 0
    local indent1 = string.rep(separator, indent)
    local indent2 = string.rep(separator, indent + 1)
    local strtable = {}
    table.insert(strtable, indent1 .. "{")
    for k, v in pairs(tbl) do
        if type(v) == "string" then
            table.insert(strtable, indent2 .. k .. ' = "' .. v .. '"')
        elseif type(v) == "boolean" then
            table.insert(strtable, indent2 .. k .. ' = "' .. tostring(v) .. '"')
        elseif type(v) ~= "table" then
            table.insert(strtable, indent2 .. k .. " = " .. v .. '')
        else
            table.insert(strtable, indent2 .. k .. " = ")
            local tmp = tablex.tostring(v, separator, indent + 1)
            table.insert(strtable, tmp)
        end
    end
    table.insert(strtable, indent1 .. "}")
    return table.concat(strtable, "\n")
end

-- 打印table
function tablex.print(tbl, separator, indent)
    print(tablex.tostring(tbl, separator, indent))
end

-- 打乱table
function tablex.shuffle(tbl, rand)
    rand = rand or math.random
    if #tbl <= 1 then
        return
    end
    for i = #tbl, 2, -1 do
        local j = rand(1, i - 1)
        print(i, j)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

return tablex
