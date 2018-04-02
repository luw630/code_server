#pragma once

#include "god_include.h"
#include "Singleton.h"
#include "config.pb.h"


class cfg_server_cfg_mgr : public TSingleton<cfg_server_cfg_mgr>
{
private:
	std::string										cfg_file_name_;
	ConfigServer_Config								config_;
public:
	cfg_server_cfg_mgr();
	~cfg_server_cfg_mgr();
	ConfigServer_Config& get_config() { return config_; }
	bool load_config();
	void set_cfg_file_name(const std::string& filename) { cfg_file_name_ = filename; }
private:
	bool load_file(const char* file, std::string& buf);
};
