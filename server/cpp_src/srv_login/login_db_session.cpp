#include "login_db_session.h"
#include "login_session.h"
#include "base_game_log.h"
#include "public_enum.pb.h"
#include "base_game_time_mgr.h"
#include "base_redis_con_thread.h"
#include "base_utils_helper.h"
#include "redis.pb.h"
#include "login_server.h"

login_db_session::login_db_session(boost::asio::io_service& ioservice)
	: base_net_session(ioservice)
	, dispatcher_manager_(nullptr)
{
}

login_db_session::~login_db_session()
{
}

void login_db_session::on_dl_reg_account(DL_RegAccount* msg)
{
	if (msg->ret() == LOGIN_RESULT_SUCCESS)
	{
		PlayerLoginInfo info;
		info.set_session_id(msg->session_id());
		info.set_gate_id(msg->gate_id());
		info.set_account(msg->account());
		info.set_guid(msg->guid());
		info.set_nickname(msg->nickname());
		//info.set_login_time(base_game_time_mgr::instance()->get_second_time());
		if (msg->is_guest())
			info.set_is_guest(true);

		info.set_phone(msg->phone());
		info.set_phone_type(msg->phone_type());
		info.set_version(msg->version());
		info.set_channel_id(msg->channel_id());
		info.set_package_name(msg->package_name());
		info.set_imei(msg->imei());
		info.set_ip(msg->ip());
		info.set_ip_area(msg->ip_area());

		std::string password_ = msg->password();

		base_redis_con_thread::instance()->command_impl([info, password_](RedisConnection* con) {
			LOG_INFO("[%s] reg account, guid = %d", info.account().c_str(), info.guid());

			// 找一个默认大厅服务器
			int gameid = login_session_mgr::instance()->find_a_default_lobby();
			if (gameid == 0)
			{
				int session_id = info.session_id();
				int gate_id = info.gate_id();

				base_redis_con_thread::instance()->add_reply([session_id, gate_id]() {
					LC_Login reply;
					reply.set_result(LOGIN_RESULT_NO_DEFAULT_LOBBY);

					login_session_mgr::instance()->post_msg_to_client_pb(session_id, gate_id, &reply);
				});

				base_redis_con_thread::instance()->command(str(boost::format("HDEL player_login_info %1%") % info.account()));
				base_redis_con_thread::instance()->command(str(boost::format("HDEL player_login_info_guid %1%") % info.guid()));
				LOG_WARN("no default lobby");
				login_session_mgr::instance()->print_game_server_info();
				return;
			}

			// 存入redis
			con->command(str(boost::format("HSET player_online_gameid %1% %2%") % info.guid() % gameid));
			con->command(str(boost::format("HSET player_session_gate %1%@%2% %3%") % info.session_id() % info.gate_id() % info.account()));
			con->command(str(boost::format("HSET player_login_info %1% %2%") % info.account() % crypto_manager::to_hex(info.SerializeAsString())));
			con->command(str(boost::format("HSET player_login_info_guid %1% %2%") % info.guid() % crypto_manager::to_hex(info.SerializeAsString())));
			base_redis_con_thread::instance()->add_reply([gameid, info, password_]() {
				LS_LoginNotify notify;
				notify.mutable_player_login_info()->CopyFrom(info);
				notify.set_password(password_);

				login_session_mgr::instance()->post_msg_to_game_pb(gameid, &notify);
			});
		});
	}
	else
	{
		LC_Login reply;
		reply.set_result(msg->ret());
		reply.set_account(msg->account());
		reply.set_is_guest(msg->is_guest());
		login_session_mgr::instance()->post_msg_to_client_pb(msg->session_id(), msg->gate_id(), &reply);
	}
}
void login_db_session::on_dl_reg_phone_query(DL_PhoneQuery* msg)
{
	LG_PhoneQuery request;
	request.set_phone(msg->phone());
	request.set_ret(msg->ret());
	request.set_gate_session_id(msg->gate_session_id());
	login_session_mgr::instance()->broadcast2gate_pb(&request);
}
void login_db_session::on_dl_get_inviter_info(LC_GetInviterInfo* msg)
{
	login_session_mgr::instance()->post_msg_to_client_pb(msg->guid_self(), msg->gate_id(), msg);
}

