#ifndef __COMMON_LOGIC_H__
#define __COMMON_LOGIC_H__

#include "GameConfig.h"
#include "Fish.h"
#include "Bullet.h"

class CommonLogic
{
public:
	static CFish* CreateFish(Fish& finf, float x, float y, float dir, float delay, int speed, int pathid, bool bTroop = false, int ft = ESFT_NORMAL);

	static CBullet* CreateBullet(Bullet binf, const MyPoint& pos, float fDirection, int CannonType, int CannonMul, bool bForward = false);

	static long long  GetFishEffect(CBullet* pBullet, CFish* pFish, std::list<MyObject*>& list, bool bPretreating = false);

	static const char* ReplaceString(unsigned int wChairID, std::string& str);
};

#endif
