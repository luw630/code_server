#pragma once

#include "god_include.h"
#include <algorithm>
#include <string>
#include <vector>
#include "Singleton.h"
#include "base_game_log.h"

typedef unsigned char byte;
typedef unsigned int uint;
#define B2IL(b) (((b)[0] & 0xFF) | (((b)[1] << 8) & 0xFF00) | (((b)[2] << 16) & 0xFF0000) | (((b)[3] << 24) & 0xFF000000))
#define B2IU(b) (((b)[3] & 0xFF) | (((b)[2] << 8) & 0xFF00) | (((b)[1] << 16) & 0xFF0000) | (((b)[0] << 24) & 0xFF000000))
struct s_ipip{
	byte *data;
	byte *index;
	uint *flag;
	uint offset;
};
class IP17MON {
public:
	s_ipip ipip;
	IP17MON()
	{
		ipip.offset = 0;
	}
	~IP17MON()
	{
		if (ipip.offset) {
		free(ipip.flag);
		free(ipip.index);
		free(ipip.data);
		ipip.offset = 0;
		}
	}
	bool init(const std::string strPathToDataFile = "../data/17mon.dat") {
		if (ipip.offset) {
			return false;
		}
		FILE *file = fopen(strPathToDataFile.c_str(), "rb");
		fseek(file, 0, SEEK_END);
		long size = ftell(file);
		fseek(file, 0, SEEK_SET);

		ipip.data = (byte *)malloc(size * sizeof(byte));
		size_t r = fread(ipip.data, sizeof(byte), (size_t)size, file);

		if (r == 0) {
			return false;
		}

		fclose(file);

		uint length = B2IU(ipip.data);

		ipip.index = (byte *)malloc(length * sizeof(byte));
		memcpy(ipip.index, ipip.data + 4, length);

		ipip.offset = length;

		ipip.flag = (uint *)malloc(256 * sizeof(uint));
		memcpy(ipip.flag, ipip.index, 256 * sizeof(uint));
		return true;
	}
	
	int find(const char *ip, char *result) {
		uint ips[4];
		int num = sscanf(ip, "%d.%d.%d.%d", &ips[0], &ips[1], &ips[2], &ips[3]);
		if (num == 4) {
			uint ip_prefix_value = ips[0];
			uint ip2long_value = B2IU(ips);
			uint start = ipip.flag[ip_prefix_value];
			uint max_comp_len = ipip.offset - 1028;
			uint index_offset = 0;
			uint index_length = 0;
			for (start = start * 8 + 1024; start < max_comp_len; start += 8) {
				if (B2IU(ipip.index + start) >= ip2long_value) {
					index_offset = B2IL(ipip.index + start + 4) & 0x00FFFFFF;
					index_length = ipip.index[start + 7];
					break;
				}
			}
			memcpy(result, ipip.data + ipip.offset + index_offset - 1024, index_length);
			result[index_length] = '\0';
		}
		return 0;
	}
};
class ip_area_info
{
public:
	unsigned int m_begin = 0;
	unsigned int m_end = 0;
	//std::string m_begin_str;
	//std::string m_end_str;
	std::string m_area_str;

	ip_area_info(){};
	ip_area_info(const char* default_str) :m_area_str(default_str){};
	inline bool is_in_this_area(unsigned int ip)
	{
		return ip >= m_begin && ip <= m_end;
	}
	bool operator > (unsigned int ip)
	{
		return m_begin > ip;
	}

	bool operator > (const ip_area_info& out)
	{
		return m_begin > out.m_end;
	}
	bool operator < (const ip_area_info& out)
	{
		return m_end > out.m_begin;
	}
};
class ip_mgr : public TSingleton<ip_mgr>
{
private:
	IP17MON oIP17MON;
	std::string oIP17MON_tmp_ip;
	unsigned int begin_pos;
	unsigned int end_pos;
	ip_area_info ip_area_info_not_found;
	ip_area_info* half_find(unsigned int ip)
	{
		
		for (auto iter = ip_area_info_list.rbegin(); iter != ip_area_info_list.rend(); iter++)
		{
			if ((*iter).is_in_this_area(ip))
			{
				return &(*iter);
			}
		}
		return &ip_area_info_not_found;
	}
public:
	unsigned int ip_area_info_list_size;
	std::vector<ip_area_info> ip_area_info_list;
	ip_mgr() :ip_area_info_not_found("***")
	{
	}

