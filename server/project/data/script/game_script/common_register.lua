local pb = require "extern/lib/lib_pb"
pb.register_file("../data/opcode/public_enum.proto")
pb.register_file("../data/opcode/public_player.proto")
pb.register_file("../data/opcode/public_msg.proto")
pb.register_file("../data/opcode/login.proto")
pb.register_file("../data/opcode/redis.proto")
pb.register_file("../data/opcode/config.proto")
pb.register_file("../data/opcode/server.proto")
local GAME_READY_MODE_NONE = pb.get_ev("GAME_READY_MODE", "GAME_READY_MODE_NONE")
local GAME_READY_MODE_ALL = pb.get_ev("GAME_READY_MODE", "GAME_READY_MODE_ALL")
local GAME_READY_MODE_PART = pb.get_ev("GAME_READY_MODE", "GAME_READY_MODE_PART")
local def_game_id = def_game_id
local print_r = require "extern/lib//lib_print_r"
require "extern/lib/lib_table"


local function get_game_cfg()
	local cfg = get_gameserver_config()
	if cfg then
		return parse_table(cfg)
	end
	error(string.format("get_game_cfg failed,game id = %d", def_game_id))
end
local game_cfg_ = get_game_cfg()

local function get_game_lua_cfg()
	local json = get_gameserver_room_lua_cfg()
	return json;
end
local game_lua_cfg_ = get_game_lua_cfg()


function func_get_robot_count()
	local rc = 0
	for i,v in pairs(ly_robot_mgr.robot_list) do
		if v then rc = rc + 1 end
	end
	return rc
end
function func_get_niuniu_banker_count()
	return ly_niuniu_banker_times --???????? ??
end
function func_get_android_online_count()
	return ly_android_online_count
end
function func_get_ios_online_count()
	return ly_ios_online_count
end



