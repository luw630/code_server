#pragma once
#include <stdint.h>
extern "C" {
#include "lua.hpp"
#include "lauxlib.h"
#include "lualib.h"
}

class Earnings
{
public:
	static Earnings& getInstance();
	~Earnings();

	int64_t		getEarnings(){ return m_Earnings; }
	void			addEarnings(int64_t toAdd){ m_Earnings += toAdd; }
	int64_t		getRevenue(){ return m_Revenue; }
	void			addRevenue(int64_t toAdd){ m_Revenue += toAdd; }
	float			getRevenueRatio(){ return m_RevenueRatio; }
	void			onUserFire(int fireBulletMutiple);
	void			onCatchFish(int allFishScore);

	float			getProbabilityRatio(float fishMulti, int guid);

private:
	Earnings();

	int64_t	 m_Earnings = 0;
	int64_t	 m_Revenue = 0;
	float	m_RevenueRatio = 0;
	float	m_tmp_Revenue = 0.0f;
};