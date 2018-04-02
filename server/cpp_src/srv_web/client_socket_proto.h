#pragma once

#include <functional>
#include "client_socket.h"
#include "server.pb.h"
#include "public_enum.pb.h"

#pragma pack(1)
struct MsgHeaderT
{
	unsigned short							len;		
	unsigned short							id;			
};
#pragma pack()


class client_socket_proto : public client_socket
{
public:
	bool connect(const char* ip, int port, bool bRet = true)
	{
		if (Create(ip, port) && bRet)
		{
			S_Connect msg;
			msg.set_type(ServerSessionFromWeb);
			return send_pb(&msg);
		}
		return false;
	}

	template<typename T>
	bool send_pb(T* pb)
	{
		std::string str = pb->SerializeAsString();

		MsgHeaderT msg;
		msg.id = T::ID;
		msg.len = sizeof(MsgHeaderT) + str.size();

		if (!SendMsg(&msg, sizeof(MsgHeaderT)))
			return false;

		return str.empty() || SendMsg(const_cast<char*>(str.c_str()), str.size());
	}

	template<typename T>
	bool recv_msg(const std::function<bool(T*)>& func)
	{
		if (!Check()) {
			return false;
		}

		while (true)
		{
			char buffer[_MAX_MSGSIZE] = { 0 };
			int nSize = sizeof(buffer);
			char* pbufMsg = buffer;
			if (!ReceiveMsg(pbufMsg, nSize)) {
				break;
			}

			MsgHeaderT* header = (MsgHeaderT*)pbufMsg;
			T msg;
			if (header->len > sizeof(MsgHeaderT) && !msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeaderT)))
			{
				printf("msg error, id=%d", header->id);
				return false;
			}

			if (!func(&msg))
			{
				return false;
			}
		}

		return true;
	}
};
