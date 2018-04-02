#include "base_asyn_task_mgr.h"

base_asyn_task_mgr::base_asyn_task_mgr()
{
	std::thread t(boost::bind(&base_asyn_task_mgr::task_thread, this));
	t.detach();
}

base_asyn_task_mgr::~base_asyn_task_mgr()
{
}

void base_asyn_task_mgr::tick()
{
	while(true)
	{
		asyn_task_ptr tempTask;
		{
			std::unique_lock<std::mutex> lock(taskFinishListLock);
			if (taskFinishList.empty())
			{
				break;
			}
			else
			{
				tempTask = taskFinishList.front();
				taskFinishList.pop_front();
			}
		}
		if (tempTask)
		{
			tempTask->finish_task_handler();
		}
	}
}

void base_asyn_task_mgr::add_task(asyn_task_ptr task)
{
	std::unique_lock<std::mutex> lock(taskListLock);
	taskList.push_back(task);
	cond.notify_one();  
}
void base_asyn_task_mgr::add_task_finish(asyn_task_ptr task)
{
	std::unique_lock<std::mutex> lock(taskFinishListLock);
	taskFinishList.push_back(task);
}
void base_asyn_task_mgr::stop()
{
	isRun = false;
}
void base_asyn_task_mgr::task_thread()
{
	while (isRun)
	{
		asyn_task_ptr tempTask;
		{
			std::unique_lock<std::mutex> lock(taskListLock);
			if (!taskList.empty())
			{
				tempTask = taskList.front();
				taskList.pop_front();
			}
		}
		if (tempTask)
		{
			tempTask->execute_task_handler();
			add_task_finish(tempTask);
		}
		else
		{
			std::unique_lock<std::mutex> lock(mu);
			cond.wait(mu);
		}
	}
}
