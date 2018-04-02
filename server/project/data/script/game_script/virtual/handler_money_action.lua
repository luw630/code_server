local pb = require "extern/lib/lib_pb"
require "game_script/handler_net"
local post_msg_to_client_pb = post_msg_to_client_pb
local post_msg_to_mysql_pb = post_msg_to_mysql_pb
local post_msg_to_login_pb = post_msg_to_login_pb
require "game_script/virtual/virtual_player"
require "extern/lib/lib_table"
local virtual_player = virtual_player
local def_game_id = def_game_id

function on_changmoney_deal(msg)
	local info = msg.info
	log_info(string.format("on_changmoney_deal  begin----------------- player  guid[%d]  money[%g] type[%d] order_id[%d]", info.guid, info.gold, info.type_id, info.order_id))
	local player = virtual_player:find(info.guid)	
	local nmsg = {
		web_id = msg.web_id,
		result = 1,	
		info = msg.info,
		befor_bank = 0,
		after_bank = 0,
	}
	if player and player.pb_base_info then
		if player.recharge_total == nil then
			player.recharge_total = 0
		end
		player.recharge_total = player.recharge_total + info.gold
		local bank_ = player.pb_base_info.bank
		--local bRet = player:change_money(info.gold, info.type_id, true)
		local bRet = player:change_bank(info.gold, info.type_id, true)
		if bRet == true then
			nmsg.befor_bank = bank_
			nmsg.after_bank =  player.pb_base_info.bank
			post_msg_to_mysql_pb("SD_ChangMoneyReply",nmsg)
			post_msg_to_mysql_pb("SD_Do_OneSql",{db_name = "game",sql = string.format("UPDATE t_player SET recharge_total = recharge_total + %d,last_recharge_game_total = 0 WHERE guid = %d",info.gold,info.guid)})
			player.recharge_total = player.recharge_total or 0
			player.recharge_total = player.recharge_total + info.gold
			log_info "end...................................on_changmoney_deal   A"
			return
		end
		log_info("on_changmoney_deal bRet is" .. bRet);
	else
		log_error(string.format("on_changmoney_deal no find player  guid[%d]", info.guid))
		fmsg = {
		web_id =  msg.web_id,
		info = msg.info,
		}
		post_msg_to_mysql_pb("FD_ChangMoneyDeal",fmsg)
		log_info ("end...................................on_changmoney_deal   B")		
	end
