local pb = require "extern/lib/lib_pb"
require "mysql_db/handler_net"
local post_msg_to_game_pb = post_msg_to_game_pb
local send2center_pb = send2center_pb
local post_msg_to_login_pb = post_msg_to_login_pb
require "mysql_db/db_api"
local db_execute = db_execute
local db_execute_query = db_execute_query
require "extern/lib/lib_timer"
local add_timer = add_timer
require "extern/lib/lib_table"
local parse_table = parse_table
require "extern/lib/lib_redis"
local redis_command = redis_command
local redis_cmd_query = redis_cmd_query
local get_init_money = get_init_money
local def_save_db_time = 60 
local def_offline_cache_time = 600 
local LOG_MONEY_OPT_TYPE_RECHARGE_MONEY = pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_RECHARGE_MONEY")
local LOG_MONEY_OPT_TYPE_CASH_MONEY = pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY")
local LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE = pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE")

local function save_player(guid, info)
	local db = get_game_db()
	info.money = info.money or 0
	info.bank = info.bank or 0
	db_execute(db, "UPDATE t_player SET $FIELD$ WHERE guid=" .. guid .. ";", info)
end

function handler_mysql_OnlineAccount(game_id, msg)
	local db = get_account_db()
	local sql = string.format("REPLACE INTO t_online_account SET guid=%d, first_game_type=%d, second_game_type=%d, game_id=%d, in_game=%d;", msg.guid, msg.first_game_type, msg.second_game_type, msg.gamer_id, msg.in_game)
	db:execute(sql)
end

function on_s_logout(game_id, msg)
	local db = get_account_db()
	local sql
	if msg.phone then
		sql = string.format("UPDATE t_account SET login_time = FROM_UNIXTIME(%d), logout_time = FROM_UNIXTIME(%d), online_time = online_time + %d, last_login_phone = '%s', last_login_phone_type = '%s', last_login_version = '%s', last_login_channel_id = '%s', last_login_package_name = '%s', last_login_imei = '%s', last_login_ip = '%s' WHERE guid = %d;",
			msg.login_time, msg.logout_time, msg.logout_time-msg.login_time, msg.phone, msg.phone_type, msg.version, msg.channel_id, msg.package_name, msg.imei, msg.ip, msg.guid)
	else
		sql = string.format("UPDATE t_account SET login_time = FROM_UNIXTIME(%d), logout_time = FROM_UNIXTIME(%d), online_time = online_time + %d WHERE guid = %d;",
			msg.login_time, msg.logout_time, msg.logout_time-msg.login_time, msg.guid)
	end
	db:execute(sql)

	sql = string.format("DELETE FROM t_online_account WHERE guid=%d;", msg.guid)
	db:execute(sql)
end

function handler_mysql_delonline_player(game_id, msg)
	local db = get_account_db()
	sql = string.format("DELETE FROM t_online_account WHERE guid=%d and game_id=%d;", msg.guid, msg.game_id)
	db:execute(sql)
end
function handler_mysql_cash_money_type(game_id, msg)	
	local guid_ = msg.guid
	local db = get_recharge_db()
	local sql = string.format([[
		select money,created_at,status from t_cash where  guid = %d and created_at BETWEEN (curdate() - INTERVAL 6 DAY) and (curdate() - INTERVAL -1 DAY)  order by created_at desc limit 3
]], guid_)
	log_info("handler_mysql_cash_money_type 01 " .. guid_)
	db_execute_query(db, true, sql, function (data)
		log_info("handler_mysql_cash_money_type 02 " .. guid_)
		if data and #data > 0 then
			--for _,datainfo in ipairs(data) do
				--print(datainfo)
				--for i,info in pairs(datainfo) do
					--print(i,info)
				--end
			--end
			local msg = {
			    guid = msg.guid,
				pb_cash_info = data,
			}
			post_msg_to_game_pb(game_id,"DS_CashMoneyType",msg)
			log_info("handler_mysql_cash_money_type 03 " .. guid_)
		end
	end)
end

