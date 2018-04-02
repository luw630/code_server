#pragma once

#include "god_include.h"
#include "Singleton.h"
#ifdef PLATFORM_WINDOWS
#define LOG_INFO(fmt, ...) base_game_log::instance()->log_info(__FILE__, __LINE__, __FUNCTION__, fmt, __VA_ARGS__)
#define LOG_ERR(fmt, ...) base_game_log::instance()->log_error(__FILE__, __LINE__, __FUNCTION__, fmt, __VA_ARGS__)
#define LOG_WARN(fmt, ...) base_game_log::instance()->log_warning(__FILE__, __LINE__, __FUNCTION__, fmt, __VA_ARGS__)
#define LOG_DEBUG(fmt, ...) base_game_log::instance()->log_debug(__FILE__, __LINE__, __FUNCTION__, fmt, __VA_ARGS__)
#endif

#ifdef PLATFORM_LINUX
#define LOG_INFO(fmt, args...) base_game_log::instance()->log_info(__FILE__, __LINE__, __FUNCTION__, fmt, ##args)
#define LOG_ERR(fmt, args...) base_game_log::instance()->log_error(__FILE__, __LINE__, __FUNCTION__, fmt, ##args)
#define LOG_WARN(fmt, args...) base_game_log::instance()->log_warning(__FILE__, __LINE__, __FUNCTION__, fmt, ##args)
#define LOG_DEBUG(fmt, args...) base_game_log::instance()->log_debug(__FILE__, __LINE__, __FUNCTION__, fmt, ##args)
#endif


class base_game_log : public TSingleton < base_game_log >
{
protected:
	std::ofstream						log_file_;
	std::string							log_name_;
	time_t								tomorrow_;

	std::recursive_mutex				mutex_;

	bool								log_print_open_;
public:

	

	base_game_log();

	

	virtual ~base_game_log();

	

	virtual void init(const std::string& logname);
	
	

	virtual void log_info(const char* file, int line, const char* func, const char* fmt, ...);

	

	virtual void log_error(const char* file, int line, const char* func, const char* fmt, ...);

	

	virtual void log_warning(const char* file, int line, const char* func, const char* fmt, ...);

	

	virtual void log_debug(const char* file, int line, const char* func, const char* fmt, ...);

	enum LOG_TYPE
	{
		LOG_TYPE_DEBUG,
		LOG_TYPE_WARNING,
		LOG_TYPE_ERROR,
		LOG_TYPE_INFO,
	};

	void log_string(LOG_TYPE type, const char* log);

	void log(LOG_TYPE type, const char* file, int line, const char* func, const char* str);

	void set_log_print(bool open){ log_print_open_ = open; }

protected:

	

	void calc_tomorrow();

	

	void open_log_file();


};



