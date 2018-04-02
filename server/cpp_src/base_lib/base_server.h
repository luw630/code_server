#pragma once

#include "god_include.h"
#include "base_windows_console.h"
#include "base_game_time_mgr.h"
#include "base_game_log.h"
#include "config.pb.h"

class base_server : public TSingleton < base_server >
{
protected:
#if defined(_DEBUG) && defined(PLATFORM_WINDOWS)
	base_windows_console								windows_console_;
#endif
	std::unique_ptr<base_game_time_mgr>			game_time_;
	std::unique_ptr<base_game_log>				game_log_;
	std::thread									thread_;
	volatile bool								is_run_;
	CommonServer_Config							common_config_;
	struct MsgStatistics
	{
		uint64_t								count_;
		uint64_t								byte_;
		MsgStatistics(uint64_t _count, uint64_t _byte)
			: count_(_count)
			, byte_(_byte)
		{
		}
	};
	std::unordered_map<uint16_t, MsgStatistics> send_statistics_;
	std::unordered_map<uint16_t, MsgStatistics> recv_statistics_;
	std::recursive_mutex						mutex_statistics_;
	std::string									filename_statistics_;
	time_t										time_statistics_;

	std::vector<std::pair<int, uint16_t>>		msg_flow_log_;
	std::recursive_mutex						mutex_msg_flow_log_;
	std::string									filename_msg_flow_log_;
	time_t										time_msg_flow_log_;
public:
	base_server();
	virtual ~base_server();
	void startup();
	virtual bool init();
	virtual void run();
	virtual void stop();
	virtual void release();
	virtual void on_gm_command(const char* cmd);
	size_t get_core_count();
	virtual const char* main_lua_file();
	CommonServer_Config& get_common_cfg()
	{
		return common_config_;
	}
	void send_statistics(uint16_t msgid, uint64_t byte_);
	void recv_statistics(uint16_t msgid, uint64_t byte_);
	void print_statistics();
	void set_print_filename(const std::string& filename);
	void recv_msg_flow(int id, uint16_t msgid);
	void print_msg_flow();
	void set_msg_flow_log_filename(const std::string& filename);
protected:
	bool load_file(const char* file, std::string& buf);
	virtual bool load_common_config();

};
