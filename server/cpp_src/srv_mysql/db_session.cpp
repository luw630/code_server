#include "db_session.h"
#include "db_session_mgr.h"
#include "base_game_log.h"
#include "db_mgr.h"
#include "public_enum.pb.h"
#include "db_server.h"
#include "db_session_mgr.h"

db_session::db_session(boost::asio::ip::tcp::socket& sock)
	: virtual_session(sock)
	, dispatcher_manager_(nullptr)
	, port_(0)
	, type_(0)
	, server_id_(0)
{
}

db_session::~db_session()
{
}

void db_session::handler_sd_set_password(SD_SetPassword* msg)
{
	int guid = msg->guid();
	int game_id = server_id_;

	db_mgr::instance()->get_db_connection_account().execute_update([game_id, guid](int ret) {
		DS_SetPassword reply;
		reply.set_guid(guid);
		if (ret > 0)
		{
			reply.set_ret(LOGIN_RESULT_SUCCESS);
			db_session_mgr::instance()->post_msg_to_game_pb(game_id, &reply);
		}
		else
		{
			db_mgr::instance()->get_db_connection_account().execute_query_string([guid, game_id](std::vector<std::string>* data) {
				DS_SetPassword reply;
				reply.set_guid(guid);
				if (data)
				{
					reply.set_ret(LOGIN_RESULT_SUCCESS);
				}
				else
				{
					reply.set_ret(LOGIN_RESULT_SET_PASSWORD_FAILED);
				}
				db_session_mgr::instance()->post_msg_to_game_pb(game_id, &reply);
			}, "select guid from t_account where guid = '%d';", guid);
		}

	}, "UPDATE t_account SET `password` = '%s' WHERE guid = %d AND `password` = '%s';", msg->password().c_str(), guid, msg->old_password().c_str());
}

