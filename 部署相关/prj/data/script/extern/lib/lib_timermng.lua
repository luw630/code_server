--[[
	定时器管理器
]]
local List = require "extern/lib/lib_list"
--local Filelog = require "filelog"
--local tabletool = require "tabletool"
--local timetool = require "timetool"

--local file_name = "timermng.lua"

----- 定时管理器声明---------
local TimerMng = {
					timerpool = {},	    --定时器结构  timer {id, time[绝对时间单位 ms], source_address, msg} 
					conf = {}, 			--定时器的配置: {timer_size}
					timerhash = {},		--{timerid, index} 	
					curtimerid = 1,
					freelist = nil,

				}
-----------------------------
function TimerMng:new(obj, conf)
	-- if conf == nil then
	-- 	self.conf.timer_size = 1000
	-- end
	-- if conf.timer_size == nil or conf.timer_size <= 0 then
	-- 	self.conf.timer_size = 1000
	-- end
	self.conf.timer_size = 1000
	--self.conf = conf

	obj = obj or {}

	setmetatable(obj, self)
	self.__index = self
	self.freelist = List:new()
	local i = 1
	while i <= self.conf.timer_size do
		self.timerpool[i] = {}
		self.timerpool[i].time = 0
		self.timerpool[i].id = 0
		self.freelist:push_right(i)
		i = i + 1
	end

	return obj
end

function TimerMng:write_info_log()
	--Filelog.sys_info("TimerMng: totalsize--"..(#self.timerpool).." freesize--"..(self.freelist:get_size()).." usedsize--"..(#self.timerhash))
end

function TimerMng:write_debug_log()
	--Filelog.sys_obj("timermng", "timerhash", self.timerhash, "---freelist---", self.freelist, "---timerpool---", self.timerpool)
end

function TimerMng:is_empty_freelist()
	return (self.freelist:get_size() == 0)
end

function TimerMng:is_empty_usedlist()
	return 0
end

function TimerMng:set_timer( ms10_time, func, msg)
	if TimerMng:is_empty_freelist() then
		--Filelog.sys_error(file_name.." [BASIC_TIMER] TimerMng:set_timer not enough timer")
		return -1
	end

	if ms10_time == nil or type(ms10_time) ~= "number" or ms10_time < 0 then
		--Filelog.sys_error(file_name.." [BASIC_TIMER] TimerMng:set_timer invalid ms10_time", ms10_time, msgname, msg)
		return -1
	end

	local index = self.freelist:pop_left()
	local timerid = self.curtimerid
	self.timerhash[timerid] = index
	self.curtimerid = self.curtimerid + 1

	self.timerpool[index].id = timerid
	self.timerpool[index].time = os.time()*100 + ms10_time
	--self.timerpool[index].source_address = source_address
	self.timerpool[index].msg = msg
	self.timerpool[index].msgname = func
	return timerid
end

function TimerMng:clear_timer(timerid)
	if self.timerhash[timerid] == nil then
		--Filelog.sys_error(file_name.." [BASIC_TIMER] TimerMng:clear_timer invalid timerid",timerid)
		return
	end
	local index = self.timerhash[timerid]
	self.timerhash[timerid] = nil
	if self.timerpool[index] == nil then
		return
	end
	self.timerpool[index].id = 0
	self.timerpool[index].time = 0
	--self.timerpool[index].source_address = nil
	self.timerpool[index].msg = nil
	self.timerpool[index].msgname = nil
	self.freelist:push_right(index)
end

function TimerMng:time_tick(func)
	local now_time = os.time()*100
	local delete_table = {}
	local timer
	for timerid, index in pairs(self.timerhash) do
		if index ~= nil and self.timerpool[index] ~= nil then
			timer = self.timerpool[index]
			if timer.time <= now_time then
				timer.msgname(timerid, timer.msg)
				--func(timer.source_address, timer.msgname, timerid, timer.msg)
				table.insert(delete_table, timerid)
			end
		end
	end

	for _, timerid in ipairs(delete_table) do
		TimerMng:clear_timer(timerid)
	end
end


return TimerMng
