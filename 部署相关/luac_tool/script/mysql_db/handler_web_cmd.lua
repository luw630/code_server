local pb = require "extern/lib/lib_pb"
local LOG_MONEY_OPT_TYPE_GM = pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_GM")
local LOG_MONEY_OPT_TYPE_CHANNEL_ZK = pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CHANNEL_ZK")
local db_execute = db_execute
require "extern/lib/lib_redis"
local redis_command = redis_command
require "mysql_db/handler_net"
local post_msg_to_game_pb = post_msg_to_game_pb
local post_msg_to_login_pb = post_msg_to_login_pb


function gm_change_money(guid,money,log_type)
	local db = get_game_db()

	local sql = string.format("SELECT money,bank from t_player WHERE guid = %d;",guid)
	db_execute_query(db, true, sql, function (data)
		if data and #data > 0 then	
			local old_money = data[1].money
			local old_bank = data[1].bank
			if(money < 0) then
				local tempMoney = old_money + money
				if tempMoney < 0 then
					return false
				end
			end
			local new_money = old_money + money
			local sql = string.format("UPDATE t_player SET money=%d WHERE guid=%d;",new_money,guid)
			db:execute(sql)
			local log_db = get_log_db()
			local log_sql = string.format("INSERT INTO t_log_money SET guid = %d,old_money=%d,new_money=%d,old_bank=%d,new_bank=%d,opt_type=%d;",guid,old_money,new_money,old_bank,old_bank,log_type or LOG_MONEY_OPT_TYPE_GM)
			log_db:execute(log_sql)

			post_msg_to_cfg_pb("DF_SavePlayerInfo", {
				info = {guid = guid,
				money = new_money,
				bank = old_bank}}
			) 
		end
	end)
	return true
  
end

function gm_change_bank_money(guid,bank_money,log_type)
    local db = get_game_db()
	local sql = string.format("SELECT money,bank from t_player WHERE guid = %d;",guid)
	db_execute_query(db, true, sql, function (data)
		if data and #data > 0 then	
			local old_money = data[1].money
			local old_bank = data[1].bank
			if(bank_money < 0) then
				local tempMoney = old_bank + bank_money
				if tempMoney < 0 then
					return false
				end
			end
			local new_bank_money = old_bank + bank_money
			local sql = string.format("UPDATE t_player SET bank=%d WHERE guid=%d;",new_bank_money,guid)
			db:execute(sql)
			local log_db = get_log_db()
			local log_sql = string.format("INSERT INTO t_log_money SET guid = %d,old_money=%d,new_money=%d,old_bank=%d,new_bank=%d,opt_type=%d;",guid,old_money,old_money,old_bank,new_bank_money,log_type or LOG_MONEY_OPT_TYPE_GM)
			log_db:execute(log_sql)

			post_msg_to_cfg_pb("DF_SavePlayerInfo", {
				info = {guid = guid,
				money = old_money,
				bank = new_bank_money}}
			) 
		end
	end)

	return true
end

function gm_change_bank(web_id_, login_id, guid, bank_money, log_type)
    local db = get_game_db()
	local sql = string.format("UPDATE t_player SET bank = bank + %d WHERE guid = %d;", bank_money, guid)

	db_execute_query_update(db, sql, function(ret)
		if ret == 0 then
			post_msg_to_login_pb(login_id, "DL_LuaCmdPlayerResult", {
				web_id = web_id_,
				result = 0,
				})

			log_warning("gm_change_bank not find guid:" .. guid)
			return;
		end

		post_msg_to_login_pb(login_id, "DL_LuaCmdPlayerResult", {
			web_id = web_id_,
			result = 1,
			})

		sql = string.format("SELECT money, bank FROM t_player WHERE guid = %d;", guid)
		db_execute_query(db, false, sql, function (data)
			if not data then
				log_warning("gm_change_bank data = null")
				return
			end
			db = get_log_db()
			local log = {
				guid = guid,
				old_money = data.money,
				new_money = data.money,
				old_bank = data.bank-bank_money,
				new_bank = data.bank,
				opt_type = log_type or LOG_MONEY_OPT_TYPE_GM,
			}
			db_execute(db, "INSERT INTO t_log_money SET $FIELD$;", log)

			post_msg_to_cfg_pb("DF_SavePlayerInfo", {
				info = {guid = guid,
				money = data.money,
				bank = data.bank}}
			) 
		end)
	end)
end

--渠道追款
function gm_channel_zk_bank(web_id_, login_id, guid, bank_money, log_type)
	if bank_money > 0 then
		post_msg_to_login_pb(login_id, "DL_LuaCmdPlayerResult", {
	    	web_id = web_id_,
	    	result = 0,
			})
		log_warning(string.format("channel_zk error guid[%d] money[%d] ", guid, bank_money))	
		return
	end

	local db = get_game_db()
	local sql = string.format("SELECT money, bank FROM t_player WHERE guid = %d;", guid)
	db_execute_query(db, false, sql, function (data)
		if not data then
			log_warning("gm_channel_zk_bank data = null")
			post_msg_to_login_pb(login_id, "DL_LuaCmdPlayerResult", {
				web_id = web_id_,
				result = 0,
				})
			return
		end
		if (data.bank + bank_money) < 0 then
			log_error("gm_channel_zk_bank bank < 0")
			post_msg_to_login_pb(login_id, "DL_LuaCmdPlayerResult", {
				web_id = web_id_,
				result = 0,
				})
			return
		end

		db = get_game_db()
		sql = string.format("UPDATE t_player SET bank = bank + %d WHERE guid = %d;", bank_money, guid)
		log_warning("gm_channel_zk_bank guid:" .. guid)
		db_execute_query_update(db, sql, function(ret)
			if ret == 0 then
				post_msg_to_login_pb(login_id, "DL_LuaCmdPlayerResult", {
					web_id = web_id_,
					result = 0,
					})
	
				log_warning("gm_channel_zk_bank not find guid:" .. guid)
				return;
			end

			log_info("gm_channel_zk_bank suc guid:" .. guid)
			post_msg_to_login_pb(login_id, "DL_LuaCmdPlayerResult", {
				web_id = web_id_,
				result = 1,
				})

			db = get_log_db()
			local log = {
					guid = guid,
					old_money = data.money,
					new_money = data.money,
					old_bank = data.bank,
					new_bank = data.bank+bank_money,
					opt_type = LOG_MONEY_OPT_TYPE_CHANNEL_ZK,
			}
			db_execute(db, "INSERT INTO t_log_money SET $FIELD$;", log)

			post_msg_to_cfg_pb("DF_SavePlayerInfo", {
				info = {guid = guid,
				money = data.money,
				bank = data.bank+bank_money}}
			) 
		end)
	end)
end

