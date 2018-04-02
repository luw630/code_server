#pragma once
#include "god_include.h"
#include "Singleton.h"
#include <condition_variable>
#include <memory>
#include <list>


class AsynTask
{
public:
	AsynTask(){};
	virtual ~AsynTask(){};

	virtual void execute_task_handler() = 0;
	virtual void finish_task_handler() = 0;
};

typedef std::shared_ptr<AsynTask> asyn_task_ptr;

class base_asyn_task_mgr : public TSingleton<base_asyn_task_mgr>
{
public:
    base_asyn_task_mgr();
    virtual ~base_asyn_task_mgr();
	
	void tick();
	void add_task(asyn_task_ptr task);
	void add_task_finish(asyn_task_ptr task);
	void task_thread();
	void stop();

private: 
	std::mutex mu;  
	std::condition_variable_any cond;

	std::mutex			taskListLock;
	std::list<asyn_task_ptr>	taskList;

	std::mutex			taskFinishListLock;
	std::list<asyn_task_ptr>	taskFinishList;

	bool isRun = true;
};

#define sbase_asyn_task_mgr (*base_asyn_task_mgr::instance())
