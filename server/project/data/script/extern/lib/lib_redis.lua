if not g_redis_init_query_queue then
	g_redis_init_query_queue_index = 1
	g_redis_init_query_queue = {}
end

function redis_command_query_callback(index, reply)
	local func = g_redis_init_query_queue[index]
	assert(func)
	func(reply)
	g_redis_init_query_queue[index] = nil
end

function redis_cmd_query(cmd, func)
	g_redis_init_query_queue[g_redis_init_query_queue_index] = func
	redis_command_query("redis_command_query_callback", g_redis_init_query_queue_index, cmd)
	g_redis_init_query_queue_index = g_redis_init_query_queue_index + 1
end


function redis_cmd_do(cmd , master_flag)
	local reply = redis_command_do(cmd , master_flag == nil and true or master_flag)
	return reply
end