function handler_mysql_cash_money(game_id, msg)	
	local guid_ = msg.guid
	local money_ = msg.money
	local coins_ = msg.coins
	local pay_money_ = msg.pay_money
	local ip_ = msg.ip
	local phone_ = msg.phone
	local phone_type_ = msg.phone_type
	local bag_id_ = msg.bag_id
	local db = get_recharge_db()
	local bef_money_ = msg.bef_money
	local bef_bank_ = msg.bef_bank
	local aft_money_ = msg.aft_money
	local aft_bank_ = msg.aft_bank
	local cash_type_ = msg.cash_type
	local dbA = get_account_db()
	local sql = string.format([[
	select channel_id as bag_id_ from t_account where guid = %d;]], 
	guid_)

	log_info("handler_mysql_cash_money 01 " .. guid_)

	db_execute_query(dbA, true, sql, function (data)
		bag_id_ = data[1].bag_id_
		log_info("handler_mysql_cash_money 02 " .. guid_)
			local sql = string.format([[
		INSERT INTO t_cash (`guid`,`money`,`coins`,`pay_money`,`ip`,`phone`,`phone_type`,`bag_id`, `before_money`, `before_bank`, `after_money`, `after_bank`, `cash_type`)VALUES ('%d','%d','%d','%d','%s','%s','%s','%s', '%g', '%g', '%g', '%g','%d')
]], guid_, money_, coins_, pay_money_, ip_, phone_, phone_type_, bag_id_, bef_money_, bef_bank_, aft_money_, aft_bank_,cash_type_)

		db_execute_query_update(db, sql, function (ret)
			nmsg = {
			guid = guid_,
			coins = coins_,
			result = 0,
			}
			log_info("handler_mysql_cash_money 03 " .. guid_)
			if ret > 0 then
				nmsg.result = 1
				
				log_info("handler_mysql_cash_money 04 " .. guid_)
				sql = string.format("select max(`order_id`) as `order_id` from t_cash where `guid`=%d and `money`=%d  and `coins`=%d  and `pay_money`=%d  and `ip`='%s' and `phone`='%s' and `phone_type`='%s';",
					guid_, money_, coins_, pay_money_, ip_, phone_, phone_type_)
				db_execute_query(db, false, sql, function (data)
					log_info("handler_mysql_cash_money 05 " .. guid_)
					if data and data.ret ~= 0 and data.order_id then
						log_info("handler_mysql_cash_money 06 " .. guid_)
						smd5 =  string.format("order_id=%s%s",data.order_id, get_php_sign_key())
						print (smd5)
						stemp = get_to_md5(smd5)
						print (stemp)
						http_post_no_reply(get_sd_cash_money_addr(), string.format("{\"order_id\":\"%s\",\"sign\":\"%s\"}",data.order_id, stemp))
					end
				end)
			else
				log_error("handler_mysql_cash_money 07 " .. guid_)
			end		
			post_msg_to_game_pb(game_id,"DS_CashMoney",nmsg)
			log_info("handler_mysql_cash_money 08 " .. guid_)
		end)
	end)
end

function handler_mysql_agent_cash_money(game_id, msg)	
	log_info("handler_mysql_agent_cash_money 01  " .. msg.guid)
	local guid_ = msg.guid
	local agent_id_ = msg.agent_id
	local money_ = msg.money
	local coins_ = msg.coins
	local pay_money_ = msg.pay_money
	local ip_ = msg.ip
	local phone_ = msg.phone
	local phone_type_ = msg.phone_type
	local bag_id_ = msg.bag_id
	local db = get_recharge_db()
	local bef_money_ = msg.bef_money
	local bef_bank_ = msg.bef_bank
	local aft_money_ = msg.aft_money
	local aft_bank_ = msg.aft_bank
	local dbA = get_account_db()
	local sql = string.format([[
	select channel_id as bag_id_ from t_account where guid = %d;]], 
	guid_)
	db_execute_query(dbA, true, sql, function (data)
		bag_id_ = data[1].bag_id_

		log_info("handler_mysql_agent_cash_money 02 " .. guid_)

			local sql = string.format([[
		INSERT INTO t_cash (`guid`,`agent_id`,`money`,`coins`,`pay_money`,`ip`,`phone`,`phone_type`,`bag_id`, `before_money`, `before_bank`, `after_money`, `after_bank`)VALUES ('%d','%d','%d','%d','%d','%s','%s','%s','%s', '%g', '%g', '%g', '%g')
]], guid_,agent_id_, money_, coins_, pay_money_, ip_, phone_, phone_type_, bag_id_, bef_money_, bef_bank_, aft_money_, aft_bank_)

		db_execute_query_update(db, sql, function (ret)
			nmsg = {
			guid = guid_,
			coins = coins_,
			result = 0,
			}

			log_info("handler_mysql_agent_cash_money 03 " .. guid_)
			if ret > 0 then
				nmsg.result = 1
				
				sql = string.format("select max(`order_id`) as `order_id` from t_cash where `guid`=%d and `agent_id`=%d and `money`=%d  and `coins`=%d  and `pay_money`=%d  and `ip`='%s' and `phone`='%s' and `phone_type`='%s';",
					guid_,agent_id_, money_, coins_, pay_money_, ip_, phone_, phone_type_)
				db_execute_query(db, false, sql, function (data)
					log_info("handler_mysql_agent_cash_money 04 " .. guid_)
					if data and data.ret ~= 0 and data.order_id then
						log_info("handler_mysql_agent_cash_money 05 " .. guid_)
						smd5 =  string.format("order_id=%s%s",data.order_id, get_php_sign_key())
						print (smd5)
						stemp = get_to_md5(smd5)
						print (stemp)
						http_post_no_reply(get_sd_cash_money_addr(), string.format("{\"order_id\":\"%s\",\"sign\":\"%s\"}",data.order_id, stemp))
					end
				end)
			else
				log_error("on_sd_agent_cash_money error:" .. sql)
			end		
		end)
	end)