void db_session::handler_ld_verify_account(LD_VerifyAccount* msg)
{
	int login_id = server_id_;
	int sessionid = msg->session_id();
	int gateid = msg->gate_id();
	std::string account = msg->verify_account().account();
	
	if (db_session_mgr::instance()->find_verify_account(account))
	{
		DL_VerifyAccountResult reply;
		auto p = reply.mutable_verify_account_result();
		p->set_ret(LOGIN_RESULT_FREQUENTLY_LOGIN);
		reply.set_session_id(sessionid);
		reply.set_gate_id(gateid);
		reply.set_account(account);

		db_session_mgr::instance()->post_msg_to_login_pb(login_id, &reply);
		return;
	}

	db_session_mgr::instance()->add_verify_account(account);
	db_mgr::instance()->get_db_connection_account().execute_query<VerifyAccountResult>([login_id, sessionid, gateid, account](VerifyAccountResult* data) {
		DL_VerifyAccountResult reply;
		if (data)
		{
			reply.mutable_verify_account_result()->CopyFrom(*data);
		}
		else
		{
			LOG_ERR("verify account[%s] failed", account.c_str());

			auto p = reply.mutable_verify_account_result();
			p->set_ret(LOGIN_RESULT_DB_ERR);
		}
		reply.set_session_id(sessionid);
		reply.set_gate_id(gateid);
		reply.set_account(account);

		db_session_mgr::instance()->post_msg_to_login_pb(login_id, &reply);

		db_session_mgr::instance()->remove_verify_account(account);

	}, nullptr, "CALL verify_account(\"%s\", \"%s\")", account.c_str(), msg->verify_account().password().c_str());
}
void db_session::reg_channel_detailed(int android_uid, int android_pid, int guid, std::string imei, std::string phone, std::string ip, std::string str_channel_id)
{
	init_channel();
	char buff_ny[128] = { 0 };
	char buff_nyr[128] = { 0 };
	const tm* tp_tm = base_game_time_mgr::instance()->get_tm();
	sprintf(buff_ny, "%04d%02d", tp_tm->tm_year + 1900, tp_tm->tm_mon + 1);
	sprintf(buff_nyr, "%04d%02d%02d", tp_tm->tm_year + 1900, tp_tm->tm_mon + 1, tp_tm->tm_mday);
	int ny = atoi(buff_ny);
	int nyr = atoi(buff_nyr);

	if (m_vinvite.size() > 0)
	{
		for (std::vector<sinvite>::iterator it= m_vinvite.begin(); it != m_vinvite.end(); it++)
		{
			if (str_channel_id.compare(it->str_channel_id.c_str()) == 0)
			{
				LOG_INFO("guid %d ,ios channel  find, channe; %s", guid, str_channel_id.c_str());
				db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channelIos_%d \
				(`uid`,`pid`,`imei`,`guid`,`phone`,`ip`,`times`,`times_index`,`Rate`,`effect` )VALUES \
				('%d', '%d', '%s',   '%d',  '%s',   '%s', '%d',    '%d',        '%d',   '%d')",
				ny, it->uid, it->pid, imei.c_str(), guid, phone.c_str(), ip.c_str(),
				int(base_game_time_mgr::instance()->get_second_time()), nyr, 0, 1);

				db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channel_guid \
				(`uid`,`guid`,`phone`,`times_index`)VALUES \
				('%d', '%d', '%d',  '%d')",
				it->uid, guid, 2, nyr);
				return;
			}
		}
	}

	db_mgr::instance()->get_db_connection_account().execute_query_string([android_uid, android_pid, guid, imei, phone, ip](std::vector<std::string>* data) {
		
		char buff_ny[128] = { 0 };
		char buff_nyr[128] = { 0 };
		const tm* tp_tm = base_game_time_mgr::instance()->get_tm();
		sprintf(buff_ny, "%04d%02d", tp_tm->tm_year + 1900, tp_tm->tm_mon + 1);
		sprintf(buff_nyr, "%04d%02d%02d", tp_tm->tm_year + 1900, tp_tm->tm_mon + 1, tp_tm->tm_mday);
		int ny = atoi(buff_ny);
		int nyr = atoi(buff_nyr);

		if (data)
		{
			int fid = atoi((*data)[0].c_str());
			int rate = atoi((*data)[1].c_str());
			int liang = (rand() % 100 < rate) ? 1 : 0;

			db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channelDetailed_%s \
				(`uid`,`pid`,`imei`,`guid`,`phone`,`ip`,`times`,`times_index`,`Rate`,`effect` )VALUES \
				('%d', '%d', '%s',   '%d',  '%s',   '%s', '%d',    '%d',        '%d',   '%d')",
				buff_ny, android_uid, android_pid, imei.c_str(), guid, phone.c_str(), ip.c_str(), 
				int(base_game_time_mgr::instance()->get_second_time()), nyr, rate, liang);

			db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channel_guid \
									(`uid`,`guid`,`phone`,`times_index`)VALUES \
									('%d', '%d', '%d',  '%d')",
									android_uid, guid,1, nyr);
			if (android_uid == 201)
			{
				db_mgr::instance()->get_db_connection_account().execute_query_string([guid, nyr, phone, ip](std::vector<std::string>* data) {
					if (data)
					{
						int tguid = atoi((*data)[0].c_str());
						int nphone = 2;
						if (phone.compare("android") == 0)
						{
							nphone = 1;
						}
						db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_player_guid  \
						(`guid`,`zguid`,`phone`,`times_index` )VALUES \
						('%d', '%d',  '%d', '%d')",
						tguid, guid, nphone, nyr);
					}
				}, "select guid from t_playerip_%d where ip = '%s' and times_index='%d' ORDER BY times DESC LIMIT 1 ;", ny, ip.c_str(), nyr);	
			}
			else
			{//传销推广
// 				db_mgr::instance()->get_db_connection_account().execute_query_string([guid, nyr, phone, ip](std::vector<std::string>* data) {
// 					if (data)
// 					{
// 						int agentid = atoi((*data)[0].c_str());
// 						int tid = atoi((*data)[1].c_str());
// 						int nphone = 2;
// 						if (phone.compare("android") == 0)
// 						{
// 							nphone = 1;
// 						}
// 						db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_agent_guid  \
// 						(`agentid`,`guid`,`phone`,`times_index` )VALUES \
// 						('%d', '%d',  '%d', '%d')",
// 						agentid, guid, nphone, nyr);
// 					}
// 				}, "select agentid,tid from t_agentip_%d where ip = '%s' and times_index='%d' and pid='%d' ORDER BY times DESC LIMIT 1 ;", ny, ip.c_str(), nyr,android_pid);	
				LOG_INFO("guid %d ,ios channel not find, ip %s", guid, ip.c_str());
// 				db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channelIos_%d \
// 				(`uid`,`pid`,`imei`,`guid`,`phone`,`ip`,`times`,`times_index`,`Rate`,`effect` )VALUES \
// 				('%d', '%d', '%s',   '%d',  '%s',   '%s', '%d',    '%d',        '%d',   '%d')",
// 				ny, 8882, 888, imei.c_str(), guid, phone.c_str(), ip.c_str(),
// 				int(base_game_time_mgr::instance()->get_second_time()), nyr, 0, 1);
// 
// 				db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channel_guid \
// 				(`uid`,`guid`,`phone`,`times_index`)VALUES \
// 				('%d', '%d', '%d',  '%d')",
// 				8882, guid, 2, nyr);
			}

		}
		else
		{
			LOG_INFO("guid %d uid %d not find, new ios user", guid, android_uid);

			db_mgr::instance()->get_db_connection_account().execute_query_string([guid, imei, phone, ip, nyr,ny](std::vector<std::string>* data) {
				if (data)
				{
					int uid_t = atoi((*data)[0].c_str());
					int pid_t = atoi((*data)[1].c_str());
					db_mgr::instance()->get_db_connection_account().execute_query_string
						([uid_t, pid_t,guid, imei, phone, ip, nyr, ny](std::vector<std::string>* data)
					{
						if (data)
						{
							int fid = atoi((*data)[0].c_str());
							int rate = atoi((*data)[1].c_str());
							int liang = (rand() % 100 < rate) ? 1 : 0;

							db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channelIos_%d \
							(`uid`,`pid`,`imei`,`guid`,`phone`,`ip`,`times`,`times_index`,`Rate`,`effect` )VALUES \
							('%d', '%d', '%s',   '%d',  '%s',   '%s', '%d',    '%d',        '%d',   '%d')",
							ny, uid_t, pid_t, imei.c_str(), guid, phone.c_str(), ip.c_str(),
							int(base_game_time_mgr::instance()->get_second_time()), nyr, rate, liang);

							db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channel_guid \
																			(`uid`,`guid`,`phone`,`times_index`)VALUES \
																			('%d', '%d', '%d',  '%d')",
																			uid_t, guid, 2, nyr);
						}
						else
						{
							//LOG_ERR("uid_t %d not find ", uid_t);
							LOG_INFO("guid %d ,ios channel not find, ip %s", guid, ip.c_str());
							db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channelIos_%d \
							(`uid`,`pid`,`imei`,`guid`,`phone`,`ip`,`times`,`times_index`,`Rate`,`effect` )VALUES \
							('%d', '%d', '%s',   '%d',  '%s',   '%s', '%d',    '%d',        '%d',   '%d')",
							ny, 8882, 888, imei.c_str(), guid, phone.c_str(), ip.c_str(),
							int(base_game_time_mgr::instance()->get_second_time()), nyr, 0, 1);

							db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channel_guid \
							(`uid`,`guid`,`phone`,`times_index`)VALUES \
							('%d', '%d', '%d',  '%d')",
							8882, guid, 2, nyr);

						}

					}, "select father_id,Rate from t_channel_account where uid = '%d';", uid_t);
				}
				else
				{
					db_mgr::instance()->get_db_connection_account().execute_query_string([guid, imei, phone, ip, nyr, ny](std::vector<std::string>* data) {
						if (data)
						{
							int tguid = atoi((*data)[0].c_str());
							int nphone = 2;
							if (phone.compare("android") == 0)
							{
								nphone = 1;
							}
							db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_player_guid  \
							(`guid`,`zguid`,`phone`,`times_index` )VALUES \
							('%d', '%d',  '%d', '%d')",
							tguid, guid, nphone, nyr);

							db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channelIos_%d \
							(`uid`,`pid`,`imei`,`guid`,`phone`,`ip`,`times`,`times_index`,`Rate`,`effect` )VALUES \
							('%d', '%d', '%s',   '%d',  '%s',   '%s', '%d',    '%d',        '%d',   '%d')",
							ny, 202, 200, imei.c_str(), guid, phone.c_str(), ip.c_str(),
							int(base_game_time_mgr::instance()->get_second_time()), nyr, 0, 1);

							db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channel_guid \
							(`uid`,`guid`,`phone`,`times_index`)VALUES \
							('%d', '%d', '%d',  '%d')",
							202, guid, 2, nyr);
						}
						else
						{
							db_mgr::instance()->get_db_connection_account().execute_query_string([guid, imei, phone, ip, nyr, ny](std::vector<std::string>* data) {
								if (data)
								{
									int agentid = atoi((*data)[0].c_str());
									int pid = atoi((*data)[1].c_str());

									db_mgr::instance()->get_db_connection_account().execute_query_string([guid, imei, phone, ip, nyr, ny,agentid,pid](std::vector<std::string>* data) {
										if (data)
										{
											int uid = atoi((*data)[0].c_str());
											int nphone = 2;
											if (phone.compare("android") == 0)
											{
												nphone = 1;
											}
// 											db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_agent_guid  \
// 											(`agentid`,`guid`,`phone`,`times_index` )VALUES \
// 											('%d', '%d',  '%d', '%d')",
// 											agentid, guid, nphone, nyr);

											db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channelIos_%d \
											(`uid`,`pid`,`imei`,`guid`,`phone`,`ip`,`times`,`times_index`,`Rate`,`effect` )VALUES \
											('%d', '%d', '%s',   '%d',  '%s',   '%s', '%d',    '%d',        '%d',   '%d')",
											ny, uid, pid, imei.c_str(), guid, phone.c_str(), ip.c_str(),
											int(base_game_time_mgr::instance()->get_second_time()), nyr, 0, 1);

											db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channel_guid \
											(`uid`,`guid`,`phone`,`times_index`)VALUES \
											('%d', '%d', '%d',  '%d')",
											uid, guid, 2, nyr);
										}
										else
										{
											LOG_ERR("guid %d ,ios channel uid not find, ip %s,pid is %d", guid, ip.c_str(),pid);
											LOG_INFO("guid %d ,ios channel not find, ip %s", guid, ip.c_str());
											db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channelIos_%d \
											(`uid`,`pid`,`imei`,`guid`,`phone`,`ip`,`times`,`times_index`,`Rate`,`effect` )VALUES \
											('%d', '%d', '%s',   '%d',  '%s',   '%s', '%d',    '%d',        '%d',   '%d')",
											ny, 8882, 888, imei.c_str(), guid, phone.c_str(), ip.c_str(),
											int(base_game_time_mgr::instance()->get_second_time()), nyr, 0, 1);

											db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channel_guid \
											(`uid`,`guid`,`phone`,`times_index`)VALUES \
											('%d', '%d', '%d',  '%d')",
											8882, guid, 2, nyr);
										}
									}, "select uid from t_channel_account where father_id='%d' LIMIT 1 ;", pid);	

								}
								else
								{
									LOG_INFO("guid %d ,ios channel not find, ip %s", guid, ip.c_str());
									db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channelIos_%d \
									(`uid`,`pid`,`imei`,`guid`,`phone`,`ip`,`times`,`times_index`,`Rate`,`effect` )VALUES \
									('%d', '%d', '%s',   '%d',  '%s',   '%s', '%d',    '%d',        '%d',   '%d')",
									ny, 8882, 888, imei.c_str(), guid, phone.c_str(), ip.c_str(),
									int(base_game_time_mgr::instance()->get_second_time()), nyr, 0, 1);

									db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_channel_guid \
									(`uid`,`guid`,`phone`,`times_index`)VALUES \
									('%d', '%d', '%d',  '%d')",
									8882, guid, 2, nyr);
								}
							}, "select agentid,pid from t_agentip_%d where ip = '%s' and times_index='%d'ORDER BY times DESC LIMIT 1 ;", ny, ip.c_str(), nyr);	
						}
					}, "select guid from t_playerip_%d where ip = '%s' and times_index='%d' ORDER BY times DESC LIMIT 1 ;", ny, ip.c_str(), nyr);
				}
			}, "select uid,pid from t_channelIosIp_%s where ip='%s' and times_index=%d order by times desc limit 1;", buff_ny, ip.c_str(), nyr);

		}
	}, "select father_id,Rate from t_channel_account where uid = '%d';", android_uid);
}

