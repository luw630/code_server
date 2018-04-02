#include "BufferManager.h"
#include "BufferFactory.h"

BufferMgr::BufferMgr()
{

}

BufferMgr::~BufferMgr()
{
	Clear();
}

void BufferMgr::Add(CBuffer* pObj)
{
	if(pObj != NULL)
	{
		m_Buffers.push_back(pObj);
		pObj->SetOwner(GetOwner());
	}
}

void BufferMgr::Add(int bty, float par, float tim)
{
	CBuffer* pBuffer = CreateBuffer(bty);
	if(pBuffer != NULL)
	{
		pBuffer->SetParam(par);
		pBuffer->SetLife(tim);
		Add(pBuffer);
	}
}

bool BufferMgr::HasBuffer(int byt)
{
	obj_table_iter it = m_Buffers.begin();
	while(it != m_Buffers.end())
	{
		if((*it)->GetType() == byt)
			return true;
		++it;
	}
	return false;
}

void BufferMgr::Clear()
{
	obj_table_iter it = m_Buffers.begin();
	while(it != m_Buffers.end())
	{
		BufferFactory::GetInstance()->Recovery((*it)->GetType(), *it);
		++it;
	}
	m_Buffers.clear();
}

void BufferMgr::OnCCEvent(CComEvent* pEvent)
{
	obj_table_iter it = m_Buffers.begin();
	while(it != m_Buffers.end())
	{
		(*it)->OnCCEvent(pEvent);
		++it;
	}
}

void BufferMgr::OnUpdate(int ms)
{
	obj_table_iter it = m_Buffers.begin();
	while(it != m_Buffers.end())
	{
		if(!(*it)->OnUpdate(ms))
		{
			CBuffer* pb =*it;
			it = m_Buffers.erase(it);
			pb->Clear();
			BufferFactory::GetInstance()->Recovery(pb->GetType(), pb);
			continue;
		}
		++it;
	}
}

