#pragma once

#include <string>  
#include <vector>
#include <map>

class web_cfg
{
public:
	web_cfg();
	~web_cfg();
	bool load();
	std::string get_http_addr() { return http_addr; }
	unsigned short get_http_port() { return http_port; }
    std::pair<std::string, int> get_login_attr(); 
    std::pair<std::string, int> get_cfg_attr();
protected:
	bool load_file(const char* filename, std::string& out);
	bool load_cfg();
private:
	std::string									http_addr;
	unsigned short								http_port;
    std::vector<std::pair<std::string, int>>	login_attr;
    std::vector<std::pair<std::string, int>>	cfg_attr;
	size_t										cur_attr;
};
