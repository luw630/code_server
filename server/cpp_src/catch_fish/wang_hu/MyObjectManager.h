////
#ifndef __MyObjMgr_h__
#define __MyObjMgr_h__

#include "MyObject.h"
#include <list>
#include <mutex>

typedef std::map< uint32_t, MyObject* > obj_table_t;
typedef obj_table_t::iterator obj_table_iter;

class MyObjMgr
{
public:
	MyObject* Find(uint32_t nID);

	void Add(MyObject* pObj);//添加一个角色到列表
	void Remove(MyObject* pObj);
	void Remove(uint32_t nID);

	void OnUpdate(uint32_t);

	obj_table_iter Begin();
	obj_table_iter End();

	void Clear();//清除所有角色

	int CountObject();//统计角色数量

	MyObjMgr();
	~MyObjMgr();
public:
	void Lock(void);
	void Unlock(void);
protected:
	obj_table_t m_mapObject;

	std::recursive_mutex m_lock;
};

#endif//__MyObjMgr_h__