local function load_game_info_01()
	if def_game_name == "lobby" then
		require "game_script/virtual/virtual_room_mgr"
		g_room_mgr = virtual_room_mgr:new()
		g_room_mgr:init(game_cfg_, 2, GAME_READY_MODE_NONE, game_lua_cfg_)
	elseif def_game_name == "fishing" then
		pb.register_file("../data/opcode/public_fishing.proto")
		require "game_script/all_game/fishing_room_mgr"
		g_room_mgr = fishing_room_mgr:new()
		g_room_mgr:init(game_cfg_, 4, GAME_READY_MODE_ALL, game_lua_cfg_)
	elseif def_game_name == "land" then
		pb.register_file("../data/opcode/public_land.proto")
		require "game_script/all_game/ddz_room_mgr"
		g_room_mgr = ddz_room_mgr:new()
		g_room_mgr:init(game_cfg_, 3, GAME_READY_MODE_ALL, game_lua_cfg_)
	elseif def_game_name == "zhajinhua" then
		pb.register_file("../data/opcode/public_zhajinhua.proto")
		require "game_script/all_game/zjh_room_mgr"
		g_room_mgr = zjh_room_mgr:new()
		g_room_mgr:init(game_cfg_, g_zjh_tb_maxplayernum, GAME_READY_MODE_PART, game_lua_cfg_)
	elseif def_game_name == "ox" then
		pb.register_file("../data/opcode/public_ox.proto")
		require "game_script/all_game/brnn_room_mgr"
		g_room_mgr = brnn_room_mgr:new()
		g_room_mgr:init(game_cfg_, 100, GAME_READY_MODE_ALL, game_lua_cfg_)
		func_get_robot_count = function()
			local rc = 0
			for i,room in ipairs(g_room_mgr.room_list_) do
				for j,t in pairs(room.table_list_) do
					for k,player in pairs(t.ox_game_player_list) do
						if player and player.is_player == false then --机器人
							rc = rc + 1
						end
					end
				end
			end
			return rc
		end
	elseif def_game_name == "banker_ox" then
		pb.register_file("../data/opcode/public_banker.proto")
		require "game_script/all_game/qznn_room_mgr"
		g_room_mgr = qznn_room_mgr:new()
		g_room_mgr:init(game_cfg_, 5, GAME_READY_MODE_ALL, game_lua_cfg_)
	elseif def_game_name == "classic_ox" then
		pb.register_file("../data/opcode/public_banker.proto")
		require "game_script/all_game/qznn_room_mgr"
		g_room_mgr = qznn_room_mgr:new()
		g_room_mgr:init(game_cfg_, 5, GAME_READY_MODE_ALL, game_lua_cfg_)
	elseif def_game_name == "slotma" then
		pb.register_file("../data/opcode/common_msg_slotma.proto")
		require "game_script/lhj/lhj_room_manager"
		g_room_mgr = slotma_room_manager:new()
		g_room_mgr:init(game_cfg_, 1, GAME_READY_MODE_ALL, game_lua_cfg_)
	elseif def_game_name == "showhand" then
		pb.register_file("../data/opcode/public_showhand.proto")
		require "game_script/all_game/showhand_room_mgr"
		g_room_mgr = showhand_room_mgr:new()
		g_room_mgr:init(game_cfg_, 2, GAME_READY_MODE_ALL, game_lua_cfg_)
	elseif def_game_name == "texas" then
		pb.register_file("../data/opcode/public_texas.proto")
		require "game_script/all_game/texas_room_mgr"
		g_room_mgr = texas_room_mgr:new()
		g_room_mgr:init(game_cfg_, 7, GAME_READY_MODE_ALL, game_lua_cfg_)
	elseif def_game_name == "point21" then
		pb.register_file("../data/opcode/public_point21.proto")
		require "game_script/all_game/point21_room_mgr"
		g_room_mgr = point21_room_mgr:new()
		g_room_mgr:init(game_cfg_, 6, GAME_READY_MODE_PART, game_lua_cfg_)
	elseif def_game_name == "sangong" then
		pb.register_file("../data/opcode/public_sangong.proto")
		require "game_script/all_game/sangong_room_mgr"
		g_room_mgr = sangong_room_mgr:new()
		g_room_mgr:init(game_cfg_, 5, GAME_READY_MODE_PART, game_lua_cfg_)
	elseif def_game_name == "hongheidz" then
		pb.register_file("../data/opcode/public_hhdz.proto")
		require "game_script/all_game/hhdz_room_mgr"
		g_room_mgr = hhdz_room_mgr:new()
		g_room_mgr:init(game_cfg_, 1000, GAME_READY_MODE_ALL, game_lua_cfg_)
	elseif def_game_name == "longhudz" then
		pb.register_file("../data/opcode/public_lhdz.proto")
		require "game_script/all_game/longhu_room_mgr"
		g_room_mgr = longhu_room_mgr:new()
		g_room_mgr:init(game_cfg_, 1000, GAME_READY_MODE_ALL, game_lua_cfg_)
	end
end
load_game_info_01()

function handler_mysql_connected()
	local function load_data_function()
		post_msg_to_mysql_pb("SD_QueryChannelInviteCfg", {})
		post_msg_to_mysql_pb("SD_QueryRobotCfg", {game_id = def_game_id})
		if def_first_game_type == 8 then
			post_msg_to_mysql_pb("SD_QueryBrnnChiCfg", {game_id = def_game_id})
		end

		post_msg_to_mysql_pb("SD_Do_OneSql",{db_name = "game",sql = string.format("UPDATE t_game_maintain_cfg set `open` = %d WHERE game_id=%d and first_game_type = %d and second_game_type=%d",
			1,def_game_id,def_first_game_type,def_second_game_type)})

		--post_msg_to_cfg_pb("WS_MaintainUpdate",{id_index = 2,first_game_type = def_first_game_type,switchopen = 0})
		post_msg_to_login_pb("WS_MaintainUpdate",{id_index = 2,first_game_type = def_first_game_type,switchopen = 0})

		post_msg_to_mysql_pb("SD_UpdateGameTotalTax", {
			game_id = def_game_id,
			first_game_type = def_first_game_type,
			second_game_type = def_second_game_type,
			tax_add = 0
		})

		post_msg_to_cfg_pb("WS_MaintainUpdate",{id_index = 4})
		post_msg_to_cfg_pb("WS_MaintainUpdate",{id_index = 5})
	end
	add_timer(4, load_data_function) --????  ??db????????
	add_timer(2,on_load_notifylist)
