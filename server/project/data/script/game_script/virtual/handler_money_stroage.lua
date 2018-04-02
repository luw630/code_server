local pb = require "extern/lib/lib_pb"
require "game_script/handler_net"
local post_msg_to_client_pb = post_msg_to_client_pb
local post_msg_to_mysql_pb = post_msg_to_mysql_pb
require "game_script/virtual/virtual_player"
local virtual_player = virtual_player
local def_game_id = def_game_id
function handler_money_stroage_set_password(player, msg)
	if player.bank_password then
		post_msg_to_client_pb(player, "SC_BankSetPassword", {
			result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_PASSWORD_HAS_BEEN_SET"),
		})
		return
	end
	
	player.bank_password = true
	post_msg_to_client_pb(player, "SC_BankSetPassword", {
		result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS"),
	})
	
	post_msg_to_mysql_pb("SD_BankSetPassword", {
		guid = player.guid,
		password = msg.password,
	})
	
end
function handler_money_stroage_change_password(player, msg)
	if not player.bank_password then
		post_msg_to_client_pb(player, "SC_BankChangePassword", {
			result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_PASSWORD_IS_NOT_SET"),
		})
		return
	end
	
	post_msg_to_mysql_pb("SD_BankChangePassword", {
		guid = player.guid,
		old_password = msg.old_password,
		password = msg.password,
	})
	
end
function handler_mysql_bank_change_password(msg)
	local player = virtual_player:find(msg.guid)
	if not player then
		return
	end
	
	post_msg_to_client_pb(player, "SC_BankChangePassword", {
		result = msg.result,
	})
end
function handler_money_stroage_login(player, msg)
	if player.bank_login then
		post_msg_to_client_pb(player, "SC_BankLogin", {
			result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_ALREADY_LOGGED"),
		})
		return
	end
	
	post_msg_to_mysql_pb("SD_BankLogin", {
		guid = player.guid,
		password = msg.password,
	})
end
function handler_mysql_bank_login(msg)
	local player = virtual_player:find(msg.guid)
	if not player then
		return
	end
	if msg.result == pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS") then
		player.bank_login = true
	end
	post_msg_to_client_pb(player, "SC_BankLogin", {
			result = msg.result,
		})
end
local room_mgr = g_room_mgr
function handler_money_stroage_deposit(player, msg)
	----------------------------
	--handler_client_query_promotion(player)
---------------------------------
	
	if room_mgr:isPlay(player)  or (not room_mgr:can_bank_action(player)) then
		post_msg_to_client_pb(player, "SC_BankDeposit", {
			result = BANK_OPT_RESULT_FORBID_IN_GAMEING,
		})
		--log_error("handler_money_stroage_deposit error " .. player.guid)
		return
	end
	
	if not player.pb_base_info then
		log_error("handler_money_stroage_deposit error ,player.pb_base_info is nil, guid  " .. tostring(player.guid))
		return
	end
	local money_ = msg and msg.money or 0
	local money = player.pb_base_info.money
	
	if money_ <= 0 or money < money_ then
		post_msg_to_client_pb(player, "SC_BankDeposit", {
			result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_MONEY_ERR"),
		})
		return
	end
	
	player.pb_base_info.money = money - money_
	local bank = player.pb_base_info.bank
	player.pb_base_info.bank = bank + money_
	
	player.flag_base_info = true
	player:save()
	
	post_msg_to_client_pb(player, "SC_BankDeposit", {
		result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS"),
		money = money_,
	})
	
	post_msg_to_mysql_pb("SD_BankLog", {
		time = get_second_time(),
		guid = player.guid,
		nickname = player.nickname,
		phone = player.phone,
		opt_type = 0,
		money = money_,
		old_money = money,
		new_money = player.pb_base_info.money,
		old_bank = bank,
		new_bank = player.pb_base_info.bank,
		ip = player.ip,
	})
end
function handler_money_stroage_draw(player, msg)
	if room_mgr:isPlay(player) or (not room_mgr:can_bank_action(player)) then
		post_msg_to_client_pb(player, "SC_BankDraw", {
			result = BANK_OPT_RESULT_FORBID_IN_GAMEING,
		})
--		log_error("handler_money_stroage_draw error " .. player.guid)
		return
	end

	if player.pb_base_info == nil then
		log_error("handler_money_stroage_draw pb_base_info nil  error " .. player.guid)
		return
	end
	
	local money_ = msg and msg.money or 0
	local bank = player.pb_base_info.bank
	if money_ <= 0 or bank < money_ then
		post_msg_to_client_pb(player, "SC_BankDraw", {
			result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_MONEY_ERR"),
		})
		return
	end
	
	local money = player.pb_base_info.money
	player.pb_base_info.money = money + money_
	player.pb_base_info.bank = bank - money_
	
	player.flag_base_info = true
	player:save()
	
	post_msg_to_client_pb(player, "SC_BankDraw", {
		result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS"),
		money = money_,
	})
	
	post_msg_to_mysql_pb("SD_BankLog", {
		time = get_second_time(),
		guid = player.guid,
		nickname = player.nickname,
		phone = player.phone,
		opt_type = 1,
		money = money_,
		old_money = money,
		new_money = player.pb_base_info.money,
		old_bank = bank,
		new_bank = player.pb_base_info.bank,
		ip = player.ip,
	})