void db_session::reg_channel_invite( int guid, std::string phone, std::string ip)
{
		char buff_ny[128] = { 0 };
		char buff_nyr[128] = { 0 };
		const tm* tp_tm = base_game_time_mgr::instance()->get_tm();
		sprintf(buff_ny, "%04d%02d", tp_tm->tm_year + 1900, tp_tm->tm_mon + 1);
		sprintf(buff_nyr, "%04d%02d%02d", tp_tm->tm_year + 1900, tp_tm->tm_mon + 1, tp_tm->tm_mday);
		int ny = atoi(buff_ny);
		int nyr = atoi(buff_nyr);

		db_mgr::instance()->get_db_connection_account().execute_query_string([guid, nyr, phone, ip](std::vector<std::string>* data) {

		if (data)
		{
			int tguid = atoi((*data)[0].c_str());
			int nphone = 2;
			if (phone.compare("android") == 0)
			{
				nphone = 1;
			}
			db_mgr::instance()->get_db_connection_account().execute("INSERT INTO t_player_guid  \
			(`guid`,`zguid`,`phone`,`times_index` )VALUES \
			('%d', '%d',  '%d', '%d')",
			tguid, guid, nphone, nyr);
		}
	}, "select guid from t_playerip_%d where ip = '%s' and times_index='%d' ORDER BY times DESC LIMIT 1 ;", ny, ip.c_str(), nyr);

}

void db_session::handler_ld_reg_account(LD_RegAccount* msg)
{
	int login_id = server_id_;
	int sessionid = msg->session_id();
	int gateid = msg->gate_id();
	std::string account_;
	if (msg->has_account())
	{
		account_ = msg->account();
	}
	std::string password_;
	if (msg->has_password())
	{
		password_ = msg->password();
	}

	std::string str_phone = msg->phone();
	std::string str_phone_type = msg->phone_type();
	std::string str_version = msg->version();
	std::string str_channel_id = msg->channel_id();
	std::string str_package_name = msg->package_name();
	std::string str_imei = msg->imei();
	std::string str_ip = msg->ip();
	std::string str_ip_area = msg->ip_area();

	int android_uid = msg->android_uid();
	int android_pid = msg->android_pid();

	if (account_.empty())
	{
		db_mgr::instance()->get_db_connection_account().execute_query<GuestAccount>([this,login_id, sessionid, gateid, str_phone, str_phone_type, 
			str_version, str_channel_id, str_package_name, str_imei, str_ip, str_ip_area, android_uid, android_pid](GuestAccount* data) {
			DL_RegAccount2 reply;
			if (data)
			{
				reply.mutable_guest_account_result()->CopyFrom(*data);
				reply.set_phone(str_phone);
				reply.set_phone_type(str_phone_type);
				reply.set_version(str_version);
				reply.set_channel_id(str_channel_id);
				reply.set_package_name(str_package_name);
				reply.set_imei(str_imei);
				reply.set_ip(str_ip);
				reply.set_ip_area(str_ip_area);
				LOG_INFO("reg player01 %d ui %d , pid %d", reply.guest_account_result().guid(), android_uid, android_pid);
				if (reply.guest_account_result().is_first() == 1)
				{
					LOG_INFO("reg player02 %d ui %d , pid %d", reply.guest_account_result().guid(), android_uid, android_pid);
					reg_channel_detailed(android_uid, android_pid, reply.guest_account_result().guid(), reply.imei(), reply.phone(), reply.ip(), str_channel_id);
					
				}
				check_blacklist_ip(str_ip, reply.guest_account_result().guid());
			}
			else
			{
				LOG_ERR("guest imei[%s] failed", str_imei.c_str());

				auto p = reply.mutable_guest_account_result();
				p->set_ret(LOGIN_RESULT_DB_ERR);
			}
			reply.set_session_id(sessionid);
			reply.set_gate_id(gateid);

			db_session_mgr::instance()->post_msg_to_login_pb(login_id, &reply);

		}, nullptr, "CALL create_guest_account('%s', '%s', '%s', '%s', '%s', '%s', '%s');", msg->phone().c_str(), msg->phone_type().c_str(), msg->version().c_str(), 
			msg->channel_id().c_str(), msg->package_name().c_str(), msg->imei().c_str(), msg->ip().c_str());
	}
	else
	{
		LOG_WARN("has account");

		/*std::string sql = str(boost::format("INSERT INTO t_account (account,password,is_guest,nickname,create_time,phone,phone_type,version,channel_id,package_name,imei,ip) VALUES ('%1%','%2%',0,'%3%',NOW(),'%4%', %5%, %6%, %7%, '%8%', '%9%', '%10%');") %
			account_ % msg->password() % account_ % msg->phone() % msg->phone_type() % msg->version() % msg->channel_id() %
			msg->package_name() % msg->imei() % msg->ip());
		db_mgr::instance()->get_db_connection_account().execute_try([login_id, sessionid, gateid, account_, str_phone, str_phone_type, str_version, str_channel_id, str_package_name, str_imei, str_ip, str_ip_area](int ret) {
			if (ret == 0)
			{
				db_mgr::instance()->get_db_connection_account().execute_query<GuestAccount>([login_id, sessionid, gateid, str_phone, str_phone_type, str_version, str_channel_id, str_package_name, str_imei, str_ip, str_ip_area](GuestAccount* data) {
					DL_RegAccount reply;
					reply.set_session_id(sessionid);
					reply.set_gate_id(gateid);
					reply.set_is_guest(true);
					if (data)
					{
						reply.set_ret(REG_ACCOUNT_RESULT_SUCCESS);
						reply.set_account(data->account());
						reply.set_guid(data->guid());
						reply.set_nickname(data->nickname());
						reply.set_password(data->password());
						reply.set_phone(str_phone);
						reply.set_phone_type(str_phone_type);
						reply.set_version(str_version);
						reply.set_channel_id(str_channel_id);
						reply.set_package_name(str_package_name);
						reply.set_imei(str_imei);
						reply.set_ip(str_ip);
						reply.set_ip_area(str_ip_area);
					}
					else
						reply.set_ret(REG_ACCOUNT_RESULT_FAILED);

					db_session_mgr::instance()->post_msg_to_login_pb(login_id, &reply);

				}, nullptr, "SELECT account, password, guid, nickname FROM t_account WHERE account='%s';", account_.c_str());
			}
			else
			{
				DL_RegAccount reply;
				reply.set_ret(REG_ACCOUNT_RESULT_FAILED);
				reply.set_account(account_);
				reply.set_is_guest(false);
				reply.set_session_id(sessionid);
				reply.set_gate_id(gateid);

				db_session_mgr::instance()->post_msg_to_login_pb(login_id, &reply);
			}
		}, sql.c_str());*/
		//}, "INSERT INTO t_account (account,password,is_guest,nickname,create_time,phone,phone_type,version,channel_id,package_name,imei,ip) VALUES ('%s','%s',0,'%s',NOW(),'%s', %d, %d, %d, '%s', '%s', '%s');", 
		//	account_.c_str(), msg->password().c_str(), account_.c_str(), msg->phone().c_str(), msg->phone_type().c_str(), msg->version(), msg->channel_id(),
		//	msg->package_name().c_str(), msg->imei().c_str(), msg->ip().c_str());
	}
}
bool db_session::handler_msg_dispatch(MsgHeader* header)
{
	if (virtual_session::handler_msg_dispatch(header))
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
		LOG_ERR("msg[%d] not registered", header->id);
		return true;
	}

	return dispatcher->parse(this, header);
}

