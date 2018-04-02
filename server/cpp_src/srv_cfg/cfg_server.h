#pragma once

#include "god_include.h"
#include "base_server.h"
#include "cfg_server_cfg_mgr.h"
#include "cfg_session_mgr.h"
#include "cfg_db_mgr.h"
#include "base_gm_mgr.h"
#include "base_redis_con_thread.h"

class cfg_server : public base_server
{
public:
	std::unordered_map<int,PlayerInfoInMemery>		player_info_in_memery_;
	std::unordered_map<int,PlayerInfoInMemery>		player_info_in_memery_tmp_;
	PlayerInfoInMemery get_player_info_in_memery(int guid)
	{
		auto iter = player_info_in_memery_.find(guid);
		if (iter != player_info_in_memery_.end())
		{
			return iter->second;
		}
		//LOG_ERR("unknown player GF_SavePlayerInfo %d", guid);
		PlayerInfoInMemery tmp;
		tmp.set_guid(-1000);
		tmp.set_money(-1000);
		tmp.set_bank(-1000);
		return tmp;
	}
	void set_player_info_in_memery(const PlayerInfoInMemery& info)
	{
		auto& tmp = player_info_in_memery_[info.guid()];
		tmp.set_guid(info.guid());
		if (info.bank() >= 0)
		{
			tmp.set_bank(info.bank());
		}
		if (info.money() >= 0)
		{
			tmp.set_money(info.money());
		}
		if (!(tmp.money() >= 0 && tmp.bank() >= 0 && tmp.money() <= 1000000000 && tmp.bank() <= 1000000000))
		{
			LOG_ERR("player  %d info error  money %d  bank %d", tmp.guid(),tmp.money(),tmp.bank());
		}
		if (!(tmp.money() >= 0 && tmp.money() <= 1000000000))
		{
			tmp.set_money(0);
		}
		if (!(tmp.bank() >= 0 && tmp.bank() <= 1000000000))
		{
			tmp.set_bank(0);
		}
	}
	void save_players_info_to_mysql();
	void begin_save_players_info_to_mysql();
private:
	void tick();
	virtual bool load_common_config() {
		return true;
	}

	cfg_server_cfg_mgr							cfg_manager_;

	std::unique_ptr<cfg_session_mgr>				sesssion_manager_;
	std::unique_ptr<base_net_server>						network_server_;
	std::unique_ptr<cfg_db_mgr>							db_manager_;

#ifdef _DEBUG
	web_mgr											gm_manager_;
#endif
public:
	cfg_server();
	~cfg_server();
	virtual bool init();
	virtual void run();
	virtual void stop();
	virtual void release();
	virtual void on_gm_command(const char* cmd);
	virtual bool LoadSeverConfig();
	void init_timer();

};