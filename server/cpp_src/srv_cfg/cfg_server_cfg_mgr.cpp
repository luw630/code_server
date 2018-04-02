#include "cfg_server_cfg_mgr.h"
#include "base_game_log.h"
#include <google/protobuf/text_format.h>

cfg_server_cfg_mgr::cfg_server_cfg_mgr()
{
	cfg_file_name_ = "../data/config_self.cfg";
}

cfg_server_cfg_mgr::~cfg_server_cfg_mgr()
{

}

bool cfg_server_cfg_mgr::load_file(const char* file, std::string& buf)
{
	std::ifstream ifs(file, std::ifstream::in);
	if (!ifs.is_open())
	{
		LOG_ERR("load %s failed", file);
		return false;
	}

	buf = std::string(std::istreambuf_iterator<char>(ifs), std::istreambuf_iterator<char>());
	if (ifs.bad())
	{
		LOG_ERR("load %s failed", file);
		return false;
	}

	return true;
}

bool cfg_server_cfg_mgr::load_config()
{
	std::string buf;
	if (!load_file(cfg_file_name_.c_str(), buf))
		return false;

	if (!google::protobuf::TextFormat::ParseFromString(buf, &config_))
	{
		LOG_ERR("parse %s failed", cfg_file_name_.c_str());
		return false;
	}

	LOG_INFO("load cfg ok......");
	return true;
}
