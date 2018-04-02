require "extern/lib/lib_table"
local serialize_table = serialize_table

local function pb2string(tb)
	local tmp={}
	for k, v in pairs(tb or {}) do
		local strType = type(v)
		if strType == "number" or strType == "boolean" then
			table.insert(tmp, k.."="..v)
		elseif type(v) == "string" then
			table.insert(tmp, k.."='"..v.."'")
        elseif type(v) == "table" then
			table.insert(tmp, k.."='"..serialize_table(v).."'")
        end
    end
	return table.concat(tmp,",")
end

function db_execute(db, sql, pb)
	local str = pb2string(pb)
	str = string.gsub(sql, '%$FIELD%$', str)
	db:execute(str)
end

if not g_init_query_queue then
	g_init_query_queue_index = 1
	g_init_query_queue = {}
	
	g_init_query_update_queue_index = 1
	g_init_query_update_queue = {}
end

function db_execute_query_callback(index, stringbuffer)
	local func = g_init_query_queue[index]
	assert(func)
	local data = nil
	if stringbuffer then
		data = assert(load("do local ret="..stringbuffer.." return ret end"))()
	end
	func(data)
	g_init_query_queue[index] = nil
end

function db_execute_query(db, more, sql, func)
	g_init_query_queue[g_init_query_queue_index] = func
	db:execute_query("db_execute_query_callback", g_init_query_queue_index, more, sql)
	g_init_query_queue_index = g_init_query_queue_index + 1
end

function db_execute_query_update_callback(index, ret)
	local func = g_init_query_update_queue[index]
	assert(func)
	func(ret)
	g_init_query_update_queue[index] = nil
end

function db_execute_query_update(db, sql, func)
	g_init_query_update_queue[g_init_query_update_queue_index] = func
	db:execute_update("db_execute_query_update_callback", g_init_query_update_queue_index, sql)
	g_init_query_update_queue_index = g_init_query_update_queue_index + 1
end