bool db_session::handler_accept()
{
	port_ = get_remote_ip_port(ip_);
	LOG_INFO("accept session ... <%s:%d>", ip_.c_str(), port_);

	dispatcher_manager_ = db_session_mgr::instance()->get_dispatcher_manager();

	return true;
}

void db_session::on_closed()
{
	LOG_INFO("session disconnect ... <%s:%d> type:%d", ip_.c_str(), port_, type_);

	switch (type_)
	{
	case ServerSessionFromLogin:
		db_session_mgr::instance()->del_login_session(shared_from_this());
		break;
	case ServerSessionFromGame:
		db_session_mgr::instance()->del_game_session(shared_from_this());
		break;
	default:
		LOG_WARN("unknown connect closed %d", type_);
		break;
	}
}

void db_session::on_s_connect(S_Connect* msg)
{
	type_ = msg->type();
	switch (type_)
	{
	case ServerSessionFromLogin:
		dispatcher_manager_ = db_session_mgr::instance()->get_dispatcher_manager_login();
		server_id_ = msg->server_id();
		db_session_mgr::instance()->add_login_session(shared_from_this());

		LOG_INFO("connect session loginid=%d ... <%s:%d>", server_id_, ip_.c_str(), port_);
		break;
	case ServerSessionFromGame:
		dispatcher_manager_ = db_session_mgr::instance()->get_dispatcher_manager_game();
		server_id_ = msg->server_id();
		db_session_mgr::instance()->add_game_session(shared_from_this());
		db_mgr::instance()->get_db_connection_account().execute("DELETE FROM t_online_account WHERE game_id=%d;", server_id_);

		LOG_INFO("connect session gameid=%d ... <%s:%d>", server_id_, ip_.c_str(), port_);
		break;
	default:
		LOG_WARN("unknown connecting %d", type_);
		close();
	}
}
void db_session::handler_ld_sms_login(LD_SmsLogin* msg)
{
	int login_id = server_id_;
	int sessionid = msg->session_id();
	int gateid = msg->gate_id();
	std::string account = msg->account();
	std::string phone_ = msg->phone();
	std::string phone_type_ = msg->phone_type();
	std::string version_ = msg->version();
	std::string channel_id_ = msg->channel_id();
	std::string package_name_ = msg->package_name();
	std::string imei_ = msg->imei();
	std::string ip_ = msg->ip();
	std::string ip_area_ = msg->ip_area();

	db_mgr::instance()->get_db_connection_account().execute_query<VerifyAccountResult>([this, login_id, sessionid, gateid, account, phone_, phone_type_, version_, channel_id_, package_name_, imei_, ip_, ip_area_](VerifyAccountResult* data) {
		DL_VerifyAccountResult reply;
		if (data)
		{
			if (data->ret() == LOGIN_RESULT_ACCOUNT_PASSWORD_ERR)
			{
				db_mgr::instance()->get_db_connection_account().execute_query<GuestAccount>([this, login_id, sessionid, gateid, phone_, phone_type_, version_, channel_id_, package_name_, imei_, ip_, ip_area_](GuestAccount* data) {
					DL_RegAccount reply;
					reply.set_session_id(sessionid);
					reply.set_gate_id(gateid);
					reply.set_is_guest(false);
					if (data)
					{
						reply.set_ret(REG_ACCOUNT_RESULT_SUCCESS);
						reply.set_account(data->account());
						reply.set_guid(data->guid());
						reply.set_nickname(data->nickname());
						reply.set_password(data->password());
						reply.set_phone(phone_);
						reply.set_phone_type(phone_type_);
						reply.set_version(version_);
						reply.set_channel_id(channel_id_);
						reply.set_package_name(package_name_);
						reply.set_imei(imei_);
						reply.set_ip(ip_);
						reply.set_ip_area(ip_area_);

						std::string t_package_name_;
						t_package_name_.assign(package_name_);//com.joy_honor.card_game_leyou_joy_22000_22001
						int need_num = 2;
						std::vector<std::string> num_list;
						num_list.resize(need_num);
						int cur_num_index = 0;
						for (size_t i = 0; i < t_package_name_.size(); i++)
						{
							char tchar = t_package_name_.at(i);
							if (tchar >= '0'&& tchar <= '9')
							{
								size_t j = i + 1;
								for (; j < t_package_name_.size(); j++)
								{
									char tchar_j = t_package_name_.at(j);
									if (tchar_j >= '0'&& tchar_j <= '9')
									{

									}
									else
									{
										break;
									}
								}
								num_list[cur_num_index].assign(t_package_name_.substr(i, j - i));
								cur_num_index++;
								if (need_num == cur_num_index)
								{
									break;
								}
								i = j;
							}
						}
						//22001 uid
						//22000 pid

						reg_channel_detailed(atoi(num_list[1].c_str()), atoi(num_list[0].c_str()), reply.guid(), imei_, reply.phone(), reply.ip(), channel_id_);
				
					}
					else
						reply.set_ret(REG_ACCOUNT_RESULT_FAILED);

					db_session_mgr::instance()->post_msg_to_login_pb(login_id, &reply);

				}, nullptr, "CALL create_account('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s');", account.c_str(), phone_.c_str(), phone_type_.c_str(), version_.c_str(), 
					channel_id_.c_str(), package_name_.c_str(), imei_.c_str(), ip_.c_str());

				return;
			}

			reply.mutable_verify_account_result()->CopyFrom(*data);
			reply.set_password(data->password());
		}
		else
		{
			LOG_ERR("sms login[%s] failed", account.c_str());

			auto p = reply.mutable_verify_account_result();
			p->set_ret(LOGIN_RESULT_DB_ERR);
		}
		reply.set_session_id(sessionid);
		reply.set_gate_id(gateid);
		reply.set_account(account);

		db_session_mgr::instance()->post_msg_to_login_pb(login_id, &reply);
	}, nullptr, "CALL sms_login(\"%s\")", account.c_str());
}

