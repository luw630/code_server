#include "common.h"
#include "MoveCompent.h"
#include "MathAide.h"
#include "PathManager.h"
//#include "../消息定义/CMD_Fish.h"
#include "MyObject.h"
#include "GameConfig.h"
#include <math.h>

MoveCompent::MoveCompent()
:m_bPause(false)
,m_fSpeed(1.0f)
,m_nPathID(0)
,m_bEndPath(false)
,m_fDelay(0.0f)
,m_bBeginMove(false)
,m_bRebound(true)
,m_dwTargetID(0)
,m_pObjMgr(NULL)
,m_bTroop(false)
{
	SetPosition(-5000, -5000);
}
//分离
void MoveCompent::OnDetach()
{
	m_bPause = false;
	m_fSpeed = 1.0f;
	m_nPathID = 0;
	m_bEndPath = false;
	m_fDelay = 0.0f;
	m_bBeginMove = false;
	m_bRebound = true;
	m_dwTargetID = 0;
	m_pObjMgr = NULL;
	SetPosition(-5000, -5000);
}
//事件处理
void MoveCompent::OnCCEvent(CComEvent* pEvent)
{
	if(pEvent != NULL)
	{
		switch(pEvent->GetID())
		{
		case EME_STATE_CHANGED:
			{
				if(pEvent->GetParam1() >= EOS_DEAD)
				{
					SetPause(true);
				}
				break;
			}
		}
	}
}
//路径移动初始化
void MoveByPath::InitMove()
{
	//获取路径
	MovePoints* pPath = PathManager::GetInstance()->GetPathData(GetPathID(), bTroop());
	if(pPath != NULL)
	{
		m_fDuration = pPath->size();
	}
	//初始移动距离
	m_Elaspe = 0.0f;
	m_bEndPath = false;
}
//路径移动
void MoveByPath::OnUpdate(int ms)
{
 	if(m_bPause || m_bEndPath) return;

	MovePoints* pPath = PathManager::GetInstance()->GetPathData(GetPathID(), bTroop());
	if(pPath == NULL) return;

	if(ms < 0) ms = 1000/GAME_FPS;

	float fdt =  ms / 1000.0f;
	//查询当前速度（子弹EME_QUERY_SPEED_MUL） 可优
	MyObject* pOwner = GetOwner();
	if(pOwner != NULL)
	{
		CComEvent se;
		se.SetID(EME_QUERY_SPEED_MUL);
		se.SetParam1(0);
		se.SetParam2(&fdt);

		pOwner->ProcessCCEvent(&se);
	}
	//诞时判断
	if(m_fDelay > 0)
	{
		m_fDelay -= fdt;
		return;
	}
	//是否开始移动
	if(m_bBeginMove == false && m_Elaspe > 0)
	{
		m_bBeginMove = true;
	}
	//已经移动的距离 + 时间 X 速度
	m_Elaspe += fdt * GetSpeed();
	//设定初始点坐标？
	CMovePoint mp(MyPoint(-5000, -5000), 0.0f);
	//获取移动节点百分比
	float time = min(1.0f, (m_Elaspe / m_fDuration));
	float fDiff;
	//得到节点偏移值？
	float fIndex = time * pPath->size();
	//取整节点
	int index = fIndex;
	//偏移
	fDiff = fIndex - index;
	//判断是否到达终点或超过
	if (index >= pPath->size())
	{
		index = pPath->size() - 1;
	}
	else if(index < 0 || fDiff < 0)
	{
		index = 0;
		fDiff = 0;
	}
	//如果小于最大节点数-1 移动
	if (index < pPath->size() - 1)
	{
		//获取当前节点坐标及下一节点坐标
		CMovePoint move_point1 = pPath->at(index);
		CMovePoint move_point2 = pPath->at(index+1);
		//运算坐标差及 方向差
		mp.m_Position = move_point1.m_Position*(1.0-fDiff)+ move_point2.m_Position*fDiff;
		mp.m_Direction = move_point1.m_Direction*(1.0-fDiff)+ move_point2.m_Direction*fDiff;
		//获取最终方向
		if (std::abs(move_point1.m_Direction-move_point2.m_Direction) > M_PI)
		{
			mp.m_Direction = move_point1.m_Direction;
		}
	}
	else
	{//到达终点
		mp = pPath->at(index);
		m_bEndPath = true;
	}
	//设置坐标
 	SetPosition(mp.m_Position + m_Offest);
	//设置方向
 	SetDirection(mp.m_Direction);
}
//方向移动
void MoveByDirection::OnUpdate(int ms)
{
	if(m_bPause || m_bEndPath) return;

	if(ms < 0) ms = 1000/GAME_FPS;
	//判断是否存在锁定目标
	if(m_pObjMgr != NULL && m_dwTargetID != 0)
	{
		MyObject* pObj = m_pObjMgr->Find(m_dwTargetID);
		if(pObj != NULL && pObj->GetState() < EOS_DEAD && pObj->InSideScreen())
		{
			//计算距离大于10从新定位方向小于10则不再定位
			if(CMathAide::CalcDistance(pObj->GetPosition().x_, pObj->GetPosition().y_, GetPostion().x_, GetPostion().y_) > 10)
			{
				//通过计算目标与自己坐标角度获取方向
				SetDirection(CMathAide::CalcAngle(pObj->GetPosition().x_, pObj->GetPosition().y_, GetPostion().x_, GetPostion().y_));
				//初始移动
				InitMove();
			}
			else
			{
				//设置坐标与方向
				SetPosition(pObj->GetPosition());
				SetDirection(pObj->GetDirection());
				return;
			}
		}
		else
		{
			//目标为空
			m_dwTargetID = 0;
		}
	}

	float fdt =  ms / 1000.0f;
	//查询当前速度（子弹EME_QUERY_SPEED_MUL）可优
	MyObject* pOwner = GetOwner();
	if(pOwner != NULL)
	{
		CComEvent se;
		se.SetID(EME_QUERY_SPEED_MUL);
		se.SetParam1(0);
		se.SetParam2(&fdt);

		pOwner->ProcessCCEvent(&se);
	}
	//延时判断
	if(m_fDelay > 0)
	{
		m_fDelay -= fdt;
		return;
	}
	//是否可以移动
	if(m_bBeginMove == false)
	{
		m_bBeginMove = true;
	}
	//获取当前坐标
	MyPoint pt(GetPostion());

	pt.x_ += m_fSpeed* dx_ * fdt;
	pt.y_ += m_fSpeed* dy_ * fdt;
	//获取默认宽度高度
	float fWidth = CGameConfig::GetInstance()->nDefaultWidth;
	float fHeigth = CGameConfig::GetInstance()->nDefaultHeight;
	//是否反弹
	if(Rebound())
	{
		//运算反弹
		if (pt.x_ < 0.0f) { pt.x_ = 0 + (0 - pt.x_); dx_ = -dx_; angle_ =  - angle_; }
		if (pt.x_ > fWidth)  {pt.x_ = fWidth - (pt.x_ - fWidth); dx_ = -dx_; angle_ =  - angle_;}

		if (pt.y_ < 0.0f) { pt.y_ = 0 + (0 - pt.y_); dy_ = -dy_; angle_ = M_PI - angle_;}
		if (pt.y_ > fHeigth)  {pt.y_ = fHeigth - (pt.y_ - fHeigth); dy_ = -dy_; angle_ = M_PI - angle_;}
	}
	else
	{
		//不反弹是否到边线
		if(pt.x_ < 0 || pt.x_ > fWidth || pt.y_ < 0 || pt.y_ > fHeigth)
			m_bEndPath = true;
	}

	if(pOwner != NULL)//可优(在上边已经判断过是否存在）
	{
		//设置方向
		SetDirection(pOwner->GetObjType() == EOT_FISH ? angle_ - M_PI_2 : angle_);
	}
	//设置坐标
	SetPosition(pt);
}
//初始化移动
void MoveByDirection::InitMove()
{
	angle_ = GetDirection();
	dx_ = cosf(angle_ - M_PI_2);
	dy_ = sinf(angle_ - M_PI_2);
	m_bEndPath = false;
}