end
function handler_money_stroage_transfer(player, msg)
	if type(msg) ~= "table " then
		return
	end
	if msg.account == player.account then
		return
	end
	if not player.enable_transfer then
		return
	end
	
	local bank = player.pb_base_info.bank
	if msg.money <= 0 or bank < msg.money then
		post_msg_to_client_pb(player, "SC_BankTransfer", {
			result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_MONEY_ERR"),
		})
		return
	end
	
	player.pb_base_info.bank = bank - msg.money
	player.flag_base_info = true
	player:save()
		
	local target = virtual_player:find_by_account(msg.account)
	if target then 
		target.pb_base_info.bank = target.pb_base_info.bank + msg.money
		target.flag_base_info = true
		
		post_msg_to_client_pb(player, "SC_BankTransfer", {
			result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS"),
		})
		post_msg_to_client_pb(target, "SC_BankTransfer", {
			result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS"),
		})
	else 
		post_msg_to_login_pb("SD_BankTransfer", {
			guid = player.guid,
			time = get_second_time(),
			target = msg.account,
			money = msg.money,
			bank_balance = player.pb_base_info.bank,
			selfname = player.account,
			game_id = def_game_id,
		})
	end
end
function on_ls_bank_transfer_self(msg)
	post_msg_to_client_pb(msg.guid, "SC_BankTransfer", {
		result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS"),
	})
end
function on_ls_bank_transfer_target(msg)
	local target = virtual_player:find_by_account(msg.target)
	if not target then 
		return
	end
	target.pb_base_info.bank = target.pb_base_info.bank + msg.money
	target.flag_base_info = true
	post_msg_to_client_pb(target, "SC_BankTransfer", {
		result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS"),
	})
end
function handler_mysql_bank_transfer(msg)
	if msg.result == pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS") then
		local statement_ = pb.decode(msg.pb_statement[1], msg.pb_statement[2])
		
		post_msg_to_client_pb(statement_.guid, "SC_BankTransfer", {
			result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS"),
		})
		
	else
		local player = virtual_player:find(msg.guid)
		if not player then
			log_warning(string.format("handler_mysql_bank_transfer guid[%d] not find in game", msg.guid))
			return
		end
		
		player.pb_base_info.bank = player.pb_base_info.bank + msg.money
	
		player.flag_base_info = true
		
		post_msg_to_client_pb(player, "SC_BankTransfer", {
			result = msg.result,
		})
	end
end
function handler_money_stroage_transfer_by_guid(player, msg)
	if msg.guid == player.guid then
		return
	end
	if not player.enable_transfer then
		return
	end
	
	
	local bank = player.pb_base_info.bank
	if msg.money <= 0 or bank < msg.money then
		post_msg_to_client_pb(player, "SC_BankTransfer", {
			result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_MONEY_ERR"),
		})
		return
	end
	
	
	player.pb_base_info.bank = bank - msg.money
	player.flag_base_info = true
		
	local target = virtual_player:find(msg.guid)
	if target then 
		target.pb_base_info.bank = target.pb_base_info.bank + msg.money
		target.flag_base_info = true
		
		
		post_msg_to_client_pb(player, "SC_BankTransfer", {
			result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS"),
			money = -msg.money,
			bank = player.pb_base_info.bank,
		})
		
		post_msg_to_client_pb(target, "SC_BankTransfer", {
			result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS"),
			money = msg.money,
			bank = target.pb_base_info.bank,
		})
	else 
		
		post_msg_to_login_pb("S_BankTransferByGuid", {
			guid = player.guid,
			target_guid = msg.guid,
			money = msg.money,
			
		})
	end
end
function on_ls_bank_transfer_by_guid(msg)
	local player = virtual_player:find(msg.guid)
	if not player then 
		return
	end
	if msg.money > 0 then
		player.pb_base_info.bank = player.pb_base_info.bank + msg.money
		player.flag_base_info = true
	end
	post_msg_to_client_pb(player, "SC_BankTransfer", {
		result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS"),
		money = msg.money,
		bank = player.pb_base_info.bank,
	})
end
function handler_mysql_bank_transfer_by_guid(msg)
	local player = virtual_player:find(msg.guid)
	if not player then
		return
	end
	if msg.result == pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS") then
		post_msg_to_client_pb(player, "SC_BankTransfer", {
			result = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS"),
			money = -msg.money,
			bank = player.pb_base_info.bank,
		})
	else
		player.pb_base_info.bank = player.pb_base_info.bank + msg.money
		player.flag_base_info = true
		post_msg_to_client_pb(player, "SC_BankTransfer", {
			result = msg.result,
		})
	end
end
function handler_mysql_save_bank_statement(msg)
	local statement_ = pb.decode(msg.pb_statement[1], msg.pb_statement[2])
end
function handler_money_stroage_statement(player, msg)
	if player.b_bank_statement then
		return
	end
	player.b_bank_statement = true
	post_msg_to_mysql_pb("SD_BankStatement", {
		guid = player.guid,
		cur_serial = (msg and msg.cur_serial or 0),
	})
end
function handler_mysql_bank_statement(msg)
	local player = virtual_player:find(msg.guid)
	if not player then
		return
	end
	for i, v in ipairs(msg.pb_statement) do
		msg.pb_statement[i] = pb.decode(v[1], v[2])
	end
	post_msg_to_client_pb(player, "SC_BankStatement", {
		pb_statement = msg.pb_statement,
	})
end