end
-- 查询玩家消息及公告
function  handler_mysql_query_player_msg(game_id, msg)
	local guid_ = msg.guid
	local db = get_game_db()
	local sql = string.format([[
		select a.id as id,UNIX_TIMESTAMP(a.start_time) as start_time,UNIX_TIMESTAMP(a.end_time) as end_time,'2' as msg_type,
		if(isnull(b.is_read),1,2) as is_read,a.content as content from t_notice a 
		LEFT JOIN t_notice_read b on a.id = b.n_id and b.guid = %d where a.end_time > FROM_UNIXTIME(UNIX_TIMESTAMP()) and a.type = 2
		union all
		select c.id as id,UNIX_TIMESTAMP(c.start_time) as start_time,UNIX_TIMESTAMP(c.end_time) as end_time,'1' as msg_type,
		c.is_read as is_read, c.content as content from t_notice_private as c 
		where c.guid = %d and c.type = 1 and c.end_time > FROM_UNIXTIME(UNIX_TIMESTAMP())]], 
		guid_,guid_)
	db_execute_query(db, true, sql, function (data)
		if data and #data > 0 then
			
			local b = true
			for _, item in ipairs(data) do
				post_msg_to_game_pb(game_id,"DS_QueryPlayerMsgData",{
						guid = guid_,
						pb_msg_data = { pb_msg_data_info = {item} },
						first = b,
					})

				if b then
					b = false
				end
			end 
		else
			post_msg_to_game_pb(game_id,"DS_QueryPlayerMsgData",{
				guid = guid_,
			})
		end
	end)
end


function  handler_mysql_query_player_marquee(game_id, msg)
	local guid_ = msg.guid
	local db = get_game_db()
	local sql = string.format([[
		select id,UNIX_TIMESTAMP(start_time) as start_time,UNIX_TIMESTAMP(end_time) as end_time,content,number,interval_time from t_notice where end_time > FROM_UNIXTIME(UNIX_TIMESTAMP()) and type = 3;]], 
		guid_,guid_)
	db_execute_query(db, true, sql, function (data)
		if data and #data > 0 then
			local b = true
			for _, item in ipairs(data) do
				post_msg_to_game_pb(game_id,"DS_QueryPlayerMarquee",{
						guid = guid_,
						pb_msg_data = { pb_msg_data_info = {item} },
						first = b,
					})

				if b then
					b = false
				end
			end 
		else
			post_msg_to_game_pb(game_id,"DS_QueryPlayerMarquee",{
				guid = guid_,
			})
		end
	end)
end


function handler_mysql_Set_Msg_Read_Flag( game_id, msg )
	local guid_ = msg.guid
	local db = get_game_db()
	if msg.msg_type == 1 then
		local sql = string.format("update t_notice_private set is_read = 2 where guid = %d and id = %d", 
			msg.guid, msg.id)
		db_execute_query_update(db, sql, function(ret)
			
		end)
	elseif msg.msg_type == 2 then		
		local sql = string.format("replace into t_notice_read set guid = %d ,n_id = %d,is_read = 2", 
			msg.guid, msg.id)
		db_execute_query_update(db, sql, function(ret)
			
		end)
	else
	end
end

function handler_mysql_query_channel_invite_cfg(game_id, msg)
	local gameid = game_id
	local db = get_account_db()
	db_execute_query(db, true, string.format("SELECT * FROM t_channel_invite;"), function (data)
		if not data then
			return
		end
		local ret_msg = {}
		for k,v in pairs(data) do
			local tmp = {}
			tmp.channel_id = v.channel_id
			local channel_lock = v.channel_lock;
			local big_lock = v.big_lock
			if big_lock == 1 and channel_lock == 1 then
				tmp.is_invite_open = 1
			else
				tmp.is_invite_open = 2
			end
			tmp.tax_rate = v.tax_rate
			table.insert( ret_msg, tmp)
		end
		post_msg_to_game_pb(gameid, "DS_QueryChannelInviteCfg", {cfg = ret_msg})
	end)
