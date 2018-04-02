local pb = require "extern/lib/lib_pb"
require "game_script/handler_net"
local post_msg_to_client_pb = post_msg_to_client_pb
local post_msg_to_mysql_pb = post_msg_to_mysql_pb
local newplayer_rewardmoney = 300
require "game_script/virtual/virtual_player"

	
local relief_payment_money = 2000			
local relief_payment_money_limit = 1000		
local relief_payment_count_limit = 5		
function handler_client_request_award(player, msg)
	if true then 
		log_error(string.format("error handler_client_request_award player[%d]",player.guid))
		return
	end
	if player.pb_base_info.newplayer_reward == 2 then
			post_msg_to_client_pb(player, "SC_RequestNewAward", {
			newaward_result = 2,
		})
		return
	end
	player.pb_base_info.newplayer_reward = 2 
	player:change_money(newplayer_rewardmoney, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_REWARD_LOGIN"), true)
	post_msg_to_client_pb(player, "SC_RequestNewAward", {
 		newaward_result = 1,
 		money = newplayer_rewardmoney,
 	})
end

function handler_client_receive_reward_online(player, msg)
	if true then 
		log_error(string.format("error handler_client_receive_reward_online player[%d]",player.guid))
		return
	end
	local award = data_online[player.pb_base_info.online_award_num + 1]
	if not award then
		post_msg_to_client_pb(player, "SC_RequestNewAward", {
			result = 3,
		})
		return
	end
	
	if award.money <= 0 then
		post_msg_to_client_pb(player, "SC_ReceiveRewardOnline", {
			result = pb.get_ev("RECEIVE_REWARD_RESULT", "RECEIVE_REWARD_RESULT_ERR_MONEY"),
		})
		return
	end
	
	if player.pb_base_info.online_award_time + get_second_time() - player.online_award_start_time < award.cd then
		post_msg_to_client_pb(player, "SC_ReceiveRewardOnline", {
			result = pb.get_ev("RECEIVE_REWARD_RESULT", "RECEIVE_REWARD_RESULT_ERR_ONLINE_AWARD_CD"),
		})
		return
	end
	local oldbank = player.pb_base_info.bank
	player.pb_base_info.bank = player.pb_base_info.bank + award.money
	player.pb_base_info.online_award_time = 0
	player.pb_base_info.online_award_num = player.pb_base_info.online_award_num + 1
	
	player.flag_base_info = true
	player:save()
	
	player.online_award_start_time = get_second_time()
	
	post_msg_to_client_pb(player, "SC_ReceiveRewardOnline", {
		result = pb.get_ev("RECEIVE_REWARD_RESULT", "RECEIVE_REWARD_RESULT_SUCCESS"),
		money = award.money,
	})
	
	post_msg_to_mysql_pb("SD_UpdateEarnings", {
		guid = player.guid,
		money = award.money,
	})
	
	post_msg_to_mysql_pb("SD_LogMoney", {
		guid = player.guid,
		old_money = player.pb_base_info.money,
		new_money = player.pb_base_info.money,
		old_bank = oldbank,
		new_bank = player.pb_base_info.bank,
		opt_type = pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_REWARD_ONLINE"),
	})
end
function handler_client_receive_relief_payment(player, msg)
	if true then 
		log_error(string.format("error handler_client_receive_relief_payment player[%d]",player.guid))
		return
	end
	if player.pb_base_info.relief_payment_count >= relief_payment_count_limit then
		post_msg_to_client_pb(player, "SC_ReceiveReliefPayment", {
			result = pb.get_ev("RECEIVE_REWARD_RESULT", "RECEIVE_REWARD_RESULT_ERR_COUNT_LIMIT"),
		})
		return
	end
	
	if player.pb_base_info.money +  player.pb_base_info.bank >= relief_payment_money_limit then
		post_msg_to_client_pb(player, "SC_ReceiveReliefPayment", {
			result = pb.get_ev("RECEIVE_REWARD_RESULT", "RECEIVE_REWARD_RESULT_ERR_COUNT_LIMIT"),
		})
		return
	end
	
	local oldbank = player.pb_base_info.bank
	player.pb_base_info.bank = player.pb_base_info.bank + relief_payment_money
	player.pb_base_info.relief_payment_count = player.pb_base_info.relief_payment_count + 1
	
	player.flag_base_info = true
	player:save()
	
	post_msg_to_client_pb(player, "SC_ReceiveReliefPayment", {
		result = pb.get_ev("RECEIVE_REWARD_RESULT", "RECEIVE_REWARD_RESULT_SUCCESS"),
		money = relief_payment_money,
	})
	
	post_msg_to_mysql_pb("SD_UpdateEarnings", {
		guid = player.guid,
		money = relief_payment_money,
	})
	
	post_msg_to_mysql_pb("SD_LogMoney", {
		guid = player.guid,
		old_money = player.pb_base_info.money,
		new_money = player.pb_base_info.money,
		old_bank = oldbank,
		new_bank = player.pb_base_info.bank,
		opt_type = pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_RELIEF_PAYMENT"),
	})
end
