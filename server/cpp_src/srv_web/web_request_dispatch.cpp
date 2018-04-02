#include "web_request_dispatch.h"
#include "client_socket_proto.h"
#include "web_cfg.h"
#include "base_utils_helper.h"
#include <boost/format.hpp>

extern web_cfg g_cfg;
extern std::string s_http_key;
void http_game_server_info(std::string& out)
{
	client_socket_proto sock;
	auto attr = g_cfg.get_login_attr();
	sock.connect(attr.first.c_str(), attr.second);

	WL_RequestGameServerInfo msg;
	sock.send_pb(&msg);
	sock.Flush();

	volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<LW_ResponseGameServerInfo>([&flag, &out](LW_ResponseGameServerInfo* msg) {
			rapidjson::Document document;
			document.SetArray();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			for (auto& item : msg->info_list())
			{
				rapidjson::Value object(rapidjson::kObjectType);
				object.AddMember("cpu", item.cpu(), allocator);
				object.AddMember("memory", item.memory(), allocator);
				object.AddMember("status", item.status(), allocator);
				rapidjson::Value strObject(rapidjson::kStringType);
				strObject.SetString(item.ip().c_str(), allocator);
				object.AddMember("ip", strObject, allocator);
				object.AddMember("port", item.port(), allocator);
				object.AddMember("first_game_type", item.first_game_type(), allocator);
				object.AddMember("second_game_type", item.second_game_type(), allocator);
				object.AddMember("player_online_count", item.player_online_count(), allocator);
				object.AddMember("robot_online_count", item.robot_online_count(), allocator);
				object.AddMember("niuniu_banker_times", item.niuniu_banker_times(), allocator);
				object.AddMember("android_online_count", item.android_online_count(), allocator);
				object.AddMember("ios_online_count", item.ios_online_count(), allocator);
				document.PushBack(object, allocator);
			}

			rapidjson::Value top_object(rapidjson::kObjectType);
			top_object.AddMember("android_online_top", msg->android_online_top(), allocator);
			top_object.AddMember("ios_online_top", msg->ios_online_top(), allocator);
			document.PushBack(top_object, allocator);
			
			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);


			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}
	}
	
	sock.Destroy();
}

char * utf82gbk(char* strutf)
{
    //utf-8转为Unicode
    int size = MultiByteToWideChar(CP_UTF8, 0, strutf, -1, NULL, 0);
    WCHAR   *strUnicode = new   WCHAR[size];
    MultiByteToWideChar(CP_UTF8, 0, strutf, -1, strUnicode, size);

    //Unicode转换成UTF-8;
    int i = WideCharToMultiByte(CP_ACP, 0, strUnicode, -1, NULL, 0, NULL, NULL);
    char   *strGBK = new   char[i];
    WideCharToMultiByte(CP_ACP, 0, strUnicode, -1, strGBK, i, NULL, NULL);
    return strGBK;
}
void RetOut(int iRet, std::string & out){
    rapidjson::Document document;
    document.SetObject();
    rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
    document.AddMember("result", iRet, allocator);
    rapidjson::StringBuffer buffer;
    rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
    document.Accept(writer);
    out = buffer.GetString();
}

