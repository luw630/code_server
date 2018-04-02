#pragma once

#include "base_net_server_session.h"
#include "base_net_dispatcher.h"
#include "public_msg.pb.h"
#include "public_enum.pb.h"
#include "server.pb.h"

class cfg_session : public virtual_session
{
private:
	base_net_dispatcher_mgr*			dispatcher_manager_;
	std::string							ip_;
	unsigned short						port_;
	int									type_;
	int									server_id_;
public:
	int get_type() {
		return type_;
	}
	void get_login_config(int session_id, int login_id);
	void get_game_config(int session_id, int game_id);
	void get_gate_config(int session_id, int gate_id);
	void get_client_channel_config(int session_id, int gate_id);
	void get_db_config(int session_id, int db_id);
	void update_gate_config(int session_id, int gate_id, int game_id);
	void update_gate_login_config(int session_id, int gate_id, int login_id);
	void update_game_login_config(int session_id, int game_id, int login_id);
	void update_game_db_config(int session_id, int game_id, int db_id);
	void update_login_db_config(int session_id, int login_id, int db_id);
	cfg_session(boost::asio::ip::tcp::socket& sock);
	virtual ~cfg_session();
	virtual bool handler_msg_dispatch(MsgHeader* header);
	virtual bool handler_accept();
	virtual void on_closed();
	virtual int get_server_id() { return server_id_; }
	void set_server_id(int server_id) { server_id_ = server_id; }
	void on_S_RequestServerConfig(S_RequestServerConfig* msg);
	void on_S_Connect(S_Connect* msg);
	void on_S_RequestUpdateGameServerConfig(S_RequestUpdateGameServerConfig* msg);
	void on_S_RequestUpdateLoginServerConfigByGate(S_RequestUpdateLoginServerConfigByGate* msg);
	void on_S_RequestUpdateLoginServerConfigByGame(S_RequestUpdateLoginServerConfigByGame* msg);
	void on_S_RequestUpdateDBServerConfigByGame(S_RequestUpdateDBServerConfigByGame* msg);
	void on_S_RequestUpdateDBServerConfigByLogin(S_RequestUpdateDBServerConfigByLogin* msg);
    void on_WF_ChangeGameCfg(WF_ChangeGameCfg* msg);
	void on_WF_ChangeRobotCfg(WF_ChangeRobotCfg* msg);
    void on_WF_GetCfg(WF_GetCfg* msg);
    void on_SF_ChangeGameCfg(SF_ChangeGameCfg* msg);
	void on_ReadMaintainSwitch(WS_MaintainUpdate* msg);
	//void on_RequestMaintainSwitchConfig(int id_index); 
	void on_RequestMaintainSwitchConfig(int session_id, int game_id, int id_index);
	void on_GF_PlayerOut(GF_PlayerOut* msg);
    void on_GF_PlayerIn(GF_PlayerIn* msg);
    void on_WF_Recharge(WF_Recharge *msg);
	void on_WF_Cash_false(WF_Cash_false *msg);
    void on_DF_Reply(DF_Reply *msg); 
    void on_DF_ChangMoney(DF_ChangMoney *msg);
    void on_FS_ChangMoneyDeal(FS_ChangMoneyDeal *msg);
	void on_SS_JoinPrivateRoom(SS_JoinPrivateRoom* msg);
	void on_GF_SavePlayerInfo(GF_SavePlayerInfo* msg);
	void on_GF_GetPlayerInfo(GF_GetPlayerInfo* msg);
	void on_DF_SavePlayerInfo(DF_SavePlayerInfo* msg);
	void on_DF_GetPlayerInfo(DF_GetPlayerInfo* msg);
	void on_WF_SavePlayersInfoToMySQL(WF_SavePlayersInfoToMySQL* msg);

};
