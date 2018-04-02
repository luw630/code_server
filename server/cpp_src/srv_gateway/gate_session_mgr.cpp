#include "gate_session_mgr.h"
#include "gate_client_session.h"
#include "gate_login_session.h"
#include "gate_game_session.h"
#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"
#include "gate_server.h"



gate_session_mgr::gate_session_mgr()
	: cur_login_session_(0)
	, first_connect_db_(0)
{
}

gate_session_mgr::~gate_session_mgr()
{
	assert(game_session_.empty());
}



std::shared_ptr<virtual_session> gate_session_mgr::create_session(boost::asio::ip::tcp::socket& socket)
{
	return std::static_pointer_cast<virtual_session>(std::make_shared<gate_client_session>(socket));
}


std::shared_ptr<virtual_session> gate_session_mgr::create_login_session(const std::string& ip, unsigned short port)
{
	auto session = std::make_shared<gate_login_session>(network_server_->get_io_server_pool().get_io_service());
	session->set_ip_port(ip, port);
	return std::static_pointer_cast<virtual_session>(session);
}

std::shared_ptr<virtual_session> gate_session_mgr::create_game_session(const std::string& ip, unsigned short port)
{
	auto session = std::make_shared<gate_game_session>(network_server_->get_io_server_pool().get_io_service());
	session->set_ip_port(ip, port);
	return std::static_pointer_cast<virtual_session>(session);
}

void gate_session_mgr::set_network_server(base_net_server* network_server)
{
	net_work_holder::set_network_server(network_server);

	auto& cfg = static_cast<gateway_server*>(base_server::instance())->get_config();

	for (auto& attr : cfg.login_addr())
	{
		login_session_.push_back(create_login_session(attr.ip(), attr.port()));
	}

	for (auto& attr : cfg.game_addr())
	{
        Add_Game_Server_Session(attr.ip(), attr.port());
	}


}
void gate_session_mgr::Add_Game_Server_Session(std::string ip, int port){
    game_session_.push_back(create_game_session(ip, port));
}

void gate_session_mgr::Add_Login_Server_Session(const std::string& ip, int port)
{
	login_session_.push_back(create_login_session(ip, port));
}
void gate_session_mgr::close_all_session()
{
	net_work_holder::close_all_session();

	for (auto item : login_session_)
		item->close();

	for (auto item : game_session_)
		item->close();

}

void gate_session_mgr::release_all_session()
{
	net_work_holder::release_all_session();

	for (auto item : login_session_)
	{
		item->on_closed();
	}
	login_session_.clear();

	for (auto item : game_session_)
	{
		item->on_closed();
	}
	game_session_.clear();

}

bool gate_session_mgr::tick()
{
	bool ret = net_work_holder::tick();

	for (auto item : login_session_)
	{
		if (!item->tick())
			ret = false;
	}

	for (auto item : game_session_)
	{
		if (!item->tick())
			ret = false;
	}

	if (first_connect_db_ == 1)
	{
		handler_mysql_connected();
		first_connect_db_ = 2;
	}
	on_login_quque();
	return ret;
}
std::shared_ptr<virtual_session> gate_session_mgr::get_client_session(int guid)
{
	auto it = client_session_.find(guid);
	if (it != client_session_.end())
		return it->second;

	return std::shared_ptr<virtual_session>();
}
void gate_session_mgr::add_client_session(std::shared_ptr<virtual_session> session)
{
	//client_session_.insert(std::make_pair(static_cast<gate_client_session*>(session.get())->get_guid(), session));
	client_session_[static_cast<gate_client_session*>(session.get())->get_guid()] = session;
}

void gate_session_mgr::remove_client_session(int guid, int session_id)
{
	auto it = client_session_.find(guid);
	if (it != client_session_.end() && static_cast<gate_client_session*>(it->second.get())->get_id() == session_id)
	{
		client_session_.erase(guid);
	}
}

int gate_session_mgr::find_gameid_by_guid(int guid)
{
    auto it = client_session_.find(guid);
    if (it != client_session_.end())
    {
        auto session = static_cast<gate_client_session*>(it->second.get());
        return session->get_game_server_id();
    }
    else
    {
        return -1;
    }
}

void gate_session_mgr::SendOnLine()
{
    for (auto& player : client_session_)
    {
        GF_PlayerIn nmsg;
        nmsg.set_guid(player.first);
        gate_cfg_net_server::instance()->post_msg_to_cfg_pb(&nmsg);
    }
}
std::shared_ptr<virtual_session> gate_session_mgr::get_login_session()
{
	if (login_session_.empty())
		return std::shared_ptr<virtual_session>();

	int check_time = 0;
	while (check_time != login_session_.size())
	{
		if (cur_login_session_ >= login_session_.size())
			cur_login_session_ = 0;
		std::shared_ptr<virtual_session> cur_session = login_session_[cur_login_session_];
		if (cur_session->is_connect())
		{
			cur_login_session_++;
			return cur_session;
		}
		else
		{
			cur_login_session_++;
			check_time++;
		}
	}
	return std::shared_ptr<virtual_session>();
}