#define endStr "JudgeParamEnd"
#define checkJsonMember(ABC,...)  checkJsonMemberS(ABC,1,__VA_ARGS__,endStr)
#define LOG_ERR printf
bool checkJsonMemberS(rapidjson::Document& document,int start, ...){
    va_list args;
    char * lp = NULL;
    char * lp_type = NULL;
    va_start(args, start);
    do
    {
        lp = va_arg(args, char *);
        if (lp != NULL){
            if (strcmp(lp, endStr) == 0){
                break;
            }
            if (!document.HasMember(lp)){
                LOG_ERR("param [%s] not find", lp);
                return true;
            }
        }
        lp_type = va_arg(args, char *);
        if (lp_type != NULL){
            if (strcmp(lp_type, endStr) == 0){
                break;
            }
            if (strcmp(lp_type, "int") == 0){
                if (!document[lp].IsInt()){
                    return true;
                }
            }
            if (strcmp(lp_type, "int64") == 0){
                if (!document[lp].IsInt64()){
                    return true;
                }
            }
            else if (strcmp(lp_type, "string") == 0){
                if (!document[lp].IsString()){
                    return true;
                }
            }
            else if (strcmp(lp_type, "bool") == 0){
                if (!document[lp].IsBool()){
                    return true;
                }
            }
            else if (strcmp(lp_type, "float") == 0){
                if (!document[lp].IsFloat()){
                    return true;
                }
            }
        }
    } while (true);
    va_end(args);
    return false;
}
void http_gm_command(rapidjson::Document& document, std::string& out){
    client_socket_proto sock;
    auto attr = g_cfg.get_login_attr();
    if (sock.connect(attr.first.c_str(), attr.second)){
        if (checkJsonMember(document, "Command","string","Data","string","sign","string")){
            RetOut(GMmessageRetCode::GMmessageRetCode_GmParamMiss, out);
            return;
        }

        WL_GMMessage msg;
        msg.set_gmcommand(document["Command"].GetString());
        msg.set_data(document["Data"].GetString());


        std::string stmpA = "";
        std::string stmpB = "";
        std::string stmpC = "";
        stmpA = boost::str(boost::format("Command=%1%&Data=%2%%3%") % msg.gmcommand() % msg.data().c_str() % s_http_key.c_str());
		stmpC = crypto_manager::md5(stmpA).c_str();
        stmpB = document["sign"].GetString();
		if (stmpC != stmpB)
        {
            out = "{ \"result\" : 0 }";
            return;
        }

        sock.send_pb(&msg);
        sock.Flush();

        volatile bool flag = true;
		DWORD cur_time = GetTickCount();
		while (flag && GetTickCount() - cur_time < 20000)
		{
			if (sock.recv_msg<LW_GMMessage>([&flag, &out](LW_GMMessage* msg) {
				RetOut(msg->result(), out);
				flag = false;
				return true;
			}))
			{
				Sleep(1);
			}
		}
		
        sock.Destroy();
    }
    else {
        RetOut(GMmessageRetCode::GMmessageRetCode_SocketConnectFail, out);
        return;
    }
}

