local pb = require "extern/lib/lib_pb"
pb.register_file("../data/opcode/public_enum.proto")
pb.register_file("../data/opcode/public_player.proto")
pb.register_file("../data/opcode/public_msg.proto")
pb.register_file("../data/opcode/login.proto")
pb.register_file("../data/opcode/redis.proto")
pb.register_file("../data/opcode/config.proto")
pb.register_file("../data/opcode/server.proto")
require "mysql_db/handler_in_out_action"
require "mysql_db/handler_money_stroage"
require "mysql_db/handler_log"


local show_log = not (b_register_dispatcher_hide_log or false)
function on_server_dispatcher(server_id, func, msgname, stringbuffer)
	local f = _G[func]
	assert(f, string.format("on_server_dispatcher func:%s", func))
	local msg = nil
	if stringbuffer ~= "" then
		msg = pb.decode(msgname, stringbuffer)
	end
	f(msg)
end
function on_gameserver_dispatcher(server_id, func, msgname, stringbuffer)
	local f = _G[func]
	assert(f, string.format("on_gameserver_dispatcher func:%s", func))
	local msg = nil
	if stringbuffer ~= "" then
		msg = pb.decode(msgname, stringbuffer)
	end
	f(server_id, msg)
end
function on_loginserver_dispatcher(server_id, func, msgname, stringbuffer)
	local f = _G[func]
	assert(f, string.format("on_loginserver_dispatcher func:%s", func))
	local msg = nil
	if stringbuffer ~= "" then
		msg = pb.decode(msgname, stringbuffer)
	end
	f(server_id, msg)
end
function on_cfgserver_dispatcher(server_id, func, msgname, stringbuffer)
	local f = _G[func]
	assert(f, string.format("on_cfgserver_dispatcher func:%s", func))
	local msg = nil
	if stringbuffer ~= "" then
		msg = pb.decode(msgname, stringbuffer)
	end
	--f(server_id, msg)
	f(msg)
end


local function register_game_dispatcher(msgname, func)
	local id = pb.get_ev(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s, func:%s", msgname, func))
	reg_game_dispatcher(msgname, id, func, "on_gameserver_dispatcher", show_log)
end
local function login_handler_reg(msgname, func)
	local id = pb.get_ev(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s, func:%s", msgname, func))
	reg_login_dispatcher(msgname, id, func, "on_loginserver_dispatcher", show_log)
end
local function cfg_handler_reg(msgname, func)
	local id = pb.get_ev(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s, func:%s", msgname, func))
	reg_cfg_dispatcher(msgname, id, func, "on_cfgserver_dispatcher", show_log)
end

b_register_dispatcher_hide_log = true


cfg_handler_reg("FD_GetPlayerInfo", "handler_cfg_get_player_info")

login_handler_reg("SD_BankTransfer", "handler_mysql_bank_transfer")
login_handler_reg("S_BankTransferByGuid", "on_s_bank_transfer_by_guid")

register_game_dispatcher("SD_Delonline_player", "handler_mysql_delonline_player")
register_game_dispatcher("SD_OnlineAccount", "handler_mysql_OnlineAccount")
register_game_dispatcher("S_Logout", "on_s_logout")
register_game_dispatcher("SD_QueryPlayerMsgData","handler_mysql_query_player_msg")
register_game_dispatcher("SD_QueryPlayerMarquee","handler_mysql_query_player_marquee")
register_game_dispatcher("SD_SetMsgReadFlag","handler_mysql_Set_Msg_Read_Flag")
register_game_dispatcher("SD_QueryPlayerData", "handler_mysql_query_player_data")
register_game_dispatcher("SD_SavePlayerData", "handler_mysql_save_player_data")
register_game_dispatcher("SD_SavePlayerMoney", "handler_mysql_SavePlayerMoney")
register_game_dispatcher("SD_SavePlayerBank", "handler_mysql_SavePlayerBank")
register_game_dispatcher("SD_BankSetPassword", "handler_mysql_bank_set_password")
register_game_dispatcher("SD_BankChangePassword", "handler_mysql_bank_change_password")
register_game_dispatcher("SD_BankLogin", "handler_mysql_bank_login")
register_game_dispatcher("SD_BankTransfer", "handler_mysql_bank_transfer")
register_game_dispatcher("SD_SaveBankStatement", "handler_mysql_save_bank_statement")
register_game_dispatcher("SD_BankStatement", "handler_mysql_bank_statement")
register_game_dispatcher("SD_BankLog", "handler_mysql_BankLog")
register_game_dispatcher("SD_SendMail", "handler_mysql_send_mail")
register_game_dispatcher("SD_DelMail", "handler_mysql_del_mail")
register_game_dispatcher("SD_ReceiveMailAttachment", "handler_mysql_receive_mail_attachment")
register_game_dispatcher("SD_LogMoney", "handler_mysql_log_money")
register_game_dispatcher("SD_LoadAndroidData", "handler_mysql_load_android_data")
login_handler_reg("LD_NewNotice","on_ld_NewNotice")
login_handler_reg("LD_DelMessage","on_ld_DelMessage")
login_handler_reg("LD_AlipayEdit","on_ld_AlipayEdit")
register_game_dispatcher("SD_CashMoneyType", "handler_mysql_cash_money_type")
register_game_dispatcher("SD_CashMoney", "handler_mysql_cash_money")
register_game_dispatcher("SD_Agent_CashMoney", "handler_mysql_agent_cash_money")
register_game_dispatcher("SD_SavePlayerOxData", "handler_mysql_save_player_Ox_data")
register_game_dispatcher("SL_Log_Money","on_sl_log_money")
register_game_dispatcher("SD_QueryOxConfigData", "handler_mysql_query_Ox_config_data")
register_game_dispatcher("SL_Log_Game","on_sl_log_Game")
register_game_dispatcher("SL_Channel_Invite_Tax","on_sl_channel_invite_tax")
register_game_dispatcher("SD_QueryPlayerInviteReward","handler_mysql_query_player_invite_reward")
register_game_dispatcher("SD_QueryChannelInviteCfg","handler_mysql_query_channel_invite_cfg")
register_game_dispatcher("SD_QueryRobotCfg","handler_mysql_query_robot_cfg")
register_game_dispatcher("SD_QueryBrnnChiCfg","handler_mysql_query_brnn_chi_cfg")
register_game_dispatcher("SD_Save_Storage","handler_mysql_save_storage")
register_game_dispatcher("SD_UpdateGameTotalTax","handler_mysql_update_game_total_tax")
register_game_dispatcher("SD_QueryPlayerPromotion","handler_mysql_query_playerpromotion")
register_game_dispatcher("SD_NotifyPhpServer","handler_mysql_notify_php")
register_game_dispatcher("SD_QueryPlayerRecharge","handler_mysql_query_player_recharge")



login_handler_reg("LD_AgentsTransfer_finish","on_ld_AgentTransfer_finish")
login_handler_reg("LD_CC_ChangeMoney","on_ld_cc_changemoney")
register_game_dispatcher("SL_Log_Robot_Money","on_sl_robot_log_money")
login_handler_reg("LD_DO_SQL","on_ld_do_sql")
register_game_dispatcher("SD_PrivateRoomLog","handler_mysql_PrivateRoomLog")
register_game_dispatcher("SD_FilishPrivateRoomLog","handler_mysql_FilishPrivateRoomLog")
register_game_dispatcher("SD_StartPrivateRoomLog","handler_mysql_StartPrivateRoomLog")
register_game_dispatcher("SD_Do_OneSql","handler_mysql_Do_OneSql")
login_handler_reg("SD_Do_OneSql","handler_mysql_Do_OneSql")


