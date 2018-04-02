local pb = require "extern/lib/lib_pb"
require "game_script/handler_net"
local post_msg_to_client_pb = post_msg_to_client_pb
local post_msg_to_mysql_pb = post_msg_to_mysql_pb
require "game_script/virtual/virtual_player"
local virtual_player = virtual_player
function handler_client_send_mail(player, msg)
	local mail_ = pb.decode(msg.pb_mail[1], msg.pb_mail[2])
	for i, item in ipairs(mail_.pb_attachment) do
		mail_.pb_attachment[i] = pb.decode(item[1], item[2])
	end
	mail_.send_guid = player.guid
	mail_.send_name = player.account
	post_msg_to_mysql_pb("SD_SendMail", {
		pb_mail = mail_,
	})
end
function on_des_send_mail(msg)
	local mail_ = pb.decode(msg.pb_mail[1], msg.pb_mail[2])
	for i, item in ipairs(mail_.pb_attachment) do
		mail_.pb_attachment[i] = pb.decode(item[1], item[2])
	end
	
	local player = virtual_player:find(mail_.send_guid)
	if player then
		post_msg_to_client_pb(player, "SC_SendMail", {
			ret = msg.ret,
			pb_mail = mail_,
		})
	end
end
function on_des_send_mail_from_center(msg)
	local mail_ = pb.decode(msg.pb_mail[1], msg.pb_mail[2])
	for i, item in ipairs(mail_.pb_attachment) do
		mail_.pb_attachment[i] = pb.decode(item[1], item[2])
	end
	
	local player = virtual_player:find(mail_.guid)
	if player then
		player.pb_mail_list[mail_.mail_id] = mail_
		
		post_msg_to_client_pb(player, "SC_RecviceMail", {
			pb_mail = mail_,
		})
	end
end
function handler_client_del_mail(player, msg)
	if player.pb_mail_list and player.pb_mail_list[msg.mail_id] then
		local mail = player.pb_mail_list[msg.mail_id]
		if get_second_time() >= mail.expiration_time then
			player.pb_mail_list[msg.mail_id] = nil
			
			post_msg_to_client_pb(player, "SC_DelMail", {
				result = pb.get_ev("MAIL_OPT_RESULT", "MAIL_OPT_RESULT_EXPIRATION"),
				mail_id = msg.mail_id,
			})
			return
		end
		
		if mail.attachment and #mail.attachment > 0 then
			post_msg_to_client_pb(player, "SC_DelMail", {
				result = pb.get_ev("MAIL_OPT_RESULT", "MAIL_OPT_RESULT_HAS_ATTACHMENT"),
				mail_id = msg.mail_id,
			})
			return
		end
		
		player.pb_mail_list[msg.mail_id] = nil
		
		post_msg_to_client_pb(player, "SC_DelMail", {
			result = pb.get_ev("MAIL_OPT_RESULT", "MAIL_OPT_RESULT_SUCCESS"),
			mail_id = msg.mail_id,
		})
		
		
		post_msg_to_mysql_pb("SD_DelMail", {
			guid = player.guid,
			mail_id = msg.mail_id,
		})
	else
		post_msg_to_client_pb(player, "SC_DelMail", {
			result = pb.get_ev("MAIL_OPT_RESULT", "MAIL_OPT_RESULT_FIND_FAILED"),
			mail_id = msg.mail_id,
		})
	end
end
function handler_client_receive_mail_attachment(player, msg)
	if player.pb_mail_list and player.pb_mail_list[msg.mail_id] then
		local mail = player.pb_mail_list[msg.mail_id]
		if get_second_time() >= mail.expiration_time then
			player.pb_mail_list[msg.mail_id] = nil
			
			post_msg_to_client_pb(player, "SC_ReceiveMailAttachment", {
				result = pb.get_ev("MAIL_OPT_RESULT", "MAIL_OPT_RESULT_EXPIRATION"),
				mail_id = msg.mail_id,
			})
			return
		end
		
		if not mail.pb_attachment or #mail.pb_attachment == 0 then
			post_msg_to_client_pb(player, "SC_ReceiveMailAttachment", {
				result = pb.get_ev("MAIL_OPT_RESULT", "MAIL_OPT_RESULT_NO_ATTACHMENT"),
				mail_id = msg.mail_id,
			})
			return
		end
		
		for i, v in ipairs(mail.pb_attachment) do
			player:add_item(v.item_id, v.item_num)
		end
		
		post_msg_to_client_pb(player, "SC_ReceiveMailAttachment", {
			result = pb.get_ev("MAIL_OPT_RESULT", "MAIL_OPT_RESULT_SUCCESS"),
			mail_id = msg.mail_id,
			pb_attachment = mail.pb_attachment
		})
		
		mail.pb_attachment = nil
		
		
		post_msg_to_mysql_pb("SD_ReceiveMailAttachment", {
			guid = player.guid,
			mail_id = msg.mail_id,
		})
	else
		post_msg_to_client_pb(player, "SC_ReceiveMailAttachment", {
			result = pb.get_ev("MAIL_OPT_RESULT", "MAIL_OPT_RESULT_FIND_FAILED"),
			mail_id = msg.mail_id,
		})
	end
end
