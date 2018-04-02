#pragma once

#include "Singleton.h"
#include "server.pb.h"

class WebGm
{
protected:
	int								id_;
public:
	WebGm(int id) : id_(id) {}
	virtual ~WebGm() {}

	virtual int get_id() { return id_; }

};

class WebGmGameServerInfo : public WebGm
{
private:
	int								count_;
	LW_ResponseGameServerInfo		msg_;
public:
	WebGmGameServerInfo(int id, int count);
	virtual ~WebGmGameServerInfo();

	bool add_info(WebGameServerInfo* info);

	LW_ResponseGameServerInfo* get_msg() { return &msg_; }

};

class web_server_mgr : public TSingleton<web_server_mgr>
{
private:
	std::map<int, WebGm*>			web_gm_;
public:
	web_server_mgr();

	~web_server_mgr();

	void addWebGm(WebGm* p);

	void removeWebGm(WebGm* p);

	WebGm* getWebGm(int id);


};
