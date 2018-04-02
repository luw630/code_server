local pb = require "extern/lib/lib_pb"
require "mysql_db/handler_net"
local post_msg_to_game_pb = post_msg_to_game_pb
require "mysql_db/db_api"
local db_execute_query_update = db_execute_query_update
local db_execute_query = db_execute_query
require "extern/lib/lib_redis"
local redis_command = redis_command
local redis_cmd_query = redis_cmd_query

local BANK_OPT_RESULT_SUCCESS = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS")
local BANK_OPT_RESULT_PASSWORD_HAS_BEEN_SET = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_PASSWORD_HAS_BEEN_SET")
local BANK_OPT_RESULT_PASSWORD_IS_NOT_SET = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_PASSWORD_IS_NOT_SET")
local BANK_OPT_RESULT_OLD_PASSWORD_ERR = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_OLD_PASSWORD_ERR")
local BANK_OPT_RESULT_ALREADY_LOGGED = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_ALREADY_LOGGED")
local BANK_OPT_RESULT_LOGIN_FAILED = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_LOGIN_FAILED")
local BANK_OPT_RESULT_NOT_LOGIN = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_NOT_LOGIN")
local BANK_OPT_RESULT_MONEY_ERR = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_MONEY_ERR")
local BANK_OPT_RESULT_TRANSFER_ACCOUNT = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_TRANSFER_ACCOUNT")
local BANK_OPT_RESULT_FORBID_IN_GAMEING = pb.get_ev("BANK_OPT_RESULT", "BANK_OPT_RESULT_FORBID_IN_GAMEING")
local BANK_STATEMENT_OPT_TYPE_DEPOSIT = pb.get_ev("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_DEPOSIT")
local BANK_STATEMENT_OPT_TYPE_DRAW = pb.get_ev("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_DRAW")
local BANK_STATEMENT_OPT_TYPE_TRANSFER_OUT = pb.get_ev("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_TRANSFER_OUT")
local BANK_STATEMENT_OPT_TYPE_TRANSFER_IN = pb.get_ev("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_TRANSFER_IN")

function handler_mysql_bank_set_password(game_id, msg)
	local db = get_account_db()
	local sql = string.format("UPDATE t_account SET bank_password = '%s' WHERE guid = %d;", msg.password, msg.guid)
	db:execute(sql)
end

function handler_mysql_bank_change_password(game_id, msg)
	local guid_ = msg.guid
	
	local db = get_account_db()
	local sql = string.format("UPDATE t_account SET bank_password = '%s' WHERE guid = %d AND bank_password = '%s';", 
		msg.password, guid_, msg.old_password)
	local gameid = game_id
		
	db_execute_query_update(db, sql, function(ret)
		post_msg_to_game_pb(gameid, "DS_BankChangePassword", {
			guid = guid_,
			result = (ret > 0 and BANK_OPT_RESULT_SUCCESS or BANK_OPT_RESULT_OLD_PASSWORD_ERR),
		})
	end)
end

function handler_mysql_bank_login(game_id, msg)
	local guid_ = msg.guid
	
	local db = get_account_db()
	local sql = string.format("SELECT guid FROM t_account WHERE guid = %d AND bank_password = '%s';", guid_, msg.password)
	local gameid = game_id
	
	db_execute_query(db, false, sql, function (data)
		post_msg_to_game_pb(gameid, "DS_BankLogin", {
			guid = guid_,
			result = (data ~= nil and BANK_OPT_RESULT_SUCCESS or BANK_OPT_RESULT_LOGIN_FAILED)
		})
	end)
	
end