end
function on_gm_update_cfg()
	local tb = get_game_cfg()
	g_room_mgr:gm_update_cfg(tb)
end

function g_get_game_cfg()
    return get_game_cfg()
end

function on_load_notifylist( ... )
	--log_info("on_load_notifylist")
	-- local  obj=io.popen("cd")
	-- path=obj:read("*all"):sub(1,-2) --path存放当前路径
	-- obj:close() --关掉句柄
	-- log_info(path)

	g_notify_list = {}
	local file = io.open("..//data//notice.txt","r")
	if file ~= nil then
		for c in file:lines() do 
			g_notify_list[tonumber(c)] = 1
		end
	end
	io.close(file)
	add_timer(60,on_load_notifylist)
end



require "game_script/virtual/virtual_player"
local virtual_player = virtual_player


require "game_script/virtual/handler_in_out_action"
require "game_script/virtual/handler_money_stroage"
require "game_script/virtual/handler_award"
require "game_script/virtual/handler_room"
require "game_script/virtual/handler_chat"
require "game_script/virtual/handler_mail"
require "game_script/virtual/handler_money_action"



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

function on_client_dispatcher(guid, func, msgname, stringbuffer)
	local player = virtual_player:find(guid)
	if not player then
		return
	end
	local f = _G[func]
	assert(f, string.format("on_client_dispatcher func:%s", func))
	local msg = nil
	if stringbuffer ~= "" then
		msg = pb.decode(msgname, stringbuffer)
	end
	f(player, msg)
