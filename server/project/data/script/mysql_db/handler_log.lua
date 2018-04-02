local pb = require "extern/lib/lib_pb"
require "mysql_db/handler_net"
local send2center_pb = send2center_pb
local post_msg_to_game_pb = post_msg_to_game_pb

require "mysql_db/db_api"
local db_execute = db_execute
local db_execute_query = db_execute_query
function handler_mysql_log_money(game_id, msg)
	local db = get_log_db()
	db_execute(db, "INSERT INTO t_log_money SET $FIELD$;", msg)
end

function save_error_sql(str_sql)
    local db = get_log_db()
    local sqlT = string.gsub(str_sql,"'","''")
    local sql = string.format("INSERT INTO `log`.`t_erro_sql` (`sql`) VALUES ('%s')",sqlT)
    db_execute(db,sql)
end

function on_sl_channel_invite_tax(game_id, msg)
    local db = get_log_db()
    local sql = string.format([[
    INSERT INTO `log`.`t_log_channel_invite_tax` (`guid`, `guid_contribute`, `val`, `time`)
    VALUES (%d, %d, %d, NOW())]],
    msg.guid_invite,msg.guid,msg.val);

    db_execute_query_update(db, sql, function(ret)
        if ret > 0 then
        else
        end
    end)
    local game_db = get_game_db()
    sql = string.format([[
    INSERT INTO `game`.`t_channel_invite_tax` (`guid`, `val`)
    VALUES (%d, %d)]],
    msg.guid_invite,msg.val);

    db_execute_query_update(game_db, sql, function(ret)
        if ret > 0 then
        else
        end
    end)
end
function on_sl_log_money(game_id, msg)
    if msg.tax < 0 then msg.tax = 0 end
    local db = get_log_db()
    local sql = string.format([[
    INSERT INTO `log`.`t_log_money_tj` (`guid`, `type`, `gameid`, `game_name`,`phone_type`, `old_money`, `new_money`, `tax`, `change_money`, `ip`, `id`, `channel_id`)
    VALUES (%d, %d, %d, '%s', '%s', %d, %d, %d, %d, '%s', '%s', '%s')]],
    msg.guid,msg.type,msg.gameid,msg.game_name,msg.phone_type,msg.old_money,msg.new_money,msg.tax,msg.change_money,msg.ip,msg.id,msg.channel_id);

    db_execute_query_update(db, sql, function(ret)
        if ret > 0 then
        else
        end
    end)
    if msg.tax > 0 then
        handler_mysql_update_game_total_tax(msg.gameid, 
        {
            game_id = msg.gameid,
            first_game_type = 0,
            second_game_type = 0,
            tax_add = msg.tax
        })
    end
end
function on_sl_log_Game(game_id, msg)
    local db = get_log_db()
    local sql = string.format([[
    INSERT INTO `log`.`t_log_game_tj` (`id`, `type`, `log`, `start_time`,`end_time`)
    VALUES ('%s', '%s', '%s', FROM_UNIXTIME(%d), FROM_UNIXTIME(%d))]],
    msg.playid,msg.type,msg.log,msg.starttime,msg.endtime);
    db_execute_query_update(db, sql, function(ret)
        if ret > 0 then
        else
        end
    end)
end

function on_sl_robot_log_money(game_id,msg)
    local db = get_log_db()
    local sql = string.format([[
    INSERT INTO `log`.`t_log_robot_money_tj` (`guid`, `is_banker`, `winorlose`,`gameid`, `game_name`,`old_money`, `new_money`, `tax`, `money_change`, `id`)
    VALUES (%d, %d, %d, %d, '%s', %d, %d, %d, %d, '%s')]],
    msg.guid,msg.isbanker,msg.winorlose,msg.gameid,msg.game_name,msg.old_money,msg.new_money,msg.tax,msg.money_change,msg.id);

    db_execute_query_update(db, sql, function(ret)
        if ret > 0 then
        else
        end
    end)
end