void db_session::handler_sd_reset_account(SD_ResetAccount* msg)
{
	int guid = msg->guid();
	std::string account = msg->account();
	std::string nickname = msg->nickname();
	int game_id = server_id_;

	db_mgr::instance()->get_db_connection_account().execute_update_try([game_id, guid, account, nickname](int ret, int err) {
		if (ER_DUP_ENTRY == err)
		{
			db_mgr::instance()->get_db_connection_account().execute_query_string([guid, game_id, account, nickname](std::vector<std::string>* data) {
				DS_ResetAccount reply;
				reply.set_guid(guid);
				reply.set_account(account);
				reply.set_nickname(nickname);

				if (data)
				{
					reply.set_ret(LOGIN_RESULT_RESET_ACCOUNT_DUP_ACC);
				}
				else
				{
					reply.set_ret(LOGIN_RESULT_RESET_ACCOUNT_DUP_NICKNAME);
				}
				db_session_mgr::instance()->post_msg_to_game_pb(game_id, &reply);

			}, "select account from t_account where account = '%s';", account.c_str());

			return;
		}

		DS_ResetAccount reply;
		reply.set_guid(guid);
		reply.set_account(account);
		reply.set_nickname(nickname);
		if (ret > 0 && err == 0)
		{
			reply.set_ret(LOGIN_RESULT_SUCCESS);

			db_mgr::instance()->get_db_connection_game().execute("UPDATE t_player SET account='%s', nickname = '%s' WHERE guid=%d;", account.c_str(), nickname.c_str(), guid);

            db_mgr::instance()->get_db_connection_account().execute_query_string([guid, game_id](std::vector<std::string>* data) {
                DS_BandAlipayNum nmsg;
                if (data)
                {
                    nmsg.set_guid(guid);
                    int temp = atoi((*data)[0].c_str());
                    nmsg.set_band_num(temp);
                    db_session_mgr::instance()->post_msg_to_game_pb(game_id, &nmsg);
                }
            }, "select change_alipay_num from t_account where guid = '%d';", guid);
		}
		else
		{
			reply.set_ret(LOGIN_RESULT_RESET_ACCOUNT_FAILED);

			LOG_ERR("mysql ret = %d, err = %d", ret, err);
		}

		db_session_mgr::instance()->post_msg_to_game_pb(game_id, &reply);
	}, "UPDATE t_account SET account = '%s', `password` = '%s', nickname = '%s', is_guest = 0, register_time = NOW() WHERE guid = %d AND is_guest != 0;", account.c_str(), msg->password().c_str(), nickname.c_str(), guid);
}
	


void db_session::handler_sd_set_password_by_sms(SD_SetPasswordBySms* msg)
{
	int guid = msg->guid();
	int game_id = server_id_;

	db_mgr::instance()->get_db_connection_account().execute_update([game_id, guid](int ret) {
		DS_SetPassword reply;
		reply.set_guid(guid);
		if (ret > 0)
		{
			reply.set_ret(LOGIN_RESULT_SUCCESS);
			db_session_mgr::instance()->post_msg_to_game_pb(game_id, &reply);
		}
		else
		{
			//reply.set_ret(LOGIN_RESULT_SET_PASSWORD_FAILED);

			db_mgr::instance()->get_db_connection_account().execute_query_string([guid, game_id](std::vector<std::string>* data) {
				DS_SetPassword reply;
				reply.set_guid(guid);
				if (data)
				{
					reply.set_ret(LOGIN_RESULT_SUCCESS);
				}
				else
				{
					reply.set_ret(LOGIN_RESULT_SET_PASSWORD_FAILED);
				}
				db_session_mgr::instance()->post_msg_to_game_pb(game_id, &reply);
			}, "select guid from t_account where guid = '%d';", guid);
		}
	}, "UPDATE t_account SET `password` = '%s' WHERE guid = %d;", msg->password().c_str(), guid);
}

void db_session::handler_sd_set_nickname(SD_SetNickname* msg)
{
	int guid = msg->guid();
	std::string nickname = msg->nickname();
	int game_id = server_id_;

	db_mgr::instance()->get_db_connection_account().execute_update_try([game_id, guid, nickname](int ret, int err) {
		DS_SetNickname reply;
		reply.set_guid(guid);
		reply.set_nickname(nickname);
		if (ret > 0 && err == 0)
		{
			reply.set_ret(LOGIN_RESULT_SUCCESS);
		}
		else if (ER_DUP_ENTRY == err)
		{
			reply.set_ret(LOGIN_RESULT_SET_NICKNAME_DUP_NICKNAME);
		}
		else
		{
			reply.set_ret(LOGIN_RESULT_SET_NICKNAME_FAILED);

			LOG_ERR("mysql ret = %d, err = %d", ret, err);
		}

		db_session_mgr::instance()->post_msg_to_game_pb(game_id, &reply);

		db_mgr::instance()->get_db_connection_game().execute("UPDATE t_player SET nickname='%s' WHERE guid=%d;", nickname.c_str(), guid);
	}, "UPDATE t_account SET `nickname` = '%s' WHERE guid = %d;", nickname.c_str(), guid);
}

void db_session::handler_sd_update_earnings(SD_UpdateEarnings* msg)
{
	db_mgr::instance()->get_db_connection_game().execute("UPDATE t_earnings SET daily_earnings = daily_earnings + %d, weekly_earnings = weekly_earnings + %d, monthly_earnings = monthly_earnings + %d WHERE guid = %d;",
		msg->money(), msg->money(), msg->money(), msg->guid());
}

//void db_session::handler_ld_recharge(LD_Recharge* msg)
//{
//    int login_id = server_id_;
//    int order_id = msg->order_id();
//    int web_id = msg->web_id();
//    db_mgr::instance()->get_db_connection_recharge().execute_query<Recharge>([web_id, order_id, login_id](Recharge* data) {
//        if (data && (data->pay_status() != 2) && (data->server_status() == 0))
//        {
//            DL_RechargeInfo reply;
//            reply.set_web_id(web_id);
//            reply.mutable_info()->CopyFrom(*data);
//            reply.set_login_id(login_id);
//            db_session_mgr::instance()->post_msg_to_login_pb(login_id, &reply);
//        }
//        else
//        {
//            DL_RechargeReply reply;
//            reply.set_web_id(web_id);
//            reply.set_result(2);
//            db_session_mgr::instance()->post_msg_to_login_pb(login_id, &reply);
//        }
//    }, nullptr, "SELECT guid, id, exchange_gold, pay_status,server_status FROM t_recharge_order WHERE id='%d';", order_id);
//}


//void db_session::handler_ld_recharge_reply(LD_RechargeReply* msg)
//{
//    int result = msg->result();
//    int order_id = msg->order_id();
//    __int64 bbank_ = msg->befor_bank();
//    __int64 abank_ = msg->after_bank();
//    db_mgr::instance()->get_db_connection_recharge().execute("UPDATE t_recharge_order SET `server_status` = '%d' , before_bank = '%I64d', after_bank = '%I64d' WHERE id = %d;", result, bbank_, abank_, order_id);
//}

