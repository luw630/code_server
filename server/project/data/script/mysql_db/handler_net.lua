local pb = require "extern/lib/lib_pb"

function post_msg_to_game_pb(game_id, msgname, msg)
	local id = pb.get_ev(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end
	
	game_id = game_id or 0
	if game_id == 0 then
		--print( debug.traceback() )
	end
	send2game(game_id, id, stringbuffer)
end

function post_msg_to_login_pb(login_id, msgname, msg)
	local id = pb.get_ev(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end
	
	send2login(login_id, id, stringbuffer)
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