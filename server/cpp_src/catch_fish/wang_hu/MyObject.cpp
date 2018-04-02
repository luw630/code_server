#include "common.h"
#include "MyObject.h"
#include "MyFunctor.h"
#include "MoveCompent.h"
#include "GameConfig.h"
//#include "../消息定义/CMD_Fish.h"
#include "MyComponentFactory.h"
#include <algorithm>


MyObject::MyObject(void)
:id_(0)
,objType_(0)
,m_Mgr(NULL)
,m_Score(0)
,m_fProbability(MAX_PROBABILITY)
,m_dwCreateTick(timeGetTime())
,m_nState(EOS_LIVE)
,m_nTypeID(0)
{
}

MyObject::~MyObject(void)
{
	std::for_each(ccevent_queue_.begin(), ccevent_queue_.end(), FuncDelete<CComEvent>());
	ClearComponent();
}
//更新响应
void MyObject::OnUpdate(int msElapsed)
{
	//处理事件列表事件
	while(ccevent_queue_.size() > 0)
	{
		CComEvent* pEvent = ccevent_queue_.front();
		ccevent_queue_.pop_front();
		ProcessCCEvent(pEvent);
		delete pEvent;
	}
	//挂载组件调用OnUpdate
	std::for_each(components_.begin(), components_.end(), FuncMapUpdatePtr< Component_Table_t >(msElapsed));
}

MyComponent* MyObject::GetComponent(const uint32_t& familyID)
{
	Component_Table_t::iterator it = components_.find(familyID);
	if(it != components_.end())
		return it->second;

	return NULL;
}

void MyObject::ProcessCCEvent(CComEvent*pEvent)
{
	//所有组件都执行一次事件(根据判断pEvent->GetID() 来决定是否执行或返回） 可优
	for(Component_Table_t::iterator it = components_.begin(); it != components_.end(); ++it)
	{
		it->second->OnCCEvent(pEvent);
	}
}

void MyObject::ProcessCCEvent(uint32_t idEvent, int64_t nParam1 /* = 0 */, void* pParam2 /* = 0 */)
{
	CComEvent se;
	se.SetID(idEvent);
	se.SetParam1(nParam1);
	se.SetParam2(pParam2);

	ProcessCCEvent(&se);
}

void MyObject::PushCCEvent(std::auto_ptr<CComEvent>& evnt)
{
	ccevent_queue_.push_back(evnt.release());
}

void MyObject::PushCCEvent(uint32_t idEvent, int64_t nParam1 /* = 0 */, void* pParam2 /* = 0 */)
{
	CComEvent* pEvent = new CComEvent;
	pEvent->SetID(idEvent);
	pEvent->SetParam1(nParam1);
	pEvent->SetParam2(pParam2);

	std::auto_ptr< CComEvent > autoDel(pEvent);
	PushCCEvent(autoDel);
}

//设置组件
void MyObject::SetComponent(MyComponent* newComponent)
{
	MyComponent* oldComponent(NULL);
	Component_Table_t::iterator it = components_.find(newComponent->GetFamilyID());
	newComponent->SetOwner(this);
	if(it != components_.end())
	{
		oldComponent = it->second;
		oldComponent->OnDetach();
		MyComponentFactory::GetInstance()->Recovery(oldComponent->GetID(), oldComponent);
		it->second = newComponent;
	}
	else
	{
		components_[newComponent->GetFamilyID()] = newComponent;
	}

	if (newComponent){
		newComponent->OnAttach();
	}
}

bool MyObject::DelComponent(const uint32_t& familyID)
{
	MyComponent* oldSoc(NULL);
	Component_Table_t::iterator it = components_.find(familyID);
	if(it != components_.end())
	{
		it->second->OnDetach();
		MyComponentFactory::GetInstance()->Recovery((it->second)->GetID(), it->second);
		components_.erase(it);
		return true;
	}

	return false;
}

void MyObject::ClearComponent()
{
	for(Component_Table_t::iterator it = components_.begin(); it != components_.end(); ++it)
	{
		it->second->OnDetach();
		MyComponentFactory::GetInstance()->Recovery((it->second)->GetID(), it->second);
	}

	//std::for_each(components_.begin(), components_.end(), FuncMapDelete< Component_Table_t >());
	components_.clear();
}

float MyObject::GetDirection()
{
	MoveCompent* pMove = (MoveCompent*)this->GetComponent(ECF_MOVE);
	if(pMove != NULL)
		return pMove->GetDirection();

	return 0.0f;
}

MyPoint MyObject::GetPosition()
{
	MoveCompent* pMove = (MoveCompent*)this->GetComponent(ECF_MOVE);
	if(pMove != NULL)
		return pMove->GetPostion();

	return MyPoint(-5000.0f, -5000.0f);
}

bool MyObject::InSideScreen()
{
	MoveCompent* pMove = (MoveCompent*)this->GetComponent(ECF_MOVE);
	if(pMove != NULL)
		return pMove->GetPostion().x_ > 10 && pMove->GetPostion().x_ < CGameConfig::GetInstance()->nDefaultWidth - 10 &&
							pMove->GetPostion().y_ > 10 && pMove->GetPostion().y_ < CGameConfig::GetInstance()->nDefaultHeight - 10;
	return false;
}
bool MyObject::OutLeftSideScreen()
{
	MoveCompent* pMove = (MoveCompent*)this->GetComponent(ECF_MOVE);
	if (pMove != NULL)
		return pMove->GetPostion().x_ < 10;
	return false;
}
bool MyObject::OutUpSideScreen()
{
	MoveCompent* pMove = (MoveCompent*)this->GetComponent(ECF_MOVE);
	if (pMove != NULL)
		return pMove->GetPostion().y_ < 10;
	return false;
}
bool MyObject::OutDownSideScreen()
{
	MoveCompent* pMove = (MoveCompent*)this->GetComponent(ECF_MOVE);
	if (pMove != NULL)
		return pMove->GetPostion().y_ > CGameConfig::GetInstance()->nDefaultHeight - 10;
	return false;
}

void MyObject::SetState(int st, MyObject* pobj)
{
	ProcessCCEvent(EME_STATE_CHANGED, st, pobj);
	m_nState = st;
}

int MyObject::GetState()
{
	return m_nState;
}




