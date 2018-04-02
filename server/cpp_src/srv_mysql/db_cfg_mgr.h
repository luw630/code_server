#pragma once

#include "god_include.h"
#include "Singleton.h"
#include "config.pb.h"

class db_cfg_mgr : public TSingleton<db_cfg_mgr>
{
private:
	std::string										cfg_file_name_;
	DBServerConfig									config_;
private:
	bool load_file(const char* file, std::string& buf);
public:
	db_cfg_mgr();
	~db_cfg_mgr();
	DBServerConfig& get_config() { return config_; }
	bool load_config();
	void set_cfg_file_name(const std::string& filename) { cfg_file_name_ = filename; }
	std::string get_title();

};
