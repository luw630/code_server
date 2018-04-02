#include "game_client_session.h"
#include "base_game_log.h"
#include "xn_test_mgr.h"
#include "xn_test_lua_mgr.h"

game_client_session::game_client_session(boost::asio::io_service& ioservice)
	: NetworkConnectSession(ioservice)
	, server_id_(0)
	, dispatcher_manager_(nullptr)
	, deta_(0)
	, oldtime_(0)
{
}

game_client_session::~game_client_session()
{
}

bool game_client_session::on_dispatch(MsgHeader* header)
{
	if (nullptr == dispatcher_manager_)
	{
		LOG_ERR("dispatcher manager is null");
		return false;
	}

	auto dispatcher = dispatcher_manager_->query_dispatcher(header->id);
	if (nullptr == dispatcher)
	{
		LOG_ERR("msg[%d] not registered", header->id);
		return true;
	}

	return dispatcher->parse(this, header);
}

bool game_client_session::on_connect()
{
	LOG_INFO("test connect success ...");

	dispatcher_manager_ = xn_test_mgr::instance()->get_dispatcher_manager();

	C_RequestPublicKey request;
	send_pb(&request);

	return NetworkConnectSession::on_connect();
}

void game_client_session::on_connect_failed()
{
	LOG_INFO("test connect failed ...");

	NetworkConnectSession::on_connect_failed();
}

void game_client_session::on_closed()
{
	LOG_INFO("test disconnect ...");

	lua_tinker::call<void>(xn_test_lua_mgr::instance()->get_lua_state(), "on_session_closed", get_server_id());

	NetworkConnectSession::on_closed();
}

bool game_client_session::tick()
{
	if (deta_ != 0)
	{
		do
		{
			if (oldtime_ == 0)
			{
				time(&oldtime_);
			}
			else
			{
				time_t t;
				time(&t);
				if (t - oldtime_ >= deta_)
				{
					deta_ = 0;
					break;
				}
			}

			return true;
		} while (false);
	}

	if (connect_state_ == CONNECT_STATE_CONNECTED)
	{
		if (socket_.is_open())
		{
			// ³¬Ê±
			if (last_msg_time_ != 0 && GameTimeManager::instance()->get_second_time() - last_msg_time_ > MSG_TIMEOUT_LIMIT)
			{
				LOG_WARN("time out close socket, ip[%s] port[%d]", ip_.c_str(), port_);
				socket_.close();
				return true;
			}

			if (last_heartbeat_ == 0 || GameTimeManager::instance()->get_second_time() - last_heartbeat_ > 7)
			{
				last_heartbeat_ = GameTimeManager::instance()->get_second_time();

				CS_HEARTBEAT msg;
				send_pb(&msg);
			}

			post();
			dispatch();
		}
		else
		{
			LOG_INFO("tick socket closed");
			on_closed();
			connect_state_ = CONNECT_STATE_DISCONNECT;
		}
	}
	else
	{
		int old_state = connect_state_.load();
		if (old_state == CONNECT_STATE_INVALID)
		{
			if (connect(ip_.c_str(), port_))
			{
				connect_state_.compare_exchange_weak(old_state, CONNECT_STATE_CONNECTING);
			}
		}
		else if (old_state == CONNECT_STATE_DISCONNECT)
		{
			auto cur = GameTimeManager::instance()->get_millisecond_time();
			if (cur - wait_tick_ >= 5000)
			{
				if (connect(ip_.c_str(), port_))
				{
					connect_state_.compare_exchange_weak(old_state, CONNECT_STATE_CONNECTING);
				}
			}
		}
	}

	return true;
}