function handler_mysql_bank_transfer(game_id, msg)
	log_warning(string.format("handler_mysql_bank_transfer (%d, %d, '%s', %d, %d);", 
	msg.guid, msg.time, msg.target, msg.money, msg.bank_balance))

	local db = get_game_db()
	local sql = string.format("CALL bank_transfer(%d, %d, '%s', %d, %d);", 
		msg.guid, msg.time, msg.target, msg.money, msg.bank_balance)
	local gameid = msg.game_id
	
	db_execute_query(db, false, sql, function (data)
		if not data then
			return
		end
		
		if data.ret ~= 0 then
			post_msg_to_game_pb(gameid, "DS_BankTransfer", {
				result = BANK_OPT_RESULT_TRANSFER_ACCOUNT,
				guid = msg.guid,
				money = msg.money,
			})
			return
		end
		
		post_msg_to_game_pb(gameid, "DS_BankTransfer", {
			result = BANK_OPT_RESULT_SUCCESS,
			pb_statement = {
				serial = tostring(data.id),
				guid = msg.guid,
				time = msg.time,
				opt = BANK_STATEMENT_OPT_TYPE_TRANSFER_OUT,
				target = msg.target,
				money = msg.money,
				bank_balance = msg.bank_balance,
			},
		})
	end)
end

function on_s_bank_transfer_by_guid(login_id, msg)
	log_warning(string.format("on_s_bank_transfer_by_guid (%d, %d);", 
	msg.money, msg.target_guid))

	local db = get_game_db()
	local sql = string.format("UPDATE t_player SET bank = bank + %d WHERE guid = %d;", 
		msg.money, msg.target_guid)
	db_execute_query_update(db, sql, function(ret)
		post_msg_to_game_pb(msg.game_id, "DS_BankTransferByGuid", {
			result = (ret > 0 and BANK_OPT_RESULT_SUCCESS or BANK_OPT_RESULT_TRANSFER_ACCOUNT),
			guid = msg.guid,
			money = msg.money,
		})
	end)
end

function handler_mysql_save_bank_statement(game_id, msg)
	local statement_ = pb.decode(msg.pb_statement[1], msg.pb_statement[2])
	local db = get_game_db()
	local sql = string.format("CALL save_bank_statement(%d,%d,%d,'%s',%d,%d);", 
		statement_.guid, statement_.time, statement_.opt, statement_.target, statement_.money, statement_.bank_balance)
	local gameid = game_id
	
	db_execute_query(db, false, sql, function (data)
		if not data then
			return
		end
		statement_.serial = data.id
		post_msg_to_game_pb(gameid, "DS_SaveBankStatement", {
			pb_statement = statement_,
		})
	end)
end

local function get_bank_statement(guid_, serial, gameid)
	local db = get_game_db()
	local sql = string.format("SELECT id AS serial,guid,UNIX_TIMESTAMP(time) AS time,opt,target,money,bank_balance FROM t_bank_statement WHERE id>%d AND guid=%d ORDER BY id ASC LIMIT 20;", serial, guid_)
	db_execute_query(db, true, sql, function (data)
		if not data then
			return
		end
		
		for _, item in ipairs(data) do
			item.serial = item.serial
		end
		
		post_msg_to_game_pb(gameid, "DS_BankStatement", {
			guid = guid_,
			pb_statement = data,
		})
		
		if #data ~= 20 then
			return
		end
		
		get_bank_statement(guid_, data[20].serial, gameid)
	end)
end
function handler_mysql_bank_statement(game_id, msg)
	get_bank_statement(msg.guid, msg.cur_serial, game_id)
end


function handler_mysql_BankLog(game_id, msg)
	local db = get_log_db()
	local sql = string.format("INSERT INTO t_log_bank SET time=FROM_UNIXTIME(%d),guid=%d,nickname='%s',phone='%s',opt_type=%d,money=%d,old_money=%d,new_money=%d,old_bank=%d,new_bank=%d,ip='%s'", 
		msg.time, msg.guid, msg.nickname, msg.phone, msg.opt_type, msg.money, msg.old_money, msg.new_money, msg.old_bank, msg.new_bank, msg.ip)

	db:execute(sql)
end