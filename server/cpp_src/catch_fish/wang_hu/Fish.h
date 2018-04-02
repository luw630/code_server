#ifndef __FISH_H__
#define __FISH_H__

#include "MyObject.h"
#include <tchar.h>

class CFish : public MyObject
{
public:
	CFish();
	virtual ~CFish();

	void SetBroadCast(bool bbc){m_bBroadCast = bbc;}
	bool BroadCast(){return m_bBroadCast;}

	void SetBoundingBox(int n){m_nBoundingBoxID = n;}
	int	GetBoundingBoxID(){return m_nBoundingBoxID;}

	int GetLockLevel(){return m_nLockLevel;}
	void SetLockLevel(int n){m_nLockLevel = n;}


#if _MSC_VER>1400
	void SetName(const TCHAR*  sn){_sntprintf_s(m_szName,_TRUNCATE, TEXT("%s"), sn);}
#else
	void SetName(const TCHAR*  sn){_sntprintf(m_szName, CountArray(m_szName), TEXT("%s"), sn);}
#endif
	
	TCHAR* GetName(){return m_szName;}

	void SetFishType(int type){m_FishType = type;}
	int GetFishType(){return m_FishType;}

	void SetRefershID(uint32_t id){m_nRefershID = id;}
	uint32_t GetRefershID(){return m_nRefershID;}

protected:
	bool			m_bBroadCast;                   // 可优
	int				m_nBoundingBoxID;               // 绑定身体ID
	int				m_nLockLevel;                   // 锁定等级
	TCHAR			m_szName[256];                  // 可优
	int				m_FishType;                     // 鱼类型
	uint32_t			m_nRefershID;                   // 刷新ID
};

#endif



