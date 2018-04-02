local pb = require "extern/lib/lib_pb"
require "game_script/handler_net"
local post_msg_to_client_pb = post_msg_to_client_pb
require "game_script/virtual/virtual_table"
require "extern/lib/lib_table"
virtual_room = {}
function virtual_room:new()  
    local o = {}  
    setmetatable(o, {__index = self})
	
    return o 
end
function virtual_room:init(room_manager, table_count, chair_count, ready_mode, room_limit, cell_money, roomconfig, room_lua_cfg)
	self.tax_show_ = roomconfig.tax_show 
	self.tax_open_ = roomconfig.tax_open 
	self.tax_ = roomconfig.tax * 0.01
	self.roomConfig = roomconfig
	self.room_manager_ = room_manager
	self.ready_mode_ = ready_mode 
	self.room_limit_ = room_limit or 0 
	self.cell_score_ = cell_money or 0 
	self.player_count_limit_ = table_count * chair_count 
	self.table_list_ = {}
	self.configid_ = 0
	self.lua_cfg_ = room_lua_cfg
	
	for i = 1, table_count do
		local t = room_manager:create_table()
		t:init(self, i, chair_count)
		if self.lua_cfg_ ~= nil then
			t:load_lua_cfg()
		end
		self.table_list_[i] = t
	end
	self.room_player_list_ = {}
	self.cur_player_count_ = 0 
end
function virtual_room:gm_update_cfg(room_manager,table_count, chair_count, room_limit, cell_money, roomconfig, room_lua_cfg)
	self.room_limit_ = room_limit or 0 
	self.cell_score_ = cell_money or 0 
	self.tax_show_ = roomconfig.tax_show 
	self.tax_open_ = roomconfig.tax_open
	self.tax_ = roomconfig.tax * 0.01
	self.roomConfig = roomconfig	
	self.player_count_limit_ = table_count * chair_count 
	self.configid_ = self.configid_ + 1
	self.lua_cfg_ = room_lua_cfg
	for i = #self.table_list_+1, table_count do
		local t = room_manager:create_table()
		t:init(self, i, chair_count)
		if self.lua_cfg_ ~= nil then
			t:load_lua_cfg()
		end
		self.table_list_[i] = t
	end
	log_info("virtual_room:gm_update_cfg "..self.tax_)
end

function virtual_room:find_table(table_id)
	if not table_id then
		return nil
	end
	return self.table_list_[table_id]
end

function virtual_room:get_user_table(player)
	if not player.table_id then
		log_warning(string.format("guid[%d] not find in table", player.guid))
		return nil
	end
	local tb = self:find_table(player.table_id)
	if not tb then
		log_warning(string.format("table_id[%d] not find in table", player.table_id))
		return nil
	end
	return tb
end
function virtual_room:get_room_cell_money()
	return self.cell_score_
end
function virtual_room:get_room_tax()
	return self.tax_
end
function virtual_room:get_ready_mode()
	return self.ready_mode_
end

function virtual_room:get_room_limit()
	return self.room_limit_
end

function virtual_room:find_player_list()
	return self.room_player_list_
end

function virtual_room:get_player(chair_id)
	return self.room_player_list_[chair_id]
end

function virtual_room:get_table_list()
	return self.table_list_
end

function virtual_room:foreach_by_player(func)
	for _, p in pairs(self.room_player_list_) do
		func(p)
	end
end

function virtual_room:broadcast_msg_to_client_by_player(msg_name, pb)
	local id, msg = get_msg_id_str(msg_name, pb)
	for _, p in pairs(self.room_player_list_) do
		post_msg_to_client_pb_str(p, id, msg)
	end
end

function virtual_room:foreach_by_table(func)
	for _, t in pairs(self.table_list_) do
		func(t)
	end
end

function virtual_room:player_enter_room(player, room_id_)
	player.in_game = true
	player.room_id = room_id_
	if not self.room_player_list_[player.guid] then
		self.cur_player_count_ = self.cur_player_count_ + 1
	end
	self.room_player_list_[player.guid] = player
end

function virtual_room:player_exit_room(player)
	player.room_id = nil
	if self.room_player_list_[player.guid] then
		self.cur_player_count_ = self.cur_player_count_ - 1
	end
	self.room_player_list_[player.guid] = false
end
