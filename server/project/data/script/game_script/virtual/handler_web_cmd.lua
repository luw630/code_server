local pb = require "extern/lib/lib_pb"
require "game_script/virtual/virtual_room_mgr"
local room_manager = g_room_mgr
require "game_script/virtual/virtual_player"
local virtual_player = virtual_player
local def_game_id = def_game_id
require "game_script/handler_net"
local post_msg_to_client_pb = post_msg_to_client_pb
local post_msg_to_mysql_pb = post_msg_to_mysql_pb
local post_msg_to_login_id_pb = post_msg_to_login_id_pb
function gm_change_money(guid,money,log_type)
    local player = virtual_player:find(guid)
	if not player then
			return
	end
    player:change_money(money, log_type or pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_GM"))
	post_msg_to_mysql_pb("SD_SavePlayerData", {
		guid = guid,
		pb_base_info = player.pb_base_info,		
	})
end
function gm_change_bank_money(guid,money,log_type)
    local player = virtual_player:find(guid)
	if not player then
	
		return
	end
    player:change_bank(money,log_type or pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_GM"))
	post_msg_to_mysql_pb("SD_SavePlayerData", {
		guid = guid,
		pb_base_info = player.pb_base_info,
	})
end
function gm_change_bank(web_id_, login_id, guid, money, log_type)
	local player = virtual_player:find(guid)
	if not player then
		
		post_msg_to_login_id_pb(login_id, "SL_LuaCmdPlayerResult", {
	    	web_id = web_id_,
	    	result = 0,
	    	})
		return
	end
	
    player:change_bank(money, log_type or pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_GM"), true)
    post_msg_to_login_id_pb(login_id, "SL_LuaCmdPlayerResult", {
    	web_id = web_id_,
    	result = 1,
    	})
end
--渠道追款
function gm_channel_zk_bank(web_id_, login_id, guid, money, log_type)
	if money > 0 then
		post_msg_to_login_id_pb(login_id, "SL_LuaCmdPlayerResult", {
	    	web_id = web_id_,
	    	result = 0,
			})
		log_warning(string.format("channel_zk error guid[%d] money[%d] ", guid, money))	
		return
	end
	local player = virtual_player:find(guid)
	if not player then
		post_msg_to_login_id_pb(login_id, "SL_LuaCmdPlayerResult", {
	    	web_id = web_id_,
	    	result = 0,
			})
		log_warning(string.format("channel_zk guid[%d] money[%d] not find in game=%d", guid, money, def_game_id))	
		return
	end
	
	local ret = player:change_bank(money, log_type or pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CHANNEL_ZK"), true)
	local ret_msg = {
    	web_id = web_id_,
    	result = 1,
		}
	if not ret then ret_msg.result = 2 end
	post_msg_to_login_id_pb(login_id, "SL_LuaCmdPlayerResult", ret_msg)
	log_info(string.format("channel_zk guid[%d] money[%d] result[%d]", guid, money, ret_msg.result))	
end
function gm_broadcast_client(json_str)
	local msg = {
		update_info = json_str
	}
	virtual_player:broadcast_msg_to_client_pb("SC_BrocastClientUpdateInfo", msg)
end
function gm_set_slotma_rate(guid,count)
    local player = virtual_player:find(guid)
	if not player then
		log_warning(string.format("guid[%d] not find in game=%d", guid, def_game_id))
		return
	end
    
	player.pb_base_info.slotma_addition = count
	player.flag_base_info = true
	post_msg_to_mysql_pb("SD_SavePlayerData", {
		guid = guid,
		pb_base_info = player.pb_base_info,
	})
end