bool login_db_session::handler_msg_dispatch(MsgHeader* header)
{
	if (header->id == S_Heartbeat::ID)
	{
		return true;
	}

	if (nullptr == dispatcher_manager_)
	{
		LOG_ERR("dispatcher manager is null");
		return false;
	}

	auto dispatcher = dispatcher_manager_->query_dispatcher(header->id);
	if (nullptr == dispatcher)
	{
		LOG_ERR("opcode:%d not registered", header->id);
		return true;
	}

	return dispatcher->parse(this, header);
}

bool login_db_session::handler_connect()
{
	LOG_INFO("srv_login<-->srv_msql connect success ... <%s:%d>", ip_.c_str(), port_);

	dispatcher_manager_ = login_session_mgr::instance()->get_dispatcher_manager_db();

	S_Connect msg;
	msg.set_type(ServerSessionFromLogin);
	msg.set_server_id(static_cast<login_server*>(base_server::instance())->get_login_id());
	send_pb(&msg);

	login_session_mgr::instance()->set_first_connect_db();

	S_ConnectDB notify;
	login_session_mgr::instance()->broadcast2gate_pb(&notify);

	return base_net_session::handler_connect();
}

void login_db_session::handler_connect_failed()
{
	LOG_INFO("srv_login<-->srv_msql not connect ... <%s:%d>", ip_.c_str(), port_);

	base_net_session::handler_connect_failed();
}

void login_db_session::on_closed()
{
	LOG_INFO("srv_login<-->srv_msql close ... <%s:%d>", ip_.c_str(), port_);

	base_net_session::on_closed();
}

