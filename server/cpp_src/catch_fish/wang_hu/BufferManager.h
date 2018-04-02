#ifndef __BUFFER_MANAGER_H__
#define __BUFFER_MANAGER_H__

#include "MyComponent.h"
#include "Buffer.h"
#include <list>

enum BufferMgrComType
{
	EBCT_BUFFERMGR = (ECF_BUFFERMGR << 8),
};

class BufferMgr : public MyComponent
{
public:
	BufferMgr();
	virtual ~BufferMgr();

	const uint32_t GetFamilyID() const{return ECF_BUFFERMGR;}

	void Add(CBuffer* pObj);
	void Add(int bty, float par, float tim);
	void Clear();

	bool HasBuffer(int byt);

	virtual void OnCCEvent(CComEvent*);

	virtual void OnUpdate(int ms);

	virtual void OnDetach(){Clear();}

protected:
	typedef std::list< CBuffer* > obj_table_t;
	typedef obj_table_t::iterator obj_table_iter;

	obj_table_t m_Buffers;
};

#endif