end

function handler_mysql_query_robot_cfg(game_id, msg)
	local gameid = game_id
	local db = get_game_db()
	db_execute_query(db, true, string.format("CALL get_robot_cfg(%d);",game_id), function (data)
		if not data then
			return
		end

		local ret_msg = {}
		for k,v in pairs(data) do
			ret_msg.game_id = v.game_id
			ret_msg.use_robot = v.use_robot
			ret_msg.storage = v.storage
			ret_msg.robot_level = v.robot_level
			break
		end
		post_msg_to_game_pb(gameid, "DS_QueryRobotCfg", ret_msg)
	end)
end
function handler_mysql_query_brnn_chi_cfg(game_id, msg)
	local gameid = game_id
	local db = get_game_db()
	db_execute_query(db, true, string.format("select * from t_brnn_chi_cfg where game_id = %d;",gameid), function (data)
		if not data then
			return
		end

		local ret_msg = {game_id = gameid, pb_brnn_chi_cfg = {}}
		for k,v in pairs(data) do
			local tt = {}
			tt.beginr = tonumber(v.begin_range)
			tt.endr = tonumber(v.end_range)
			tt.prob = tonumber(v.range_prob)
			log_info(string.format("query_brnn_chi_cfg %s-%s prob %s",tostring(tt.beginr),tostring(tt.endr),tostring(tt.prob)))
			if tt.prob >= 0 and tt.prob <= 100 and tt.beginr >= 0 and tt.beginr < tt.endr then
				table.insert(ret_msg.pb_brnn_chi_cfg,tt)
			end
		end
		post_msg_to_game_pb(gameid, "DS_QueryBrnnChiCfg", ret_msg)
	end)
end

function handler_mysql_query_playerpromotion(game_id, msg)
	local gameid = game_id
	local playerguid = msg.guid
	local db = get_account_db()
	local daytime =os.date("*t",os.time())
	local daytime_int = (daytime.year * 100 + daytime.month)*100 + daytime.day
	db_execute_query(db, true, string.format("select tid,profit from t_player_form where guid = %d and Pay_ck = 0 and times < %d;",playerguid,tonumber(daytime_int)), function (data)
		local ret_msg = {game_id = gameid,guid =playerguid, pb_playerpromotion = {}}
		if not data then
			post_msg_to_game_pb(gameid, "DS_QueryPlayerPromotion", ret_msg)
			return
		end

		for k,v in pairs(data) do
			local tt = {}
			tt.tid = tonumber(v.tid)
			tt.profit = tonumber(v.profit)
			log_info(string.format("query_playerpromotion guid=%d %d-%d ",playerguid,tt.tid,tt.profit))
			if tt.tid > 0  then
				table.insert(ret_msg.pb_playerpromotion,tt)
			end
		end
		post_msg_to_game_pb(gameid, "DS_QueryPlayerPromotion", ret_msg)
	end)
end

function handler_mysql_save_storage(game_id, msg)
	local gameid = game_id
	local db = get_game_db()
	db:execute(string.format("UPDATE t_robot_cfg SET `storage` = %d WHERE game_id = %d;",msg.storage,game_id))
end
function handler_mysql_update_game_total_tax(game_id, msg)
	local gameid = game_id
	local db = get_game_db()
	db:execute(string.format("call update_game_total_tax(%d,%d,%d,%d);",msg.game_id,msg.first_game_type,msg.second_game_type,msg.tax_add))
end

function handler_mysql_query_player_invite_reward(game_id, msg)
	local guid_ = msg.guid
	local gameid = game_id

	local db = get_game_db()
	db_execute_query(db, false, string.format("CALL get_player_invite_reward(%d)",guid_), function (data)
		if not data then
			log_error("handler_mysql_query_player_invite_reward not find guid:" .. guid_)
			return
		end
		post_msg_to_game_pb(gameid, "DS_QueryPlayerInviteReward", {
			guid = guid_,
			reward = data.total_reward,
		})
	end)
end