end
function on_cash_false_deal(msg)
	local info = msg.info
	log_info(string.format("on_cash_false_deal  begin----------------- player  guid[%d]  money[%g]  order_id[%d]", info.guid, info.coins, info.order_id))
	local player = virtual_player:find(info.guid)	
	local nmsg = {
		web_id = msg.web_id,
		result = 1,	
		server_id = msg.server_id,
		order_id = info.order_id,
		info = msg.info,
	}
	if player and  player.pb_base_info then
		local bRet = player:change_bank(info.coins, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY"), true)
		if bRet == false then
			nmsg.result = 6
			log_warning(string.format("on_cash_false_deal..............................%d add money false player", info.guid))
		end
	else		
		nmsg.result = 5
		log_warning(string.format("on_cash_false_deal..............................%d no find player", info.guid))
	end
	post_msg_to_login_id_pb(msg.login_id, "SL_CashReply",nmsg)
	log_info "end...................................on_cash_false_deal"
end
function handler_client_cash_money(player, msg)
	log_info("...................................handler_client_cash_money" ..player.guid)
	log_info(string.format("handler_client_cash_money  begin----------------- player  guid[%d]  money[%d] ", player.guid, msg.money ))
	if player.pb_base_info == nil then
		log_error("handler_client_cash_money pb_base_info"..player.guid)
		return
	end
	local nmsg = {
		result = 1,
		bank = player.pb_base_info.bank ,
		money = player.pb_base_info.money,
	}
	
	if ly_cash_switch == 1 then 
		if player.vip ~= 100 then 
			local msg = {
			result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_MAINTAIN"),
			}
			post_msg_to_client_pb(player,"SC_CashMaintain", msg)		
			return
		end
		
	end
	
	if player.disable == 1 then
		post_msg_to_client_pb(player,"SC_CashMoneyResult", nmsg)		
		return
	end
	msg.cash_type = msg.cash_type or 1
	if msg.cash_type == 1 then
		if (player.alipay_account == nil or player.alipay_account == "") and (player.alipay_name == nil or player.alipay_name == "") then
			log_error ("alipay is empty")
			nmsg.result = 9
			post_msg_to_client_pb(player,"SC_CashMoneyResult", nmsg)		
			return
		end

		if ly_cash_ali_switch == 1 then 
			if player.vip ~= 100 then 
				local msg = {
				result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_ALIBABA_CLOSE"),
				}
				post_msg_to_client_pb(player,"SC_CashMaintain", msg)		
				return
			end
		end
	elseif msg.cash_type == 2 then
		if player.bank_info == nil or player.bank_info.bank_code == nil or player.bank_info.bank_code == ""  then
			log_error ("bank_info is empty")
			nmsg.result = 9
			post_msg_to_client_pb(player,"SC_CashMoneyResult", nmsg)		
			return
		end

		if ly_cash_bank_switch == 1 then 
			if player.vip ~= 100 then 
				local msg = {
				result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_CASH_BANKCLOSE"),
				}
				post_msg_to_client_pb(player,"SC_CashMaintain", msg)		
				return
			end
		end
	else
		return
	end
	local nmoney = msg.money / 100
	if nmoney <50 or  nmoney % 50 ~= 0 then
		log_error ("msg.money < 50 or  msg.money % 50 ~= 0     ----------:".. msg.money )
		post_msg_to_client_pb(player,"SC_CashMoneyResult", nmsg)
		return
	end
	if player.pb_base_info.bank + player.pb_base_info.money < msg.money + 600 then
		local all_money_t_ = player.pb_base_info.bank + player.pb_base_info.money
		log_error ("msg.money----------:".. msg.money .. "all money -----------:" ..all_money_t_)
		post_msg_to_client_pb(player,"SC_CashMoneyResult", nmsg)
		return
	end
	local bRet = false
	local bef_money_ = player.pb_base_info.money 
	local bef_bank_ = player.pb_base_info.bank
	if player.pb_base_info.bank < msg.money then
		local money = msg.money - player.pb_base_info.bank
		bRet = player:change_money(-money, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY"), true)
		if bRet == false then
			log_error("handler_client_cash_money player:change_money false")
			return
		end
		if player.pb_base_info.bank > 0 then
			bRet = player:change_bank(-player.pb_base_info.bank, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY"), true)
			if bRet == false then
				log_error("handler_client_cash_money player:change_bank false")
				return
			end
		end
	else
		bRet = player:change_bank(-msg.money, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY"), true)
		if bRet == false then
			log_error("handler_client_cash_money player:change_bank false")
			return
		end
	end
	local pay_money_ =  0
	if nmoney  < 150 then
		pay_money_ = nmoney - 2
	else
		pay_money_ = nmoney - nmoney * 0.02
	end
	local aft_money_ = player.pb_base_info.money 
	local aft_bank_ = player.pb_base_info.bank
	local fmsg = {
	guid = player.guid,
	money = nmoney,
	coins = msg.money,
	pay_money = pay_money_,
	phone = player.phone,
	phone_type = player.phone_type,
	ip = player.ip,
	bag_id = player.channel_id,
	bef_money = bef_money_,
	bef_bank = bef_bank_,
	aft_money = aft_money_,
	aft_bank = aft_bank_,
	cash_type = msg.cash_type,
	}
	--player.cash_total = player.cash_total + msg.money
	post_msg_to_mysql_pb("SD_CashMoney", fmsg)
	post_msg_to_mysql_pb("SD_Do_OneSql",{db_name = "game",sql = string.format("UPDATE t_player SET cash_total = cash_total + %d WHERE guid = %d",msg.money,player.guid)})
	log_info "end...................................handler_client_cash_money"
end
function handler_client_cash_money_type( player, msg )
	post_msg_to_mysql_pb("SD_CashMoneyType", {guid = player.guid,})
end
function handler_mysql_cash_money_type( msg )
	local player = virtual_player:find(msg.guid)	
	if player then
		local nmsg = {
		pb_cash_info = msg.pb_cash_info
		}
		post_msg_to_client_pb(player,"SC_CashMoneyType",nmsg)
	else		
		log_warning(string.format("handler_mysql_cash_money_type..............................%d no find player", msg.guid))
	end
end
function handler_mysql_cash_money( msg )
	log_info (string.format("handler_mysql_cash_money begin  guid[%d]  money[%d]", msg.guid, msg.coins))
	local player = virtual_player:find(msg.guid)	
	local bRet = false
	if player and  player.pb_base_info  then
		bRet = true
		local nmsg = {
			result = 0,
			bank = player.pb_base_info.bank ,
			money = player.pb_base_info.money,
		}
		if msg.result ~= 1 then				
			nmsg.result = 2
			bRet = player:change_bank(msg.coins, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE"))
		end
		post_msg_to_client_pb(player,"SC_CashMoneyResult", nmsg)
	else		
		log_warning(string.format("handler_mysql_cash_money..............................%d no find player", msg.guid))
	end
	if bRet == false then		
		log_error(string.format("handler_mysql_cash_money no find player  guid[%d]", msg.guid))
		fmsg = {
		web_id =  -1,
		info = {
			guid = msg.guid,
			type_id = pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE"),
			gold = msg.coins,
			order_id = -1,
			},
		}
		post_msg_to_mysql_pb("FD_ChangMoneyDeal",fmsg)
	end
	log_info "end...................................handler_mysql_cash_money"
end
function on_ls_addmoney( msg )
	local player = virtual_player:find(msg.guid)	
	local bRet = false
	if player and  player.pb_base_info  then
		bRet = player:change_bank(msg.money, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY"))
	end
	if bRet == false then
		local fmsg = 
		{
			guid = msg.guid,
			money = msg.money,
			add_type = msg.add_type,
		}
		post_msg_to_login_pb("SL_AddMoney",fmsg)
	end
end
function handler_client_agent_cash_money(player, msg)  
	log_info("...................................handler_client_agent_cash_money" ..player.guid)
	log_info(string.format("handler_client_agent_cash_money  begin----------------- player  guid[%d]  money[%d] ", player.guid, msg.money ))
	local nmsg = {
		result = 1,
		bank = player.pb_base_info.bank ,
		money = player.pb_base_info.money,
	}
	if ly_cash_switch == 1 then 
		if player.vip ~= 100 then 
			local msg = {
			result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_MAINTAIN"),
			}
			post_msg_to_client_pb(player,"SC_Agent_CashMoneyResult", msg)		
			return
		end
		
	end
	if player.disable == 1 then
		post_msg_to_client_pb(player,"SC_Agent_CashMoneyResult", nmsg)		
		return
	end
	local nmoney = msg.money / 100
	if nmoney < 100 or  nmoney % 50 ~= 0 then
		log_error ("msg.money < 50 or  msg.money % 50 ~= 0     ----------:".. msg.money )
		post_msg_to_client_pb(player,"SC_Agent_CashMoneyResult", nmsg)
		return
	end
	if player.pb_base_info.bank + player.pb_base_info.money < msg.money + 1000 then
		local all_money_t_ = player.pb_base_info.bank + player.pb_base_info.money
		log_error ("msg.money----------:".. msg.money .. "all money -----------:" ..all_money_t_)
		post_msg_to_client_pb(player,"SC_Agent_CashMoneyResult", nmsg)
		return
	end
	local bRet = false
	local bef_money_ = player.pb_base_info.money 
	local bef_bank_ = player.pb_base_info.bank
	if player.pb_base_info.bank < msg.money then
		local money = msg.money - player.pb_base_info.bank
		bRet = player:change_money(-money, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY"), true)
		if bRet == false then
			log_error("handler_client_agent_cash_money player:change_money false")
			return
		end
		if player.pb_base_info.bank > 0 then
			bRet = player:change_bank(-player.pb_base_info.bank, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY"), true)
			if bRet == false then
				log_error("handler_client_agent_cash_money player:change_bank false")
				return
			end
		end
	else
		bRet = player:change_bank(-msg.money, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY"), true)
		if bRet == false then
			log_error("handler_client_agent_cash_money player:change_bank false")
			return
		end
	end
	local pay_money_ =  0
	if nmoney  < 150 then
		pay_money_ = nmoney - 2
	else
		pay_money_ = nmoney - nmoney * 0.02
	end
	local aft_money_ = player.pb_base_info.money 
	local aft_bank_ = player.pb_base_info.bank
	local fmsg = {
	guid = player.guid,
	money = nmoney,
	coins = msg.money,
	pay_money = pay_money_,
	phone = player.phone,
	phone_type = player.phone_type,
	ip = player.ip,
	bag_id = player.channel_id,
	bef_money = bef_money_,
	bef_bank = bef_bank_,
	aft_money = aft_money_,
	aft_bank = aft_bank_,
	agent_id = msg.agent_id,
	}
	player.cash_total = player.cash_total + msg.money
	nmsg.result=0
	bank = player.pb_base_info.bank
	money = player.pb_base_info.money,
	post_msg_to_client_pb(player,"SC_Agent_CashMoneyResult", nmsg)
	post_msg_to_mysql_pb("SD_Agent_CashMoney", fmsg)
	post_msg_to_mysql_pb("SD_Do_OneSql",{db_name = "game",sql = string.format("UPDATE t_player SET cash_total = cash_total + %d WHERE guid = %d",msg.money,player.guid)})
	log_info "end7handler_client_agent_cash_money"
end
function handler_client_get_help_money( player,msg )
	if true then 
		log_error(string.format("error handler_client_get_help_money player[%d]",player.guid))
		return
	end

	redis_cmd_query(string.format("GET player_get_help_money_time_%d", player.guid), function (reply)
		if reply:is_error() then
			post_msg_to_client_pb(player,"SC_GetHelpMoney", {result_cash = 4,left_times = 0, 
			cash_money = ly_jjj_value, money_must_less = ly_jjj_limit_line})
			return
		end
		local local_used_times = 0
		local local_result = 1
		if reply:is_string() then
			local_used_times = tonumber(reply:get_string())
		end
		if msg.get_rightnow == 2 then
			post_msg_to_client_pb(player,"SC_GetHelpMoney", {result_cash = 4,left_times = ly_jjj_time_limit - local_used_times, 
			cash_money = ly_jjj_value, money_must_less = ly_jjj_limit_line})
			return
		end
		if player.disable == 1 or ((player.pb_base_info.bank + player.pb_base_info.money) > ly_jjj_limit_line) then
			local_result = 3
		elseif local_used_times < ly_jjj_time_limit then
			local bRet = player:change_money(ly_jjj_value, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_RELIEF_PAYMENT"), true)
			if bRet == false then
				log_error("handler_client_get_help_money player:change_money false")
				local_result = 3
			else
				local_used_times = local_used_times + 1
				redis_command(string.format("SET player_get_help_money_time_%d %d", player.guid,local_used_times))
				local now_time = os.date("*t",os.time())
				local left_sec = 24*3600 - (now_time.hour*3600 + now_time.min*60 + now_time.sec)
				redis_command(string.format("EXPIRE player_get_help_money_time_%d %d", player.guid,left_sec))
			end
		else
			local_result = 2
		end
		post_msg_to_client_pb(player,"SC_GetHelpMoney", {result_cash = local_result,left_times = ly_jjj_time_limit - local_used_times, 
		cash_money = ly_jjj_value, money_must_less = ly_jjj_limit_line})	
	end)
end

local function string_split(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end
function on_ls_lua_game_cmd( msg )
	log_info("on_ls_lua_game_cmd gameid = "..msg.gameid.." msg.cmd "..msg.cmd)
	if msg.cmd == "change_storage" then
		local change = tonumber(msg.param)
		if change == nil then
			local fmsg = 
			{
				result = 0,
				param = lua_to_json(param_back),
				webid = msg.webid
			}
			post_msg_to_login_pb("SL_LuaGameCmd",fmsg)
			log_info("change_storage "..tostring(msg.param))
			return
		end

		local param_back = {old_stroage = ly_robot_storage, new_stroage = ly_robot_storage + change}
		ly_robot_storage = param_back.new_stroage
		
		if def_game_id > 2 and def_game_id < 7 then
			ly_robot_storage=AddEarnings(change)
			param_back.new_stroage=ly_robot_storage
		end
		log_info(string.format("change_storage  %d = %d + %d",param_back.new_stroage,param_back.old_stroage,change))
		
		local fmsg = 
		{
			result = 1,
			param = lua_to_json(param_back),
			webid = msg.webid
		}
		post_msg_to_login_pb("SL_LuaGameCmd",fmsg)


		post_msg_to_mysql_pb("SD_Save_Storage", {
			game_id = def_game_id,
			storage = ly_robot_storage
		})

		local sql = string.format(
		[[insert into t_log_change_storage
		( game_id , change_storage , time )
		values(%d, %d, '%s')
		]],
		def_game_id,
		change,
		os.date('%Y-%m-%d %H:%M:%S')
		)
		post_msg_to_mysql_pb("SD_Do_OneSql",{db_name = "log", sql = sql})
		return
	elseif msg.cmd == "change_maintain" then
		local fmsg = 
		{
			result = 1,
			param = "",
			webid = msg.webid
		}
		post_msg_to_login_pb("SL_LuaGameCmd",fmsg)
		
		if handler_client_change_maintain then
			local maintain_msg = {
				maintaintype = 2,
				switchopen = 0,
				game_id = msg.gameid,
			}
			local msggametype = def_game_id_table[tonumber(msg.gameid)]
			maintain_msg.first_game_type = 0
			if msggametype ~= nil  then
				maintain_msg.switchopen = 1
				maintain_msg.first_game_type = msggametype
			end
			--log_info("change_maintain gameid = "..msg.gameid.." msggametype "..maintain_msg.first_game_type)
			if maintain_msg.first_game_type > 0 then
				handler_client_change_maintain(maintain_msg)
			end
		end
		return
	elseif msg.cmd == "clear_kill_player" then
		ly_kill_list = {}
		log_info("clear_kill_player ....")
	elseif msg.cmd == "kill_player" then
		local fmsg = 
		{
			result = 1,
			param = "suc",
			webid = msg.webid
		}
		post_msg_to_login_pb("SL_LuaGameCmd",fmsg)

		log_info("kill_player  " .. msg.param)
		local param_list = string_split(msg.param, ",")
		if #param_list == 2 then
			--param  guid,times  例如  杀23556玩家 5次 参数为：23556，5
			local guid = tonumber(param_list[1])
			local times = tonumber(param_list[2])
			if guid > 0 and times > 0 then
				ly_kill_list[guid] = ly_kill_list[guid] or 0
				ly_kill_list[guid] = ly_kill_list[guid] + times
			end
		end
		return
	elseif msg.cmd == "change_brnn_chi_cfg" then
		local fmsg = 
		{
			result = 0,
			param = "fail",
			webid = msg.webid
		}

		local param_list = string_split(msg.param, ",")
		if #param_list == 4 then
			local gameid = tonumber(param_list[1])
			local beginr = tonumber(param_list[2])
			local endr = tonumber(param_list[3])
			local prob = tonumber(param_list[4])
			if gameid == def_game_id and beginr >= 0 and beginr < endr and prob >= 0 then
				fmsg.result = 1
				fmsg.param = "suc"
				for i=1,20 do
					for k,v in pairs(ly_brnn_chi_cfg) do
						if (beginr >= v.beginr and beginr < v.endr ) or (endr > v.beginr and endr <= v.endr) then
							table.remove(ly_brnn_chi_cfg,k)
							break
						end
					end
				end
				ly_brnn_chi_cfg[#ly_brnn_chi_cfg + 1] = {beginr = beginr,endr = endr,prob = prob}
			end
		end
		post_msg_to_login_pb("SL_LuaGameCmd",fmsg)
		return
	end

	local fmsg = 
	{
		result = 1,
		param = "suc",
		webid = msg.webid
	}
	post_msg_to_login_pb("SL_LuaGameCmd",fmsg)
end