	void parse_file(const char* file_name = "../data/17mon.dat")
	{
		bool suc = oIP17MON.init();
		assert(suc);
		return;
	}
	char* U2G(const char* utf8)
	{
		int len = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, NULL, 0);
		wchar_t* wstr = new wchar_t[len + 1];
		memset(wstr, 0, len + 1);
		MultiByteToWideChar(CP_UTF8, 0, utf8, -1, wstr, len);
		len = WideCharToMultiByte(CP_ACP, 0, wstr, -1, NULL, 0, NULL, NULL);
		static std::string str_tmp;
		str_tmp.resize(len + 1);
		char* str = const_cast<char*>(str_tmp.c_str());
		memset(str, 0, len + 1);
		WideCharToMultiByte(CP_ACP, 0, wstr, -1, str, len, NULL, NULL);
		if (wstr) delete[] wstr;
		return str;
	}
	char* G2U(const char* gb2312)
	{
		int len = MultiByteToWideChar(CP_ACP, 0, gb2312, -1, NULL, 0);
		wchar_t* wstr = new wchar_t[len + 1];
		memset(wstr, 0, len + 1);
		MultiByteToWideChar(CP_ACP, 0, gb2312, -1, wstr, len);
		len = WideCharToMultiByte(CP_UTF8, 0, wstr, -1, NULL, 0, NULL, NULL);
		static std::string str_tmp;
		str_tmp.resize(len + 1);
		char* str = const_cast<char*>(str_tmp.c_str());
		memset(str, 0, len + 1);
		WideCharToMultiByte(CP_UTF8, 0, wstr, -1, str, len, NULL, NULL);
		if (wstr) delete[] wstr;
		return str;
	}
	const char* get_ip_area_str(const std::string& ip_str)
	{
		static char buff[1024] = {0};
		buff[0] = '\0';		
		oIP17MON.find(ip_str.c_str(), buff);
		if (buff[0] == '\0')
		{
			buff[0] = '*';
			buff[1] = '*';
			buff[2] = '*';
			buff[3] = '\0';
			LOG_INFO("parse ip failed : %s", ip_str.c_str());
		}
		else
		{
			for (int i = 0; i < 1024; i++ )
			{
				if (buff[i] == '\t')
				{
					char tmp_buff[1024] = {0};
					memcpy(tmp_buff, buff + i + 1, strlen(buff + i + 1));
					memset(buff, 0, 1024);
					int buff_index = 0;
					for (int j = 0; tmp_buff[j] != '\0'; j++)
					{
						if (tmp_buff[j] != '\t')
						{
							buff[buff_index++] = tmp_buff[j];
						}
					}
					break;
				}
			}
		}
		std::string strTemp = U2G(buff);
		LOG_INFO("set_ip_area = %s", strTemp.c_str());
		if (strTemp == "柬埔寨" || strTemp == "新加坡"){
			strTemp = "广东";
			strcpy(buff, G2U(strTemp.c_str()));
			strTemp = U2G(buff);
			LOG_INFO("set_ip_area = %s", strTemp.c_str());
		}
		return buff;

		begin_pos = 0;
		end_pos = ip_area_info_list_size-1;
		unsigned int ip = get_int_from_ip_str(ip_str);
		ip_area_info* p = half_find(ip);
		return p->m_area_str.c_str();
	}

	static unsigned int get_int_from_ip_str(const std::string& ip_str)
	{
		std::vector<std::string> v;
		boost::split(v, ip_str, boost::is_any_of("."));
		if (v.size() == 4)
		{
			unsigned int num01 = boost::lexical_cast<int>(v[0]);
			unsigned int num02 = boost::lexical_cast<int>(v[1]);
			unsigned int num03 = boost::lexical_cast<int>(v[2]);
			unsigned int num04 = boost::lexical_cast<int>(v[3]);

			return (((0x00000000 | num01 << 24) | num02 << 16) | num03 << 8) | num04 << 0;
		}
		else
		{
			assert(false);
		}
		return 0;
	}
};