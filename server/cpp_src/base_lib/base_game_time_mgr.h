#pragma once

#include <sys/timeb.h>
#include "god_include.h"
#include "Singleton.h"

struct game_timer_cmp;

class game_timer
{
	friend struct game_timer_cmp;
public:
	game_timer(float delay);

	virtual ~game_timer();

	bool check_time();

protected:
	virtual void on_time(float delta) {}

protected:
	long long start_;
	long long delay_;
};

struct game_timer_cmp
{
	bool operator()(const game_timer* _Left, const game_timer* _Right) const
	{
		return (_Left->delay_ > _Right->delay_);
	}
};



class base_game_time_mgr : public TSingleton < base_game_time_mgr >
{
protected:
	tm											tm_;
	timeb										tb_;

	std::priority_queue<game_timer*, std::vector<game_timer*>, game_timer_cmp> timers_;
public:

	
	base_game_time_mgr();

	
	~base_game_time_mgr();

	
	base_game_time_mgr& now();

	
	time_t get_second_time() const { return tb_.time; }

	
	const tm* get_tm() const { return &tm_; }

	
	long long get_millisecond_time() const;

	
	int to_days(time_t time);

	
	int to_days();

	
	int to_weeks(time_t time);

	
	int to_weeks();

	
	void add_timer(game_timer* timer);

	
	void tick();


};