void http_cash_false(rapidjson::Document& document, std::string& out)
{
	client_socket_proto sock;
	auto attr = g_cfg.get_cfg_attr();
	sock.connect(attr.first.c_str(), attr.second);
	if (!document.HasMember("serial_order_no") || !document["serial_order_no"].IsInt())
	{
		out = "{ \"result\" : 0 }";
		return;
	}


	if (!document.HasMember("sign") || !document["sign"].IsString())
	{
		out = "{ \"result\" : 0 }";
		return;
	}

	WF_Cash_false msg;
	msg.set_order_id(document["serial_order_no"].GetInt());
	msg.set_reason(document["reason"].GetInt());


	std::string stmpA = "";
	std::string stmpB = "";
	std::string stmpC = "";
	stmpA = boost::str(boost::format("serial_order_no=%1%%2%") % msg.order_id() % s_http_key.c_str());
	stmpC = crypto_manager::md5(stmpA).c_str();
	stmpB = document["sign"].GetString();
	if (stmpC != stmpB)
	{
		out = "{ \"result\" : 0 }";
		return;
	}
	sock.send_pb(&msg);
	sock.Flush();

	volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<FW_Result>([&flag, &out](FW_Result* msg) {

			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}
	}

	sock.Destroy();
}
void http_recharge(rapidjson::Document& document, std::string& out)
{
    client_socket_proto sock;
    auto attr = g_cfg.get_cfg_attr();
    sock.connect(attr.first.c_str(), attr.second);
    if (!document.HasMember("serial_order_no") || !document["serial_order_no"].IsInt())
    {
        out = "{ \"result\" : 0 }";
		printf("http_recharge  serial_order_no err");
        return;
    }


    if (!document.HasMember("sign") || !document["sign"].IsString())
    {
        out = "{ \"result\" : 0 }";
		printf("http_recharge  sign err");
        return;
    }

    WF_Recharge msg;
    msg.set_order_id(document["serial_order_no"].GetInt());


    std::string stmpA = "";
    std::string stmpB = "";
    std::string stmpC = "";
    stmpA = boost::str(boost::format("serial_order_no=%1%%2%") % msg.order_id() % s_http_key.c_str());
	stmpC = crypto_manager::md5(stmpA).c_str();
    stmpB = document["sign"].GetString();
    if (stmpC != stmpB)
    {
        out = "{ \"result\" : 0 }";
		printf("http_recharge  stmpC != stmpB err");
        return;
    }
    sock.send_pb(&msg);
    sock.Flush();

    volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
        if (sock.recv_msg<FW_Result>([&flag, &out](FW_Result* msg) {
			
			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}
	}
	
    sock.Destroy();
}

void http_change_tax(rapidjson::Document& document, std::string& out)
{
    client_socket_proto sock;
    auto attr = g_cfg.get_login_attr();
    sock.connect(attr.first.c_str(), attr.second);
    if (!document.HasMember("id") || !document["id"].IsInt())
    {
        out = "{ \"result\" : 0 }";
        return;
    }
    if (!document.HasMember("tax") || !document["tax"].IsInt())
    {
        out = "{ \"result\" : 0 }";
        return;
    }

    if (!document.HasMember("is_enable") || !document["is_enable"].IsInt())
    {
        out = "{ \"result\" : 0 }";
        return;
    }

    if (!document.HasMember("is_show") || !document["is_show"].IsInt())
    {
        out = "{ \"result\" : 0 }";
        return;
    }


    WL_ChangeTax msg;
    msg.set_id(document["id"].GetInt());
    msg.set_tax(document["tax"].GetInt());
    msg.set_is_show(document["is_show"].GetInt());
    msg.set_is_enable(document["is_enable"].GetInt());
    sock.send_pb(&msg);
    sock.Flush();

    volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<LW_ChangeTax>([&flag, &out](LW_ChangeTax* msg) {
			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}
	}
    sock.Destroy();
}

void http_change_robot_cfg(rapidjson::Document& document, std::string& out)
{
	client_socket_proto sock;
	auto attr = g_cfg.get_cfg_attr();
	sock.connect(attr.first.c_str(), attr.second, false);
	if (!document.HasMember("cfg_param") || !document["cfg_param"].IsString())
	{
		out = "{ \"result\" : 0 }";
		return;
	}
	if (!document.HasMember("game_id") || !document["game_id"].IsInt())
	{
		out = "{ \"result\" : 0 }";
		return;
	}

	WF_ChangeRobotCfg msg;
	msg.set_cfg_param(document["cfg_param"].GetString());
	msg.set_game_id(document["game_id"].GetInt());
	sock.send_pb(&msg);
	sock.Flush();

	volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<FW_ChangeRobotCfg>([&flag, &out](FW_ChangeRobotCfg* msg) {

			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}
	}

	sock.Destroy();
}
void http_change_game_cfg(rapidjson::Document& document, std::string& out)
{
    client_socket_proto sock;
    auto attr = g_cfg.get_cfg_attr();
    sock.connect(attr.first.c_str(), attr.second, false);
    if (!document.HasMember("id") || !document["id"].IsInt())
    {
        out = "{ \"result\" : 0 }";
        return;
    }
    if (!document.HasMember("sign") || !document["sign"].IsString())
    {
        out = "{ \"result\" : 0 }";
        return;
    }

    WF_ChangeGameCfg msg;
    msg.set_id(document["id"].GetInt());


    //校验
    std::string stmpA = "";
    std::string stmpB = "";
    std::string stmpC = "";
    stmpA = boost::str(boost::format("id=%1%%2%") % msg.id() % s_http_key.c_str());
	stmpC = crypto_manager::md5(stmpA).c_str();
    stmpB = document["sign"].GetString();
    if (stmpC != stmpB)
    {
        out = "{ \"result\" : 0 }";
        return;
    }

    sock.send_pb(&msg);
    sock.Flush();

    volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<FW_ChangeGameCfg>([&flag, &out](FW_ChangeGameCfg* msg) {

			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}
	}
    
    sock.Destroy();
}

void http_change_money(rapidjson::Document& document, std::string& out)
{
	client_socket_proto sock;
	auto attr = g_cfg.get_login_attr();
	sock.connect(attr.first.c_str(), attr.second);
	if (!document.HasMember("guid") || !document["guid"].IsInt())
	{
		out = "{ \"result\" : 0 }";
		return;
	}

	if (!document.HasMember("GmCommand") || !document["GmCommand"].IsString())
	{
		out = "{ \"result\" : 0 }";
		return;
    }

    if (!document.HasMember("sign") || !document["sign"].IsString())
    {
        out = "{ \"result\" : 0 }";
        return;
    }
	WL_ChangeMoney msg;
	msg.set_guid(document["guid"].GetInt());
	msg.set_gmcommand(document["GmCommand"].GetString());

    std::string stmpA = "";
    std::string stmpB = "";
    std::string stmpC = "";
    stmpA = boost::str(boost::format("guid=%1%&GmCommand=%2%%3%") % msg.guid() % msg.gmcommand().c_str() % s_http_key.c_str());
	stmpC = crypto_manager::md5(stmpA).c_str();
    stmpB = document["sign"].GetString();
    if (stmpC != stmpB)
    {
        out = "{ \"result\" : 0 }";
        return;
    }
	sock.send_pb(&msg);
	sock.Flush();

	volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<LW_ChangeMoney>([&flag, &out](LW_ChangeMoney* msg) {

			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}

	}
	sock.Destroy();
}

void http_broadcast_client_update(rapidjson::Document& document, std::string& out)
{
	client_socket_proto sock;
	auto attr = g_cfg.get_login_attr();
	sock.connect(attr.first.c_str(), attr.second);

	if (!document.HasMember("GmCommand") || !document["GmCommand"].IsString())
	{
		out = "{ \"result\" : 0 }";
		return;
	}

	WL_BroadcastClientUpdate msg;
	msg.set_gmcommand(document["GmCommand"].GetString());
	sock.send_pb(&msg);
	sock.Flush();

	volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<LW_ClientUpdateResult>([&flag, &out](LW_ClientUpdateResult* msg) {

			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}

	}
	sock.Destroy();
}

void http_lua_cmd_player_res(rapidjson::Document& document, std::string& out)
{
	client_socket_proto sock;
	auto attr = g_cfg.get_login_attr();
	sock.connect(attr.first.c_str(), attr.second);
	if (!document.HasMember("guid") || !document["guid"].IsInt())
	{
		out = "{ \"result\" : 0 }";
		return;
	}

	if (!document.HasMember("cmd") || !document["cmd"].IsString())
	{
		out = "{ \"result\" : 0 }";
		return;
	}

	WL_LuaCmdPlayerResult msg;
	msg.set_guid(document["guid"].GetInt());
	msg.set_cmd(document["cmd"].GetString());
	sock.send_pb(&msg);
	sock.Flush();

	volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<LW_LuaCmdPlayerResult>([&flag, &out](LW_LuaCmdPlayerResult* msg) {

			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}

	}
	sock.Destroy();
}

void http_lua_game_cmd(rapidjson::Document& document, std::string& out)
{
	client_socket_proto sock;
	auto attr = g_cfg.get_login_attr();
	sock.connect(attr.first.c_str(), attr.second);

	if (!document.HasMember("gameid") || !document["gameid"].IsInt())
	{
		out = "{ \"result\" : 0 }";
		printf("gameid nil");
		return;
	}

	if (!document.HasMember("cmd") || !document["cmd"].IsString())
	{
		out = "{ \"result\" : 0 }";
		printf("cmd nil");
		return;
	}

	if (!document.HasMember("param") || !document["param"].IsString())
	{
		out = "{ \"result\" : 0 }";
		printf("param nil");
		return;
	}

	WL_LuaGameCmd msg;
	msg.set_gameid(document["gameid"].GetInt());
	msg.set_cmd(document["cmd"].GetString());
	msg.set_param(document["param"].GetString());
	sock.send_pb(&msg);
	sock.Flush();

	volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<LW_LuaGameCmd>([&flag, &out](LW_LuaGameCmd* msg) {

			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);
			rapidjson::Value strObject(rapidjson::kStringType);
			strObject.SetString(msg->param().c_str(), allocator);
			document.AddMember("param", strObject, allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}

	}
	sock.Destroy();
}

void http_lua_cmd_query_maintain(rapidjson::Document& document, std::string& out)
{
	client_socket_proto sock;
	auto attr = g_cfg.get_cfg_attr();
	sock.connect(attr.first.c_str(), attr.second);


	if (!document.HasMember("id_index") || !document["id_index"].IsInt())
	{
		out = "{ \"result\" : 0 }";
		return;
	}

	if (!document.HasMember("sign") || !document["sign"].IsString())
	{
		out = "{ \"result\" : 0 }";
		return;
	}

	WS_MaintainUpdate msg;
	msg.set_id_index(document["id_index"].GetInt());

	std::string stmpA = "";
	std::string stmpB = "";
	std::string stmpC = "";
	stmpA = boost::str(boost::format("id_index=%1%%2%") % msg.id_index() % s_http_key.c_str());
	stmpC = crypto_manager::md5(stmpA).c_str();
	stmpB = document["sign"].GetString();
	if (stmpC != stmpB)
	{
		out = "{ \"result\" : 0 }";
		return;
	}

	sock.send_pb(&msg);
	sock.Flush();

	volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<SW_MaintainResult>([&flag, &out](SW_MaintainResult* msg) {

			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}

	}
	sock.Destroy();
}



void http_save_players_info_to_mysql(rapidjson::Document& document, std::string& out)
{
	client_socket_proto sock;
	auto attr = g_cfg.get_cfg_attr();
	sock.connect(attr.first.c_str(), attr.second);


	WF_SavePlayersInfoToMySQL msg;
	
	sock.send_pb(&msg);
	sock.Flush();

	volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<FW_SavePlayersInfoToMySQL>([&flag, &out](FW_SavePlayersInfoToMySQL* msg) {

			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->suc(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}

	}
	sock.Destroy();
}