void login_db_session::on_dl_verify_account_result(DL_VerifyAccountResult* msg)
{
	if (msg->verify_account_result().ret() == LOGIN_RESULT_SUCCESS)
	{
		VerifyAccountResult var = msg->verify_account_result();
		int status = static_cast<login_server*>(base_server::instance())->get_maintain_switch();
		if (status == 1 && var.vip() != 100)
		{
			LC_Login reply;
			reply.set_result(LOGIN_RESULT_MAINTAIN);
			login_session_mgr::instance()->post_msg_to_client_pb(msg->session_id(), msg->gate_id(), &reply);
			send_pb(&reply);
			return;
		}
		std::string account_ = msg->account();
		std::string password_ = msg->password();
		int gate_id_ = msg->gate_id();
		int session_id_ = msg->session_id();

		base_redis_con_thread::instance()->command_impl([var, account_, password_, gate_id_, session_id_](RedisConnection* con) {
			PlayerLoginInfo info;
			if (!con->get_player_login_info(account_, &info))
			{
				LOG_ERR("player[%s] not find", account_.c_str());
				return;
			}

			info.set_session_id(session_id_);
			info.set_gate_id(gate_id_);
			info.set_account(account_);
			info.set_guid(var.guid());
			info.set_nickname(var.nickname());
			info.set_vip(var.vip());
			info.set_login_time(var.login_time());
			info.set_logout_time(var.logout_time());
			info.set_alipay_account(var.alipay_account());
			info.set_alipay_name(var.alipay_name());
			info.set_change_alipay_num(var.change_alipay_num());
			if (var.no_bank_password() == 0)
				info.set_has_bank_password(true);
			if (var.is_guest())
				info.set_is_guest(true);
			info.set_risk(var.risk());
            info.set_create_channel_id(var.channel_id());
			info.set_enable_transfer(var.enable_transfer());
			info.set_inviter_guid(var.inviter_guid());
			info.set_invite_code(var.invite_code());


			// 重连
			int game_id = con->get_gameid_by_guid(info.guid());
			if (game_id)
			{
				LOG_INFO("player[%d] reconnect game_id:%d", info.guid(), game_id);

				if (login_session_mgr::instance()->has_game_server_info(game_id))
				{
					base_redis_con_thread::instance()->add_reply([account_, game_id, info, password_]() {
						LS_LoginNotify notify;
						notify.mutable_player_login_info()->CopyFrom(info);
						notify.mutable_player_login_info()->set_is_reconnect(true);
						notify.set_password(password_);

						login_session_mgr::instance()->post_msg_to_game_pb(game_id, &notify);

						LOG_INFO("login reconnect account=%s,gameid=%d", account_.c_str(), game_id);
					});

					return;
				}
			}

			// 找一个默认大厅
			int gameid = login_session_mgr::instance()->find_a_default_lobby();
			if (gameid == 0)
			{
				int session_id = info.session_id();
				int gate_id = info.gate_id();

				base_redis_con_thread::instance()->add_reply([account_, session_id, gate_id, gameid]() {
					LC_Login reply;
					reply.set_result(LOGIN_RESULT_NO_DEFAULT_LOBBY);

					login_session_mgr::instance()->post_msg_to_client_pb(session_id, gate_id, &reply);

					LOG_INFO("login to lobby, user : %s, game_id=%d", account_.c_str(), gameid);
				});

                base_redis_con_thread::instance()->command(str(boost::format("HDEL player_login_info %1%") % info.account()));
                base_redis_con_thread::instance()->command(str(boost::format("HDEL player_login_info_guid %1%") % info.guid()));
				LOG_WARN("no default lobby");
				login_session_mgr::instance()->print_game_server_info();
				return;
			}

			// 存入redis
            con->command(str(boost::format("HSET player_online_gameid %1% %2%") % info.guid() % gameid));
            con->command(str(boost::format("HSET player_session_gate %1%@%2% %3%") % info.session_id() % info.gate_id() % info.account()));
			con->command(str(boost::format("HSET player_login_info %1% %2%") % info.account() % crypto_manager::to_hex(info.SerializeAsString())));
			con->command(str(boost::format("HSET player_login_info_guid %1% %2%") % info.guid() % crypto_manager::to_hex(info.SerializeAsString())));

			base_redis_con_thread::instance()->add_reply([account_, gameid, info, password_]() {
				LS_LoginNotify notify;
				notify.mutable_player_login_info()->CopyFrom(info);
				notify.set_password(password_);

				login_session_mgr::instance()->post_msg_to_game_pb(gameid, &notify);

			});
		});
	}
	else
	{
		LOG_ERR("login verify_account error:%d", msg->verify_account_result().ret());

        const VerifyAccountResult& var = msg->verify_account_result();
        std::string account = msg->account();
        int session_id = msg->session_id();
        int gate_id = msg->gate_id();
        int ret = msg->verify_account_result().ret();
        base_redis_con_thread::instance()->command_impl([account, session_id, gate_id, ret](RedisConnection* con) {
            // 登陆请求状态判断
            con->command(str(boost::format("HGET player_login_info %1%") % account));
            RedisReply reply = con->get_reply();
            if (! reply.is_nil())
            {
                PlayerLoginInfo other;
				if (!other.ParseFromString(crypto_manager::from_hex(reply.get_string())))
                {
                    LOG_ERR("ParseFromString failed, accout:%s", other.account().c_str());
                }
                base_redis_con_thread::instance()->command(str(boost::format("HDEL player_login_info %1%") % other.account()));
                base_redis_con_thread::instance()->command(str(boost::format("HDEL player_login_info_guid %1%") % other.guid()));
            }
            LC_Login replyT;
            replyT.set_result(ret);
            login_session_mgr::instance()->post_msg_to_client_pb(session_id, gate_id, &replyT);
        });
    }
}


