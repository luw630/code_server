#include "MyComponent.h"
#include "MyObject.h"

void MyComponent::RaiseEvent(CComEvent* pEvent)
{
	pEvent->SetSender(this);
	GetOwner()->ProcessCCEvent(pEvent);
}

void MyComponent::RaiseEvent(uint32_t idEvent, int64_t nParam1, void* pParam2)
{
	CComEvent se;
	se.SetID(idEvent);
	se.SetParam1(nParam1);
	se.SetParam2(pParam2);
	se.SetSender(this);

	GetOwner()->ProcessCCEvent(&se);
}


void MyComponent::PostEvent(std::auto_ptr<CComEvent> &evnt)
{
	evnt->SetSender(this);
	GetOwner()->PushCCEvent(evnt);
}

void MyComponent::PostEvent(uint32_t idEvent, int64_t nParam1, void* pParam2)
{
	CComEvent* pEvent = new CComEvent;
	pEvent->SetID(idEvent);
	pEvent->SetParam1(nParam1);
	pEvent->SetParam2(pParam2);
	pEvent->SetSender(this);

	std::auto_ptr< CComEvent > autoDel(pEvent);
	GetOwner()->PushCCEvent(autoDel);
}