local sd_query_player_data_lock = {}
function handler_cfg_get_player_info(msg)
	local guid_ = msg.guid
	local account = msg.account
	local nick = msg.nickname
	local gameid = msg.gameid
	local PlayerInfoInMemery = msg.info
	sd_query_player_data_lock[guid_] = nil

	local db = get_game_db()
	local Rdb = get_recharge_db()
	local ldb = get_log_db()

	
	db_execute_query(db, false, string.format("CALL get_player_data(%d,'%s','%s',%d)",guid_,account,nick,get_init_money()), function (data)
		if not data then
			log_error("query_player_data not find guid:" .. guid_)
			return
		end

	data.money = data.money or 0
	data.bank = data.bank or 0
	log_info("bank A:"..data.bank)
	log_info("money A:"..data.money)
	log_info("guid_ A:"..guid_)
	if PlayerInfoInMemery and PlayerInfoInMemery.money >= 0 and PlayerInfoInMemery.bank >= 0 then
		if data.money ~= PlayerInfoInMemery.money or data.bank ~= PlayerInfoInMemery.bank then
			log_error(string.format("load data diffent player %d: db money %d,bank %d   memery money %d,bank %d",
			guid_,data.money,data.bank,PlayerInfoInMemery.money,PlayerInfoInMemery.bank))
			data.money = PlayerInfoInMemery.money
			data.bank = PlayerInfoInMemery.bank
		end
	else
		post_msg_to_cfg_pb("DF_SavePlayerInfo", {
			info = {guid = guid_,
			money = data.money,
			bank = data.bank}}
		) 
	end
	
	local sql = string.format([[select id,money,type,order_id from t_re_recharge where  guid = %d and status = 0]], guid_)
	db_execute_query(Rdb, true, sql, function (dataR)
		local num = 0
		local total =  0
		if dataR and #dataR > 0 then
			total =  #dataR
			log_info("-----------------1")
			for _,datainfo in ipairs(dataR) do
				local sql_change = 	string.format([[update t_re_recharge set status = 1, updated_at = current_timestamp where  id = %d]], datainfo.id)
				db_execute_query_update(Rdb, sql_change, function(ret)
					num = num + 1
					if ret > 0 then				
					
						local before_bank = data.bank
						log_info("bank C:"..data.bank)
						log_info ("datainfo.money:"..datainfo.money)
						data.bank = before_bank + datainfo.money
						local after_bank = data.bank
						datainfo.type = tonumber(datainfo.type)		
						local typebret = 0
						if datainfo.type == LOG_MONEY_OPT_TYPE_RECHARGE_MONEY then 
							typebret = 1
						end
						log_info(string.format("datainfo.type X: %d  %d %d %s %s",  datainfo.type , LOG_MONEY_OPT_TYPE_RECHARGE_MONEY, typebret,  type(datainfo.type), type(LOG_MONEY_OPT_TYPE_RECHARGE_MONEY)))
						if datainfo.type == LOG_MONEY_OPT_TYPE_RECHARGE_MONEY then
							log_info("-------------------------A")
							local sqlR = string.format([[
							update t_recharge_order set server_status = 1, before_bank = %d, after_bank = %d where  id = %d]], before_bank, after_bank, datainfo.order_id)
							Rdb:execute(sqlR)
							smd5 =  string.format("type=1&sources=1&order_no=%d%s",datainfo.order_id, get_php_sign_key())
							stemp = get_to_md5(smd5)
							local sjson = string.format("{\"type\":1,\"sources\":1,\"order_no\":%d,\"sign\":\"%s\"}",datainfo.order_id, stemp)
							log_info("sjson:"..sjson)
							http_post_no_reply(get_php_interface_addr(), sjson)

							local t_sql = string.format("UPDATE t_player SET recharge_total = recharge_total + %d,last_recharge_game_total = 0 WHERE guid = %d",datainfo.money,guid_)
							db:execute(t_sql)
						elseif datainfo.type == LOG_MONEY_OPT_TYPE_CASH_MONEY then

						elseif datainfo.type == LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE then
							log_info("-------------------------B")
							local sqlR = string.format([[
							update t_cash set status_c = 1 where  order_id = %d]],  datainfo.order_id)
							Rdb:execute(sqlR)
						end
						
						local log_money_={
							guid = guid_,
							old_money = data.money,
							new_money = data.money,
							old_bank =  before_bank,
							new_bank = after_bank,
							opt_type = datainfo.type,
						}		
						db_execute(ldb, "INSERT INTO t_log_money SET $FIELD$;", log_money_)	
						log_info ("...................... on_sd_log_money")		
					end
					log_info("----------num".. num, total)
					if(num ==  total) then
						log_info("bank B:"..data.bank)
						save_player(guid_, data)
						post_msg_to_game_pb(gameid, "DS_LoadPlayerData", {
							guid = guid_,
							info_type = 1,
							pb_base_info = data,
						})
						if data.bank and data.bank >=0 and data.money and data.money >=0 then
							post_msg_to_cfg_pb("DF_SavePlayerInfo", {
								info = {guid = guid_,
								money = data.money,
								bank = data.bank}}
							) 
						else
							log_error("DF_SavePlayerInfo error guid".. guid_)
						end
					end
				end)
			end
		else
			
			post_msg_to_game_pb(gameid, "DS_LoadPlayerData", {
				guid = guid_,
				info_type = 1,
				pb_base_info = data,
			})
		end
		end)
	end)
