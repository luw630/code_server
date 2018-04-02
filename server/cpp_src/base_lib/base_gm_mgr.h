#pragma once

#include "god_include.h"
#include "Singleton.h"

class GmBase
{
public:
	GmBase() {}
	virtual ~GmBase() {}

	virtual void exe() = 0;
};

class GmReloadScript : public GmBase
{
public:
	GmReloadScript() {}
	virtual ~GmReloadScript() {}

	virtual void exe();
};

class GmLuaCommand : public GmBase
{
public:
	GmLuaCommand() {}
	virtual ~GmLuaCommand() {}

	virtual void exe();

	void set_command(const std::string& cmd)
	{
		cmd_ = cmd;
	}

protected:
	std::string								cmd_;
};

class web_mgr
{
public:
	web_mgr();

	virtual ~web_mgr();

	virtual bool gm_command(std::vector<std::string>& vc);

	void exe_gm_command();

protected:
	std::recursive_mutex					mutex_;
	std::vector<std::shared_ptr<GmBase>>	gm_list_;
};
