#ifndef __BULLET_H__
#define __BULLET_H__

#include "MyObject.h"
#include "Fish.h"
#include <map>

class CBullet : public MyObject
{
public:
	CBullet();
	virtual ~CBullet();

	void AddProbilitySet(int ftp, float pp);
	float GetProbilitySet(int ftp);

	void SetMaxCatch(int n){m_nMaxCatch = n;}
	int GetMaxCatch(){return m_nMaxCatch;}

	void SetCatchRadio(int n){m_nCatchRadio = n;}
	int	GetCatchRadio(){return m_nCatchRadio;}

	void SetCannonType(int n){m_nCannonType = n;}
	int GetCannonType(){return m_nCannonType;}

	void SetChairID(unsigned int id){m_wChairID = id;}
	unsigned int GetChairID(){return m_wChairID;}

	bool HitTest(CFish* pFish);

	bool NetCatch(CFish* pFish);

	void SetSize(int n){m_nSize = n;}
	int  GetSize(){return m_nSize;}

	virtual void OnUpdate(int msElapsed);

	bool	bDouble(){return m_bDouble;}
	void	setDouble(bool b){m_bDouble = b;}
// 	void SetInvincibility(bool b){m_bInvincibility = b;}

protected:
	std::map<int, float>	ProbabilitySet;         //概率集 可优
	int						m_nMaxCatch;            //最大抓捕
	int						m_nCatchRadio;          //抓捕半径
	int						m_nCannonType;          //炮弹类型
	unsigned int					m_wChairID;             //椅子ID
	int						m_nSize;                //子弹大小
	bool					m_bDouble;              //是否双倍
// 	bool					m_bInvincibility;
};

#endif

