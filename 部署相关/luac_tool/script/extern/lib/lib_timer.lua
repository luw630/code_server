-- 定时器


if not g_init_timer then
	g_init_timer_index = 1
	g_init_timer = {}
end

function on_timer(index, delta)
	local func = g_init_timer[index]
	assert(func)
	func(delta)
	g_init_timer[index] = nil
end

function add_timer(delay, func)
	g_init_timer[g_init_timer_index] = func
	add_lua_timer(g_init_timer_index, delay)
	g_init_timer_index = g_init_timer_index + 1
end
