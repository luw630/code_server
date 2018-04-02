#pragma once

#include "base_net_server_session.h"
#include "base_net_dispatcher.h"
#include "public_msg.pb.h"
#include "server.pb.h"
#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"
#include "stdarg.h" 
#define endStr "JudgeParamEnd"
#define checkJsonMember(ABC,...)  login_session::checkJsonMemberT(ABC,1,__VA_ARGS__,endStr)

class login_session : public virtual_session
{
private:
	struct stCostBankMoeny
	{
		std::string m_data;
		std::function<void(int  retCode, int oldmoeny, int newmoney, std::string)> func;
	};
	struct stDoSql
	{
		std::string m_data;
		std::function<void(int  retCode, std::string retData, std::string stData)> func;
	};
	std::map<std::string, stCostBankMoeny > m_mapCostBankFunc;
	std::map<std::string, stDoSql > m_mapDoSql;
	base_net_dispatcher_mgr*			dispatcher_manager_;
	std::string							ip_;
	unsigned short						port_;
	int									type_;
	int									server_id_;
public:
	login_session(boost::asio::ip::tcp::socket& sock);
	virtual ~login_session();
	virtual bool handler_msg_dispatch(MsgHeader* header);
	virtual bool handler_accept();
	virtual void on_closed();
	virtual int get_server_id() { return server_id_; }
	void set_server_id(int server_id) { server_id_ = server_id; }
public:
	void on_s_connect(S_Connect* msg);
	void on_S_UpdateGamePlayerCount(S_UpdateGamePlayerCount* msg);
	void on_s_logout(S_Logout* msg);
	void on_cl_login(int session_id, CL_Login* msg);
	void on_cl_reg_account(int session_id, CL_RegAccount* msg);
	void on_cl_login_by_sms(int session_id, CL_LoginBySms* msg);
	void on_L_KickClient(L_KickClient* msg);
	void on_ss_change_game(SS_ChangeGame* msg);
	void on_SL_ChangeGameResult(SL_ChangeGameResult* msg);
	void on_cs_request_sms(CS_RequestSms* msg);
	void handler_sd_bank_transfer(SD_BankTransfer* msg);
	void handler_sd_bank_transfer_by_guid(S_BankTransferByGuid* msg);
	void on_cs_chat_world(int session_id, CS_ChatWorld* msg);
	void on_sc_chat_private(SC_ChatPrivate* msg);
	void on_gl_broadcast_new_notice(LS_NewNotice* msg);
	void on_gsMaintainSwitch(WS_MaintainUpdate* msg);
	void on_wl_request_game_server_info(WL_RequestGameServerInfo* msg);
	void on_sl_web_game_server_info(SL_WebGameServerInfo* msg);
    void on_wl_request_GMMessage(WL_GMMessage * msg);
    static void player_is_online(int guid, const std::function<void( int  gateid,  int sessionid, std::string)>& func);
    void on_gl_NewNotice(GL_NewNotice * msg);
    static void Ret_GMMessage(int retCode, int retID);
    void UpdateFeedBack(rapidjson::Document &document);
    static bool checkJsonMemberT(rapidjson::Document &document, int start, ...);
    void on_wl_request_change_tax(WL_ChangeTax* msg);
    void on_sl_change_tax_reply(SL_ChangeTax* msg);
	void on_wl_request_gm_change_money(WL_ChangeMoney *msg);
	void on_WL_LuaCmdPlayerResult(WL_LuaCmdPlayerResult* msg);
	void on_WL_LuaGameCmd(WL_LuaGameCmd* msg);
	void on_SL_LuaCmdPlayerResult(SL_LuaCmdPlayerResult* msg);
    void on_SL_AddMoney(SL_AddMoney* msg);
	void on_SL_LuaGameCmd(SL_LuaGameCmd* msg);
	
    void on_gl_get_server_cfg(int session_id, GL_GetServerCfg* msg);
	void on_cl_get_server_cfg(int session_id, CL_GetInviterInfo* msg);
	void on_wl_broadcast_gameserver_cmd(WL_BroadcastClientUpdate *msg);
	bool cost_player_bank_money(std::string keyid, int guid, int money, std::string strData, std::function<void(int  retCode, int oldmoeny, int newmoney, std::string)> func);
	void create_do_Sql(std::string  keyid, std::string database, std::string strSql, std::string strData, std::function<void(int  retCode, std::string retData, std::string stData)>);
	void on_SL_AT_ChangeMoney(SL_CC_ChangeMoney* msg);
	void on_sl_FreezeAccount(SL_FreezeAccount * msg);
	void on_DB_Request(DL_CC_ChangeMoney * msg);
	void on_do_SqlReQuest(DL_DO_SQL * msg);
	void on_AT_PL_ChangeMoney(AgentsTransferData stData);
	void EditAliPay(rapidjson::Document &document);
};