local pb = require "extern/lib/lib_pb"
require "game_script/handler_net"
local post_msg_to_client_pb = post_msg_to_client_pb
local post_msg_to_login_pb = post_msg_to_login_pb
require "game_script/virtual/virtual_player"
local virtual_player = virtual_player
require "game_script/virtual/virtual_room_mgr"
local room_manager = g_room_mgr
function handler_client_chat_world(player, msg)
	local chat = {
		chat_content = msg.chat_content,
		chat_guid = player.guid,
		chat_name = player.account,
	}
	room_manager:broadcast_msg_to_client_by_player("SC_ChatWorld", chat)
end
function handler_client_chat_private(player, msg)
	local chat = {
		chat_content =  msg.chat_content,
		private_guid = msg.private_name,
		chat_name = player.account,
	}
	post_msg_to_client_pb(player, "SC_ChatPrivate", chat)
	local target = virtual_player:find_by_account(msg.private_name)
	if target then
		post_msg_to_client_pb(target,  "SC_ChatPrivate", chat)
	else
		post_msg_to_login_pb("SC_ChatPrivate", chat)
	end
end
function on_sc_chat_private(msg)
	local target = virtual_player:find_by_account(msg.private_name)
	if target then
		post_msg_to_client_pb(target,  "SC_ChatPrivate", msg)
	end
end
function handler_client_chat_server(player, msg)
	local chat = {
		chat_content = msg.chat_content,
		chat_guid = player.guid,
		chat_name = player.account,
	}
	room_manager:broadcast_msg_to_client_by_player("SC_ChatServer", chat)
end
function handler_client_chat_room(player, msg)
	local room = room_manager:find_room_by_player(player)
	if room then
		local chat = {
			chat_content = msg.chat_content,
			chat_guid = player.guid,
			chat_name = player.account,
		}
		room:broadcast_msg_to_client_by_player("SC_ChatRoom", chat)
	end
end
function handler_client_chat_table(player, msg)
	local tb = room_manager:get_user_table(player)
	if tb then
		local chat = {
			chat_content = msg.chat_content,
			chat_guid = player.guid,
			chat_name = player.account,
		}
		tb:broadcast_msg_to_client("SC_ChatTable", chat)
	end
end
