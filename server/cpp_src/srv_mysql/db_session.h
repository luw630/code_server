#pragma once

#include "base_net_server_session.h"
#include "base_net_dispatcher.h"
#include "public_msg.pb.h"
#include "server.pb.h"

typedef struct SINVITE
{
	int pid;
	int uid;
	std::string str_channel_id;
}sinvite;

class db_session : public virtual_session
{
private:
	base_net_dispatcher_mgr*			dispatcher_manager_;
	std::string							ip_;
	unsigned short						port_;
	int									type_;
	int									server_id_;
	std::vector<sinvite>			m_vinvite;
public:
	db_session(boost::asio::ip::tcp::socket& sock);
	virtual ~db_session();
	virtual bool handler_msg_dispatch(MsgHeader* header);
	virtual bool handler_accept();
	virtual void on_closed();
	virtual int get_server_id() { return server_id_; }
	void set_server_id(int server_id) { server_id_ = server_id; }
public:
	void handler_sd_set_password(SD_SetPassword* msg);
	void handler_sd_set_password_by_sms(SD_SetPasswordBySms* msg);
	void handler_sd_set_nickname(SD_SetNickname* msg);
	void handler_sd_update_earnings(SD_UpdateEarnings* msg);
	void handler_ld_re_add_player_money(LD_AddMoney* msg);
	void handler_sd_band_alipay(SD_BandAlipay* msg);
	void handler_sd_band_bank_card(SD_BindBankCard* msg);
	void handler_sd_get_band_bank_info(SD_GetBankCardInfo* msg);
	void handler_sd_server_cfg(SD_ServerConfig* msg);
	void handler_ld_phone_query(LD_PhoneQuery* msg);
	void handler_ld_offlinechangemoney_query(LD_OfflineChangeMoney * msg);
	void handler_ld_get_server_cfg(LD_GetServerCfg* msg);
	void on_s_connect(S_Connect* msg);
	void handler_ld_verify_account(LD_VerifyAccount* msg);
	void handler_ld_reg_account(LD_RegAccount* msg);
	void reg_channel_detailed(int android_uid, int android_pid, int guid, std::string imei, std::string phone, std::string ip, std::string str_channel_id);
	void reg_channel_invite( int guid, std::string phone, std::string ip);
	void handler_ld_sms_login(LD_SmsLogin* msg);
	void handler_sd_reset_account(SD_ResetAccount* msg);
	void handler_ld_get_inviter_info(CL_GetInviterInfo* msg);
	void handler_ld_LuaCmdPlayerResult(LD_LuaCmdPlayerResult* msg);
    void handler_sd_changemoney(SD_ChangMoneyReply* msg); 
    void handler_fd_changemoney(FD_ChangMoneyDeal* msg);
	void check_blacklist_ip(std::string reg_ip,int guid);
	void init_channel();
};
