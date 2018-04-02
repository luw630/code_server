#pragma once

#include "base_net_session.h"
#include "base_net_dispatcher.h"
#include "public_msg.pb.h"
#include "server.pb.h"
#include "login_session_mgr.h"

class login_db_session : public base_net_session
{
private:
	base_net_dispatcher_mgr*			dispatcher_manager_;
public:
	login_db_session(boost::asio::io_service& ioservice);
	virtual ~login_db_session();
	virtual bool handler_msg_dispatch(MsgHeader* header);
	virtual bool handler_connect();
	virtual void handler_connect_failed();
	virtual void on_closed();
	void on_dl_verify_account_result(DL_VerifyAccountResult* msg);
	void on_dl_reg_account(DL_RegAccount* msg);
	void on_dl_reg_account2(DL_RegAccount2* msg);
	void on_dl_NewNotice(DL_NewNotice * msg);
	void on_cc_ChangMoney(DL_CC_ChangeMoney * msg);
	void on_dl_doSql(DL_DO_SQL * msg);
    void on_dl_DelMessage(DL_DelMessage * msg);
	void on_dl_AlipayEdit(DL_AlipayEdit* msg);
	void on_dl_reg_phone_query(DL_PhoneQuery* msg);
    void on_dl_server_config(DL_ServerConfig* msg);    
    void on_dl_server_config_mgr(DL_DBGameConfigMgr* msg);
	void on_dl_get_inviter_info(LC_GetInviterInfo* msg);
	void on_DL_LuaCmdPlayerResult(DL_LuaCmdPlayerResult* msg);
	
};
