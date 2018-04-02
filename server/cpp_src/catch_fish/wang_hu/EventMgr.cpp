#include "EventMgr.h"
#include "MyFunctor.h"
#include <algorithm>

SingletonInstance(CEventMgr);

CEventMgr::CEventMgr()
:bEnabled_(true)
{

}

CEventMgr::~CEventMgr()
{
	for(map_handler_t::iterator it = mapHandler_.begin(); it != mapHandler_.end(); ++it)
	{
		std::for_each(it->second.begin(), it->second.end(), FuncDelete< TemplateCallback< CMyEvent* > >());
	}
}

void CEventMgr::RegisterEvent(const EventID& id, TemplateCallback< CMyEvent* > *handler)
{
	mapHandler_[id].push_back(handler);
}

void CEventMgr::UnregisterEvent(const EventID& id, TemplateCallback< CMyEvent* > *handler)
{
	map_handler_t::iterator itList = mapHandler_.find(id);
	if(itList != mapHandler_.end())
	{
		list_handler_t::iterator it = find(itList->second.begin(), itList->second.end(), handler);
		if(it != itList->second.end())
		{
			delete *it;
			itList->second.erase(it);
		}
	}
}

void CEventMgr::ProcessEvent(CMyEvent* pEvent)
{
	if(!bEnabled_) return ;

	map_handler_t::iterator itList = mapHandler_.find(pEvent->GetName());
	if(itList != mapHandler_.end())
	{
		for(list_handler_t::iterator it = itList->second.begin(); it != itList->second.end(); ++it)
		{
			(*it)->operator()(pEvent);
		}
	}
}

void CEventMgr::RaiseEvent(const EventID& szEventName)
{
	CMyEvent ie;
	ie.SetName(szEventName);
	ProcessEvent(&ie);

}

void CEventMgr::PostEvent(CMyEvent* &pEvent)
{
	m_listEvent.push_back(pEvent);
}

void CEventMgr::Update(int ms)
{
	while(m_listEvent.size() > 0)
	{
		CMyEvent* pEvent = m_listEvent.front();
		ProcessEvent(pEvent);
		delete pEvent;

		m_listEvent.pop_front();
	}
}
