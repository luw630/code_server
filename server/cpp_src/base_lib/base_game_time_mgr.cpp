#include "base_game_time_mgr.h"


game_timer::game_timer(float delay)
	: start_(base_game_time_mgr::instance()->get_millisecond_time())
	, delay_(base_game_time_mgr::instance()->get_millisecond_time() + static_cast<long long>(delay * 1000))
{

}

game_timer::~game_timer()
{

}

bool game_timer::check_time()
{
	auto cur = base_game_time_mgr::instance()->get_millisecond_time();
	if (cur < delay_)
		return false;

	on_time(static_cast<float>(cur - start_) / 1000.f);

	return true;
}


base_game_time_mgr::base_game_time_mgr()
{
	memset(&tm_, 0, sizeof(tm));
	memset(&tb_, 0, sizeof(timeb));
}

base_game_time_mgr::~base_game_time_mgr()
{
	while (!timers_.empty())
	{
		delete timers_.top();
		timers_.pop();
	}
}

base_game_time_mgr& base_game_time_mgr::now()
{
	ftime(&tb_);
#ifdef PLATFORM_WINDOWS
	localtime_s(&tm_, &tb_.time);
#endif

#ifdef PLATFORM_LINUX
	localtime_r(&tb_.time, &tm_);
#endif

	return *this;
}

long long base_game_time_mgr::get_millisecond_time() const
{
	return 1000 * (long long)tb_.time + tb_.millitm;
}

int base_game_time_mgr::to_days(time_t time)
{
	return static_cast<int>(time + 57600) / 86400;
}

int base_game_time_mgr::to_days()
{
	return to_days(tb_.time);
}

int base_game_time_mgr::to_weeks(time_t time)
{
	return static_cast<int>(time - 230400) / (86400 * 7);
}

int base_game_time_mgr::to_weeks()
{
	return to_weeks(tb_.time);
}

void base_game_time_mgr::add_timer(game_timer* timer)
{
	timers_.push(timer);
}

void base_game_time_mgr::tick()
{
	now();

	while (!timers_.empty())
	{
		auto timer = timers_.top();
		if (!timer->check_time())
		{
			break;
		}
		timers_.pop();
		delete timer;
	}
}

#ifdef PLATFORM_LINUX
DWORD timeGetTime()
{
	timeb tb_;
	ftime(&tb_);
	return 1000 * tb_.time + tb_.millitm;
}
#endif