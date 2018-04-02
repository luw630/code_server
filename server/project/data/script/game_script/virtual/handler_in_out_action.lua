local pb = require "extern/lib/lib_pb"
require "game_script/handler_net"
local post_msg_to_mysql_pb = post_msg_to_mysql_pb
local post_msg_to_client_pb = post_msg_to_client_pb
local post_msg_to_client_login = post_msg_to_client_login
local post_msg_to_cfg_pb = post_msg_to_cfg_pb
require "game_script/virtual/virtual_player"
local virtual_player = virtual_player
require "game_script/virtual/virtual_robot"
local virtual_active_android = virtual_active_android
local virtual_passive_android = virtual_passive_android
require "game_script/virtual/virtual_robot_mgr"
local android_manager = android_manager
require "extern/lib/lib_redis"
local redis_command = redis_command
local redis_cmd_query = redis_cmd_query
require "extern/lib/lib_timer"
local add_timer = add_timer
local def_save_db_time = 60 
local room_manager = g_room_mgr
local g_get_game_cfg = g_get_game_cfg
local def_game_id = def_game_id
local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type
local def_game_name = def_game_name
local using_login_validatebox = using_login_validatebox
local def_register_money = get_register_money()
local def_private_room_bank = get_private_room_bank()
require "extern/lib/lib_table"
local validatebox_ch = {}
for i=1,35 do
	table.insert(validatebox_ch, i)
end 
local function get_validatebox_ch()
	local ch ={}
	local count = #validatebox_ch
	for i=1,4 do
		local r = math.random(count)
		table.insert(ch, validatebox_ch[r])
		if r ~= count then
			validatebox_ch[r], validatebox_ch[count] = validatebox_ch[count], validatebox_ch[r]
		end
		count = count-1
	end
	return ch
end
function on_ls_AlipayEdit(msg)
	
	local  notify = {
		guid = msg.guid,
		alipay_name = msg.alipay_name,
		alipay_name_y = msg.alipay_name_y,
		alipay_account = msg.alipay_account,
		alipay_account_y = msg.alipay_account_y,
	}
	local player = virtual_player:find(msg.guid)
	if player  then
		player.alipay_account = msg.alipay_account
		player.alipay_name = msg.alipay_name		
	end
	post_msg_to_client_pb(player,  "SC_AlipayEdit" , notify)
end
function on_new_nitice(msg)
	
	if msg then
		virtual_player:updateNoticeEverone(msg)
	end
end
function  on_ls_DelMessage(msg)
	
	if msg then
		virtual_player:deleteNoticeEverone(msg)
	end
end


function on_redis_ddzdapai(player,is_first,num)
	if is_first == 1 then
		redis_command(string.format("HSET player_ddzdapai %d %d", player.guid, 0))
		player.ddz_dapai_times = 0
		log_info("on_redis_ddzdapai "..player.guid.." num = "..0)
		return
	elseif is_first == 2 then
		on_redis_getddzdapai(player.guid)
	elseif is_first == 3 then
		redis_command(string.format("HSET player_ddzdapai %d %d", player.guid, num))
		log_info("on_redis_ddzdapai "..player.guid.." num = "..num)
		if num >= 3 then
			redis_command(string.format("HDEL player_ddzdapai %d ", player.guid))
			log_info("on_redis_ddzdapai HDEL "..player.guid)
		end
	end

end

function on_redis_getddzdapai(guid)
	redis_cmd_query(string.format("HGET player_ddzdapai %d", guid), function (reply)
		if reply:is_string() then
			local player = virtual_player:find(guid)
			if player then
				player.ddz_dapai_times = tonumber(reply:get_string())
				log_info("on_redis_getddzdapai "..player.guid.."  num "..reply:get_string())
			end
		else
			local player = virtual_player:find(guid)  --没有查询到设置为4
			if player then
				player.ddz_dapai_times = 4
				log_info("on_redis_getddzdapai "..player.guid.."  num "..4)
			end
		end
	end)
end

function on_ls_login_notify(msg)
	local info = msg.player_login_info
	if info.is_reconnect then
		local player = virtual_player:find(info.guid)
		if player then
			player.online = true
			player.session_id = info.session_id
			player.gate_id = info.gate_id
			player.phone = info.phone
			player.phone_type = info.phone_type
			player.version = info.version
			player.channel_id = info.channel_id
			player.package_name = info.package_name
			player.imei = info.imei
			player.ip = info.ip
			player.risk = info.risk or 0
			player.ip_area = info.ip_area
			player.create_channel_id = info.create_channel_id
			player.enable_transfer = info.enable_transfer
			player.inviter_guid = info.inviter_guid or player.inviter_guid or 0
			player.invite_code = info.invite_code or player.invite_code or "0"
	
			post_msg_to_client_login(info.session_id, info.gate_id, "LC_Login", {
				guid = info.guid,
				account = info.account,
				game_id = def_game_id,
				nickname = info.nickname,
				is_guest = info.is_guest,
				password = msg.password,
				alipay_account = info.alipay_account,
				alipay_name = info.alipay_name,
				change_alipay_num = info.change_alipay_num,
				ip_area = info.ip_area,
				enable_transfer = info.enable_transfer,
			})
			
			post_msg_to_mysql_pb("SD_OnlineAccount", {
				guid = player.guid,
				first_game_type = def_first_game_type,
				second_game_type = def_second_game_type,
				gamer_id = def_game_id,
				})

			log_info(string.format("player %d reconnect ...", player.guid))
			return
		end
	end
	local player = virtual_player:new()
	player:init(info.guid, info.account, info.nickname)
	player.session_id = info.session_id
	player.gate_id = info.gate_id
	player.vip = info.vip
	player.login_time = info.login_time
	player.logout_time = info.logout_time
	player.bank_password = info.has_bank_password
	player.is_guest = info.is_guest
	player.bank_login = false
	player.online_award_start_time = 0
	player.alipay_account = info.alipay_account
	player.alipay_name = info.alipay_name
	player.change_alipay_num = info.change_alipay_num
	player.phone = info.phone
	player.phone_type = info.phone_type
	player.version = info.version
	player.channel_id = info.channel_id
	player.package_name = info.package_name
	player.imei = info.imei
	player.ip = info.ip
	player.risk = info.risk or 0
	player.ip_area = info.ip_area
	player.create_channel_id = info.create_channel_id
	player.enable_transfer = info.enable_transfer
	player.inviter_guid = info.inviter_guid or player.inviter_guid or 0
	player.invite_code = info.invite_code or player.invite_code or "0"
	log_info(string.format("player %d login ...", player.guid))
	local notify = {
		guid = info.guid,
		account = info.account,
		game_id = def_game_id,
		nickname = info.nickname,
		is_guest = info.is_guest,
		password = msg.password,
		alipay_account = info.alipay_account,
		alipay_name = info.alipay_name,
		change_alipay_num = info.change_alipay_num,
		ip_area = info.ip_area,
		enable_transfer = info.enable_transfer,
		is_first = info.is_first,
	}
	log_info("on_ls_login_notify is_first "..player.guid.." is_first "..info.is_first)
	on_redis_ddzdapai(player,info.is_first,0)
	
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	if using_login_validatebox and player.is_guest and player.login_time ~= 0 and to_days(player.login_time) ~= cur_to_days() then
		local ch = get_validatebox_ch()
		local r1 = math.random(4)
		local r2 = math.random(4)
		if r1 == r2 then
			r2 = r2%4+1
		end
		player.login_validate_answer = {ch[r1], ch[r2]}
		notify.is_validatebox = true
		notify.pb_validatebox = {
			question = ch,
			answer = player.login_validate_answer,
		}
	end
	post_msg_to_client_login(info.session_id, info.gate_id, "LC_Login", notify)
	
	local guid = player.guid
	local function save_db_timer()
		local p = virtual_player:find(guid)
		if not p then
			return
		end
		if p ~= player then
			return
		end
		p:save()
		add_timer(def_save_db_time, save_db_timer)
	end
	save_db_timer()
	post_msg_to_mysql_pb("SD_OnlineAccount", {
		guid = player.guid,
		first_game_type = def_first_game_type,
		second_game_type = def_second_game_type,
		gamer_id = def_game_id,
		})
	post_msg_to_mysql_pb("SD_GetBankCardInfo", {
			guid = player.guid,
		})
	handler_client_get_bank_card_info(player, msg)
	player:update_platfrom_online_info("on")


	local sql = string.format(
		[[insert into t_log_login 
		( guid , gate_id , game_id , account, ip_str, ip_area, mac_str, channel_id, 
		version, phone, phone_type, login_time )
		values(%d, %d, %d, '%s', '%s', '%s', '%s' , '%s', '%s', '%s','%s','%s')
		]],
		player.guid,
		player.gate_id,
		def_game_id,
		player.account,
		player.ip,
		player.ip_area,
		player.imei,
		player.channel_id,
		player.version,
		player.phone,
		player.phone_type,
		os.date('%Y-%m-%d %H:%M:%S')
		)
	post_msg_to_mysql_pb("SD_Do_OneSql",{db_name = "log", sql = sql})

	-- post_msg_to_mysql_pb("SD_QueryPlayerCharge", {
	-- 		game_id = def_game_id,
	-- 		guid = player.guid,
	-- 	})
