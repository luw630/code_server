//
#ifndef _MY_OBJECT_H_
#define _MY_OBJECT_H_

#include "common.h"
#include <set>
#include <list>
#include <map>
#include <memory>
#include <string.h>
#include "Size.h"
#include "Point.h"

class MyComponent;
class CComEvent;
class MyObjMgr;

enum ObjectType
{
	EOT_NONE = 0,				//
	EOT_PLAYER,					//玩家
	EOT_BULLET,					//子弹
	EOT_FISH,					//鱼
};

enum ObjState
{
	EOS_LIVE = 0,					//存活
	EOS_HIT,						//受击
	EOS_DEAD,						//死亡
	EOS_DESTORY,					//摧毁
	EOS_LIGHTING,					//照明？
};

enum MyEvent
{
	EME_STATE_CHANGED = 0,		//状态变化
	EME_QUERY_SPEED_MUL,		//查询速度倍率     //速度倍率？前端加速？
	EME_QUERY_ADDMUL,			//查询额外增加的倍率
};

class MyObject
{
public:
	MyObject();
	virtual ~MyObject();

public:
	//设置和获取Id
	uint32_t GetId()const{return id_;};
	void SetId(uint32_t newId){id_ = newId;};

	int GetObjType()const{return objType_;}
	void SetObjType(int objType){objType_ = objType;}

	//响应时间流逝
	virtual void OnUpdate(int msElapsed);

	void SetMgr(MyObjMgr* mgr){m_Mgr = mgr;}
	MyObjMgr* GetMgr(){return m_Mgr;}

	MyPoint GetPosition();

	float GetDirection();
	
	long long  GetScore(){return m_Score;}
	void SetScore(long long  sc){m_Score = sc;}
	void AddScore(long long  sc){m_Score += sc;}

	float	GetProbability(){return m_fProbability;}
	void SetProbability(float f){m_fProbability = f;}

	uint32_t GetCreateTick(){return m_dwCreateTick;}
	void SetCreateTick(uint32_t tk){m_dwCreateTick = tk;}

	bool InSideScreen();
	bool OutLeftSideScreen();
	bool OutUpSideScreen();
	bool OutDownSideScreen();

protected:
	MyObjMgr* m_Mgr;            //管理器指针
	uint32_t id_;
	int objType_;               //对象类型

	friend class ClientObjectFactory;

protected:
	typedef std::map< const uint32_t, MyComponent* >	Component_Table_t;     //附加控件列表
	typedef std::list< CComEvent* > CCEvent_Queue_t;          //事件列表

	Component_Table_t components_;          //附加控件列表
	CCEvent_Queue_t ccevent_queue_;         //事件列表
	
	long long	m_Score;       //金钱

	float		m_fProbability;         //概率(鱼的时候为被捕捉概率)

	uint32_t	m_dwCreateTick;             //创建钩子？

	int		m_nState;                       //状态

public:
	void ProcessCCEvent(CComEvent*);//即时处理的事件
	void ProcessCCEvent(uint32_t idEvent, int64_t nParam1 = 0, void* pParam2 = 0);

	void PushCCEvent(std::auto_ptr<CComEvent>& evnt);//延迟处理的事件
	void PushCCEvent(uint32_t idEvent, int64_t nParam1 = 0, void* pParam2 = 0);

	MyComponent* GetComponent(const uint32_t& familyID);
	void SetComponent( MyComponent* newComponent);

	bool DelComponent(const uint32_t& familyID);//删除指定组件，如果找到并成功删除则返回ｔｒｕｅ，找不到则返回ｆａｌｓｅ
	void ClearComponent();

	void SetState(int st, MyObject* pobj = NULL);
	int GetState();
    //类型
	void SetTypeID(int n){m_nTypeID = n;}
	int GetTypeID(){return m_nTypeID;}

protected:
	int			m_nTypeID;          //类型

};



#endif


