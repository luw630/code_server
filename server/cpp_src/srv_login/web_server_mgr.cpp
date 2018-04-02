#include "web_server_mgr.h"

WebGmGameServerInfo::WebGmGameServerInfo(int id, int count)
	: WebGm(id)
	, count_(count)
{

}

WebGmGameServerInfo::~WebGmGameServerInfo()
{

}

bool WebGmGameServerInfo::add_info(WebGameServerInfo* info)
{
	msg_.add_info_list()->CopyFrom(*info);
	return msg_.info_list_size() == count_;
}


web_server_mgr::web_server_mgr()
{

}

web_server_mgr::~web_server_mgr()
{

}

void web_server_mgr::addWebGm(WebGm* p)
{
	if (!web_gm_.insert(std::make_pair(p->get_id(), p)).second)
	{
		delete p;
	}
}

void web_server_mgr::removeWebGm(WebGm* p)
{
	web_gm_.erase(p->get_id());
	delete p;
}

WebGm* web_server_mgr::getWebGm(int id)
{
	auto it = web_gm_.find(id);
	if (it != web_gm_.end())
	{
		return it->second;
	}
	return nullptr;
}
