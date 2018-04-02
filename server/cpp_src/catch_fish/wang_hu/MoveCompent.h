////
#ifndef __MOVE_COMPENT_H__
#define __MOVE_COMPENT_H__

#include "MyComponent.h"
#include "MyObjectManager.h"
#include "MovePoint.h"

enum MoveCompentType
{
	EMCT_PATH = (ECF_MOVE<<8),	//按路径移动
	EMCT_DIRECTION,				//按指定方向移动
	EMCT_TARGET,				//向目标方向移动
};

class MoveCompent : public MyComponent
{
public:
	MoveCompent();
	virtual ~MoveCompent(){}

	virtual const uint32_t GetFamilyID() const{return ECF_MOVE;}

	MyPoint GetPostion(){return m_data.m_Position;}
	void SetPosition(const MyPoint &pt){m_data.m_Position = pt;}
	void SetPosition(int x, int y){m_data.m_Position.x_ = x; m_data.m_Position.y_ = y;}

	float GetDirection(){return m_data.m_Direction;}
	void SetDirection(float dr){m_data.m_Direction = dr;}

	void SetSpeed(float sp){m_fSpeed = sp;}
	float GetSpeed(){return m_fSpeed;}

	void SetPause(bool bPause = true){m_bPause = bPause;}
	bool IsPaused(){return m_bPause;}

	virtual void OnUpdate(int ms) = NULL;

	void SetPathID(int pid, bool bt = false){m_nPathID = pid; m_bTroop = bt;}
	int GetPathID(){return m_nPathID;}

	bool bTroop(){return m_bTroop;}
	virtual void InitMove() = NULL;

	bool IsEndPath(){ return m_bEndPath; }
	bool SetEndPath(bool be){m_bEndPath = be;}

	const MyPoint& GetOffest(){return m_Offest;}
	void SetOffest(MyPoint& pt){m_Offest = pt;}

	virtual void OnCCEvent(CComEvent*);

	void SetDelay(float f){m_fDelay = f;}
	float GetDelay(){return m_fDelay;}

	bool HasBeginMove(){return m_bBeginMove;}

	bool Rebound(){return m_bRebound;}
	void SetRebound(bool b){m_bRebound = b;}

	uint32_t GetTargetID(){return m_dwTargetID;}
	void SetTarget(MyObjMgr* pm, uint32_t id){m_pObjMgr = pm; m_dwTargetID = id;}

	virtual void OnDetach();

protected:
	CMovePoint	m_data;				//坐标
	float		m_fSpeed;			//速度
	bool		m_bPause;			//是否暂停
	int			m_nPathID;			//路径ID
	bool		m_bEndPath;			//是否移动到终点
	MyPoint		m_Offest;			//偏移
	float		m_fDelay;			//延时
	bool		m_bBeginMove;		//开始移动
	bool		m_bRebound;			//是否反弹
	uint32_t		m_dwTargetID;		//目标ID
	MyObjMgr*	m_pObjMgr;			//对象管理
	bool		m_bTroop;			//是否队伍
};

class MoveByPath : public MoveCompent
{
public:
	virtual void OnUpdate(int ms);

	virtual void InitMove();

protected:
	float				m_fDuration;	//总结点数
	float				m_Elaspe;		//距离
};

class MoveByDirection : public MoveCompent
{
public:
	virtual void OnUpdate(int ms);

	virtual void InitMove();

protected:
	float	angle_;		//角度
	float	dx_;		
	float	dy_;
};

#endif