end
function handler_mysql_query_player_data(game_id, msg)
	local guid_ = msg.guid
	local account = msg.account
	local nick = msg.nickname
	local gameid = game_id
	if sd_query_player_data_lock[guid_] == nil then
		sd_query_player_data_lock[guid_] = true
		post_msg_to_cfg_pb("DF_GetPlayerInfo", {guid = guid_,account = account,nickname = nick,gameid = gameid})	
	else
		log_error("on_sd_query_player_data in process " .. guid_)
	end
end

function handler_mysql_save_player_data(game_id, msg)
	save_player(msg.guid, msg.pb_base_info)
end

function handler_mysql_SavePlayerMoney(game_id, msg)
	local db = get_game_db()
	
	local sql = "UPDATE t_player SET money=" .. (msg.money or 0) .. " WHERE guid=" .. msg.guid ..";"

	db:execute(sql)
end

function handler_mysql_SavePlayerBank(game_id, msg)
	local db = get_game_db()
	
	local sql = "UPDATE t_player SET bank=" .. (msg.bank or 0) .. " WHERE guid=" .. msg.guid ..";"

	db:execute(sql)
end

function handler_mysql_load_android_data(game_id, msg)
	local opttype = msg.opt_type
	local roomid = msg.room_id
	local sql = string.format("SELECT guid, account, nickname FROM t_player WHERE guid>%d AND is_android=1 ORDER BY guid ASC LIMIT %d;", msg.guid, msg.count)
	local db = get_game_db()

	db_execute_query(db, true, sql, function (data)
		if data and #data > 0 then
			post_msg_to_game_pb(game_id, "DS_LoadAndroidData", {
				opt_type = opttype,
				room_id = roomid,
				android_list = data,
			})
		end
	end)
end
function on_ld_AlipayEdit(login_id, msg)
	local notify = {
		guid = msg.guid,
		EditNum = 0,
		retid = msg.retid,
	}
	
	local db = get_account_db()
	local sql = ""
	sql = string.format("update t_account set alipay_name = '%s',alipay_name_y = '%s',alipay_account = '%s',alipay_account_y = '%s' where guid = %d  ",
		msg.alipay_name , msg.alipay_name_y , msg.alipay_account , msg.alipay_account_y,msg.guid  )
	db_execute_query_update(db, sql, function(ret)
		notify.EditNum = 1
		post_msg_to_login_pb(login_id, "DL_AlipayEdit",notify)
	end)
end
function  on_ld_do_sql( login_id, msg)
	local db = get_game_db()
	if msg.database == "log" then
		db = get_log_db()
	elseif msg.database == "account" then
		db = get_account_db()
	end

	local sql = msg.sql
	local notify = {
		retCode = 0,
		keyid = msg.keyid,
		retData = "",
		retid = msg.retid,
	}
	db_execute_query(db, false, sql, function (data)
		if not data then
			notify.retCode = 9999
			notify.retData = "not Data"
			post_msg_to_login_pb(login_id, "DL_DO_SQL",notify)
			return
		end
		notify.retCode = data.retCode
		notify.retData = data.retData
		post_msg_to_login_pb(login_id, "DL_DO_SQL",notify)
	end)
end
function on_ld_cc_changemoney(login_id, msg)
	local notify = {
		guid = msg.guid,
		money = msg.money,
		keyid = msg.keyid,
		retid = msg.retid,
		retcode = 0,
		oldmoney = 0,
		newmoney = 0,
	}
	local sql = string.format("CALL change_player_bank_money(%d, %d)",msg.guid, msg.money)
	local db = get_game_db()
	db_execute_query(db, false, sql, function (data)		
		if not data then
			notify.retcode = 5
			post_msg_to_login_pb(login_id, "DL_CC_ChangeMoney",notify)
			return
		end
		if data.ret ~= 0 then
			notify.retcode = data.ret
			post_msg_to_login_pb(login_id, "DL_CC_ChangeMoney",notify)
			return
		end
		notify.retcode = data.ret		
		if data.ret == 0 then
			notify.oldmoney = data.oldbank
			notify.newmoney = data.newbank
			print(string.format("oldmoney is [%d] newmoney [%d]",notify.oldmoney,notify.newmoney))
		end
		post_msg_to_login_pb(login_id, "DL_CC_ChangeMoney",notify)
	end)