void db_session::handler_ld_phone_query(LD_PhoneQuery* msg)
{
	int login_id = server_id_;
	std::string phone = msg->phone();
	int gate_session_id = msg->gate_session_id();

	db_mgr::instance()->get_db_connection_account().execute_query_string([login_id, phone, gate_session_id](std::vector<std::string>* data) {
		DL_PhoneQuery reply;
		reply.set_phone(phone);
		reply.set_gate_session_id(gate_session_id);
		if (data)
		{
			reply.set_ret(2);
		}
		else
		{
			reply.set_ret(1);
		}
		db_session_mgr::instance()->post_msg_to_login_pb(login_id, &reply);
	}, "select account from t_account where account = '%s';", msg->phone().c_str());
}
void db_session::handler_ld_get_inviter_info(CL_GetInviterInfo* msg)
{
	int login_id = server_id_;
	std::string invite_code = msg->invite_code();
	int gate_session_id = msg->gate_session_id();
	int gate_id = msg->gate_id();
	int new_player_guid = msg->guid();
	
	db_mgr::instance()->get_db_connection_account().execute_query<InviterInfo>([login_id, gate_session_id, gate_id, new_player_guid](InviterInfo* data) {
		LC_GetInviterInfo reply;
		reply.set_gate_session_id(gate_session_id);
		reply.set_gate_id(gate_id);
		if (data)
		{
			reply.set_guid(data->guid());
			reply.set_account(data->account());
			reply.set_alipay_name(data->alipay_name_y());
			reply.set_alipay_account(data->alipay_account_y());
			reply.set_guid_self(new_player_guid);
			int inviter_guid = data->guid();
			db_mgr::instance()->get_db_connection_account().execute_update([](int ret) {
			}, "UPDATE t_account SET `inviter_guid` = %d WHERE guid = %d;", inviter_guid, new_player_guid);
		}
		db_session_mgr::instance()->post_msg_to_login_pb(login_id, &reply);
	}, nullptr, "select guid,account,alipay_name_y,alipay_account_y from t_account where invite_code = '%s';", invite_code.c_str());
}
//void db_session::handler_ld_recharge_deal(LD_RechargeDeal* msg)
//{
//    int login_id = server_id_;
//    int guid = msg->info().guid();
//    int order_id = msg->info().id();
//    int money = msg->info().exchange_gold();
//    int web_id = msg->web_id();
//    db_mgr::instance()->get_db_connection_game().execute_query<PlayerMoney>([order_id, money, guid, web_id, login_id](PlayerMoney* befor_data) {
//        __int64 bank_ = befor_data->bank();
//        db_mgr::instance()->get_db_connection_game().execute_update([order_id, money, guid, web_id, login_id, bank_](int ret) {
//            DL_RechargeReply reply;
//            reply.set_web_id(web_id);
//            if (ret > 0)
//            {
//                reply.set_result(1);
//                __int64 bank_after = bank_ + money;
//                db_mgr::instance()->get_db_connection_recharge().execute("UPDATE t_recharge_order SET `server_status` = '1', before_bank = '%I64d', after_bank = '%I64d' WHERE id = %d;", bank_, bank_after, order_id);
//
//                db_mgr::instance()->get_db_connection_game().execute_query<PlayerMoney>([guid, money](PlayerMoney* data) {
//                    db_mgr::instance()->get_db_connection_log().execute("INSERT INTO t_log_money (`guid`,`old_money`,`new_money`,`old_bank`,`new_bank`,`opt_type`)VALUES ('%d','%I64d','%I64d','%I64d','%I64d','%d')",
//                        guid, data->money(), data->money(), data->bank() - money, data->bank(), LOG_MONEY_OPT_TYPE_RECHARGE_MONEY);
//                }, nullptr, "SELECT money, bank FROM t_player WHERE guid='%d';", guid);
//            }
//            else
//            {
//                reply.set_result(4);
//                db_mgr::instance()->get_db_connection_recharge().execute("UPDATE t_recharge_order SET `server_status` = '4' WHERE id = %d;", order_id);
//            }
//            db_session_mgr::instance()->post_msg_to_login_pb(login_id, &reply);
//        }, "UPDATE t_player SET `bank` = `bank` +  '%d' WHERE guid = %d;", money, guid);
//    }, nullptr, "SELECT money, bank FROM t_player WHERE guid='%d';", guid);
//}


void db_session::handler_ld_re_add_player_money(LD_AddMoney* msg)
{
    int login_id = server_id_;
    int guid = msg->guid();
    int money = msg->money();
    int Add_Type = msg->add_type();

    db_mgr::instance()->get_db_connection_game().execute_update([guid, money, Add_Type,login_id](int ret) {
        if (ret > 0)
        {
            db_mgr::instance()->get_db_connection_game().execute_query<PlayerMoney>([guid, money, Add_Type](PlayerMoney* data) {
                db_mgr::instance()->get_db_connection_log().execute("INSERT INTO t_log_money (`guid`,`old_money`,`new_money`,`old_bank`,`new_bank`,`opt_type`)VALUES ('%d','%I64d','%I64d','%I64d','%I64d','%d')",
                    guid, data->money(), data->money(), data->bank() - money, data->bank(), Add_Type);
            }, nullptr, "SELECT money, bank FROM t_player WHERE guid='%d';", guid);
        }
        else
        {
            LOG_ERR("handler_ld_re_add_player_money----false guid = %d  money = %d add_type = %d", guid, money, Add_Type);
        }
    }, "UPDATE t_player SET `bank` = `bank` +  '%d' WHERE guid = %d;", money, guid);
}
bool IsNum(std::string str)
{
    std::stringstream sin(str);
    double d;
    char c;
    if (!(sin >> d))
        return false;
    if (sin >> c)
        return false;
    return true;
}
// 0 ������ 1ȫ���� 2������Ҳ�������ַ�

int IsALLChinese(std::string str)
{
    int ReCode = 1;
    bool bChinese = false;
    bool bOther = false;
    if (str.length() % 2 != 0)
    {
        bOther = true;
    }
    size_t n = 0;
    size_t count = 0;
    unsigned char c1, c2;
    setlocale(LC_ALL, "");
    std::string strTemp = "��";
    unsigned char c3, c4;
    c3 = (unsigned char)strTemp[0];
    c4 = (unsigned char)strTemp[1];
    while (n < str.size() - 1)
    {
        count = mblen(&str[n], 2);
        if (count == 1)
        {
            bOther = true;
        }
        else
        {
            c1 = (unsigned char)str[n];
            c2 = (unsigned char)str[n + 1];
            if (((c1 >= 0xa1 && c1 <= 0xa9) && (c2 >= 0xa1 && c2 <= 0xfe)) ||
                ((c1 >= 0xa8 && c1 <= 0xa9) && (c2 >= 0x40 && c2 <= 0xa0)))
            {
                //????
                if ((c1 == c3) && (c2 == c4))
                {
                    bChinese = true;
                }
                else
                {
                    bOther = true;
                }
            }
            else
            {
                bChinese = true;
            }
        }
        n = n + 2;
    }
    if (bChinese == false)
    {
        return 0;
    }
    else if (bOther)
    {
        return 2;
    }
    else
    {
        return 1;
    }
}
int Check_Alipay_Account(std::string account, std::string name)
{
    int iRet = 1;
    if (!IsNum(account))
    {
        if (IsALLChinese(account) != 0)
        {
            return false;
        }
        int n = 0, m = 0;
        n = std::count(account.begin(), account.end(), '@');
        if (n == 0 || n > 1)
        {
            return false;
        }
        n = account.find("@");
        m = account.find(".");
        if ((m - n < 1) || (m == -1) || (m >= account.length()))
        {
            return false;
        }
    }
    else
    {
        if (account.length() != 11)
        {
            return false;
        }
        iRet = 2;
    }
    if (IsALLChinese(name) != 1)
    {
        return false;
    }
    return iRet;
}
void Get_StartName(int type, std::string account, std::string name, std::string &start_account, std::string& start_name)
{
    if (type == 1)
    {
        //????4λ???4????? С?????2??
        int n = account.find("@");
        if (n > 4)
        {
            start_account = account.substr(0, n - 4);
            start_account = start_account + "****";
        }
        else if (n > 2)
        {
            start_account = account.substr(0, n - 2);
            start_account = start_account + "**";
        }
        else
        {
            start_account = account.substr(0, 1);
            start_account = start_account + "*";
        }
        start_account = start_account + account.substr(n, account.length() - n);
    }
    else
    {
        //?3??4
        start_account = account.substr(0, 3);
        start_account = start_account + "****" + account.substr(7, 4);
    }
    start_name = name.substr(0, 3);
    for (int i = 1; i < name.length() / 3; i++)
    {
        start_name = start_name + "*";
    }
}
std::string UTF8ToGBK(const char src[])
{
#ifdef PLATFORM_WINDOWS
	std::string ans;
	if (!src)  //���UTF8�ַ���ΪNULL������˳�
		return ans;

	wchar_t * lpUnicodeStr = NULL;
	int nRetLen = 0;

	nRetLen = ::MultiByteToWideChar(CP_UTF8, 0, (char *)src, -1, NULL, NULL);  //��ȡת����Unicode���������Ҫ���ַ��ռ䳤��
	lpUnicodeStr = new WCHAR[nRetLen + 1];  //ΪUnicode�ַ����ռ�
	nRetLen = ::MultiByteToWideChar(CP_UTF8, 0, (char *)src, -1, lpUnicodeStr, nRetLen);  //ת����Unicode����
	if (!nRetLen)  //ת��ʧ��������˳�
	{
		delete[] lpUnicodeStr;
		return ans;
	}

	nRetLen = ::WideCharToMultiByte(CP_ACP, 0, lpUnicodeStr, -1, NULL, NULL, NULL, NULL);  //��ȡת����GBK���������Ҫ���ַ��ռ䳤��
	char* p = new char[nRetLen + 1];
	nRetLen = ::WideCharToMultiByte(CP_ACP, 0, lpUnicodeStr, -1, (char *)p, nRetLen, NULL, NULL);  //ת����GBK����
	ans.assign(p);

	delete[] p;
	delete[]lpUnicodeStr;

	return ans;

#endif

#ifdef PLATFORM_LINUX
    std::string ans;
    int len = strlen(src) * 2 + 1;
    char *dst = (char *)malloc(len);
    if (dst == NULL)
    {
        return ans;
    }
    memset(dst, 0, len);
    const char *in = src;
    char *out = dst;
    size_t len_in = strlen(src);
    size_t len_out = len;

    iconv_t cd = iconv_open("GBK", "UTF-8");
    if ((iconv_t)-1 == cd)
    {
        printf("init iconv_t failed\n");
        free(dst);
        return ans;
    }
    int n = iconv(cd, &in, &len_in, &out, &len_out);
    if (n < 0)
    {
        printf("iconv failed\n");
    }
    else
    {
        ans = dst;
    }
    free(dst);
    iconv_close(cd);
    return ans;
#endif
}
void db_session::handler_sd_get_band_bank_info(SD_GetBankCardInfo* msg)
{
	int game_id = server_id_;
	int guid = msg->guid();
	char buff[1024] = { 0 };
	sprintf(buff, "select guid,account,card_num,user_name,bank_name,bank_addr,bank_code from t_player_bank_info where guid=%d;",guid);

	db_mgr::instance()->get_db_connection_game().execute_query<BankCardInfo>([guid, game_id](BankCardInfo* data) {
		DS_GetBankCardInfo ret_msg;
		BankCardInfo* ppp = ret_msg.mutable_info();
		ppp->set_guid(0);
		if (data)
		{
			ppp->CopyFrom(*data);
		}
		db_session_mgr::instance()->post_msg_to_game_pb(game_id, &ret_msg);
	}, nullptr,buff);
}
void db_session::handler_sd_band_bank_card(SD_BindBankCard* msg)
{
	int game_id = server_id_;
	int guid = msg->info().guid();
	std::string account = msg->info().account();
	std::string card_num = msg->info().card_num();
	std::string user_name = msg->info().user_name();
	std::string bank_name = msg->info().bank_name();
	std::string bank_addr = msg->info().bank_addr();
	std::string bank_code = msg->info().bank_code();

	if (!IsNum(card_num) || card_num.empty() || user_name.empty() || bank_name.empty() || bank_addr.empty() ||
		card_num.size() > 50 || user_name.size() > 30 || bank_name.size() > 50 || bank_addr.size() > 100  || bank_code.size() > 100)
	{
		DS_BindBankCard ret_msg;
		ret_msg.set_guid(guid);
		ret_msg.set_result(2);
		db_session_mgr::instance()->post_msg_to_game_pb(game_id, &ret_msg);
		return;
	}
	char buff[1024] = { 0 };
	sprintf(buff, "REPLACE INTO t_player_bank_info SET guid=%d, account='%s', card_num='%s', user_name='%s', bank_name='%s',bank_addr='%s', bank_code='%s';", 
		guid, account.c_str(), card_num.c_str(), user_name.c_str(), bank_name.c_str(), bank_addr.c_str(),bank_code.c_str());
	db_mgr::instance()->get_db_connection_game().execute_update([guid, game_id](int ret) {
		DS_BindBankCard ret_msg;
		ret_msg.set_guid(guid);
		if (ret > 0)
		{
			ret_msg.set_result(1);
		}
		else
		{
			ret_msg.set_result(3);
		}
		db_session_mgr::instance()->post_msg_to_game_pb(game_id, &ret_msg);
	}, buff);
}
void db_session::handler_sd_band_alipay(SD_BandAlipay* msg)
{
    int guid = msg->guid();
    int game_id = server_id_;
    std::string account = msg->alipay_account();
    std::string name = msg->alipay_name();
    std::string start_account = "";
    std::string start_name = "";
    std::string start_account_temp = UTF8ToGBK(account.c_str());
    std::string start_name_temp = UTF8ToGBK(name.c_str());
    
    int bRet = Check_Alipay_Account(start_account_temp.c_str(), start_name_temp.c_str());
    if (bRet != 0)
    {
        Get_StartName(bRet, msg->alipay_account(), msg->alipay_name(), start_account, start_name);
    }
    else
    {
        DS_BandAlipay reply;
        reply.set_guid(guid);
        reply.set_result(GAME_BAND_ALIPAY_CHECK_ERROR);
        db_session_mgr::instance()->post_msg_to_game_pb(game_id, &reply);
        return;
    }

    db_mgr::instance()->get_db_connection_account().execute_query_string([guid, game_id, account, name, start_name, start_account](std::vector<std::string>* data) {
        if (data)
        {
            DS_BandAlipay reply;
            reply.set_guid(guid);
            reply.set_result(GAME_BAND_ALIPAY_REPEAT_BAND);
            db_session_mgr::instance()->post_msg_to_game_pb(game_id, &reply);
        }
        else
        {

            db_mgr::instance()->get_db_connection_account().execute_update_try([guid, game_id, account, name, start_name, start_account](int ret, int err) {
                DS_BandAlipay reply;
                reply.set_guid(guid);
                if (ret > 0 && err == 0)
                {
                    reply.set_alipay_account(start_account.c_str());
                    reply.set_alipay_name(start_name.c_str());
                    reply.set_result(GAME_BAND_ALIPAY_SUCCESS);
                    //��ʱ��
                    db_mgr::instance()->get_db_connection_account().execute_query_string([guid, game_id, account, name, start_name, start_account](std::vector<std::string>* dataA) {
                        if (dataA == NULL)
                        {
                            db_mgr::instance()->get_db_connection_account().execute("UPDATE t_account SET `bang_alipay_time` = current_timestamp WHERE guid = %d;", guid);
                        }
                    }, "select account, password from t_account where  guid = %d and not(bang_alipay_time is NULL);", guid);
                }
                else
                {
                    reply.set_result(GAME_BAND_ALIPAY_DB_ERROR);
                }
                db_session_mgr::instance()->post_msg_to_game_pb(game_id, &reply);            
            }, "UPDATE t_account SET `alipay_account_y` = '%s', alipay_name_y = '%s', alipay_account = '%s', alipay_name = '%s', change_alipay_num = change_alipay_num - 1  WHERE guid = %d;", account.c_str(), name.c_str(), start_account.c_str(), start_name.c_str(), guid);
        }
    }, "select account, password from t_account where alipay_account_y = '%s';", account.c_str());

}

