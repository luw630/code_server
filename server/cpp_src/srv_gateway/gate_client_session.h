#pragma once

#include "base_net_server_session.h"
#include "base_net_dispatcher.h"
#include "public_msg.pb.h"
#include "gate_session_mgr.h"
#include "base_game_log.h"


class gate_client_session : public virtual_session
{
private:
	std::string							ip_;
	std::string							real_ip_;
	int									android_uid_; //渠道ID
	int									android_pid_; //渠道父ID
	unsigned short						port_;

	int									guid_;

	int									game_server_id_;
	int									first_game_type_;
	int									second_game_type_;
	int									private_room_score_type_;

	int									user_data_; // 回复login

	std::string							private_key_;
	time_t								timeout_limit_;
	//time_t								last_msg_time_;

	std::string							account_; // 账号名字
	bool                                m_islogin;

	std::string							tel_; // 手机号
	std::string							sms_no_; // 手机验证码
	time_t								last_sms_time_; // 上次发送时间
	time_t								sms_time_limit_;
	time_t								last_sms_req_time_; // 上次请求时间

	bool								is_send_login_;				// 是否发送登陆消息
	std::string							channel_id_;
	std::string							version_;
public:

	
	gate_client_session(boost::asio::ip::tcp::socket& sock);

	
	virtual ~gate_client_session();

	
	virtual bool handler_msg_dispatch(MsgHeader* header);

	
	virtual bool handler_accept();

	
	virtual void on_closed();

	
	int get_guid() { return guid_; }

	
	void set_guid(int guid) {
        LOG_WARN("set guid old[%d] new[%d]", guid_, guid);
        guid_ = guid; 
    }

	
	int get_game_server_id() { return game_server_id_; }

	
	void set_game_server_id(int server_id) { 
		game_server_id_ = server_id;
	}


	int get_first_game_type() { return first_game_type_; }
	void set_first_game_type(int first_game_type) { first_game_type_ = first_game_type; }

	int get_second_game_type() { return second_game_type_; }
	void set_second_game_type(int second_game_type) { second_game_type_ = second_game_type; }

	int get_private_room_score_type() { return private_room_score_type_; }
	void set_private_room_score_type(int private_room_score_type) { private_room_score_type_ = private_room_score_type; }

	virtual bool tick();

	
	void set_account(const std::string& account) { account_ = account; }

	std::string get_account() { return account_; }

	void set_user_data(int user_data) { user_data_ = user_data; }
	int get_user_data() { return user_data_; }

	void set_login(bool iflag) {
		LOG_WARN("set m_login [%d] guid[%d]", iflag, guid_);
		LOG_WARN("ip[%s] port[%d]", ip_.c_str(), port_);
        LOG_WARN("this address [%d]", this);
		m_islogin = iflag;
	}
	bool get_login() { return m_islogin; }

	
	void set_sms(const std::string& tel, const std::string& sms_no);
	void clear_sms();

	void reset_is_send_login() { is_send_login_ = false; }
public:
	void do_get_sms_http(const std::string& phone);
private:
	bool on_C_RequestPublicKey(MsgHeader* header);
	bool on_CL_RegAccount(MsgHeader* header);
	bool on_CL_Login(MsgHeader* header);
	bool on_CL_LoginBySms(MsgHeader* header);
	bool on_CS_RequestSms(MsgHeader* header);
	bool on_CG_GameServerCfg(MsgHeader* header);
	bool on_CS_ResetAccount(MsgHeader* header);
	bool on_CS_SetNickname(MsgHeader* header);
	bool on_CS_SetPassword(MsgHeader* header);
	bool on_CS_SetPasswordBySms(MsgHeader* header);
	bool on_CS_BankSetPassword(MsgHeader* header);
	bool on_CS_BankChangePassword(MsgHeader* header);
	bool on_CS_BankLogin(MsgHeader* header);
	bool on_CL_GetInviterInfo(MsgHeader* header);
	

	bool check_string(const std::string& str);


};