--------test
end

function on_notify_php(guid_)
	if g_notify_list[guid_] ~= nil then
		post_msg_to_mysql_pb("SD_NotifyPhpServer",{guid = guid_})
		log_info("on_notify_php "..guid_)
		--http_post_no_reply("http://125.88.177.32:8088/api/notice/noticePotato",string.format("{\"guid\":\"%d\"}",guid)
	end
end

function on_ls_login_notify_again(msg)
	local player = virtual_player:find(msg.guid)
	if player then
		local notify = {
			guid = player.guid,
			account = player.account,
			game_id = def_game_id,
			nickname = player.nickname,
			is_guest = player.is_guest,
			password = msg.password,
			alipay_account = player.alipay_account,
			alipay_name = player.alipay_name,
			change_alipay_num = player.change_alipay_num,
		}
		math.randomseed(tostring(os.time()):reverse():sub(1, 6))
		
		if using_login_validatebox and player.is_guest and player.login_time ~= 0 and to_days(player.login_time) ~= cur_to_days() then
			local ch = get_validatebox_ch()
			local r1 = math.random(4)
			local r2 = math.random(4)
			if r1 == r2 then
				r2 = r2%4+1
			end
			player.login_validate_answer = {ch[r1], ch[r2]}
			notify.is_validatebox = true
			notify.pb_validatebox = {
				question = ch,
				answer = player.login_validate_answer,
			}
		end
		post_msg_to_client_login(player.session_id, player.gate_id, "LC_Login", notify)
		log_info(string.format("notify_again player %d ...", player.guid))
	else
		log_info(string.format("notify_again player %d nil ...", msg.guid))
	end
end
function handler_client_login_validatebox(player, msg)
	if msg and msg.answer and #msg.answer == 2 and player.login_validate_answer and #player.login_validate_answer == 2  and 
		((msg.answer[1] == player.login_validate_answer[1] and msg.answer[2] == player.login_validate_answer[2]) or
		(msg.answer[1] == player.login_validate_answer[2] and msg.answer[2] == player.login_validate_answer[1])) then
		post_msg_to_client_pb(player,  "SC_LoginValidatebox", {
			result = pb.get_ev("LOGIN_RESULT", "LOGIN_RESULT_SUCCESS"),
			})
		return
	end
	
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
		local ch = get_validatebox_ch()
		local r1 = math.random(4)
		local r2 = math.random(4)
		if r1 == r2 then
			r2 = r2%4+1
		end
		player.login_validate_answer = {ch[r1], ch[r2]}
		local notify = {
			question = ch,
			answer = player.login_validate_answer,
		}
		
		local msg = {result = pb.get_ev("LOGIN_RESULT", "LOGIN_RESULT_LOGIN_VALIDATEBOX_FAIL"),pb_validatebox = notify}
		post_msg_to_client_pb(player,  "SC_LoginValidatebox",msg)
end
function logout(guid_, bfishing)
	local player = virtual_player:find(guid_)
	if not player then
		return
	end
	
	post_msg_to_mysql_pb("S_Logout", {
		account = player.account,
		guid = guid_,
		login_time = player.login_time,
		logout_time = get_second_time(),
		phone = player.phone,
		phone_type = player.phone_type,
		version = player.version,
		channel_id = player.channel_id,
		package_name = player.package_name,
		imei = player.imei,
		ip = player.ip,
	})

	log_info(string.format("player [%d] exit this server ...",guid_))
	redis_command(string.format("HDEL player_login_info %s", player.account))
	redis_command(string.format("HDEL player_login_info_guid %d", guid_))
	if player.pb_base_info then
		if room_manager:exit_server(player) then
			return true 
		end
		player.logout_time = get_second_time()
	
		local old_online_award_time = player.pb_base_info.online_award_time
		player.pb_base_info.online_award_time = player.pb_base_info.online_award_time + player.logout_time - player.online_award_start_time
		if old_online_award_time ~= player.pb_base_info.online_award_time then
		end
		player.online = false
		player:save()
	end
	
		
	
	redis_command(string.format("HDEL player_online_gameid %d", player.guid))
	redis_command(string.format("HDEL player_session_gate %d@%d", player.session_id, player.gate_id))
	
	player:del()
	return false
end
function on_s_logout(msg)
	log_info(string.format("logout player %d ...", msg.guid))
	logout(msg.guid)
	if msg.user_data > 0 then
		post_msg_to_login_pb("L_KickClient", {
			reply_account = player.account,
			user_data = msg.user_data,
		})
	end
end

local function next_day(player)
	local next_login_award_day = player.pb_base_info.login_award_day + 1
	if data_login[next_login_award_day] then
		player.pb_base_info.login_award_day = next_login_award_day
	end
	
	player.pb_base_info.online_award_time = 0
	player.pb_base_info.online_award_num = 0
	player.pb_base_info.relief_payment_count = 0
	player.flag_base_info = true
	player.online_award_start_time = get_second_time()
end
local function load_player_data_complete(player)
	player.login_time = get_second_time()
	player.online_award_start_time = player.login_time
	
	if player.is_offline then
	end
	if room_manager:isPlay(player) then
	end
	if player.is_offline and room_manager:isPlay(player) then
		local notify = {
			pb_gmMessage = {
				first_game_type = def_first_game_type,
				second_game_type = def_second_game_type,
				room_id = player.room_id,
				table_id = player.table_id,
				chair_id = player.chair_id,
			}
		}
		post_msg_to_client_pb(player,  "SC_ReplyPlayerInfoComplete", notify)
		room_manager:player_online(player)
		return
	end
	player.is_offline = nil
	
	
	post_msg_to_client_pb(player,  "SC_ReplyPlayerInfoComplete", nil)
	
	post_msg_to_mysql_pb("SD_QueryPlayerInviteReward", {
				guid = player.guid,
			})
end
local channel_cfg = {}
function channel_invite_cfg(channel_id)
	if channel_cfg then
		for k,v in pairs(channel_cfg) do
			if v.channel_id == channel_id then
				return v
			end
		end
	end
	return nil
end
function handler_mysql_load_channel_invite_cfg(msg)
	channel_cfg = msg.cfg or {}	
end
function handler_mysql_load_robot_cfg(msg)
	ly_use_robot = msg.use_robot == 1
	if ly_robot_storage == DEF_NUM_MAX then ly_robot_storage = msg.storage end
	ly_robot_smart_lv = msg.robot_level
	log_info("load-robot-cfg-suc... cur storage is " .. ly_robot_storage)
	log_info("load-robot-cfg-suc... cur smart_lv is " .. ly_robot_smart_lv)
end
function handler_mysql_load_brnn_chi_cfg(msg)
	ly_brnn_chi_cfg = {}
	for k,v in pairs(msg.pb_brnn_chi_cfg) do
		ly_brnn_chi_cfg[#ly_brnn_chi_cfg + 1] = {beginr = v.beginr,endr = v.endr,prob = v.prob}
		log_info(string.format("load_brnn_chi_cfg %s-%s prob %s",tostring(v.beginr),tostring(v.endr),tostring(v.prob)))
	end
end

function handler_mysql_load_player_invite_reward(msg)
	local player = virtual_player:find(msg.guid)
	if not player then
		return
	end
	if msg.reward and msg.reward > 0 then player:change_money(msg.reward,pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_INVITE")) end
end
local function check_load_complete(player)
		load_player_data_complete(player)
		player.flag__request_player_info = nil
end
function handler_client_request_player_info(player, msg)
	local guid = player.guid
	if player.flag__request_player_info then
		return
	end
	player.flag__request_player_info = true
		post_msg_to_mysql_pb("SD_QueryPlayerData", {
			guid = player.guid,
			account = player.account,
			nickname = player.nickname,
		})
		post_msg_to_mysql_pb("SD_QueryPlayerMsgData", {
			guid = player.guid,
		})
		post_msg_to_mysql_pb("SD_QueryPlayerMarquee", {
			guid = player.guid,
		})
end
function handler_mysql_load_player_data(msg)
	local player = virtual_player:find(msg.guid)
	if not player then
		log_warning(string.format("guid[%d] not find in game", msg.guid))
		return
	end
	if msg.info_type == 1 then
		if #msg.pb_base_info > 0 then
			local data = pb.decode(msg.pb_base_info[1], msg.pb_base_info[2])
			data.money = data.money or 0
			data.bank = data.bank or 0
			data.slotma_addition = data.slotma_addition or 0
			player.pb_base_info = data
			
			post_msg_to_client_pb(player, "SC_ReplyPlayerInfo", {
				pb_base_info = data,
			})
		else
			player.pb_base_info = {}
		end
		check_load_complete(player)
	end
end
function on_S_ReplyPrivateRoomConfig(msg)
	g_PrivateRoomConfig = {}
	for i,v in ipairs(msg.info_list.info) do
		local t = {game_id = v.game_id, first_game_type = v.first_game_type}
		if v.first_game_type == 6 then
			t.room_cfg = {}
			local cfg = parse_table(v.room_lua_cfg)
			for j,u in ipairs(cfg) do
				table.insert(t.room_cfg, {cell_money = u.score[1], money_limit = u.money_limit})
			end
	
		elseif v.first_game_type == 5 then
			t.room_cfg = {}
			local cfg = parse_table(v.room_lua_cfg)
			for j,u in ipairs(cfg) do
				table.insert(t.room_cfg, {cell_money = u.score, money_limit = u.money_limit})
			end
		
		elseif v.first_game_type == 7 then
			t.room_cfg = {}
			local cfg = parse_table(v.room_lua_cfg).p_cfg
			for j,u in ipairs(cfg) do
				table.insert(t.room_cfg, {cell_money = u.score, money_limit = u.money_limit})
			end
		end
		table.insert(g_PrivateRoomConfig, t)
	end
end
local function calcPrivateRoomNeedMoney(first_game_type, second_game_type, chair_count)
	for i,v in ipairs(g_PrivateRoomConfig) do
		if v.first_game_type == first_game_type then
			local cfg = v.room_cfg[second_game_type]
			if not cfg then
				break
			end
			local money = cfg.money_limit
			if chair_count then
				money = money + cfg.cell_money * chair_count
			end
			return money
		end
	end
	return nil
end
local function getCreatePrivateRoomNeedMoney(first_game_type, second_game_type, chair_count)
	for i,v in ipairs(g_PrivateRoomConfig) do
		if v.first_game_type == first_game_type then
			local cfg = v.room_cfg[second_game_type]
			if not cfg then
				break
			end
			if chair_count then
				return cfg.cell_money * chair_count
			end
		end
	end
	return 0
end
local function getPrivateRoomCellAndLimit(first_game_type, second_game_type)
	for i,v in ipairs(g_PrivateRoomConfig) do
		if v.first_game_type == first_game_type then
			local cfg = v.room_cfg[second_game_type]
			if not cfg then
				break
			end
			return cfg.cell_money, cfg.money_limit
		end
	end
	return 0, 0
end
local function checkPrivateRoomChair(first_game_type, chair_count)
	if first_game_type == 5 and chair_count == 3 then
		return true
	elseif first_game_type == 6 and chair_count >= 2 and chair_count <= 5 then
		return true
	end
	return false
end
function handler_client_change_game(player, msg)
	if player.disable == 1 then		
		if not room_manager:isPlay(player) then
			player:forced_exit();
		end
		return
	end

	if msg == nil then
		return
	end
	
	if  g_ly_game_switch_list[msg.first_game_type]  == 1 then 
		if player.vip ~= 100 then	
			post_msg_to_client_pb(player, "SC_GameMaintain", {
					result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_MAINTAIN"),
					first_game_type = msg.first_game_type,
					second_game_type = 0,
					})
			player:forced_exit()
			log_warning(string.format("GameServer will maintain,exit"))	
			return
		end	
	
	end
	if msg.private_room_opt == 1 and not checkPrivateRoomChair(msg.first_game_type, msg.private_room_chair_count) then
		post_msg_to_client_pb(player, "SC_EnterRoomAndSitDown", {
			result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_CHAIR"),
			game_id = def_game_id,
			first_game_type = msg.first_game_type,
			second_game_type = msg.second_game_type,
			ip_area = player.ip_area,
			private_room_score_type = msg.private_room_score_type,
			})
		return
	end
	if msg.private_room_opt == 1 then
		local needmoney = calcPrivateRoomNeedMoney(msg.first_game_type, msg.private_room_score_type, msg.private_room_chair_count)
		if not needmoney then
			post_msg_to_client_pb(player, "SC_EnterRoomAndSitDown", {
			result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_CHAIR"),
			game_id = def_game_id,
			first_game_type = msg.first_game_type,
			second_game_type = msg.second_game_type,
			ip_area = player.ip_area,
			private_room_score_type = msg.private_room_score_type,
			})
			return
		end
		local money = player.pb_base_info.money or 0
		if money < needmoney then
			post_msg_to_client_pb(player, "SC_EnterRoomAndSitDown", {
			result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_MONEY"),
			game_id = def_game_id,
			first_game_type = msg.first_game_type,
			second_game_type = msg.second_game_type,
			ip_area = player.ip_area,
			private_room_score_type = msg.private_room_score_type,
			balance_money = needmoney-money,
			})
			return
		end
	end
	if msg.first_game_type == def_first_game_type and msg.second_game_type == def_second_game_type then
		local b_private_room = true
		local result_, room_id_, table_id_, chair_id_, tb
		if msg.private_room_opt == 1 then
			local cell_money_, money_limit_ = getPrivateRoomCellAndLimit(msg.first_game_type, msg.private_room_score_type)
			result_, room_id_, table_id_, chair_id_, tb = room_manager:create_private_room(player, msg.private_room_chair_count, msg.private_room_score_type, cell_money_)
			if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
			
				local money = getCreatePrivateRoomNeedMoney(msg.first_game_type, msg.private_room_score_type, msg.private_room_chair_count)
				if money > 0 then
					player:change_money(-money, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CREATE_PRIVATE_ROOM"))
				end
				
				tb.open_private_room_cost = money
			end
		elseif msg.private_room_opt == 2 then
			result_, room_id_, table_id_, chair_id_, tb = room_manager:join_private_room(player, msg.owner_guid, player)
		else
			result_, room_id_, table_id_, chair_id_, tb = room_manager:enter_room_and_sit_down(player)
			b_private_room = false
		end
		if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
			local notify = {
				room_id = room_id_,
				table_id = table_id_,
				chair_id = chair_id_,
				result = result_,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				private_room = b_private_room,
				private_room_score_type = msg.private_room_score_type,
				private_room_cell_money = tb.private_room_cell_money,
				private_room_id = tb.private_room_id,
			}
			tb:foreach_except(chair_id_, function (p)
				local v = {
					chair_id = p.chair_id,
					guid = p.guid,
					account = p.account,
					nickname = p.nickname,
					level = p:get_level(),
					money = p:get_money(),
					header_icon = p:get_avatar(),
					ip_area = p.ip_area,
				}
				if tb.ready_list_ and tb.ready_list_[p.chair_id] then
					v.is_ready = true
				end
				notify.pb_visual_info = notify.pb_visual_info or {}
				if msg.first_game_type ~= 8 or #notify.pb_visual_info < 9 then 
					table.insert(notify.pb_visual_info, v)
				end
			end)
			
			post_msg_to_client_pb(player, "SC_EnterRoomAndSitDown", notify)
			tb:player_sit_down_finished(player)
			player.noready = nil 
	
			post_msg_to_mysql_pb("SD_OnlineAccount", {
				guid = player.guid,
				first_game_type = def_first_game_type,
				second_game_type = def_second_game_type,
				gamer_id = def_game_id,
				in_game = 1,
				})
			if msg.private_room_opt == 1 then
				local cell_money_, money_limit_ = getPrivateRoomCellAndLimit(msg.first_game_type, msg.private_room_score_type)
				post_msg_to_mysql_pb("SD_PrivateRoomLog", {
					room_id = tb.private_room_id,
					owner_guid = player.guid,
					first_game_type = def_first_game_type,
					chair_max = msg.private_room_chair_count,
					chair_count = 1,
					cell_money = cell_money_,
					room_cost = cell_money_ * msg.private_room_chair_count,
					money_limit = money_limit_,
					room_state = 1,
					})
			end
		else
			post_msg_to_client_pb(player, "SC_EnterRoomAndSitDown", {
				result = result_,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				private_room_score_type = msg.private_room_score_type,
				})
		end
	else
		if room_manager:isPlay(player) then
			post_msg_to_client_pb(player, "SC_EnterRoomAndSitDown", {
			result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_GAME"),
			})
			return
		end
		
		log_info(string.format("guid[%d] account[%s] request change game to server[%d-%d] ...", player.guid, player.account,
		msg.first_game_type,msg.second_game_type))	
			
		post_msg_to_login_pb("SS_ChangeGame", {
			guid = player.guid,
			session_id = player.session_id,
			gate_id = player.gate_id,
			account = player.account,
			nickname = player.nickname,
			vip = player.vip,
			login_time = player.login_time,
			logout_time = player.logout_time,
			bank_password = player.bank_password,
			bank_login = player.bank_login,
			is_guest = player.is_guest,
			online_award_start_time = player.online_award_start_time,
			game_id = def_game_id,
			first_game_type = msg.first_game_type,
			second_game_type = msg.second_game_type,
			phone = player.phone,
			phone_type = player.phone_type,
			version = player.version,
			channel_id = player.channel_id,
			package_name = player.package_name,
			imei = player.imei,
			ip = player.ip,
			ip_area = player.ip_area,
			risk = player.risk,
			create_channel_id = player.create_channel_id,
			enable_transfer = player.enable_transfer,
			inviter_guid = player.inviter_guid,
			invite_code = player.invite_code,
			pb_base_info = player.pb_base_info,
			private_room_opt = msg.private_room_opt,
			owner_guid = msg.owner_guid,
			private_room_chair_count = msg.private_room_chair_count,
			private_room_score_type = msg.private_room_score_type,
			alipay_account = player.alipay_account,
			alipay_name = player.alipay_name,
			change_alipay_num = player.change_alipay_num,
			ddz_dapai_times = player.ddz_dapai_times,
		})
	end
end
function on_LS_ChangeGameResult(msg)
	if msg.success then
		local player = virtual_player:find(msg.guid)
		if not player then
			return
		end

		----  test ----
		--player.pb_base_info.money = math.random(100,1000000)
		--player.pb_base_info.bank = math.random(100,1000000)
		----  test ----
		if msg.change_msg.pb_base_info and msg.change_msg.pb_base_info.money and player.pb_base_info and player.pb_base_info.money then
			if msg.change_msg.pb_base_info.money ~= player.pb_base_info.money then 
				log_error(string.format("msg.change_msg.pb_base_info.money is %d,player.pb_base_info.money is %d,guid %d",
				msg.change_msg.pb_base_info.money,player.pb_base_info.money,player.guid))
				msg.change_msg.pb_base_info.money = player.pb_base_info.money
			end
		end
		if msg.change_msg.pb_base_info and msg.change_msg.pb_base_info.bank and player.pb_base_info and player.pb_base_info.bank then
			if msg.change_msg.pb_base_info.bank ~= player.pb_base_info.bank then 
				log_error(string.format("msg.change_msg.pb_base_info.bank is %d,player.pb_base_info.bank is %d,guid %d",
				msg.change_msg.pb_base_info.bank,player.pb_base_info.bank,player.guid))
				msg.change_msg.pb_base_info.bank = player.pb_base_info.bank
			end
		end

		room_manager:exit_server(player)
		player:save()
	
		post_msg_to_mysql_pb("SD_Delonline_player", {
		guid = player.guid,
		game_id = def_game_id,
		})
		
		player:del()
		
		post_msg_to_login_pb("SL_ChangeGameResult", msg)
	end
end
local function check_change_complete(player, msg)
		local b_private_room = true
		local result_, room_id_, table_id_, chair_id_, tb
		if msg.private_room_opt == 1 then
			local cell_money_, money_limit_ = getPrivateRoomCellAndLimit(msg.first_game_type, msg.private_room_score_type)
			result_, room_id_, table_id_, chair_id_, tb = room_manager:create_private_room(player, msg.private_room_chair_count, msg.private_room_score_type, cell_money_)
			if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
				local money = getCreatePrivateRoomNeedMoney(msg.first_game_type, msg.private_room_score_type, msg.private_room_chair_count)
				if money > 0 then
					player:change_money(-money, pb.get_ev("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CREATE_PRIVATE_ROOM"))
				end
			end
		elseif msg.private_room_opt == 2 then
			result_, room_id_, table_id_, chair_id_, tb = room_manager:join_private_room(player, msg.owner_guid, player)
		else
			result_, room_id_, table_id_, chair_id_, tb = room_manager:enter_room_and_sit_down(player)
			b_private_room = false
		end
		if result_ == pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS") then
			local notify = {
				room_id = room_id_,
				table_id = table_id_,
				chair_id = chair_id_,
				result = result_,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				private_room = b_private_room,
				private_room_score_type = msg.private_room_score_type,
				private_room_cell_money = tb.private_room_cell_money,
				private_room_id = tb.private_room_id,
			}
			tb:foreach_except(chair_id_, function (p)
				local v = {
					chair_id = p.chair_id,
					guid = p.guid,
					account = p.account,
					nickname = p.nickname,
					level = p:get_level(),
					money = p:get_money(),
					header_icon = p:get_avatar(),
					ip_area = p.ip_area,
				}
				if tb.ready_list_ and tb.ready_list_[p.chair_id] then
					v.is_ready = true
				end
				notify.pb_visual_info = notify.pb_visual_info or {}
				if msg.first_game_type ~= 8 or #notify.pb_visual_info < 9 then 
					table.insert(notify.pb_visual_info, v)
				end
			end)
			
			post_msg_to_client_pb(player, "SC_EnterRoomAndSitDown", notify)
			tb:player_sit_down_finished(player)
			if msg.private_room_opt == 1 then
				local cell_money_, money_limit_ = getPrivateRoomCellAndLimit(msg.first_game_type, msg.private_room_score_type)
				post_msg_to_mysql_pb("SD_PrivateRoomLog", {
					room_id = tb.private_room_id,
					owner_guid = player.guid,
					first_game_type = def_first_game_type,
					chair_max = msg.private_room_chair_count,
					chair_count = 1,
					cell_money = cell_money_,
					room_cost = cell_money_ * msg.private_room_chair_count,
					money_limit = money_limit_,
					room_state = 1,
					})
			end
		else
			post_msg_to_client_pb(player, "SC_EnterRoomAndSitDown", {
				result = result_,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				private_room_score_type = msg.private_room_score_type,
				})
		end
end
function on_ss_change_game(msg)
	local player = virtual_player:find(msg.guid)
	if player then
		room_manager:exit_server(player)
		player:del()
		log_warning(string.format("guid[%d] in game=%d  yet ...", msg.guid, def_game_id))		
	end
	log_info(string.format("guid[%d] account[%s] change game to this server ...", msg.guid, msg.account))

	local player = virtual_player:new()
	player:init(msg.guid, msg.account, msg.nickname)
	
	player.session_id = msg.session_id
	player.gate_id = msg.gate_id
	player.vip = msg.vip
	player.login_time = msg.login_time
	player.logout_time = msg.logout_time
	player.bank_password = msg.bank_password ~= 0
	player.bank_login = msg.bank_login ~= 0
	player.is_guest = msg.is_guest
	player.online_award_start_time = msg.online_award_start_time
	player.phone = msg.phone
	player.phone_type = msg.phone_type
	player.version = msg.version
	player.channel_id = msg.channel_id
	player.package_name = msg.package_name
	player.imei = msg.imei
	player.ip = msg.ip
	player.ip_area = msg.ip_area
	player.risk = msg.risk
	player.create_channel_id = msg.create_channel_id
	player.enable_transfer = msg.enable_transfer
	player.inviter_guid = msg.inviter_guid
	player.invite_code = msg.invite_code
	player.alipay_account = msg.alipay_account
	player.alipay_name = msg.alipay_name
	player.change_alipay_num = msg.change_alipay_num
	if  msg.ddz_dapai_times ~= nil then
		player.ddz_dapai_times = msg.ddz_dapai_times
		log_info("SS_ChangeGame ddz_dapai_times "..player.guid.."  times "..msg.ddz_dapai_times)
	end

	player.flag_load_base_info = nil
	player.flag_load_item_bag = nil
	player.flag_load_mail_list = nil
	post_msg_to_mysql_pb("SD_OnlineAccount", {
		guid = player.guid,
		first_game_type = def_first_game_type,
		second_game_type = def_second_game_type,
		gamer_id = def_game_id,
		in_game = 1,
		})
	post_msg_to_mysql_pb("SD_GetBankCardInfo", {
			guid = player.guid,
		})

	redis_command(string.format("HSET player_online_gameid %d %d", player.guid, def_game_id))
	if #msg.pb_base_info > 0 then
		local data = pb.decode(msg.pb_base_info[1], msg.pb_base_info[2])
		data.money = data.money or 0
		data.bank = data.bank or 0
		player.pb_base_info = data
		
		check_change_complete(player, msg)
	end
	local guid = player.guid
	local function save_db_timer()
		local p = virtual_player:find(guid)
		if not p then
			return
		end
		if p ~= player then
			return
		end
		p:save()
		add_timer(def_save_db_time, save_db_timer)
	end
	save_db_timer()
	player:update_platfrom_online_info("on")



end
function handler_client_JoinPrivateRoom(player, msg)
	if not msg then
		post_msg_to_client_pb(player, "SC_JoinPrivateRoomFailed", {
			result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND"),
		})
		return
	end
	post_msg_to_cfg_pb("SS_JoinPrivateRoom", {
		owner_guid = msg.owner_guid,
		guid = player.guid,
		game_id = def_game_id,
	})
end
function on_SS_JoinPrivateRoom(msg)
	local player = virtual_player:find(msg.guid)
	if not player then
		return
	end
	if msg.owner_game_id > 0 then
		local needmoney = calcPrivateRoomNeedMoney(msg.first_game_type, msg.private_room_score_type)
		if not needmoney then
			post_msg_to_client_pb(player, "SC_EnterRoomAndSitDown", {
			result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_CHAIR"),
			game_id = def_game_id,
			first_game_type = msg.first_game_type,
			second_game_type = msg.second_game_type,
			ip_area = player.ip_area,
			private_room_score_type = msg.private_room_score_type,
			})
			return
		end
		local money = player.pb_base_info.money or 0
		local bank = player.pb_base_info.bank or 0
		
		if money + bank < needmoney + def_private_room_bank then
			post_msg_to_client_pb(player, "SC_EnterRoomAndSitDown", {
			result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_JOIN_PRIVATE_ROOM_ALL"),
			game_id = def_game_id,
			first_game_type = msg.first_game_type,
			second_game_type = msg.second_game_type,
			ip_area = player.ip_area,
			private_room_score_type = msg.private_room_score_type,
			})
			return
		end
		if bank < def_private_room_bank then
			post_msg_to_client_pb(player, "SC_EnterRoomAndSitDown", {
			result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_JOIN_PRIVATE_ROOM_BANK"),
			game_id = def_game_id,
			first_game_type = msg.first_game_type,
			second_game_type = msg.second_game_type,
			ip_area = player.ip_area,
			private_room_score_type = msg.private_room_score_type,
			balance_money = def_private_room_bank-bank,
			})
			return
		end
		if money < needmoney then
			post_msg_to_client_pb(player, "SC_EnterRoomAndSitDown", {
			result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_JOIN_PRIVATE_ROOM_MONEY"),
			game_id = def_game_id,
			first_game_type = msg.first_game_type,
			second_game_type = msg.second_game_type,
			ip_area = player.ip_area,
			private_room_score_type = msg.private_room_score_type,
			balance_money = needmoney-money,
			})
			return
		end
		handler_client_change_game(player, {
			first_game_type = msg.first_game_type,
			second_game_type = msg.second_game_type,
			private_room_opt = 2,
			owner_guid = msg.owner_guid,
			private_room_score_type = msg.private_room_score_type,
			})
	else
		post_msg_to_client_pb(player, "SC_JoinPrivateRoomFailed", {
			owner_guid = msg.owner_guid,
			result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND"),
		})
	end
end
function handler_cfg_black_list(msg)
	ly_black_list = nil 
	ly_black_list = {}
	if msg and msg.game_list and msg.black_list then
		if #msg.game_list == #msg.black_list then
			for i=1,#msg.black_list do
				if msg.game_list[i] == def_game_name then
					table.insert(ly_black_list,msg.black_list[i])
				elseif msg.game_list[i] == "land20" and def_game_id == 20  then
					table.insert(ly_black_list,msg.black_list[i])
					log_info("add land20 "..msg.black_list[i])
				elseif  msg.game_list[i] == "all" then
					table.insert(ly_black_list,msg.black_list[i])
				end
			end
		end
		--log_info("handler_cfg_black_list  size " .. #ly_black_list.." def_game_id "..def_game_id)
		--ly_black_list = msg.black_list
	else
		--log_info("handler_cfg_black_list  size  0")
		ly_black_list = {}
	end
end
function handler_client_PrivateRoomInfo(player, msg)
	local t = {}
	for i,v in ipairs(g_PrivateRoomConfig) do
		local cm = {}
		for j,u in ipairs(v.room_cfg) do
			cm[j] = u.cell_money
		end
		local tb = nil
		if v.first_game_type == 5 then
			tb = {3}
		elseif v.first_game_type == 6 then
			tb = {2,3,4,5}
		end
		table.insert(t, {first_game_type = v.first_game_type, table_count = tb, cell_money = cm})
	end
	post_msg_to_client_pb(player, "SC_PrivateRoomInfo", {pb_info = t})
end
function handler_client_reset_account(player, msg)
	if (not player.is_guest) and (not player.flag_wait_reset_account) then
		post_msg_to_client_pb(player,  "SC_ResetAccount", {
			result = pb.get_ev("LOGIN_RESULT", "LOGIN_RESULT_RESET_ACCOUNT_FAILED"),
			account = msg.account,
			nickname = msg.nickname,
		})
		return
	end
	player.flag_wait_reset_account = true
	post_msg_to_mysql_pb("SD_ResetAccount", {
		guid = player.guid,
		account = msg.account,
		password = msg.password,
		nickname = msg.nickname,
	})

	if player.is_guest then
		local sql = string.format(
			[[insert into t_log_bind_tel 
			( guid , account, channel_id, 
			version, phone, phone_type, time )
			values(%d, '%s', '%s', '%s', '%s' , '%s', '%s')
			]],
			player.guid,
			msg.account,
			player.channel_id,
			player.version,
			player.phone,
			player.phone_type,
			os.date('%Y-%m-%d %H:%M:%S')
			)
		post_msg_to_mysql_pb("SD_Do_OneSql",{db_name = "log", sql = sql})
	end
end
function handler_mysql_reset_account(msg)
	local player = virtual_player:find(msg.guid)
	if not player then
		return
	end
	if msg.ret == pb.get_ev("LOGIN_RESULT", "LOGIN_RESULT_SUCCESS") then
		player.is_guest = false
		player:add_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = def_register_money}}, pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_RESET_ACCOUNT"))
		redis_cmd_query(string.format("HGET player_login_info %s", player.account), function (reply)
			if reply:is_string() then
				local info = pb.decode("PlayerLoginInfo", from_hex(reply:get_string()))
				info.account = msg.account
				info.nickname = msg.nickname
				redis_command(string.format("HDEL player_login_info %s", player.account))
				redis_command(string.format("HDEL player_login_info_guid %d", player.guid))
				redis_command(string.format("HSET player_login_info %d %s", player.account, to_hex(pb.encode("PlayerLoginInfo", info))))
				redis_command(string.format("HSET player_login_info_guid %d %s", player.guid, to_hex(pb.encode("PlayerLoginInfo", info))))
			end
		end)
		
		player:reset_account(msg.account, msg.nickname)
	end
	player.flag_wait_reset_account = nil
	post_msg_to_client_pb(player,  "SC_ResetAccount", {
		result = msg.ret,
		account = msg.account,
		nickname = msg.nickname,
	})
end

function handler_mysql_bind_bank_card(msg)
	local player = virtual_player:find(msg.guid)
	if not player then
		return
	end
	log_info(string.format("handler_mysql_bind_bank_card  player %d ret %d", msg.guid, msg.result))
	post_msg_to_client_pb(player,  "SC_BindBankCard", {bind_result = msg.result})
end
function handler_client_bind_bank_card(player, msg)	
	if msg.pb_info.bank_code and msg.pb_info.bank_code ~= "" and msg.pb_info.card_num and msg.pb_info.card_num ~= "" and msg.pb_info.user_name and msg.pb_info.user_name ~= "" 
	and  msg.pb_info.bank_name and msg.pb_info.bank_name ~= "" and msg.pb_info.bank_addr and msg.pb_info.bank_addr ~= "" then
		msg.pb_info.guid = player.guid
		msg.pb_info.account = player.account
		post_msg_to_mysql_pb("SD_BindBankCard", {info = msg.pb_info})
	else
		post_msg_to_client_pb(player,  "SC_BindBankCard", {bind_result = 2})
	end
end
function handler_mysql_get_bank_card_info(msg)
	local player = virtual_player:find(msg.info.guid)
	if not player then
		return
	end
	if msg.info.bank_code and msg.info.bank_code ~= "" then
		player.bank_info = msg.info
	end
	post_msg_to_client_pb(player,  "SC_GetBankCardInfo", {pb_info = msg.info})
end
function handler_client_get_bank_card_info(player, msg)
	post_msg_to_mysql_pb("SD_GetBankCardInfo", {guid = player.guid})
end
function handler_client_bandalipay(player, msg)
	if not player.change_alipay_num then
		player.change_alipay_num = 0
		log_error(string.format("player %d change_alipay_num is nil",player.guid))
	end
	if player.change_alipay_num > 0 and (player.alipay_account == "" and player.alipay_name == "")  and player.is_guest == false then		
		post_msg_to_mysql_pb("SD_BandAlipay", {
			guid = player.guid,
			alipay_account = msg.alipay_account,
			alipay_name = msg.alipay_name,
		})
	else
		post_msg_to_client_pb(player, "SC_BandAlipay", {
			result = pb.get_ev("GAME_BAND_ALIPAY", "GAME_BAND_ALIPAY_CHECK_ERROR"),
			alipay_account = "",
			alipay_name = "",
			})
	end
end
function handler_mysql_bandalipay(msg)	
	local player = virtual_player:find(msg.guid)
	if player then		
		if msg.result == pb.get_ev("GAME_BAND_ALIPAY", "GAME_BAND_ALIPAY_SUCCESS") then
     		player.alipay_account = msg.alipay_account
     		player.alipay_name = msg.alipay_name
			post_msg_to_client_pb(player, "SC_BandAlipay", {
				result = msg.result,
				alipay_account = msg.alipay_account,
				alipay_name = msg.alipay_name,
				})
		else
			post_msg_to_client_pb(player, "SC_BandAlipay", {
				result = msg.result,
				alipay_account = "",
				alipay_name = "",
				})
		end
	end
end
function handler_mysql_bandalipaynum(msg)	
	local player = virtual_player:find(msg.guid)
	if player then	
		player.change_alipay_num = msg.band_num
	end
end
function handler_client_set_password(player, msg)
	if player.is_guest then
		post_msg_to_client_pb(player,  "SC_SetPassword", {
			result = LOGIN_RESULT_SET_PASSWORD_GUEST,
		})
	end
	post_msg_to_mysql_pb("SD_SetPassword", {
		guid = player.guid,
		old_password = msg.old_password,
		password = msg.password,
	})
end
function handler_mysql_set_password(msg)
	local player = virtual_player:find(msg.guid)
	if not player then
		return
	end
	post_msg_to_client_pb(player, "SC_SetPassword", {
		result = msg.ret,
	})
end
function handler_client_set_password_by_sms(player, msg)
	if player.is_guest then
		post_msg_to_client_pb(player,  "SC_SetPassword", {
			result = LOGIN_RESULT_SET_PASSWORD_GUEST,
		})
	end
	post_msg_to_mysql_pb("SD_SetPasswordBySms", {
		guid = player.guid,
		password = msg.password,
	})
end
function handler_client_set_nickname(player, msg)
	post_msg_to_mysql_pb("SD_SetNickname", {
		guid = player.guid,
		nickname = msg.nickname,
	})
end
function handler_mysql_set_nickname(msg)
	local player = virtual_player:find(msg.guid)
	if not player then
		return
	end
	if msg.ret == pb.get_ev("LOGIN_RESULT", "LOGIN_RESULT_SUCCESS") then
		redis_cmd_query(string.format("HGET player_login_info %s", player.account), function (reply)
			if reply:is_string() then
				local info = pb.decode("PlayerLoginInfo", from_hex(reply:get_string()))
				info.nickname = msg.nickname
				redis_command(string.format("HSET player_login_info %s %s", player.account, to_hex(pb.encode("PlayerLoginInfo", info))))
				redis_command(string.format("HSET player_login_info_guid %d %s", player.guid, to_hex(pb.encode("PlayerLoginInfo", info))))
			end
		end)
		player.nickname = msg.nickname
	end
	post_msg_to_client_pb(player,  "SC_SetNickname", {
		nickname = msg.nickname,
		result = msg.ret,
	})
end
function handler_client_change_header_icon(player, msg)
	if player.pb_base_info == nil then
		log_info("pb_base_info nil "..player.guid)
		return
	end
	local header_icon = player.pb_base_info.header_icon or 0
	if msg.header_icon ~= header_icon then
		player.pb_base_info.header_icon = msg.header_icon
		player.flag_base_info = true
	end
	post_msg_to_client_pb(player,  "SC_ChangeHeaderIcon", {
		header_icon = msg.header_icon,
	})
end
local function add_android(opt_type, room_id, android_list)
	if opt_type == pb.get_ev("GM_ANDROID_OPT", "GM_ANDROID_ADD_ACTIVE") then
		for _, v in ipairs(android_list) do
			local a = virtual_active_android:new()
			a:init(room_id, v.guid, v.account, v.nickname)
		end
	elseif opt_type == pb.get_ev("GM_ANDROID_OPT", "GM_ANDROID_ADD_PASSIVE") then
		for _, v in ipairs(android_list) do
			local a = virtual_passive_android:new()
			a:init(room_id, v.guid, v.account, v.nickname)
		end
	end
end
function on_gm_android_opt(opt_type_, roomid_, num_)
	if not room_manager:find_room(roomid_) then
		return
	end
	if opt_type_ == pb.get_ev("GM_ANDROID_OPT", "GM_ANDROID_ADD_ACTIVE") or opt_type_ == pb.get_ev("GM_ANDROID_OPT", "GM_ANDROID_ADD_PASSIVE") then
		local a = android_manager:create_android(def_game_id, num_)
		local n = #a
		if n > 0 then
			add_android(opt_type_, roomid_, a)
		end
		if n ~= num_ then
			post_msg_to_mysql_pb("SD_LoadAndroidData", {
				opt_type = opt_type_,
				room_id = roomid_,
				guid = android_manager:get_max_guid(),
				count = num_ - n,
				})
		end
	elseif opt_type_ == pb.get_ev("GM_ANDROID_OPT", "GM_ANDROID_SUB_ACTIVE") then
		virtual_active_android:sub_android(roomid_, num_)
	elseif opt_type_ == pb.get_ev("GM_ANDROID_OPT", "GM_ANDROID_SUB_PASSIVE") then
		virtual_passive_android:sub_android(roomid_, num_)
	end
end
function handler_mysql_load_android_data(msg)
	if not msg then
		return
	end
	android_manager:load_from_db(msg.android_list)
	local a = android_manager:create_android(def_game_id, #msg.android_list)
	if #a <= 0 then
		return
	end
	
	add_android(msg.opt_type, msg.room_id, a)
end
function  handler_mysql_QueryPlayerMsgData(msg)
	local player = virtual_player:find(msg.guid)
	if player then
		if msg.pb_msg_data then
			if msg.first then
				post_msg_to_client_pb(player,"SC_QueryPlayerMsgData",{
					pb_msg_data = msg.pb_msg_data.pb_msg_data_info
				})
			else
				post_msg_to_client_pb(player,"SC_NewMsgData",{
					pb_msg_data = msg.pb_msg_data.pb_msg_data_info
				})
			end
		else
			post_msg_to_client_pb(player,"SC_QueryPlayerMsgData")
		end
	else
	end
end
function handler_client_QueryPlayerMsgData( player, msg )
	post_msg_to_mysql_pb("SD_QueryPlayerMsgData", {
		guid = player.guid,
	})
end
function handler_mysql_QueryPlayerMarquee(msg)
	local player = virtual_player:find(msg.guid)
	if player then
		if msg.pb_msg_data then
			if msg.first then
				post_msg_to_client_pb(player,"SC_QueryPlayerMarquee",{
					pb_msg_data = msg.pb_msg_data.pb_msg_data_info
				})
			else
				post_msg_to_client_pb(player,"SC_NewMarquee",{
					pb_msg_data = msg.pb_msg_data.pb_msg_data_info
				})
			end
		else
			post_msg_to_client_pb(player,"SC_QueryPlayerMarquee")
		end
	else
	end
end
function handler_client_QueryPlayerMarquee( player, msg )
	post_msg_to_mysql_pb("SD_QueryPlayerMarquee", {
		guid = player.guid,
	})
end
function handler_client_SetMsgReadFlag( player, msg )
	post_msg_to_mysql_pb("SD_SetMsgReadFlag", {
		guid = player.guid,
		id = msg.id,
		msg_type = msg.msg_type,
	})
end
function  handler_mysql_LoadOxConfigData(msg)
end
function on_ls_set_tax(msg)
	room_manager:change_tax(msg.tax, msg.is_show, msg.is_enable)
	local nmsg = {
	webid = msg.webid,
	result = 1,
	}
	post_msg_to_login_pb("SL_ChangeTax",nmsg)
end
function on_ls_FreezeAccount( msg )
	local player = virtual_player:find(msg.guid)
	local notify = {
		guid = msg.guid,
		status = msg.status,
		retid = msg.retid,
		ret = 0,
	}
	if not player then
		notify.ret = 1
		post_msg_to_login_id_pb(msg.login_id,"SL_FreezeAccount",notify)
		return
	end	
	local notifyT = {
		guid = msg.guid,
		status = msg.status,
	}
	
	post_msg_to_client_pb(player,  "SC_FreezeAccount", notifyT)
	
	player.disable = msg.status;
	if player.disable == 1 then
		if not room_manager:isPlay(player) then
			player:forced_exit();
		end
	end
	post_msg_to_login_id_pb(msg.login_id,"SL_FreezeAccount",notify)
end
function on_ls_cc_changemoney(msg)
	local player = virtual_player:find(msg.guid)	
	local notify = {
		guid = msg.guid,
		money = msg.money,
		keyid = msg.keyid,
		retid = msg.retid,
		oldmoney = 0,
		newmoney = 0,
		retcode = pb.get_ev("ChangeMoneyRecode", "ChangMoney_NotEnoughMoney"),
	}
	if player and  player.pb_base_info then		
		notify.retcode,notify.oldmoney,notify.newmoney = player:changeBankMoney(msg.money)
	end
	post_msg_to_login_id_pb(msg.login_id,"SL_AgentsTransfer_ChangeMoney",notify)
end
function on_fs_chang_config(msg)
	local nmsg = {
	webid = msg.webid,
	result = 1,
	pb_cfg = {
		game_id = def_game_id,
		second_game_type = def_second_game_type,
		first_game_type = def_first_game_type,
		game_name = def_game_name,
		table_count = 0,
		money_limit = 0,
		cell_money = 0,
		tax = 0,
		},	
	}
	local tb_l
	if msg.room_list ~= "" then	
		local tb = parse_table(msg.room_list )
		log_info("on_fs_chang_config "..def_game_id)
		g_room_mgr:gm_update_cfg(tb, msg.room_lua_cfg)
		tb_l = tb
	else			
		nmsg.result = 0
	end
	local table_count_l = 0
	local money_limit_l = 0
	local cell_money_l = 0
	local tax_l = 0
	for i,v in ipairs(tb_l) do
		 table_count_l = v.table_count
		 money_limit_l = v.money_limit
		 cell_money_l = v.cell_money
		 tax_l = v.tax * 0.01
	end
	nmsg.pb_cfg.table_count = table_count_l
	nmsg.pb_cfg.money_limit = money_limit_l
	nmsg.pb_cfg.cell_money = cell_money_l
	nmsg.pb_cfg.tax = tax_l
	post_msg_to_cfg_pb("SF_ChangeGameCfg",nmsg)
	
end
function on_fs_chang_robot_cfg(msg)
	local cfg_f = load(msg.cfg_param)
	local cfg = cfg_f()
	ly_use_robot = cfg.use_robot
	ly_robot_smart_lv = cfg.robot_level
	log_info("on_fs_chang_robot_cfg " .. tostring(ly_use_robot) .. " " .. tostring(ly_robot_smart_lv))
end
function handler_mysql_server_config(msg)
	if msg.cfg.room_list ~= "" then	
		print(msg.cfg.room_list)
		local tb = load_json_buffer(msg.cfg.room_list)
		g_room_mgr:gm_update_cfg(tb, msg.cfg.room_lua_cfg)
	else			
	end
end
function handler_client_change_maintain(msg)
	--log_info("handler_client_change_maintain : "  .. tostring(msg.maintaintype) .. " " .. tostring(msg.switchopen))
	if msg.maintaintype == 1 then 
		ly_cash_switch = msg.switchopen
	elseif msg.maintaintype == 2 then
		if msg.first_game_type ~= -1000 then
			g_ly_game_switch_list[msg.first_game_type] = msg.switchopen
		end
		for i,v in pairs(g_ly_game_switch_list) do
			log_info("handler_client_change_maintain  "..i.." open = "..v)
		end
		if msg.first_game_type == def_first_game_type or msg.first_game_type == -1000 then
			ly_game_switch = msg.switchopen
		end
		
		if ly_game_switch == 1 then
			room_manager:foreach_by_player(function (player) 
				if player and player.vip ~= 100 then 
					post_msg_to_client_pb(player, "SC_GameMaintain", {
					result = pb.get_ev("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_MAINTAIN") ,
					first_game_type = def_first_game_type,
					second_game_type = 0,
					})
				end
			end)
			log_info("handler_client_change_maintain "..msg.first_game_type.."    open =  "..msg.switchopen)
		else
			virtual_player:update_gamemaintain(msg)
			-- room_manager:foreach_by_player(function (player) 
			-- 	if player and player.vip ~= 100 then 
			-- 		log_info("handler_client_change_maintain close  "..msg.first_game_type.."    open =  "..msg.switchopen)
			-- 		post_msg_to_client_pb(player, "SC_GameMaintain", {
			-- 		result = 0 ,
			-- 		first_game_type = msg.first_game_type,
			-- 		second_game_type = 0,
			-- 		})
			-- 	end
			-- end)
		end
	elseif msg.maintaintype == 4 then 
		ly_cash_ali_switch = msg.switchopen
		log_info("ly_cash_ali_switch "..msg.switchopen)
	elseif msg.maintaintype == 5 then 
		ly_cash_bank_switch = msg.switchopen
		log_info("ly_cash_bank_switch "..msg.switchopen)
	end
end

function handler_client_query_promotion(player,msg)
	if g_ly_playerpromotion[player.guid] == nil then
		g_ly_playerpromotion[player.guid] = {}
	end

	if msg == nil then
		g_ly_playerpromotion[player.guid].request_index = 1
	else
		g_ly_playerpromotion[player.guid].request_index = msg.index
	end
	
	post_msg_to_mysql_pb("SD_QueryPlayerPromotion", {
			game_id = def_game_id,
			guid = player.guid,
		})

	log_info("query promotion")
end

function handler_mysql_load_playerpromotion(msg)
	if g_ly_playerpromotion[msg.guid] == nil then
		return
	end

	
	local player = virtual_player:find(msg.guid)
	if player == nil then
		return
	end

	local pbrpromotion= msg.pb_playerpromotion
	if #pbrpromotion == 0 then
		post_msg_to_client_pb(player,"SC_PlayerPromotion",{promotion_result = 2})
		log_info("handler_mysql_load_playerpromotion result = 2")
		return
	end


	if #pbrpromotion > 0 then
		for k,v in pairs(pbrpromotion) do
			local rindex = g_ly_playerpromotion[msg.guid].request_index
			local pmoney = v.profit
			if pmoney > 0 then
				player:add_money({{money_type = pb.get_ev("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD"), money = pmoney}}, pb.get_ev("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_PLAYER_PROMOTION"))
			end	
			post_msg_to_mysql_pb("SD_Do_OneSql",{db_name = "account",sql = string.format("UPDATE t_player_form set `Pay_ck` = 1 WHERE tid=%d ;",
			v.tid)})
			
		end
		post_msg_to_client_pb(player,"SC_PlayerPromotion",{promotion_result = 1})
		log_info("handler_mysql_load_playerpromotion result = 1 "..msg.guid)
	end

end

function handler_mysql_load_playerrecharge(msg)
	if msg.guid == 0 then
		return
	end
	local player = virtual_player:find(msg.guid)
	if player == nil then
		return
	end

	player.cash_total = msg.player_cash_total
	player.recharge_total = msg.player_recharge_total
	log_info("playerrecharge "..player.cash_total.." win_money "..virtual_player:getwinmoney())
end
function handler_mysql_query_player_recharge(msg)
	local player = virtual_player:find(msg.guid)
	if player == nil then
		return
	end
	player.recharge_total = msg.recharge or 0
end


local function string_split(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end
local function get_change_ip_str(ip)
	local ip_littel = string_split(ip,".")
	local xunlie = {math.random(100,200),math.random(300,400),math.random(500,600),math.random(700,800)}
	local fanxunlie_start = {math.random(700,800),math.random(100,200),math.random(500,600),math.random(300,400)}
	local fanxunlie_end = {math.random(300,400),math.random(100,200),math.random(700,800),math.random(500,600)}
	local ret = string.format("%03d%03d%03d%03d-%03d%03d%03d%03d-%03d%03d%03d%03d-%03d%03d%03d%03d",
	fanxunlie_start[3],xunlie[3],ip_littel[3]+xunlie[1],fanxunlie_end[3],
	fanxunlie_start[2],xunlie[2],ip_littel[2]+xunlie[2],fanxunlie_end[2],
	fanxunlie_start[4],xunlie[4],ip_littel[4]+xunlie[3],fanxunlie_end[4],
	fanxunlie_start[1],xunlie[1],ip_littel[1]+xunlie[4],fanxunlie_end[1])

	return ret
end
local function get_real_ip_str(change_ip)
	if change_ip then
		local ip_littel = string_split(change_ip,"-")
		if #ip_littel == 4 and #ip_littel[1] == 12 and 
		#ip_littel[2] == 12 and #ip_littel[3] == 12 and #ip_littel[4] == 12 then
			local x_3 = tonumber(string.sub(ip_littel[1],4,6))
			local x_2 = tonumber(string.sub(ip_littel[2],4,6))
			local x_4 = tonumber(string.sub(ip_littel[3],4,6))
			local x_1 = tonumber(string.sub(ip_littel[4],4,6)) 

			local ip_3 = tonumber(string.sub(ip_littel[1],7,9)) - x_1
			local ip_2 = tonumber(string.sub(ip_littel[2],7,9)) - x_2
			local ip_4 = tonumber(string.sub(ip_littel[3],7,9)) - x_3
			local ip_1 = tonumber(string.sub(ip_littel[4],7,9)) - x_4

			if (x_4 > x_3 and x_3 > x_2 and x_2 > x_1) and (ip_1 >= 0 and ip_1 <= 255) and (ip_2 >= 0 and ip_2 <= 255) 
			and (ip_3 >= 0 and ip_3 <= 255) and (ip_4 >= 0 and ip_4 <= 255) then
				return tostring(ip_1) .. "." .. tostring(ip_2) .. "." .. tostring(ip_3) .. "." .. tostring(ip_4)	
			end
		end
	end
	log_error("error ip string " .. tostring(change_ip))
	return "113.125.40.36" --"山东省济南市"
end

function handler_cfg_query_cashswich(msg)
	log_info("cfg query success")
end

--log_info(get_real_ip_str(get_change_ip_str("127.0.0.255")))