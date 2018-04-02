local pb = require "extern/lib/lib_pb"

function post_msg_to_mysql_pb(msgname, msg)
	local id = pb.get_ev(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end

	if msgname == "SD_SavePlayerData" or msgname == "SD_SavePlayerBank" or msgname == "SD_SavePlayerMoney" then
		send2db_game_only(id, stringbuffer)
		if msgname == "SD_SavePlayerData" and msg.guid ~= nil and msg.pb_base_info ~= nil and msg.pb_base_info.money ~= nil 
		and msg.pb_base_info.bank ~= nil then
			post_msg_to_cfg_pb("GF_SavePlayerInfo", {info = {guid = msg.guid,money = msg.pb_base_info.money,bank = msg.pb_base_info.bank}}) 
		elseif msgname == "SD_SavePlayerBank" and msg.guid ~= nil and msg.bank ~= nil then
			post_msg_to_cfg_pb("GF_SavePlayerInfo", {info = {guid = msg.guid,money = -1000,bank = msg.bank}}) 
		elseif msgname == "SD_SavePlayerMoney" and msg.guid ~= nil and msg.money ~= nil then
			post_msg_to_cfg_pb("GF_SavePlayerInfo", {info = {guid = msg.guid,money = msg.money,bank = -1000}}) 
		else
			log_error("unkown error")
		end
	else
		send2db(id, stringbuffer)
	end
end

function post_msg_to_cfg_pb(msgname, msg)
	local id = pb.get_ev(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end
	
	send2cfg(id, stringbuffer)
end

function get_msg_id_str(msgname, msg)
	
	local id = pb.get_ev(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end

	return id, stringbuffer
end

function post_msg_to_client_pb_str(player_or_guid, msgid, msg_str)
	local player = player_or_guid
	if type(player) ~= "table" then
		player = virtual_player:find(player_or_guid)
		if not player then
			log_warning("game[post_msg_to_client_pb] not find player:" .. player_or_guid)
			return
		end
	end

	if player.is_android or not player.is_player then
		--print("----player is robot,post_msg_to_client_pb return")
		return
	end

	if not player.online then
		print(string.format("game[post_msg_to_client_pb] offline, guid:%d  msgid:%d",player.guid,msgid))
		return
	end

	send2client(player.guid, player.gate_id, msgid, msg_str)
end

function post_msg_to_client_pb(player_or_guid, msgname, msg)
	local player = player_or_guid
	if type(player) ~= "table" then
		player = virtual_player:find(player_or_guid)
		if not player then
			log_warning("game[post_msg_to_client_pb] not find player:" .. player_or_guid)
			return
		end
	end
	--log_info(string.format("send to player %d %s",player.guid,msgname))

	if player.is_android or not player.is_player then
		return
	end

	if not player.online then
		return
	end


	local id = pb.get_ev(msgname .. ".MsgID", "ID")

	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end
	
	send2client(player.guid, player.gate_id, id, stringbuffer)
end

function post_msg_to_client_login(session_id, gate_id, msgname, msg)
	local id = pb.get_ev(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end
	
	send2client(session_id, gate_id, id, stringbuffer)
end

function post_msg_to_login_pb(msgname, msg)
	local id = pb.get_ev(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end
	
	send2login(id, stringbuffer)
end


function post_msg_to_login_id_pb(server_id, msgname, msg)
	local id = pb.get_ev(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end
	
	send2login_id(server_id, id, stringbuffer)
end

