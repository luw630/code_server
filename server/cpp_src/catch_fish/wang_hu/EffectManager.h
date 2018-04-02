#ifndef __EFFECT_MANAGER_H__
#define __EFFECT_MANAGER_H__

#include "MyComponent.h"
#include "Effect.h"
#include <list>

enum EEffectMgrComType
{
	EECT_MGR = (ECF_EFFECTMGR << 8),
};

class EffectMgr : public MyComponent
{
public:
	EffectMgr();
	virtual ~EffectMgr();

	const uint32_t GetFamilyID() const{return ECF_EFFECTMGR;}

	void Add(CEffect* pObj);
	void Clear();
	long long  Execute(MyObject* pTarget, std::list<MyObject*>& list, bool bPretreating);

	virtual void OnDetach(){Clear();}
protected:
	typedef std::list< CEffect* > obj_table_t;
	typedef obj_table_t::iterator obj_table_iter;

	obj_table_t m_effects;
};

#endif