std::shared_ptr<virtual_session> gate_session_mgr::get_game_session(int game_id)
{
	for (auto item : game_session_)
	{
		if (item->get_server_id() == game_id)
			return item;
	}

	return std::shared_ptr<virtual_session>();
}

/*void gate_session_mgr::set_open_game_list(LG_OpenGameList* ls)
{
	open_game_list_.clear();
	for (auto id : ls->game_id_list())
	{
		open_game_list_.insert(id);
	}
}*/

bool gate_session_mgr::in_open_game_list(int id)
{
	return open_game_list_.find(id) != open_game_list_.end();
}

void gate_session_mgr::add_game_id(int game_id)
{
	open_game_list_.insert(game_id);
}

void gate_session_mgr::remove_game_id(int game_id)
{
	open_game_list_.erase(game_id);
}

void gate_session_mgr::set_first_connect_db()
{
	if (first_connect_db_ == 0)
	{
		first_connect_db_ = 1;
	}
}

void gate_session_mgr::handler_mysql_connected()
{
    GL_GetServerCfg msg;

    // 登录时，没有guid，做过特殊处理
    auto session = gate_session_mgr::instance()->get_login_session();
    if (session && session->is_connect())
    {
        gate_session_mgr::instance()->post_msg_to_login_pb(1, &msg);
    }
    else
    {
        LOG_WARN("login server disconnect");
    }
}

void gate_session_mgr::add_CL_RegAccount(int gate_id, const CL_RegAccount& msg)
{
	CL_LoginAll a;
	a.set_type(1);
	a.set_gate_id(gate_id);
	a.mutable_reg()->CopyFrom(msg);
	login_quque_.push_back(a);
}
void gate_session_mgr::add_CL_Login(int gate_id, const CL_Login& msg)
{
	CL_LoginAll a;
	a.set_type(2);
	a.set_gate_id(gate_id);
	a.mutable_login()->CopyFrom(msg);
	login_quque_.push_back(a);

	login_quque_account_.insert(msg.account());
}
void gate_session_mgr::add_CL_LoginBySms(int gate_id, const CL_LoginBySms& msg)
{
	CL_LoginAll a;
	a.set_type(3);
	a.set_gate_id(gate_id);
	a.mutable_sms()->CopyFrom(msg);
	login_quque_.push_back(a);

	login_quque_account_.insert(msg.account());
}
void gate_session_mgr::on_login_quque()
{
	if (login_quque_time_ == 0 || base_game_time_mgr::instance()->get_second_time() - login_quque_time_ >= 1)
	{
		login_quque_time_ = base_game_time_mgr::instance()->get_second_time();

		for (int i = 0; i < 25; i++)
		{
			if (login_quque_.empty())
			{
				break;
			}
			auto& item = login_quque_.front();
			switch (item.type())
			{
			case 1:
				if (item.has_reg())
				{
					auto s = gate_session_mgr::instance()->find_by_id(item.gate_id());
					if (s)
					{
						gate_session_mgr::instance()->post_msg_to_login_pb(item.gate_id(), item.mutable_reg());
						LOG_INFO("send login request 01, imei %s", item.mutable_reg()->imei().c_str());
					}
					else
					{
						LOG_ERR("gate<--->client %d disconnect  when  login_quque_01...",item.gate_id());
					}
				}
				break;
			case 2:
				if (item.has_login())
				{
					auto s = gate_session_mgr::instance()->find_by_id(item.gate_id());
					if (s)
					{
						gate_session_mgr::instance()->post_msg_to_login_pb(item.gate_id(), item.mutable_login());
						LOG_INFO("send login request 02, account %s", item.mutable_reg()->account().c_str());
					}
					else
					{
						LOG_ERR("gate<--->client %d disconnect  when  login_quque_02...", item.gate_id());
					}
					login_quque_account_.erase(item.mutable_login()->account());
				}
				break;
			case 3:
				if (item.has_sms())
				{
					auto s = gate_session_mgr::instance()->find_by_id(item.gate_id());
					if (s)
					{
						gate_session_mgr::instance()->post_msg_to_login_pb(item.gate_id(), item.mutable_sms());
						LOG_INFO("send login request 03, account %s", item.mutable_reg()->account().c_str());
					}
					else
					{
						LOG_ERR("gate<--->client %d disconnect  when  login_quque_03...", item.gate_id());
					}
					login_quque_account_.erase(item.mutable_sms()->account());
				}
				break;
			default:
				{
					   LOG_ERR("on_login_quque   error type %d", item.type());
				}
				break;
			}
			login_quque_.pop_front();
		}
	}
}

bool gate_session_mgr::check_login_quque_account(const std::string& account)
{
	return login_quque_account_.find(account) != login_quque_account_.end();
}
/*
std::shared_ptr<GateCenterSession>& gate_session_mgr::get_gate_center_session()
{
	return gate_center_session_;
}*/