void login_db_session::on_dl_reg_account2(DL_RegAccount2* msg)
{
	if (msg->guest_account_result().ret() == LOGIN_RESULT_SUCCESS)
	{
		GuestAccount var = msg->guest_account_result();
		int status = static_cast<login_server*>(base_server::instance())->get_maintain_switch();
		if (status == 1 && var.vip() != 100)
		{
			LOG_WARN("=======maintain login==============status = [%d]", status);
			LC_Login reply;
			reply.set_result(LOGIN_RESULT_MAINTAIN);
			login_session_mgr::instance()->post_msg_to_client_pb(msg->session_id(), msg->gate_id(), &reply);
			send_pb(&reply);
			return;
		}
		int sessionid = msg->session_id();
		int gateid = msg->gate_id();

		std::string phone_ = msg->phone();
		std::string phone_type_ = msg->phone_type();
		std::string version_ = msg->version();
		std::string channel_id_ = msg->channel_id();
		std::string package_name_ = msg->package_name();
		std::string imei_ = msg->imei();
		std::string ip_ = msg->ip();
		std::string ip_area_ = msg->ip_area();

		// 在线信息
		base_redis_con_thread::instance()->command_impl([var, sessionid, gateid, phone_, phone_type_, version_, channel_id_, package_name_, imei_, ip_, ip_area_](RedisConnection* con) {
			// 登陆请求状态判断
			PlayerLoginInfo info;
			if (!con->get_player_login_info(var.account(), &info))
			{
				// 正常注册登陆
				info.set_session_id(sessionid);
				info.set_gate_id(gateid);
				info.set_account(var.account());
				info.set_guid(var.guid());
				info.set_nickname(var.nickname());
				info.set_vip(var.vip());
				info.set_login_time(var.login_time());
				info.set_logout_time(var.logout_time());
				info.set_alipay_account(var.alipay_account());
				info.set_alipay_name(var.alipay_name());
				info.set_change_alipay_num(var.change_alipay_num());
				if (var.no_bank_password() == 0)
					info.set_has_bank_password(true);
				if (var.is_guest())
					info.set_is_guest(true);
				info.set_risk(var.risk());
				info.set_create_channel_id(var.channel_id());
				info.set_enable_transfer(var.enable_transfer());

				info.set_phone(phone_);
				info.set_phone_type(phone_type_);
				info.set_version(version_);
				info.set_channel_id(channel_id_);
				info.set_package_name(package_name_);
				info.set_imei(imei_);
				info.set_ip(ip_);
				info.set_ip_area(ip_area_);
				info.set_is_first(var.is_first());

				std::string password_ = var.password();

				//base_redis_con_thread::instance()->command_impl([info, password_](RedisConnection* con) {
					LOG_INFO("[%s] reg account, guid = %d", info.account().c_str(), info.guid());

					// 找一个默认大厅服务器
					int gameid = login_session_mgr::instance()->find_a_default_lobby();
					if (gameid == 0)
					{
						int session_id = info.session_id();
						int gate_id = info.gate_id();
						int is_first = info.is_first();

						base_redis_con_thread::instance()->add_reply([session_id, gate_id, is_first]() {
							LC_Login reply;
							reply.set_result(LOGIN_RESULT_NO_DEFAULT_LOBBY);
							reply.set_is_first(is_first);

							login_session_mgr::instance()->post_msg_to_client_pb(session_id, gate_id, &reply);
						});

						base_redis_con_thread::instance()->command(str(boost::format("HDEL player_login_info %1%") % info.account()));
						base_redis_con_thread::instance()->command(str(boost::format("HDEL player_login_info_guid %1%") % info.guid()));
						LOG_WARN("no default lobby");
						login_session_mgr::instance()->print_game_server_info();
						return;
					}

					// 存入redis
					con->command(str(boost::format("HSET player_online_gameid %1% %2%") % info.guid() % gameid));
					con->command(str(boost::format("HSET player_session_gate %1%@%2% %3%") % info.session_id() % info.gate_id() % info.account()));
					con->command(str(boost::format("HSET player_login_info %1% %2%") % info.account() % crypto_manager::to_hex(info.SerializeAsString())));
					con->command(str(boost::format("HSET player_login_info_guid %1% %2%") % info.guid() % crypto_manager::to_hex(info.SerializeAsString())));
					base_redis_con_thread::instance()->add_reply([gameid, info, password_]() {
						LS_LoginNotify notify;
						notify.mutable_player_login_info()->CopyFrom(info);
						notify.set_password(password_);

						login_session_mgr::instance()->post_msg_to_game_pb(gameid, &notify);
					});
				//});
				return;
			}

			info.set_session_id(sessionid);
			info.set_gate_id(gateid);
			info.set_account(var.account());
			info.set_guid(var.guid());
			info.set_nickname(var.nickname());
			info.set_vip(var.vip());
			info.set_login_time(var.login_time());
			info.set_logout_time(var.logout_time());
			info.set_alipay_account(var.alipay_account());
			info.set_alipay_name(var.alipay_name());
			info.set_change_alipay_num(var.change_alipay_num());
			if (var.no_bank_password() == 0)
				info.set_has_bank_password(true);
			if (var.is_guest())
				info.set_is_guest(true);
			info.set_risk(var.risk());

			info.set_phone(phone_);
			info.set_phone_type(phone_type_);
			info.set_version(version_);
			info.set_channel_id(channel_id_);
			info.set_package_name(package_name_);
			info.set_imei(imei_);
			info.set_ip(ip_);
			info.set_ip_area(ip_area_);
			info.set_is_first(var.is_first());

			LG_KickClient kick;
			kick.set_session_id(sessionid);
			kick.set_reply_account(info.account());
			kick.set_user_data(1);

			if (!login_session_mgr::instance()->send2gate_pb(gateid, &kick))
			{
				std::string password_ = var.password();
				LOG_INFO("[%s] reg account, guid = %d", info.account().c_str(), info.guid());

				// 找一个默认大厅服务器
				int gameid = login_session_mgr::instance()->find_a_default_lobby();
				if (gameid == 0)
				{
					int session_id = info.session_id();
					int gate_id = info.gate_id();

					LC_Login reply;
					reply.set_result(LOGIN_RESULT_NO_DEFAULT_LOBBY);
					reply.set_is_first(info.is_first());

					login_session_mgr::instance()->post_msg_to_client_pb(session_id, gate_id, &reply);

					base_redis_con_thread::instance()->command(str(boost::format("HDEL player_login_info %1%") % info.account()));
					base_redis_con_thread::instance()->command(str(boost::format("HDEL player_login_info_guid %1%") % info.guid()));
					LOG_WARN("no default lobby");
					login_session_mgr::instance()->print_game_server_info();
					return;
				}

				base_redis_con_thread::instance()->command_impl([info, gameid, password_](RedisConnection* con) {
					// 存入redis
					con->command(str(boost::format("HSET player_online_gameid %1% %2%") % info.guid() % gameid));
					con->command(str(boost::format("HSET player_session_gate %1%@%2% %3%") % info.session_id() % info.gate_id() % info.account()));
					con->command(str(boost::format("HSET player_login_info %1% %2%") % info.account() % crypto_manager::to_hex(info.SerializeAsString())));
					con->command(str(boost::format("HSET player_login_info_guid %1% %2%") % info.guid() % crypto_manager::to_hex(info.SerializeAsString())));
					base_redis_con_thread::instance()->add_reply([gameid, info, password_]() {
						LS_LoginNotify notify;
						notify.mutable_player_login_info()->CopyFrom(info);
						notify.set_password(password_);

						login_session_mgr::instance()->post_msg_to_game_pb(gameid, &notify);
					});
				});
			}
			else
			{
				// 先缓存数据
				con->command(str(boost::format("HSET player_login_info_temp %1% %2%") % info.account() % crypto_manager::to_hex(info.SerializeAsString())));
			}
		});
	}
	else
	{
		LOG_ERR("login reg_account error:%d", msg->guest_account_result().ret());

		LC_Login reply;
		reply.set_result(msg->guest_account_result().ret());
		reply.set_account(msg->guest_account_result().account());
		reply.set_is_guest(msg->guest_account_result().is_guest());
		login_session_mgr::instance()->post_msg_to_client_pb(msg->session_id(), msg->gate_id(), &reply);
	}
}
void login_db_session::on_dl_doSql(DL_DO_SQL * msg){
	auto ss = std::dynamic_pointer_cast<login_session>(login_session_mgr::instance()->find_by_id(msg->retid()));
	if (ss){
		ss->on_do_SqlReQuest(msg);
	}
	else {
		//
		LOG_ERR("===========on_dl_doSql retcode[%d] retdata[%s]  请联系程序解决问题 ", msg->retcode(), msg->retdata().c_str());
	}
}
void login_db_session::on_cc_ChangMoney(DL_CC_ChangeMoney * msg){
	auto ss = std::dynamic_pointer_cast<login_session>(login_session_mgr::instance()->find_by_id(msg->retid()));
	if (ss){
		ss->on_DB_Request(msg);
	}
	else {
		//
		LOG_ERR("===========on_cc_ChangMoney_error guid[%d] money[%d] retcode [%d] 请联系程序解决问题 ", msg->guid(), msg->money(), msg->retcode());
	}
}
void login_db_session::on_dl_NewNotice(DL_NewNotice * msg){
    if (msg->ret() == 100){     //成功
        DL_NewNotice tempMsg;
        tempMsg.CopyFrom(*msg);
        if (msg->type() == 1)   {//消息
            login_session::player_is_online(msg->guid(), [tempMsg](int gateid, int sessionid, std::string account){
               
                if (gateid == -1) {
                    //玩家不在线
                    login_session::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_MsgPlayerOffline, tempMsg.retid());
                    return;
                }
            
                LG_NewNotice newNotice;
                newNotice.set_id(tempMsg.id());
                newNotice.set_gateid(gateid);
                newNotice.set_sessionid(sessionid);
                newNotice.set_start_time(tempMsg.start_time());
                newNotice.set_end_time(tempMsg.end_time());
                newNotice.set_msg_type(tempMsg.type());
                newNotice.set_is_read(1);
                newNotice.set_content(tempMsg.content());
                newNotice.set_retid(tempMsg.retid());
                newNotice.set_guid(tempMsg.guid());
                login_session_mgr::instance()->send2gate_pb(gateid, &newNotice);
            });
        } else if (msg->type() == 2){    //公告
            LS_NewNotice newNotice;
            newNotice.set_id(msg->id());
            newNotice.set_start_time(msg->start_time());
            newNotice.set_end_time(msg->end_time());
            newNotice.set_msg_type(msg->type());
            newNotice.set_is_read(1);
            newNotice.set_content(msg->content());
            newNotice.set_retid(msg->retid());
            login_session_mgr::instance()->broadcast2game_pb(&newNotice);
            login_session::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_Success, msg->retid());
		}
		else if (msg->type() == 3){    //跑马灯
			LS_NewNotice newNotice;
			newNotice.set_id(msg->id());
			newNotice.set_start_time(msg->start_time());
			newNotice.set_end_time(msg->end_time());
			newNotice.set_msg_type(msg->type());
			newNotice.set_number(msg->number());
			newNotice.set_interval_time(msg->interval_time());
			newNotice.set_content(msg->content());
			newNotice.set_retid(msg->retid());
			login_session_mgr::instance()->broadcast2game_pb(&newNotice);
			login_session::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_Success, msg->retid());
		}
    }
    else {  //失败
        LOG_INFO("on_dl_NewNotice faild");
        login_session::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_MsgDBFaild, msg->retid());
    }
}
void login_db_session::on_dl_AlipayEdit(DL_AlipayEdit* msg){
	if (msg->editnum() > 0){
		login_session::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_Success, msg->retid());
	}
	else{
		LOG_INFO("on_dl_DelMessage faild");
		login_session::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_EditAliPayFail, msg->retid());
	}
}
void login_db_session::on_dl_DelMessage(DL_DelMessage * msg){
    if (msg->ret() == 100){     //成功
        LOG_INFO("on_dl_DelMessage success");
        DL_DelMessage tempMsg;
        tempMsg.CopyFrom(*msg);
        if (msg->msg_type() == 1)   {//消息
            login_session::player_is_online(msg->guid(), [tempMsg](int gateid, int sessionid, std::string account){
                if (gateid == -1) {
                    //玩家不在线
                    login_session::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_Success, tempMsg.retid());
                    return;
                }
                LG_DelNotice delNotice;
                delNotice.set_guid(tempMsg.guid());
                delNotice.set_msg_type(tempMsg.msg_type());
                delNotice.set_msg_id(tempMsg.msg_id());
                delNotice.set_retid(tempMsg.retid());
                login_session_mgr::instance()->send2gate_pb(gateid, &delNotice);
            });
        }
        else if (msg->msg_type() == 2 || msg->msg_type() == 3){    //公告
            LS_DelMessage DelMessage;
            DelMessage.set_msg_type(msg->msg_type());
            DelMessage.set_msg_id(msg->msg_id());
            login_session_mgr::instance()->broadcast2game_pb(&DelMessage);
            login_session::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_Success, msg->retid());
        }
    }
    else {  //失败
        LOG_INFO("on_dl_DelMessage faild");
        login_session::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_DelMsgDBError, msg->retid());
    }
}
void Re_Add_Player_Money(int Guid, int Money, int Add_Type)
{
    int Guid_ = Guid;
    int Money_ = Money;
    int Add_Type_ = Add_Type;
    //判断是否在线
    login_session::player_is_online(Guid, [Guid_, Money_, Add_Type_](int gateid, int sessionid, std::string account){
        if (gateid == -1)
        {
        
            //玩家不在线
            LD_AddMoney reply;
            reply.set_guid(Guid_);
            reply.set_money(Money_);
            reply.set_add_type(Add_Type_);
            login_session_mgr::instance()->post_msg_to_mysql_pb(&reply);
            return;
        }
        else
        {
            //判断用户所在服务器ID
            // 在线信息
            base_redis_con_thread::instance()->command_impl([Guid_, Money_, Add_Type_, sessionid, gateid, account](RedisConnection* con) {
                con->command(str(boost::format("HGET player_online_gameid %1%") % Guid_));
                RedisReply reply = con->get_reply();
                reply = con->get_reply();
                if (reply.is_string())
                {
                    int Server_id = boost::lexical_cast<int>(reply.get_string());
                    LS_AddMoney notify;
                    notify.set_guid(Guid_);
                    notify.set_money(Money_);
                    notify.set_add_type(Add_Type_);
                    login_session_mgr::instance()->post_msg_to_game_pb(Server_id, &notify);
                    return;
                }
                else
                {
                    //玩家不在线
                    LD_AddMoney reply;
                    reply.set_guid(Guid_);
                    reply.set_money(Money_);
                    reply.set_add_type(Add_Type_);
                    login_session_mgr::instance()->post_msg_to_mysql_pb(&reply);
                }
            });
        }
    });
}

void login_db_session::on_DL_LuaCmdPlayerResult(DL_LuaCmdPlayerResult* msg)
{
	LW_LuaCmdPlayerResult notify;
	notify.set_result(msg->result());
	login_session_mgr::instance()->send2web_pb(msg->web_id(), &notify);
}

void login_db_session::on_dl_server_config(DL_ServerConfig* msg)
{
    login_session_mgr::instance()->broadcast2gate_pb(msg);
}

void login_db_session::on_dl_server_config_mgr(DL_DBGameConfigMgr* msg)
{
    LG_DBGameConfigMgr nmsg;
    nmsg.mutable_pb_cfg_mgr()->CopyFrom(msg->pb_cfg_mgr());
    login_session_mgr::instance()->send2gate_pb(msg->gid(), &nmsg);
}