end
function on_ld_DelMessage(login_id, msg)
	local sql = ""
	local notify = {
		ret = 1,
		msg_type = msg.msg_type,
		msg_id = msg.msg_id,
		retid = msg.retid,
	}
	local sql = string.format("CALL del_msg(%d, %d)",msg.msg_id, msg.msg_type)
	local db = get_game_db()
	db_execute_query(db, false, sql, function (data)
		if not data then
			post_msg_to_login_pb(login_id, "DL_DelMessage",notify)
			return
		end
		
		if data.ret ~= 0 then
			post_msg_to_login_pb(login_id, "DL_DelMessage",notify)
			return
		end
		if notify.msg_type == 1 then
			notify.guid = data.guid
		end
		notify.ret = 100
		post_msg_to_login_pb(login_id, "DL_DelMessage",notify)
	end)	
end

function on_ld_AgentTransfer_finish( login_id, msg)
	local db = get_log_db()
	sql = string.format([[insert into t_AgentsTransfer_tj (  `agents_guid`,  `player_guid`,  `transfer_id`,  `transfer_type`,  `transfer_money`,  `transfer_status`,
  						`agents_old_bank`,  `agents_new_bank`,  `player_old_bank`,  `player_new_bank`	)
						values(%d,%d,%d,%d,%d,%d,%d,%d,%d,%d)]],
		msg.pb_result.AgentsID,
		msg.pb_result.PlayerID,
		msg.pb_result.transfer_id,
		msg.pb_result.transfer_type,
		msg.pb_result.transfer_money,
		msg.retid,
		msg.a_oldmoney,
		msg.a_newmoney,
		msg.p_oldmoney,
		msg.p_newmoney)
	db:execute(sql)
end
function on_ld_NewNotice(login_id, msg)
	local sql = ""
	local db = get_game_db()
	local notify = {
		ret = 1,
		guid = msg.guid,
		type = msg.type,
		retID = msg.retID,
		content = msg.content,
		name = msg.name,
		author = msg.author,
		number = msg.number,
		interval_time = msg.interval_time,
	}
	if msg.type == 1 then 
		sql = string.format([[REPLACE INTO t_notice_private set guid=%d,type=1,name='%s',content='%s',author='%s',
			start_time='%s',end_time = '%s']],
		msg.guid, msg.name, msg.content, msg.author,msg.start_time,msg.end_time)
	elseif msg.type == 2 then 
		sql = string.format([[REPLACE INTO t_notice set type=2,name='%s',content='%s',author='%s',
			start_time='%s',end_time = '%s']],
			msg.name, msg.content, msg.author,msg.start_time,msg.end_time)
	elseif msg.type == 3 then 
		sql = string.format([[REPLACE INTO t_notice set type=3,number=%d,interval_time=%d,content='%s',
			start_time='%s',end_time = '%s']],msg.number,msg.interval_time,
			msg.content,msg.start_time,msg.end_time)
	else
	end
	db_execute_query_update(db, sql, function(ret)
		if ret > 0 then
			sql = string.format("SELECT LAST_INSERT_ID() as ID, UNIX_TIMESTAMP('%s') as start_time,UNIX_TIMESTAMP('%s') as end_time",msg.start_time,msg.end_time)
			db_execute_query(db, true, sql, function (data)
				if data then
					notify.id = data[1].ID 
					notify.start_time = data[1].start_time
					notify.end_time = data[1].end_time
				end
				notify.ret = 100
				post_msg_to_login_pb(login_id, "DL_NewNotice",notify)
			end)
		else
			post_msg_to_login_pb(login_id, "DL_NewNotice",notify)
		end
	end)
end

function handler_mysql_save_player_Ox_data(game_id, msg)
	local db = get_game_db()
	local sql = string.format("REPLACE INTO t_ox_player_info set guid = %d, is_android = %d, table_id = %d, banker_id = %d, \
	nickname = '%s', money = %d, win_money = %d, bet_money = %d,tax = %d, curtime = %d;",
	msg.guid,msg.is_android,msg.table_id,msg.banker_id,msg.nickname,msg.money,msg.win_money,msg.bet_money,msg.tax,msg.curtime)
	db:execute(sql)