void db_session::handler_ld_offlinechangemoney_query(LD_OfflineChangeMoney * msg)
{
	int playerid = msg->guid();
	std::string content = msg->gmcommand();
	//printf("1111playerid=[%d],gmcommand = [%s]\n", playerid, content.c_str());
	auto L = base_lua_mgr::instance()->get_lua_state();
	lua_tinker::dostring(L, content.c_str());
}
void db_session::handler_sd_changemoney(SD_ChangMoneyReply* msg)
{
    LOG_INFO("handler_sd_changemoney  web[%d] gudi[%d] order_id[%d] type[%d]", msg->web_id(), msg->info().guid(), msg->info().order_id(), msg->info().type_id());
	int web_id = msg->web_id();
	if (msg->info().type_id() == LOG_MONEY_OPT_TYPE_RECHARGE_MONEY)
    {
		db_mgr::instance()->get_db_connection_recharge().execute_update([web_id](int ret) {
			if (ret > 0)
			{
				DF_Reply reply;
				reply.set_web_id(web_id);
				reply.set_result(1);
				db_cfg_net_server::instance()->post_msg_to_cfg_pb(&reply);
				LOG_INFO("UPDATE suc handler_sd_changemoney  web[%d]", web_id);
			}
			else
			{
				LOG_INFO("UPDATE err handler_sd_changemoney  web[%d]", web_id);
			}
		}, "UPDATE t_recharge_order SET `server_status` = '1', before_bank = '%I64d', after_bank = '%I64d' WHERE id = %d;",
			msg->befor_bank(), msg->after_bank(), msg->info().order_id());
    }
    else if (msg->info().type_id() == LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE)
    {
		db_mgr::instance()->get_db_connection_recharge().execute_update([web_id](int ret) {
			if (ret > 0)
			{
				DF_Reply reply;
				reply.set_web_id(web_id);
				reply.set_result(1);
				db_cfg_net_server::instance()->post_msg_to_cfg_pb(&reply);
				LOG_INFO("UPDATE suc handler_sd_changemoney  web[%d]", web_id);
			}
			else
			{
				LOG_INFO("UPDATE err handler_sd_changemoney  web[%d]", web_id);
			}
		}, "UPDATE t_cash SET `status_c` = '1' WHERE order_id = %d;", msg->info().order_id());
    }
}
extern void insert_into_changemoney(FD_ChangMoneyDeal* msg);
void db_session::handler_fd_changemoney(FD_ChangMoneyDeal* msg)
{
    LOG_INFO("handler_fd_changemoney  web[%d] guid[%d] order_id[%d] type[%d]", msg->web_id(), msg->info().guid(), msg->info().order_id(), msg->info().type_id());
    insert_into_changemoney(msg);
}

void db_session::check_blacklist_ip(std::string reg_ip, int guid)
{
	db_mgr::instance()->get_db_connection_game().execute_query_vstring([reg_ip, guid](std::vector<std::vector<std::string>>* data) {
		if (data)
		{
			for (auto& item : *data)
			{
				LOG_INFO("check_blacklist_ip %d,  %s ", guid, item[0].c_str());
				db_mgr::instance()->get_db_connection_game().execute("INSERT INTO t_game_blacklist \
				(guid,game_name,revenue )VALUES (%d, '%s', %d);", guid, item[0].c_str(), 0);
			}
		}
	},"select game_name from t_game_black_ip where ip = '%s';", reg_ip.c_str());
}

void db_session::init_channel()
{
	if (m_vinvite.size() == 0)
	{
		sinvite inivite;
		inivite.pid = 300;
		inivite.uid = 301;
		inivite.str_channel_id = "game_joy_lyylchang";
		m_vinvite.push_back(inivite);

		inivite.pid = 300;
		inivite.uid = 302;
		inivite.str_channel_id = "game_joy_qznn";
		m_vinvite.push_back(inivite);
	}
}

void db_session::handler_ld_LuaCmdPlayerResult(LD_LuaCmdPlayerResult* msg)
{
	auto L = base_lua_mgr::instance()->get_lua_state();
	std::string strtemp = msg->cmd();
	auto pos = strtemp.find("(");
	if (pos == std::string::npos)
	{
		DL_LuaCmdPlayerResult notify;
		notify.set_web_id(msg->web_id());
		notify.set_result(0);
		send_pb(&notify);
		return;
	}

	int login_id = get_server_id();
	std::string cmd = str(boost::format("%d,%d,") % msg->web_id() % login_id);
	cmd = strtemp.substr(0, pos+1) + cmd + strtemp.substr(pos+1, -1);

	lua_tinker::dostring(L, cmd.c_str());
}

void GetServerCfg(int game_id, DBGameConfig* cfg)
{
	 DBGameConfigMgr &config = db_session_mgr::instance()->GetServerCfg();
    for (int i = 0; i < config.pb_cfg_size(); i++)
    {
        auto p = config.pb_cfg(i);
        if (p.game_id() == game_id)
        {
            cfg->CopyFrom(p);
            break;
        }
    }
}

void db_session::handler_sd_server_cfg(SD_ServerConfig* msg)
{
    int server_id = server_id_;
    int game_id = msg->gamer_id();
    DS_ServerConfig nmsg;
    GetServerCfg(game_id, nmsg.mutable_cfg());

    db_session_mgr::instance()->post_msg_to_game_pb(server_id, &nmsg);
    DL_ServerConfig fmsg;
    fmsg.mutable_cfg()->CopyFrom(nmsg.cfg());
    db_session_mgr::instance()->broadcast2login_pb(&fmsg);
}

//void db_session::handler_sd_change_cfg(SD_ChangeGameCfg* msg)
//{
//    int server_id = server_id_;
//    SD_ChangeGameCfg dmsg;
//    dmsg.set_webid(msg->webid());
//    dmsg.set_gamer_id(msg->gamer_id());
//    db_mgr::instance()->get_db_connection_config().execute_query_vstring([server_id, dmsg](std::vector<std::vector<std::string>>* data) {
//        if (data)
//        {
//
//            DBGameConfigMgr &dbgamer_config = db_session_mgr::instance()->GetServerCfg();
//            dbgamer_config.clear_pb_cfg();
//            for (auto& item : *data)
//            {
//                auto dbcfg = dbgamer_config.add_pb_cfg();
//                dbcfg->set_cfg_name(item[0]);
//                dbcfg->set_is_open(boost::lexical_cast<int>(item[1]));
//                dbcfg->set_using_login_validatebox(boost::lexical_cast<int>(item[2]));
//                dbcfg->set_ip(item[3]);
//                dbcfg->set_port(boost::lexical_cast<int>(item[4]));
//                dbcfg->set_game_id(boost::lexical_cast<int>(item[5]));
//                dbcfg->set_first_game_type(boost::lexical_cast<int>(item[6]));
//                dbcfg->set_second_game_type(boost::lexical_cast<int>(item[7]));
//                dbcfg->set_game_name(item[8]);
//                dbcfg->set_game_log(item[9]);
//                dbcfg->set_default_lobby(boost::lexical_cast<int>(item[10]));
//                dbcfg->set_player_limit(boost::lexical_cast<int>(item[11]));
//                dbcfg->set_data_path(item[12]);
//                dbcfg->set_room_list(item[13]);
//                dbcfg->set_room_lua_cfg(item[14]);
//            }
//
//            DS_ChangeGameCfg nmsg;
//            nmsg.set_webid(dmsg.webid());
//            GetServerCfg(dmsg.gamer_id(), nmsg.mutable_cfg());
//            db_session_mgr::instance()->post_msg_to_game_pb(server_id, &nmsg);
//            DL_ServerConfig fmsg;
//            fmsg.mutable_cfg()->CopyFrom(nmsg.cfg());
//            db_session_mgr::instance()->broadcast2login_pb(&fmsg);
//        }
//        else
//        {
//            LOG_ERR("load cfg from db error");
//        }
//    }, "SELECT * FROM t_game_server_cfg;");
//}

void db_session::handler_ld_get_server_cfg(LD_GetServerCfg* msg)
{
    int server_id = server_id_;
    DL_DBGameConfigMgr nmsg;
    nmsg.set_gid(msg->gid());
    DBGameConfigMgr &config = db_session_mgr::instance()->GetServerCfg();
    nmsg.mutable_pb_cfg_mgr()->CopyFrom(config);
    db_session_mgr::instance()->post_msg_to_login_pb(server_id, &nmsg);
}