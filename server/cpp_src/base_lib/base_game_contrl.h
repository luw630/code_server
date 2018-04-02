#pragma once
#include <string>
#include "base_redis_con_thread.h"
using namespace std;
class base_game_contrl : public TSingleton<base_game_contrl>
{
public:
	base_game_contrl();
	~base_game_contrl();
	static void setGameTimes(const char * GameType, int playGuid, int otherGuid, bool master_flag);
	static bool judgePlayTimes(const char * GameType, int playGuid, int otherGuid, int times, bool master_flag);
	static void show(const char * GameType, int playGuid);
	static void IncPlayTimes(const char * GameType, int playGuid, bool master_flag);
	static int  getPlayTimes(const char * GameType, int playGuid, bool master_flag);
};
