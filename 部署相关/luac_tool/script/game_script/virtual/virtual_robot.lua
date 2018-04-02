require "game_script/virtual/virtual_gamer"
local room_manager = g_room_mgr
require "game_script/virtual/virtual_robot_mgr"
local android_manager = android_manager
if not virtual_active_android then
	virtual_active_android = virtual_gamer:new()
	virtual_active_android.wait_active_android_ = {}	
	virtual_active_android.play_active_android_ = {}	
end
function virtual_active_android:init(roomid_, guid_, account_, nickname_)
	virtual_gamer.init(self, guid_, account_, nickname_)
	self.is_android = true
	self.wait_active_android_[roomid_] = self.wait_active_android_[roomid_] or {}
	self.wait_active_android_[roomid_][guid_] = self
	room_manager:enter_room(self, roomid_)
end
function virtual_active_android:sub_android(roomid_, count)
	local t = {}
	if count <= 0 then
		if self.wait_active_android_[roomid_] then
			for i, v in pairs(self.wait_active_android_[roomid_]) do
				table.insert(t, i)
			end
			self.wait_active_android_[roomid_] = {}
		end
		if self.play_active_android_[roomid_] then
			for i, v in pairs(self.play_active_android_[roomid_]) do
				room_manager:stand_up(v)
				table.insert(t, i)
			end
			self.play_active_android_[roomid_] = {}
		end
	else
		if self.wait_active_android_[roomid_] then
			for i, v in pairs(self.wait_active_android_[roomid_]) do
				if count <= 0 then
					break
				end
				count = count - 1
				table.insert(t, i)
				self.wait_active_android_[roomid_][i] = nil
			end
		end
		if self.play_active_android_[roomid_] then
			for i, v in pairs(self.play_active_android_[roomid_]) do
				if count <= 0 then
					break
				end
				count = count - 1
				table.insert(t, i)
				room_manager:stand_up(v)
				self.play_active_android_[roomid_][i] = nil
			end
		end
	end
	android_manager:destroy_android(t)
end
function virtual_active_android:find_active_android(room_id_)
	if self.wait_active_android_[room_id_] then
		for i, v in pairs(self.wait_active_android_[room_id_]) do
			self.play_active_android_[room_id_] = self.play_active_android_[room_id_] or {}
			self.play_active_android_[room_id_][i] = v
			self.wait_active_android_[room_id_][i] = nil
			return v
		end
	end
	return nil
end
function virtual_active_android:think_on_sit_down(room_id_, table_id_, chair_id_)
	if self.room_id ~= room_id_ then
		if self.room_id ~= 0 then
			room_manager:exit_room(self)
		end
		room_manager:enter_room(self, room_id_)
	end
	room_manager:sit_down(self, table_id_, chair_id_)
end
function virtual_active_android:check_room_limit(score)
	return false
end
function virtual_active_android:on_notify_stand_up(notify)
	room_manager:stand_up(self)
end
function virtual_active_android:get_money()
	return 1000
end
if not virtual_passive_android then
	virtual_passive_android = virtual_active_android:new()
	virtual_passive_android.init_passive_android_ = {}
	virtual_passive_android.rnd_state_wait = 70				
	virtual_passive_android.rnd_state_exit = 25				
	virtual_passive_android.time_state_wait = {180,300}		
end
function virtual_passive_android:init(roomid_, guid_, account_, nickname_)
	virtual_gamer.init(self, guid_, account_, nickname_)
	self.is_android = true
	self.init_passive_android_[roomid_] = self.init_passive_android_[roomid_] or {}
	self.init_passive_android_[roomid_][guid_] = self
	room_manager:enter_room(self, roomid_)
end
function virtual_passive_android:sub_android(roomid_, count)
	local t = {}
	if count <= 0 then
		if self.init_passive_android_[roomid_] then
			for i, v in pairs(self.init_passive_android_[roomid_]) do
				room_manager:stand_up(v)
				table.insert(t, i)
			end
			self.init_passive_android_[roomid_] = {}
		end
	else
		if self.init_passive_android_[roomid_] then
			for i, v in pairs(self.init_passive_android_[roomid_]) do
				if count <= 0 then
					break
				end
				count = count - 1
				table.insert(t, i)
				room_manager:stand_up(v)
				self.init_passive_android_[roomid_][i] = nil
			end
		end
	end
	android_manager:destroy_android(t)
end
function virtual_passive_android:on_notify_stand_up(notify)
end
function virtual_passive_android:do_update()
	local cur = get_second_time()
	for roomid, a in pairs(self.init_passive_android_) do
		for i, v in pairs(a) do
			if v.table_id and v.chair_id then
				if cur >= v.cur_time_ then
					local rnd = math.random(100)
					if rnd <= self.rnd_state_wait then
						v.cur_time_ = cur + math.random(self.time_state_wait[1], self.time_state_wait[2])
					elseif rnd <= self.rnd_state_wait + self.rnd_state_exit then
						room_manager:stand_up(v)
					else
						room_manager:stand_up(v)
					end
				end
			else
				local tableid, chairid = room_manager:find_android_pos(roomid)
				if tableid then
					room_manager:sit_down(self, tableid, chairid)
					v.cur_time_ = cur + math.random(self.time_state_wait[1], self.time_state_wait[2])
				end
			end
		end
	end
end