end
function db_handler_reg(msgname, func)
	local id = pb.get_ev(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s, func:%s", msgname, func))
	reg_db_dispatcher(msgname, id, func, "on_server_dispatcher", show_log)
end
local db_handler_reg = db_handler_reg
function login_handler_reg(msgname, func)
	local id = pb.get_ev(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s, func:%s", msgname, func))
	reg_login_dispatcher(msgname, id, func, "on_server_dispatcher", show_log)
end
local login_handler_reg = login_handler_reg
function client_handler_reg(msgname, func)
	local id = pb.get_ev(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s, func:%s", msgname, func))
	reg_gate_dispatcher(msgname, id, func, "on_client_dispatcher", show_log)
end
function cfg_handler_reg(msgname, func)
	local id = pb.get_ev(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s, func:%s", msgname, func))
	reg_cfg_dispatcher(msgname, id, func, "on_server_dispatcher", show_log)
end
function gate_handler_reg(msgname, func)
	local id = pb.get_ev(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s, func:%s", msgname, func))
	reg_gate_server_dispatcher(msgname, id, func, "on_server_dispatcher", show_log)
end
local client_handler_reg = client_handler_reg
b_register_dispatcher_hide_log = true

	
cfg_handler_reg("FS_ChangeGameCfg", "on_fs_chang_config")
cfg_handler_reg("FS_ChangeRobotCfg", "on_fs_chang_robot_cfg")
cfg_handler_reg("CS_QueryMaintain", "handler_client_change_maintain")
cfg_handler_reg("S_ReplyPrivateRoomConfig", "on_S_ReplyPrivateRoomConfig")
cfg_handler_reg("SS_JoinPrivateRoom", "on_SS_JoinPrivateRoom")
cfg_handler_reg("FS_Black_List", "handler_cfg_black_list")
cfg_handler_reg("SW_MaintainResult","handler_cfg_query_cashswich")


db_handler_reg("DS_LoadPlayerData", "handler_mysql_load_player_data")
db_handler_reg("DS_ResetAccount", "handler_mysql_reset_account")
db_handler_reg("DS_SetPassword", "handler_mysql_set_password")
db_handler_reg("DS_SetNickname", "handler_mysql_set_nickname")
db_handler_reg("DS_BankChangePassword", "handler_mysql_bank_change_password")
db_handler_reg("DS_BankLogin", "handler_mysql_bank_login")
db_handler_reg("DS_BankTransfer", "handler_mysql_bank_transfer")
db_handler_reg("DS_BankTransferByGuid", "handler_mysql_bank_transfer_by_guid")
db_handler_reg("DS_SaveBankStatement", "handler_mysql_save_bank_statement")
db_handler_reg("DS_BankStatement", "handler_mysql_bank_statement")
db_handler_reg("DES_SendMail", "on_des_send_mail")
db_handler_reg("DS_LoadAndroidData", "handler_mysql_load_android_data")
db_handler_reg("DS_QueryPlayerMsgData", "handler_mysql_QueryPlayerMsgData")
db_handler_reg("DS_QueryPlayerMarquee", "handler_mysql_QueryPlayerMarquee")
db_handler_reg("DS_CashMoneyType", "handler_mysql_cash_money_type")
db_handler_reg("DS_CashMoney", "handler_mysql_cash_money")
db_handler_reg("DS_BandAlipay", "handler_mysql_bandalipay")
db_handler_reg("DS_BandAlipayNum", "handler_mysql_bandalipaynum")
--db_handler_reg("DS_OxConfigData", "handler_mysql_LoadOxConfigData")
db_handler_reg("DS_ServerConfig", "handler_mysql_server_config")
db_handler_reg("DS_QueryPlayerInviteReward", "handler_mysql_load_player_invite_reward")
db_handler_reg("DS_QueryChannelInviteCfg", "handler_mysql_load_channel_invite_cfg")
db_handler_reg("DS_QueryRobotCfg", "handler_mysql_load_robot_cfg")
db_handler_reg("DS_QueryBrnnChiCfg", "handler_mysql_load_brnn_chi_cfg")
db_handler_reg("DS_BindBankCard", "handler_mysql_bind_bank_card")
db_handler_reg("DS_GetBankCardInfo", "handler_mysql_get_bank_card_info")
db_handler_reg("DS_QueryPlayerPromotion", "handler_mysql_load_playerpromotion")
db_handler_reg("DS_QueryPlayerRecharge", "handler_mysql_query_player_recharge")


--------------------------------------------------------------------
login_handler_reg("LS_LoginNotify", "on_ls_login_notify")
login_handler_reg("S_Logout", "on_s_logout")
login_handler_reg("SS_ChangeGame", "on_ss_change_game")
login_handler_reg("LS_ChangeGameResult", "on_LS_ChangeGameResult")
login_handler_reg("LS_BankTransferSelf", "on_ls_bank_transfer_self")
login_handler_reg("LS_BankTransferTarget", "on_ls_bank_transfer_target")
login_handler_reg("LS_BankTransferByGuid", "on_ls_bank_transfer_by_guid")
login_handler_reg("LS_LoginNotifyAgain", "on_ls_login_notify_again")
login_handler_reg("LS_NewNotice", "on_new_nitice")
login_handler_reg("LS_DelMessage", "on_ls_DelMessage")
login_handler_reg("LS_ChangeTax", "on_ls_set_tax")
login_handler_reg("LS_AlipayEdit","on_ls_AlipayEdit")
login_handler_reg("LS_CC_ChangeMoney", "on_ls_cc_changemoney")
login_handler_reg("LS_FreezeAccount", "on_ls_FreezeAccount")
login_handler_reg("LS_AddMoney", "on_ls_addmoney")
login_handler_reg("LS_LuaGameCmd", "on_ls_lua_game_cmd")
login_handler_reg("CS_QueryMaintain", "handler_client_change_maintain")

--------------------------------------------------------------------
client_handler_reg("CS_RequestPlayerInfo", "handler_client_request_player_info")
client_handler_reg("CS_LoginValidatebox", "handler_client_login_validatebox")
client_handler_reg("CS_ChangeGame", "handler_client_change_game")
client_handler_reg("CS_JoinPrivateRoom", "handler_client_JoinPrivateRoom")
client_handler_reg("CS_PrivateRoomInfo", "handler_client_PrivateRoomInfo")
client_handler_reg("CS_ResetAccount", "handler_client_reset_account")
client_handler_reg("CS_SetPassword", "handler_client_set_password")
client_handler_reg("CS_SetPasswordBySms", "handler_client_set_password_by_sms")
client_handler_reg("CS_SetNickname", "handler_client_set_nickname")
client_handler_reg("CS_ChangeHeaderIcon", "handler_client_change_header_icon")
client_handler_reg("CS_BankSetPassword", "handler_money_stroage_set_password")
client_handler_reg("CS_BankChangePassword", "handler_money_stroage_change_password")
client_handler_reg("CS_BankLogin", "handler_money_stroage_login")
client_handler_reg("CS_BankDeposit", "handler_money_stroage_deposit")
client_handler_reg("CS_BankDraw", "handler_money_stroage_draw")
client_handler_reg("CS_BankTransfer", "handler_money_stroage_transfer")
client_handler_reg("CS_BankTransferByGuid", "handler_money_stroage_transfer_by_guid")
client_handler_reg("CS_BankStatement", "handler_money_stroage_statement")
client_handler_reg("CS_SendMail", "handler_client_send_mail")
client_handler_reg("CS_DelMail", "handler_client_del_mail")
client_handler_reg("CS_ReceiveMailAttachment", "handler_client_receive_mail_attachment")
client_handler_reg("CS_ReceiveRewardLogin", "handler_client_receive_reward_login")
client_handler_reg("CS_ReceiveRewardOnline", "handler_client_receive_reward_online")
client_handler_reg("CS_ReceiveReliefPayment", "handler_client_receive_relief_payment")
client_handler_reg("CS_EnterRoom", "handler_client_enter_room")
client_handler_reg("CS_AutoEnterRoom", "handler_client_auto_enter_room")
client_handler_reg("CS_AutoSitDown", "handler_client_auto_sit_down")
client_handler_reg("CS_SitDown", "handler_client_sit_down")
client_handler_reg("CS_StandUp", "handler_client_stand_up")
client_handler_reg("CS_EnterRoomAndSitDown", "handler_client_enter_room_and_sit_down")
client_handler_reg("CS_StandUpAndExitRoom", "handler_client_stand_up_and_exit_room")
client_handler_reg("CS_ChangeChair", "handler_client_change_chair")
client_handler_reg("CS_Ready", "handler_client_ready")
client_handler_reg("CS_ChatWorld", "handler_client_chat_world")
client_handler_reg("CS_ChatPrivate", "handler_client_chat_private")
client_handler_reg("SC_ChatPrivate", "on_sc_chat_private")
client_handler_reg("CS_ChatServer", "handler_client_chat_server")
client_handler_reg("CS_ChatRoom", "handler_client_chat_room")
client_handler_reg("CS_ChatTable", "handler_client_chat_table")
client_handler_reg("CS_ChangeTable", "handler_client_change_table")
client_handler_reg("CS_Exit", "handler_client_exit")
client_handler_reg("CS_ReconnectionPlay","handler_client_reconnection_client_msg")
client_handler_reg("CS_QueryPlayerMsgData","handler_client_QueryPlayerMsgData")
client_handler_reg("CS_QueryPlayerMarquee","handler_client_QueryPlayerMarquee")
client_handler_reg("CS_SetMsgReadFlag","handler_client_SetMsgReadFlag")
client_handler_reg("CS_CashMoney","handler_client_cash_money")
client_handler_reg("CS_CashMoneyType","handler_client_cash_money_type")
client_handler_reg("CS_BandAlipay","handler_client_bandalipay")
client_handler_reg("CS_Trusteeship","handler_client_Trusteeship")
client_handler_reg("CS_Agent_CashMoney","handler_client_agent_cash_money")
client_handler_reg("CS_GetHelpMoney", "handler_client_get_help_money")
client_handler_reg("CS_RequestNewAward", "handler_client_request_award")
client_handler_reg("CS_BindBankCard", "handler_client_bind_bank_card")
client_handler_reg("CS_GetBankCardInfo", "handler_client_get_bank_card_info")
client_handler_reg("CS_PlayerPromotion", "handler_client_query_promotion")


gate_handler_reg("FS_ChangMoneyDeal", "on_changmoney_deal")
gate_handler_reg("SS_JoinPrivateRoom", "on_SS_JoinPrivateRoom")


local function load_game_info_02()
	if reg_file_map[def_game_name] then
		local game_reg_file = "game_script/all_game/" .. reg_file_map[def_game_name] .. "_register"
		require(game_reg_file)
	end
end
load_game_info_02()