end

function handler_mysql_query_Ox_config_data(game_id, msg)
	local db = get_game_db()
	local sql = string.format([[select FreeTime,BetTime,EndTime,MustWinCoeff,BankerMoneyLimit,SystemBankerSwitch,BankerCount,RobotBankerInitUid,RobotBankerInitMoney,BetRobotSwitch,BetRobotInitUid,BetRobotInitMoney,BetRobotNumControl,BetRobotTimesControl,RobotBetMoneyControl,BasicChip from t_many_ox_server_config]])
	db_execute_query(db, true, sql, function (data)
	
		if data and #data > 0 then
			local msg = {
			   	FreeTime = data[1].FreeTime,
				BetTime = data[1].BetTime,
				EndTime = data[1].EndTime,
				MustWinCoeff = data[1].MustWinCoeff,
				BankerMoneyLimit = data[1].BankerMoneyLimit,
				SystemBankerSwitch = data[1].SystemBankerSwitch,
				BankerCount = data[1].BankerCount,
				RobotBankerInitUid = data[1].RobotBankerInitUid,
				RobotBankerInitMoney = data[1].RobotBankerInitMoney,
				BetRobotSwitch = data[1].BetRobotSwitch,
				BetRobotInitUid = data[1].BetRobotInitUid,
				BetRobotInitMoney = data[1].BetRobotInitMoney,
				BetRobotNumControl = data[1].BetRobotNumControl,
				BetRobotTimesControl = data[1].BetRobotTimesControl,
				RobotBetMoneyControl = data[1].RobotBetMoneyControl,
				BasicChip = data[1].BasicChip
			}
		
			post_msg_to_game_pb(game_id,"DS_OxConfigData",msg)
		end
		
	end)
	return
end

function handler_mysql_PrivateRoomLog(game_id, msg)
    local db = get_game_db()
	local sql = string.format("INSERT INTO t_private_room SET room_id=%d, owner_guid=%d, first_game_type=%d, chair_max=%d, chair_count=%d, cell_money=%d, room_cost=%d, money_limit=%d, room_state=%d;",
	msg.room_id, msg.owner_guid, msg.first_game_type, msg.chair_max, msg.chair_count, msg.cell_money, msg.room_cost, msg.money_limit, (msg.room_state or 0))
	db:execute(sql)
end


function handler_mysql_FilishPrivateRoomLog(game_id, msg)
    local db = get_game_db()
	local sql = string.format("UPDATE t_private_room SET finish_time=NOW(), room_state=%d WHERE room_id=%d AND room_state<10;", (msg.room_state or 0), msg.room_id)
	db:execute(sql)
end


function handler_mysql_StartPrivateRoomLog(game_id, msg)
    local db = get_game_db()
	local sql = string.format("UPDATE t_private_room SET player_guid='%s', room_state=2 WHERE room_id=%d AND room_state<10;", table.concat(msg.player_guid,","), msg.room_id)
	db:execute(sql)
end
function handler_mysql_Do_OneSql(game_id, msg)
	local db
	if msg.db_name == "game" then
		db = get_game_db()
	elseif msg.db_name == "log" then
		db = get_log_db()
	elseif msg.db_name == "account" then
		db = get_account_db()
	elseif msg.db_name == "recharge" then
		db = get_recharge_db()
	end
	if db and msg.sql then
		db:execute(msg.sql)
	end
end

function handler_mysql_notify_php(game_id, msg)
	http_post_no_reply("http://125.88.177.32:8088/api/notice/notice_potato",string.format("{\"guid\":\"%d\"}",msg.guid))
end
function handler_mysql_query_player_recharge(game_id, msg)
	local db = get_game_db()
	local sql = string.format("select recharge_total from t_player where guid=%d;",msg.guid)
	db_execute_query(db, true, sql, function (data)
		if data and #data > 0 then
			local msg = {
				recharge = tonumber(data[1].recharge_total),
				guid = msg.guid
			}
		
			post_msg_to_game_pb(game_id,"DS_QueryPlayerRecharge",msg)
		end
		
	end)
end


function handler_mysql_query_player_cashtime(game_id, msg)
	local db = get_game_db()
	local sql = string.format("select recharge_total from t_player where guid=%d;",msg.guid)
	db_execute_query(db, true, sql, function (data)
		if data and #data > 0 then
			local msg = {
				recharge = tonumber(data[1].recharge_total),
				guid = msg.guid
			}
		
			post_msg_to_game_pb(game_id,"DS_QueryPlayerRecharge",msg)
		end
		
	end)
end

