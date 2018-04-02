#include "Earnings.h"
#include "catchfish.h"
#include "lua_tinker.h"

Earnings& Earnings::getInstance(){
	static Earnings* sInstance = new Earnings();
	return *sInstance;
}

Earnings::~Earnings(){

}

void Earnings::onUserFire(int fireBulletMutiple){
	m_RevenueRatio = lua_tinker::call<float>(catchfish_dll::sLuaState, "get_revenue_ratio");
	
	float this_tmp_Revenue = ((float)fireBulletMutiple) * m_RevenueRatio;
	m_tmp_Revenue += this_tmp_Revenue;
	int int_tmp_Revenue = floor(m_tmp_Revenue);
	m_tmp_Revenue -= int_tmp_Revenue;

	m_Revenue += int_tmp_Revenue;
	m_Earnings += fireBulletMutiple - int_tmp_Revenue;// ((double)fireBulletMutiple) * (1.0f - m_RevenueRatio);
}

void Earnings::onCatchFish(int allFishScore){
	m_Earnings -= allFishScore;
}


float Earnings::getProbabilityRatio(float fishMulti, int guid){
	return lua_tinker::call<float, int64_t, float>(catchfish_dll::sLuaState, "calc_storage_probability_ratio", m_Earnings, 10000.0 / fishMulti, m_Revenue, guid);
}

Earnings::Earnings(){
	m_RevenueRatio = lua_tinker::get<float>(catchfish_dll::sLuaState, "revenue_ratio");
	m_RevenueRatio = m_RevenueRatio > 1 ? 1 : m_RevenueRatio < 0 ? 0 : m_RevenueRatio;
	m_Earnings = lua_tinker::get<int64_t>(catchfish_dll::sLuaState, "ly_robot_storage");
}
