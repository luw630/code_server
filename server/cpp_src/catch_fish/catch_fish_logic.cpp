//
#include "common.h"
#include "catch_fish_logic.h"
#include "GameConfig.h"
#include "MathAide.h"
#include "GameConfig.h"
#include "CommonLogic.h"
#include "PathManager.h"
#include "EventMgr.h"
#include <math.h>
#include <MMSystem.h>
#include "IDGenerator.h"
#include "BufferManager.h"
#include "MyComponentFactory.h"
#include "base_game_log.h"
#include "Earnings.h"
#include "catchfish.h"
#include <codecvt>
#include <iostream>



//构造函数
catch_fish_logic::catch_fish_logic(){
	m_nFishCount = 0;
	ResetTable();
}

//析构函数
catch_fish_logic::~catch_fish_logic(void){
	ResetTable();
}

void catch_fish_logic::OnTest(){
	vector<int>	counts;
	counts.resize(10, 0);
	for (int i = 1; i < 1000000; i++){
		counts[rand() % 10]++;
	}

	for (int i = 0; i < 10; i++){
		std::cout << i << " " << counts[i] << std::endl;
	}
}

//初始化
bool  catch_fish_logic::Initialization(lua_tinker::table luaTable){
	m_TableID		= luaTable.get<int>("table_id_");
	m_RoomID	= luaTable.get<lua_tinker::table>("room_").get<int>("id");

	Bind_Event_Handler("ProduceFish", catch_fish_logic, OnProduceFish);
	Bind_Event_Handler("CannonSetChanaged", catch_fish_logic, OnCannonSetChange);
	Bind_Event_Handler("AddBuffer", catch_fish_logic, OnAddBuffer);
	Bind_Event_Handler("CatchFishBroadCast", catch_fish_logic, OnCatchFishBroadCast);
	Bind_Event_Handler("FirstFire", catch_fish_logic, OnFirstFire);
	Bind_Event_Handler("AdwardEvent", catch_fish_logic, OnAdwardEvent);
	Bind_Event_Handler("FishMulChange", catch_fish_logic, OnMulChange);

	m_UserWinScore.clear();

	return true;
}

void catch_fish_logic::LoadConfig(){
	int game_id = lua_tinker::get<int>(catchfish_dll::sLuaState, "def_game_id");
	std::string path = (boost::format("../data/catch_fish/%1%/") % game_id).str();
    std::cout<< "开始加载配置..." << std::endl;
	uint32_t dwStartTick = ::GetTickCount();

	CGameConfig::GetInstance()->LoadSystemConfig(path + "System.xml");
	CGameConfig::GetInstance()->LoadBoundBox(path + "BoundingBox.xml");
	CGameConfig::GetInstance()->LoadFish(path + "Fish.xml");
	PathManager::GetInstance()->LoadNormalPath(path + "path.xml");
	PathManager::GetInstance()->LoadTroop(path + "TroopSet.xml");
	CGameConfig::GetInstance()->LoadCannonSet(path + "CannonSet.xml");
	CGameConfig::GetInstance()->LoadBulletSet(path + "BulletSet.xml");
	CGameConfig::GetInstance()->LoadScenes(path + "Scene.xml");
	CGameConfig::GetInstance()->LoadSpecialFish(path + "Special.xml");

    dwStartTick = ::GetTickCount() - dwStartTick;
	std::cout << "加载完成 配置 总计耗时" << dwStartTick / 1000.f << "秒" << std::endl;
}

//重置桌子
void catch_fish_logic::ResetTable(){
	m_FishManager.Clear();
	m_BulletManager.Clear();
	m_fPauseTime = 0.0f;
	m_nSpecialCount = 0;
	m_nFishCount = 0;
	m_ChairPlayers.clear();
	m_GuidPlayers.clear();
}

//用户坐下
bool catch_fish_logic::OnActionUserSitDown(unsigned int wChairID, lua_tinker::table player)
{
	delete_invalid_player();
	std::cout << "catch_fish_logic::OnActionUserSitDown:" << wChairID << std::endl;
	int		Guid = player.get<int>("guid");
	m_GuidPlayers[Guid].ClearSet(wChairID);
	m_GuidPlayers[Guid].FromLua(player);
	m_ChairPlayers[wChairID] = &m_GuidPlayers[Guid];

	m_UserWinScore[wChairID] = 0;
        
	//获取BUFF管理器
	BufferMgr* pBMgr = (BufferMgr*)m_GuidPlayers[Guid].GetComponent(ECF_BUFFERMGR);
	if (pBMgr == NULL){
		pBMgr = (BufferMgr*)CreateComponent(EBCT_BUFFERMGR);
		if (pBMgr != NULL){
			m_GuidPlayers[Guid].SetComponent(pBMgr);
		}
	}

	if (pBMgr == NULL){
		return false;
	}

	pBMgr->Clear();
	return true;
}

//用户起立
bool  catch_fish_logic::OnActionUserStandUp(lua_tinker::table player, int is_offline){
	delete_invalid_player();
	int Guid = player.get<int>("guid");
	uint32_t wChairID = player.get<uint32_t>("chair_id");
	
	// 更新用户信息到数据库
	ReturnBulletScore(Guid);

	lua_tinker::call<void, int>(catchfish_dll::sLuaState, "player_exit_fish", Guid);

	m_UserWinScore[wChairID] = 0;
	
	auto iterChair = m_ChairPlayers.find(wChairID);
	if (iterChair != m_ChairPlayers.end()){
		m_ChairPlayers.erase(iterChair);
	}

	auto iterGuid = m_GuidPlayers.find(Guid);
	if (iterGuid != m_GuidPlayers.end()){
		m_GuidPlayers.erase(iterGuid);
	}

	if (m_GuidPlayers.empty()){
		ResetTable();
	}

	return true;
}

//游戏开始
bool  catch_fish_logic::OnEventGameStart()
{
	delete_invalid_player();
	ResetTable();

	m_dwLastTick = timeGetTime();
	m_dwLastSave = timeGetTime();
	m_nCurScene = CGameConfig::GetInstance()->SceneSets.begin()->first;
	m_fSceneTime = 0.0f;
	m_fPauseTime = 0.0f;
	m_bAllowFire = false;

	ResetSceneDistrub();

	//初始化随机种子
	RandSeed(timeGetTime());
	srand(timeGetTime());

    //m_Timer.expires_from_now(boost::posix_time::millisec(1000 / 30));
    //m_Timer.async_wait(boost::bind(&catch_fish_logic::OnGameUpdate, this));
	return true;
}
//重置场景
void catch_fish_logic::ResetSceneDistrub()
{
	//重置干扰鱼群刷新时间
	int sn = CGameConfig::GetInstance()->SceneSets[m_nCurScene].DistrubList.size();
	m_vDistrubFishTime.resize(sn);
	for (int i = 0; i < sn; ++i)
	{
		m_vDistrubFishTime[i] = 0;
	}

	//重置鱼群
	//获取场景刷新鱼时间组数
	sn = CGameConfig::GetInstance()->SceneSets[m_nCurScene].TroopList.size();
	m_vDistrubTroop.resize(sn);//设置刷新鱼信息大小
	//初始化刷新信息
	for (int i = 0; i < sn; ++i)
	{
		m_vDistrubTroop[i].bSendDes = false;
		m_vDistrubTroop[i].bSendTroop = false;
		m_vDistrubTroop[i].fBeginTime = 0.0f;
	}
}

//结束原因
#define GER_NORMAL					0x00								//常规结束
#define GER_DISMISS					0x01								//游戏解散
#define GER_USER_LEAVE				0x02								//用户离开
#define GER_NETWORK_ERROR			0x03								//网络错误

//游戏结束
bool  catch_fish_logic::OnEventGameConclude(lua_tinker::table player, BYTE cbReason)
{
	delete_invalid_player();
	int Guid = player.get<int>("guid");
	uint32_t wChairID = player.get<uint32_t>("chair_id");
	switch (cbReason)
	{
	case GER_NORMAL:
	case GER_USER_LEAVE:
	case GER_NETWORK_ERROR:
	{
		//单个玩家，网络退出
		//ReturnBulletScore(Guid);
		m_GuidPlayers[Guid].ClearSet(wChairID);
		m_GuidPlayers[Guid].SetGuidGateID(0, 0);

		return true;
	}
	case GER_DISMISS:
	{   //所有玩家退出 清除所有信息
		for (auto& iter : m_ChairPlayers){
			ReturnBulletScore(Guid);
			iter.second->ClearSet(iter.first - 1);
			iter.second->SetGuidGateID(0, 0);
		}
		return true;
	}
	}
	return false;
}

//发送场景
bool  catch_fish_logic::OnEventSendGameScene(lua_tinker::table player, BYTE cbGameStatus, bool bSendSecret)
{
	delete_invalid_player();
	uint32_t wChairID = player.get<uint32_t>("chair_id");
	int GuID = player.get<int>("guid");
    if (GuID == 0){
        return false;
    }

	switch (cbGameStatus)
	{
	case GAME_STATUS_FREE:
	case GAME_STATUS_PLAY:
	{
		SendGameConfig(GuID);
		SendPlayerInfo(0);
		SendAllowFire(0);
		for (auto& iter : m_ChairPlayers){
			SendCannonSet(iter.first);
		}
		SendSceneInfo(GuID);
		
		
		char szInfo[1024] = {0};
		sprintf_s(szInfo, "当前房间的游戏币与渔币的兑换比例为%d游戏币兑换%d渔币", 
			CGameConfig::GetInstance()->nChangeRatioUserScore, CGameConfig::GetInstance()->nChangeRatioFishScore);

		SendSystemMsg(GuID, SMT_CHAT, szInfo);

		return true;
	}
	}
	return false;
}

bool catch_fish_logic::OnReady(uint32_t wChairID){
	delete_invalid_player();
	SendFishList(wChairID);
	return true;
}

//发送游戏系统配置
void catch_fish_logic::SendGameConfig(int guid)
{
	SC_GameConfig css;
	css.set_server_id(1);
	css.set_change_ratio_fish_score(CGameConfig::GetInstance()->nChangeRatioFishScore);
	css.set_change_ratio_user_score(CGameConfig::GetInstance()->nChangeRatioUserScore);
	css.set_exchange_once(CGameConfig::GetInstance()->nExchangeOnce);
	css.set_fire_interval(CGameConfig::GetInstance()->nFireInterval);
	css.set_max_interval(CGameConfig::GetInstance()->nMaxInterval);
	css.set_min_interval(CGameConfig::GetInstance()->nMinInterval);
	css.set_show_gold_min_mul(CGameConfig::GetInstance()->nShowGoldMinMul);
	css.set_max_bullet_count(CGameConfig::GetInstance()->nMaxBullet);
	css.set_max_cannon(CGameConfig::GetInstance()->m_MaxCannon);

	SendTo_pb(guid, css);

	int i = 0;
	SC_BulletSet_List tbBulletList;
	for (auto& iter : CGameConfig::GetInstance()->BulletVector){
		SC_BulletSet* tb = tbBulletList.add_pb_bullets();
		tb->set_first(i == 0 ? 1 : 0);
		tb->set_bullet_size(iter.nBulletSize);
		tb->set_cannon_type(iter.nCannonType);
		tb->set_catch_radio(iter.nCatchRadio);
		tb->set_max_catch(iter.nMaxCatch);
		tb->set_mulriple(iter.nMulriple);
		tb->set_speed(iter.nSpeed);
		//if (i == 0)
		//{
		//	printf("mulriple %d\n", tb->mulriple());
		//}
	}
	
	SendTo_pb(guid, tbBulletList);
}

void catch_fish_logic::SendSystemMsg(int guid,int type, const std::string& msg){
	//std::wstring_convert<std::codecvt<wchar_t, char, mbstate_t>> mb_conv_ucs;
	//std::wstring test = mb_conv_ucs.from_bytes(msg);

	//std::wstring_convert<std::codecvt_utf8<wchar_t>> conv;
	//std::string narrowStr = conv.to_bytes(test);

	//lua_tinker::table table(catchfish_dll::sLuaState);
	//table.set("wType", SMT_CHAT);
	//table.set("szString", narrowStr.c_str());
	//SendTo(guid, "SC_SystemMessage", table);
}

//发送玩家信息
void catch_fish_logic::SendPlayerInfo(int TargetGuid){
	for (auto iter:m_ChairPlayers){
		SC_UserInfo tinfo;
		tinfo.set_chair_id(iter.first);
		tinfo.set_score(iter.second->GetScore());
		tinfo.set_cannon_mul(iter.second->GetMultiply());
		tinfo.set_cannon_type(iter.second->GetCannonType());
		tinfo.set_wastage(iter.second->GetWastage());
		SendTo_pb(TargetGuid, tinfo);
	}
}


int    catch_fish_logic::GetFirstPlayerGuID(){
	if (m_GuidPlayers.empty()){
		return 0;
	}

	return m_GuidPlayers.begin()->second.GetGuid();
}
//发送场景信息
void catch_fish_logic::SendSceneInfo(int GuID)
{
	uint32_t wChairID = m_GuidPlayers[GuID].GetChairID();
    {
		SC_SwitchScene tinfo;
		tinfo.set_switching(0);
		tinfo.set_nst(m_nCurScene);
		SendTo_pb(GuID, tinfo);
    }

	m_BulletManager.Lock();
	for (auto iter = m_BulletManager.Begin(); iter != m_BulletManager.End(); ++iter){
		SendBullet((CBullet*)iter->second);
	}
	m_BulletManager.Unlock();

	m_FishManager.Lock();
	for (auto iter = m_FishManager.Begin(); iter != m_FishManager.End();++iter){
		SendFish((CFish*)iter->second, wChairID);
	}
	m_FishManager.Unlock();
}

//发送是否允许开火
void catch_fish_logic::SendAllowFire(int GuID)
{
	SC_AllowFire tinfo;
	tinfo.set_allow_fire(m_bAllowFire ? 1 : 0);
	SendTo_pb(GuID, tinfo);
}

void catch_fish_logic::delete_invalid_player()
{
	while (true)
	{
		bool find_nil = false;
		for (auto& iter : m_ChairPlayers){
			if (iter.second == nullptr){
				char bbb[128] = { 0 };
				sprintf(bbb, "OnGameUpdate  nil player, chair id %d", iter.first);
				lua_tinker::call<void>(catchfish_dll::sLuaState, "log_error", bbb);
				m_ChairPlayers.erase(iter.first);
				find_nil = true;
				break;
			}
		}
		if (!find_nil)
		{
			break;
		}
	}
}
//游戏状态更新
void catch_fish_logic::OnGameUpdate()
{
	delete_invalid_player();
	uint32_t NowTime = timeGetTime();
	int ndt = NowTime - m_dwLastTick;
	float fdt = ndt / 1000.0f;

	bool hasR = HasRealPlayer();

	
	
	for (auto& iter:m_ChairPlayers){
		if (iter.second->GetGuid() == 0){
			continue;
		}

		//处理玩家事件
		iter.second->OnUpdate(ndt);
		//有玩家存在且玩家锁定了鱼
		if (iter.second->bLocking()){
			//当玩家锁定鱼时判断鱼ID，是否存在
			if (iter.second->GetLockFishID() == 0){
				//ID= 0 重新锁定
				LockFish(iter.second->GetChairID());
				if (iter.second->GetLockFishID() == 0){
					iter.second->SetLocking(false);
				}
			}else{
				CFish* pFish = (CFish*)m_FishManager.Find(iter.second->GetLockFishID());
				if (pFish == NULL || !pFish->InSideScreen()){//当鱼不存在或鱼已经出屏幕，重新锁定
					LockFish(iter.second->GetChairID());
					if (iter.second->GetLockFishID() == 0){
						iter.second->SetLocking(false);
					}
				}
			}
		}
	}
	//清理可锁定列表
	m_CanLockList.clear();
	//清理鱼数量
	m_nFishCount = 0;

	//移除队列
	std::list<uint32_t> rmList;
	//特殊鱼清0
	m_nSpecialCount = 0;

	m_FishManager.Lock();

	for (obj_table_iter ifs = m_FishManager.Begin(); ifs != m_FishManager.End(); ++ifs){
		CFish* pFish = (CFish*)ifs->second;
		//处理鱼事件
		pFish->OnUpdate(ndt);
		MoveCompent* pMove = (MoveCompent*)pFish->GetComponent(ECF_MOVE);
		if (pMove == NULL || pMove->IsEndPath()){//移动组件为空或 已经移动到结束
			if (pMove != NULL && pFish->InSideScreen()){//移动组件存且移动结束，但还在屏幕内 改为按指定方向移动
				MoveCompent* pMove2 = (MoveCompent*)CreateComponent(EMCT_DIRECTION);
				if (pMove2 != NULL){
					pMove2->SetSpeed(pMove->GetSpeed());
					pMove2->SetDirection(pMove->GetDirection());
					pMove2->SetPosition(pMove->GetPostion());
					pMove2->InitMove();
					//SetComponent有清除旧组件功能
					pFish->SetComponent(pMove2);
				}
			}else{//否则添加到移除列表
				rmList.push_back(pFish->GetId());
			}
		}else if (pFish->GetFishType() != ESFT_NORMAL){//钱类型不等于普通鱼 特殊鱼+1
			++m_nSpecialCount;
		}

		if (hasR && pFish->InSideScreen()){
			//还在屏幕内
			if (pFish->GetLockLevel() > 0){//锁定等级大于0 加入可锁定列表
				m_CanLockList.push_back(pFish->GetId());
			}

			//鱼数量+1
			++m_nFishCount;
		}
	}

	m_FishManager.Unlock();

	//清除鱼
	
	for (std::list<uint32_t>::iterator it = rmList.begin(); it != rmList.end(); it++){
		lua_tinker::call<void>(catchfish_dll::sLuaState, "on_fish_removed",m_RoomID,m_TableID, *it);
		m_FishManager.Remove(*it);
	}

	rmList.clear();

	m_BulletManager.Lock();
	for (obj_table_iter ibu = m_BulletManager.Begin(); ibu != m_BulletManager.End();++ibu){
		CBullet* pBullet = (CBullet*)ibu->second;
		//处理子弹事件
		pBullet->OnUpdate(ndt);
		//获取移动组件
		MoveCompent* pMove = (MoveCompent*)pBullet->GetComponent(ECF_MOVE);
		if (pMove == NULL || pMove->IsEndPath()){//当没有移动组件或已经移动到终点 加入到清除列表
			rmList.push_back(pBullet->GetId());
		}
		//不需要直接判断？
		else if (CGameConfig::GetInstance()->bImitationRealPlayer && !hasR){//如果开起模拟 且 无玩家？
			int GuID = GetFirstPlayerGuID();
			for (auto ifs = m_FishManager.Begin(); ifs != m_FishManager.End();++ifs){
				CFish* pFish = (CFish*)ifs->second;
				//只要鱼没死 判断 是否击中鱼
				if (pFish->GetState() < EOS_DEAD && pBullet->HitTest(pFish)){
					//发送清除子弹
                    if (GuID != 0){
						SC_KillBullet tinfo;
						tinfo.set_chair_id(pBullet->GetChairID());
						tinfo.set_bullet_id(pBullet->GetId());
						SendTo_pb(0, tinfo);
                    }
					//抓捕鱼   //抓住后 Remove 不会破坏ifs？
					CatchFish(pBullet, pFish, 1, 0);
					//子弹加入清除列表
					rmList.push_back(pBullet->GetId());
					break;
				}
			}
		}
	}

	m_BulletManager.Unlock();

	for (auto it = rmList.begin(); it != rmList.end();++it){
		m_BulletManager.Remove(*it);
	}
	rmList.clear();

	uint32_t tEvent = timeGetTime();
	CEventMgr::GetInstance()->Update(ndt);
	tEvent = timeGetTime() - tEvent;

	//场景处理包换刷新鱼
	DistrubFish(fdt);

	m_dwLastTick = NowTime;
	if (NowTime - m_dwLastSave > 10* 1000)
	{
		m_dwLastSave = NowTime;
		for (auto iter = m_GuidPlayers.begin(); iter != m_GuidPlayers.end(); iter++)
		{
			if (iter->first&&m_UserWinScore[iter->second.GetChairID()]!=0)
			{
				// 更新用户信息到数据库
				ReturnBulletScore(iter->first);
				m_UserWinScore[iter->second.GetChairID()] = 0;
			}
		}
	}

}
//判断是否有玩家在
bool catch_fish_logic::HasRealPlayer(){
	return m_ChairPlayers.size() > 0;
}
//抓捕鱼
void catch_fish_logic::CatchFish(CBullet* pBullet, CFish* pFish, int nCatch, int* nCatched)
{
	delete_invalid_player();
	//获取子弹 对鱼类型的概率值
	float pbb = pBullet->GetProbilitySet(pFish->GetTypeID()) / MAX_PROBABILITY;
	//获取鱼被抓捕概率值
	float pbf = pFish->GetProbability() / nCatch;
	//设置倍率
	float fPB = 1.0f;

	//获取安卓增加值
	fPB = CGameConfig::GetInstance()->fAndroidProbMul;

	std::list<MyObject*> list;      //存放被捕捉鱼 解除其它玩家锁定用

	int64_t lScore = 0;           //价值积分
	auto chair_id = pBullet->GetChairID();  //获取子弹所属玩家

	static std::vector<int>	counts(MAX_PROBABILITY, 0);
	static int	randCount = 0;

	//判断是否抓到（子弹抓这类鱼的概率*这类鱼被抓的概率*倍率 * 库存控制倍率）
	float probStorageControl = Earnings::getInstance().getProbabilityRatio((double)pFish->GetProbability(), m_ChairPlayers[chair_id]->GetGuid());
	int	 realProbV = (pbb * pbf * fPB * probStorageControl) ;

	int  randV = RandInt(0, MAX_PROBABILITY);
	bool bCatch = randV < realProbV;
	if (!bCatch){
		return;
	}

	//抓到，执行鱼被抓效果
	lScore = CommonLogic::GetFishEffect(pBullet, pFish, list, false);

	if (m_ChairPlayers.find(pBullet->GetChairID()) == m_ChairPlayers.end()){
		std::cout << "遗留子弹打中鱼" << std::endl;
		return;
	}


	Earnings::getInstance().onCatchFish(lScore);
	m_UserWinScore[chair_id] += lScore;
	m_ChairPlayers[chair_id]->AddScore(lScore);

	//能量炮 当鱼的值/炮弹值 大于 能量炮机率 且 随机值 小于能量炮率 为玩家获取双倍炮BUFF
	if (lScore / pBullet->GetScore() > CGameConfig::GetInstance()->nIonMultiply && 
		RandInt(0, MAX_PROBABILITY) < CGameConfig::GetInstance()->nIonProbability){
		BufferMgr* pBMgr = (BufferMgr*)m_ChairPlayers[pBullet->GetChairID()]->GetComponent(ECF_BUFFERMGR);
		if (pBMgr != NULL && !pBMgr->HasBuffer(EBT_DOUBLE_CANNON)){
			pBMgr->Add(EBT_DOUBLE_CANNON, 0, CGameConfig::GetInstance()->fDoubleTime);
			SendCannonSet(pBullet->GetChairID());
		}
	}

	SendCatchFish(pBullet, pFish, lScore);
	char log_buff[256] = {0};
	sprintf(log_buff, "player %d catch fish %d,score is %d,prob is %f,storage is %ld, scale is %d",
		m_ChairPlayers[chair_id]->GetGuid(), pFish->GetTypeID(), int(lScore), probStorageControl, Earnings::getInstance().getEarnings(), lScore / pBullet->GetScore());
	lua_tinker::call<void>(catchfish_dll::sLuaState, "log_info", log_buff);

	//解除其它玩家锁定的鱼
	for (std::list<MyObject*>::iterator im = list.begin(); im != list.end();++im){
		CFish* pf = (CFish*)*im;
		for (auto& iter:m_ChairPlayers){
			if (iter.second->GetLockFishID() == pf->GetId()){
				iter.second->SetLockFishID(0);
			}
		}

		if (pf != pFish){
			lua_tinker::call<void>(catchfish_dll::sLuaState, "on_fish_removed", m_RoomID, m_TableID, pf->GetId());
			m_FishManager.Remove(pf);
		}
	}

	lua_tinker::table table(catchfish_dll::sLuaState);
	table.set("table_id", m_TableID);
	table.set("room_id", m_RoomID);
	table.set("fish_id", pFish->GetId());
	table.set("multi", lScore / pBullet->GetScore());
	table.set("score", lScore);
	table.set("player_guid", m_ChairPlayers[chair_id]->GetGuid());
	lua_tinker::call<void>(catchfish_dll::sLuaState, "on_catch_fish",  table);

	//移除鱼
	lua_tinker::call<void>(catchfish_dll::sLuaState, "on_fish_removed", m_RoomID, m_TableID, pFish->GetId());
	m_FishManager.Remove(pFish);

	//用处不明 调用全为空 可优
	if (nCatched != NULL){
		*nCatched = *nCatched + 1;
	}
}
//发送鱼被抓
void catch_fish_logic::SendCatchFish(CBullet* pBullet, CFish*pFish, long long  score)
{
	int GuID = GetFirstPlayerGuID();
	if (GuID <= 0){
        return;
    }

	if (pBullet == NULL || pFish == NULL){
		return;
	}

	SC_KillFish tinfo;
	tinfo.set_chair_id(pBullet->GetChairID());
	tinfo.set_fish_id(pFish->GetId());
	tinfo.set_score(score);
	tinfo.set_bscoe(pBullet->GetScore());
	SendTo_pb(0, tinfo);
}
//给所有鱼添加BUFF
void catch_fish_logic::AddBuffer(int btp, float parm, float ft)
{
	int GuID = GetFirstPlayerGuID();
	if (GuID > 0){
		SC_AddBuffer tinfo;
		tinfo.set_buffer_type(btp);
		tinfo.set_buffer_param(parm);
		tinfo.set_buffer_time(ft);
		SendTo_pb(0, tinfo);
    }

	m_FishManager.Lock();
	obj_table_iter ifs = m_FishManager.Begin();
	while (ifs != m_FishManager.End()){
		MyObject* pObj = ifs->second;
		BufferMgr* pBM = (BufferMgr*)pObj->GetComponent(ECF_BUFFERMGR);
		if (pBM != NULL){
			pBM->Add(btp, parm, ft);
		}
		++ifs;
	}
	m_FishManager.Unlock();
}
//场景处理 包括场景更换 鱼刷新
void catch_fish_logic::DistrubFish(float fdt)
{
	if (m_fPauseTime > 0.0f){
		m_fPauseTime -= fdt;
		return;
	}
	//场景时间增加
	m_fSceneTime += fdt;
	//时间大于场景准备时间，且不可开火 INVALID_CHAIR群发可开火命令 可优，是否应该出现在此处改为时间回调
	if (m_fSceneTime > SWITCH_SCENE_END && !m_bAllowFire){
		m_bAllowFire = true;
		SendAllowFire(-1);
	}

	//判断当前场景是否存在
	if (CGameConfig::GetInstance()->SceneSets.find(m_nCurScene) == CGameConfig::GetInstance()->SceneSets.end()){
		return;
	}

	//场景时间是否小于场景持续时间
	if (m_fSceneTime < CGameConfig::GetInstance()->SceneSets[m_nCurScene].fSceneTime){
		int npos = 0;
		//获取当前场景的刷鱼时间列表
		for (TroopSet &ts:CGameConfig::GetInstance()->SceneSets[m_nCurScene].TroopList){
			//是否无玩家存在
			if (!HasRealPlayer()){
				//当场景时间　是否为刷鱼时间　
				if ((m_fSceneTime >= ts.fBeginTime) && (m_fSceneTime <= ts.fEndTime)){
					//是则置为刷鱼结束时间
					m_fSceneTime = ts.fEndTime + fdt;
				}
			}

			//当场景时间　是否为刷鱼时间　
			if ((m_fSceneTime >= ts.fBeginTime) && (m_fSceneTime <= ts.fEndTime)){
				//当循环小于刷新鱼信息数量
				if (npos < m_vDistrubTroop.size()){
					int tid = ts.nTroopID;
					//是否发送描述 可优 描述无需发送吧
					if (!m_vDistrubTroop[npos].bSendDes){
						//给所有鱼加速度BUFF
						AddBuffer(EBT_CHANGESPEED, 5, 60);
						//获取刷新鱼群描述信息
						Troop* ptp = PathManager::GetInstance()->GetTroop(tid);
						if (ptp != NULL){
							//获取总描述数量
							size_t nCount = ptp->Describe.size();
							//大于4条则只发送4条
							if (nCount > 4) nCount = 4;
							//配置刷新时间开始时间 为 2秒
							m_vDistrubTroop[npos].fBeginTime = nCount * 2.0f;//每条文字分配2秒的显示时间

                            //发送描述  可优 改为发送ID
							SC_SendDes tinfo;
							for (int i = 0; i < nCount; ++i){
								tinfo.add_des(ptp->Describe[i]);
							}
							BroadCast_pb(tinfo);
						}
						//设置为已发送
						m_vDistrubTroop[npos].bSendDes = true;
					}else if (!m_vDistrubTroop[npos].bSendTroop && 
						m_fSceneTime > (m_vDistrubTroop[npos].fBeginTime + ts.fBeginTime)){//如果没有发送过鱼群且 场景时间 大于 刷新时间加描述滚动时间
						m_vDistrubTroop[npos].bSendTroop = true;
						//获取刷新鱼群描述信息
						Troop* ptp = PathManager::GetInstance()->GetTroop(tid);
						if (ptp == NULL){
							//如果为空，则换下一场景
							m_fSceneTime += CGameConfig::GetInstance()->SceneSets[m_nCurScene].fSceneTime;
						}else{
							int n = 0;
							int ns = ptp->nStep.size();    //获取步数 意义不明
							for (int i = 0; i < ns; ++i){
								//刷鱼的ID
								int Fid = -1;
								//获取总步数
								int ncount = ptp->nStep[i];
								for (int j = 0; j < ncount; ++j){
									//n大于 总形状点时 退出循环
									if (n >= ptp->Shape.size()) break;
									//获取形状点
									ShapePoint& tp = ptp->Shape[n++];
									//总权重
									int WeightCount = 0;
									//获取鱼类型列表和权重列表最小值
									int nsz = min(tp.m_lTypeList.size(), tp.m_lWeight.size());
									//如果为0就跳过本次
									if (nsz == 0) continue;
									//获取总权重
									for (int iw = 0; iw < nsz; ++iw){
										WeightCount += tp.m_lWeight[iw];
									}

									for (int ni = 0; ni < tp.m_nCount; ++ni){
										if (Fid == -1 || !tp.m_bSame){
											//第几个鱼目标
											int wpos = 0;
											//随机权重
											int nf = RandInt(0, WeightCount);
											//运算匹配的权重
											while (nf > tp.m_lWeight[wpos]){
												//大于或等于权重最大值就跳出
												if (wpos >= tp.m_lWeight.size()) break;
												//随机值减去当前权重
												nf -= tp.m_lWeight[wpos];
												//目标加1
												++wpos;
												//如果大于鱼类型列表 
												if (wpos >= nsz){
													wpos = 0;
												}
											}
											//随机位置小于鱼列表 获取 鱼ID
											if (wpos < tp.m_lTypeList.size()){
												Fid = tp.m_lTypeList[wpos];
											}
										}

										//查找鱼
										std::map<int, Fish>::iterator ift = CGameConfig::GetInstance()->FishMap.find(Fid);
										if (ift != CGameConfig::GetInstance()->FishMap.end()){
											Fish &finf = ift->second;
											CFish* pFish = CommonLogic::CreateFish(finf, tp.x, tp.y, 0.0f, ni*tp.m_fInterval, tp.m_fSpeed, tp.m_nPathID, true);
											if (pFish != NULL){
												m_FishManager.Add(pFish);
												SendFish(pFish);
											}
										}
									}
								}
							}
						}
					}
				}
				return;
			}

			++npos;
		}


		//如果场景时间大于 场景开始选择时间
		if (m_fSceneTime > SWITCH_SCENE_END)
		{
			int nfpos = 0;
			//获取干扰鱼列表
			std::list<DistrubFishSet>::iterator it = CGameConfig::GetInstance()->SceneSets[m_nCurScene].DistrubList.begin();
			while (it != CGameConfig::GetInstance()->SceneSets[m_nCurScene].DistrubList.end())
			{
				//当前场景 干扰鱼群集
				DistrubFishSet &dis = *it;

				if (nfpos >= m_vDistrubFishTime.size())
				{
					break;
				}
				m_vDistrubFishTime[nfpos] += fdt;
				//[nfpos]干扰鱼刷新时间 加上 当前时间跳动时间 大于刷新时间
				if (m_vDistrubFishTime[nfpos] > dis.ftime)
				{
					//清除一个刷新时间
					m_vDistrubFishTime[nfpos] -= dis.ftime;
					//是否当前有玩家在
					if (HasRealPlayer())
					{
						//获取权重和鱼列表最小值
						int nsz = min(dis.Weight.size(), dis.FishID.size());
						//总权重
						int WeightCount = 0;
						//刷新鱼数量    随机一个刷新最小值到最大值
						int nct = RandInt(dis.nMinCount, dis.nMaxCount);
						//总刷新数量
						int nCount = nct;
						//蛇类型？
						int SnakeType = 0;
						//类型是否等于大蛇 刷新数量加2
						if (dis.nRefershType == ERT_SNAK)
						{
							nCount += 2;
							nct += 2;
						}

						//获取一个刷新ID
						uint32_t nRefershID = IDGenerator::GetInstance()->GetID64();

						//获取总权重
						for (int wi = 0; wi < nsz; ++wi)
							WeightCount += dis.Weight[wi];

						//鱼与权重必须大于1
						if (nsz > 0)
						{
							//鱼ID
							int ftid = -1;
							//获取一个普通路径ID
							int pid = PathManager::GetInstance()->GetRandNormalPathID();
							while (nct > 0)
							{
								//普通鱼
								if (ftid == -1 || dis.nRefershType == ERT_NORMAL)
								{
									if (WeightCount == 0)
									{//权重为0 
										ftid = dis.FishID[0];
									}
									else
									{
										//权重随机
										int wpos = 0, nw = RandInt(0, WeightCount);
										while (nw > dis.Weight[wpos])
										{
											if (wpos < 0 || wpos >= dis.Weight.size()) break;
											nw -= dis.Weight[wpos];
											++wpos;
											if (wpos >= nsz)
												wpos = 0;
										}
										if (wpos >= 0 || wpos < dis.FishID.size())
											ftid = dis.FishID[wpos];
									}

									SnakeType = ftid;
								}
								//如果是刷大蛇，获取头和尾
								if (dis.nRefershType == ERT_SNAK)
								{
									if (nct == nCount)
										ftid = CGameConfig::GetInstance()->nSnakeHeadType;
									else if (nct == 1)
										ftid = CGameConfig::GetInstance()->nSnakeTailType;
								}
								//查找鱼
								std::map<int, Fish>::iterator ift = CGameConfig::GetInstance()->FishMap.find(ftid);
								if (ift != CGameConfig::GetInstance()->FishMap.end())
								{
									Fish &finf = ift->second;
									//类型普通
									int FishType = ESFT_NORMAL;
									//随机偏移值
									float xOffest = RandFloat(-dis.OffestX, dis.OffestX);
									float yOffest = RandFloat(-dis.OffestY, dis.OffestY);
									//随机延时时间
									float fDelay = RandFloat(0.0f, dis.OffestTime);
									//如果是线或大蛇 则不随机
									if (dis.nRefershType == ERT_LINE || dis.nRefershType == ERT_SNAK)
									{
										xOffest = dis.OffestX;
										yOffest = dis.OffestY;
										fDelay = dis.OffestTime * (nCount - nct);
									}
									else if (dis.nRefershType == ERT_NORMAL && m_nSpecialCount < CGameConfig::GetInstance()->nMaxSpecailCount)
									{
										std::map<int, SpecialSet>* pMap = NULL;
										//试着随机到谋一种特殊鱼
										int nrand = rand() % 100;
										int fft = ESFT_NORMAL;

										if (nrand < CGameConfig::GetInstance()->nSpecialProb[ESFT_KING])
										{
											pMap = &(CGameConfig::GetInstance()->KingFishMap);
											fft = ESFT_KING;
										}
										else
										{
											nrand -= CGameConfig::GetInstance()->nSpecialProb[ESFT_KING];
										}

										if (nrand < CGameConfig::GetInstance()->nSpecialProb[ESFT_KINGANDQUAN])
										{
											pMap = &(CGameConfig::GetInstance()->KingFishMap);
											fft = ESFT_KINGANDQUAN;
										}
										else
										{
											nrand -= CGameConfig::GetInstance()->nSpecialProb[ESFT_KINGANDQUAN];
										}

										if (nrand < CGameConfig::GetInstance()->nSpecialProb[ESFT_SANYUAN])
										{
											pMap = &(CGameConfig::GetInstance()->SanYuanFishMap);
											fft = ESFT_SANYUAN;
										}
										else
										{
											nrand -= CGameConfig::GetInstance()->nSpecialProb[ESFT_SANYUAN];
										}

										if (nrand < CGameConfig::GetInstance()->nSpecialProb[ESFT_SIXI])
										{
											pMap = &(CGameConfig::GetInstance()->SiXiFishMap);
											fft = ESFT_SIXI;
										}
										//判断是否随机到特殊鱼
										if (pMap != NULL)
										{
											std::map<int, SpecialSet>::iterator ist = pMap->find(ftid);
											if (ist != pMap->end())
											{
												SpecialSet& kks = ist->second;
												//对特殊鱼进行随机判断是否生成
												if (RandFloat(0, MAX_PROBABILITY) < kks.fProbability)
													FishType = fft;
											}
										}
									}
									//生成鱼
									CFish* pFish = CommonLogic::CreateFish(finf, xOffest, yOffest, 0.0f, fDelay, finf.nSpeed, pid, false, FishType);
									if (pFish != NULL)
									{
										//设置鱼ID
										pFish->SetRefershID(nRefershID);
										m_FishManager.Add(pFish);
										SendFish(pFish);
									}
								}

								if (ftid == CGameConfig::GetInstance()->nSnakeHeadType)
									ftid = SnakeType;

								--nct;
							}
						}
					}
				}
				++it;
				++nfpos;
			}
		}
	}
	else
	{//当场景时间大于场景持续时间 切换场景
		//获取下一场景ID 并判断是否存在
		int nex = CGameConfig::GetInstance()->SceneSets[m_nCurScene].nNextID;
		if (CGameConfig::GetInstance()->SceneSets.find(nex) != CGameConfig::GetInstance()->SceneSets.end())
		{
			m_nCurScene = nex;
		}
		//重置场景
		ResetSceneDistrub();
		//清除玩家 锁定鱼 及锁定状态 子弹
        int GuID = 0;
		for (auto& iter:m_ChairPlayers)
		{
			iter.second->SetLocking(false);
			iter.second->SetLockFishID(0);
			iter.second->ClearBulletCount();
			if (iter.second->GetGuid() == 0){
                continue;
            }

			GuID = iter.second->GetGuid();
            //发送 锁定信息
			SC_LockFish tinfo;
			tinfo.set_chair_id(iter.first);
			tinfo.set_lock_id(0);
			SendTo_pb(0, tinfo);
		}

		//设定不可开火 并发送
		m_bAllowFire = false;
        SendAllowFire(-1);

        //发送场景替换
		
		SC_SwitchScene tinfo;
		tinfo.set_nst(m_nCurScene);
		tinfo.set_switching(1);
		SendTo_pb(0, tinfo);

		//清除鱼
		m_FishManager.Clear();

		m_fSceneTime = 0.0f;
	}
}
//获取总玩家数 可优，每次循环获取？
int	catch_fish_logic::CountPlayer()
{
	return m_ChairPlayers.size();
}



//发送鱼数据
void catch_fish_logic::SendFish(CFish* pFish, uint32_t wChairID){
	auto ift = CGameConfig::GetInstance()->FishMap.find(pFish->GetTypeID());
	if (ift == CGameConfig::GetInstance()->FishMap.end()){
		return;
	}

	Fish finf = ift->second;
	MoveCompent* pMove = (MoveCompent*)pFish->GetComponent(ECF_MOVE);
	BufferMgr* pBM = (BufferMgr*)pFish->GetComponent(ECF_BUFFERMGR);


	SC_SendFish tinfo;
	tinfo.set_fish_id(pFish->GetId());
	
	tinfo.set_type_id(pFish->GetTypeID());
	tinfo.set_create_tick(pFish->GetCreateTick());
	tinfo.set_fis_type(pFish->GetFishType());
	tinfo.set_refersh_id(pFish->GetRefershID());

	if (pMove != NULL){
		tinfo.set_path_id(pMove->GetPathID());
		if (pMove->GetID() == EMCT_DIRECTION){
			tinfo.set_offest_x(pMove->GetPostion().x_);
			tinfo.set_offest_y(pMove->GetPostion().y_);
		}else{
			tinfo.set_offest_x(pMove->GetOffest().x_);
			tinfo.set_offest_y(pMove->GetOffest().y_);
		}
		tinfo.set_dir(pMove->GetDirection());
		tinfo.set_delay(pMove->GetDelay());
		tinfo.set_fish_speed(pMove->GetSpeed());
		tinfo.set_troop(pMove->bTroop());
	}

	if (pBM != NULL && pBM->HasBuffer(EBT_ADDMUL_BYHIT)){
		PostEvent("FishMulChange", pFish);
	}

	tinfo.set_server_tick(timeGetTime());

	if (wChairID == INVALID_CHAIR){
		SendTo_pb(0, tinfo);
	}else{
		SendTo_pb(m_ChairPlayers[wChairID]->GetGuid(), tinfo);
	}
}

void catch_fish_logic::SendFishList(uint32_t wChairID){
	if (m_FishManager.CountObject() == 0){
		return;
	}
	int fish_size = m_FishManager.CountObject();
	std::vector<SC_SendFishList> t_tinfo;
	t_tinfo.resize(8);

	int this_count = 0;
	for (auto& iter = m_FishManager.Begin(); iter != m_FishManager.End(); iter++){
		CFish* pFish = (CFish*)iter->second;
		MoveCompent* pMove = (MoveCompent*)pFish->GetComponent(ECF_MOVE);
		BufferMgr* pBM = (BufferMgr*)pFish->GetComponent(ECF_BUFFERMGR);
		
		SC_SendFish* ff = t_tinfo[this_count].add_pb_fishes();
		this_count++; 
		if (this_count >= 8){
			this_count = 0;
		}
		ff->set_fish_id(pFish->GetId());
		ff->set_type_id(pFish->GetTypeID());
		ff->set_create_tick(pFish->GetCreateTick());
		ff->set_fis_type(pFish->GetFishType());
		ff->set_refersh_id(pFish->GetRefershID());

		if (pMove != NULL){
			ff->set_path_id(pMove->GetPathID());
			if (pMove->GetID() == EMCT_DIRECTION){
				ff->set_offest_x(pMove->GetPostion().x_);
				ff->set_offest_y(pMove->GetPostion().y_);
			}else{
				ff->set_offest_x(pMove->GetOffest().x_);
				ff->set_offest_y(pMove->GetOffest().y_);
			}

			ff->set_dir(pMove->GetDirection());
			ff->set_delay(pMove->GetDelay());
			ff->set_fish_speed(pMove->GetSpeed());
			ff->set_troop(pMove->bTroop());
		}

		if (pBM != NULL && pBM->HasBuffer(EBT_ADDMUL_BYHIT)){
			PostEvent("FishMulChange", pFish);
		}

		ff->set_server_tick(timeGetTime());
	}

	for (auto& item : t_tinfo)
	{
		if (!item.pb_fishes().empty())
		{
			if (wChairID == INVALID_CHAIR){
				SendTo_pb(0, item);
			}
			else{
				SendTo_pb(m_ChairPlayers[wChairID]->GetGuid(), item);
			}
		}
	}
}

//改变大炮集
bool catch_fish_logic::OnChangeCannonSet(lua_tinker::table player, int add)
{
	delete_invalid_player();
	int chair_id = player.get<int>("chair_id");

	if (chair_id >= GAME_PLAYER) return false;

	BufferMgr* pBMgr = (BufferMgr*)m_ChairPlayers[chair_id]->GetComponent(ECF_BUFFERMGR);
	if (pBMgr != NULL && (pBMgr->HasBuffer(EBT_DOUBLE_CANNON) || pBMgr->HasBuffer(EBT_ION_CANNON)))
	{
		return true;//离子炮或能量炮时禁止换炮
	}
	//获取大炮集类型
	int n = m_ChairPlayers[chair_id]->GetCannonSetType();

	do
	{
		if (add){
			if (n < CGameConfig::GetInstance()->CannonSetArray.size() - 1){
				++n;
			}else{
				n = 0;
			}
		}else{
			if (n >= 1){
				--n;
			}else{
				n = CGameConfig::GetInstance()->CannonSetArray.size() - 1;
			}
		}//等于离子炮ID 或双倍ID是退出循环
	} while (n == CGameConfig::GetInstance()->CannonSetArray[n].nIonID || n == CGameConfig::GetInstance()->CannonSetArray[n].nDoubleID);

	if (n < 0) n = 0;
	if (n >= CGameConfig::GetInstance()->CannonSetArray.size()){
		n = CGameConfig::GetInstance()->CannonSetArray.size() - 1;
	}

	//设置大炮集类型 ？CacluteCannonPos 获取的是大炮类型 m_nCannonType
	m_ChairPlayers[chair_id]->SetCannonSetType(n);
	//运算大炮坐标
	m_ChairPlayers[chair_id]->CacluteCannonPos(chair_id);
	//发送大炮信息
	SendCannonSet(chair_id);

	return true;
}
//开火
bool catch_fish_logic::OnFire(lua_tinker::table player, lua_tinker::table msg)
{
	delete_invalid_player();
	int guid = player.get<int>("guid");
	auto chair_id = player.get<int>("chair_id");
	double Direction = msg.get<double>("direction");
	int ClientID = msg.get<int>("client_id");
	uint32_t FireTime = msg.get<uint32_t>("fire_time");
	MyPoint bullet_pos(msg.get<double>("pos_x"), msg.get<double>("pos_y"));

	//获取子弹类型
	int mul = m_ChairPlayers[chair_id]->GetMultiply();
	if (mul < 0 || mul >= CGameConfig::GetInstance()->BulletVector.size()){
		std::cout << "invalid bullet multiple" << std::endl;
		return false;
	}

	//场景及玩家可以开火
	if (m_bAllowFire && 
		(HasRealPlayer() || CGameConfig::GetInstance()->bImitationRealPlayer) && m_ChairPlayers[chair_id]->CanFire()){
		//获取子弹
		Bullet &binf = CGameConfig::GetInstance()->BulletVector[mul];
		//玩家金钱大于子弹值， 且 玩家总子弹数 小于最大子弹数
		if (m_ChairPlayers[chair_id]->GetScore() >= binf.nMulriple &&
			m_ChairPlayers[chair_id]->GetBulletCount() + 1 <= CGameConfig::GetInstance()->nMaxBullet){
			m_ChairPlayers[chair_id]->SetFired();
	
			// 整理税收和玩家输赢分数
			Earnings::getInstance().onUserFire(binf.nMulriple);
			m_UserWinScore[chair_id] -= binf.nMulriple;
			m_ChairPlayers[chair_id]->AddScore(-binf.nMulriple);

			//创建子弹
			CBullet* pBullet = CommonLogic::CreateBullet(binf, bullet_pos, Direction,
				m_ChairPlayers[chair_id]->GetCannonType(), m_ChairPlayers[chair_id]->GetMultiply(), false);
			if (pBullet != NULL){
				if (ClientID != 0){
					pBullet->SetId(ClientID);
				}

				pBullet->SetChairID(chair_id);       //设置椅子
				pBullet->SetCreateTick(chair_id);   //设置开火时间 此时间无效校验

				//查找玩家BUFF是否有双倍炮BUFF
				BufferMgr* pBMgr = (BufferMgr*)m_ChairPlayers[chair_id]->GetComponent(ECF_BUFFERMGR);
				if (pBMgr != NULL && pBMgr->HasBuffer(EBT_DOUBLE_CANNON)){
					pBullet->setDouble(true);
				}

				//是否有锁定鱼
				if (m_ChairPlayers[chair_id]->GetLockFishID() != 0){
					//获取子弹移动控件
					MoveCompent* pMove = (MoveCompent*)pBullet->GetComponent(ECF_MOVE);
					if (pMove != NULL){
						pMove->SetTarget(&m_FishManager, m_ChairPlayers[chair_id]->GetLockFishID());
					}
				}

				uint32_t now = timeGetTime();
				if (FireTime > now){
					//m_pITableFrame->SendTableData(pf->wChairID, SUB_S_FORCE_TIME_SYNC);
				}else{
					//如果子弹生成时间大于2秒执行更新事件处理操作
					uint32_t delta = now - FireTime;
					if (delta > 2000) delta = 2000;
					pBullet->OnUpdate(delta);
				}

				//增加子弹
				m_ChairPlayers[chair_id]->ADDBulletCount(1);
				m_BulletManager.Add(pBullet);
				//发送子弹
				SendBullet(pBullet, true);
			}else{
				SC_KillBullet tinfo;
				tinfo.set_chair_id(chair_id);              //椅子ID
				tinfo.set_bullet_id(ClientID);
				SendTo_pb(0, tinfo);
				std::cout << "create bullet failed" << std::endl;
			}

			//设置最后开火时间
			m_ChairPlayers[chair_id]->SetLastFireTick(timeGetTime());
		}else{
			SC_KillBullet tinfo;
			tinfo.set_chair_id(chair_id);              //椅子ID
			tinfo.set_bullet_id(ClientID);
			SendTo_pb(0, tinfo);

			std::cout << "Score less or reach max bullet count.guid:"<< guid << " count:" << m_ChairPlayers[chair_id]->GetBulletCount() 
				<< " max count:" << CGameConfig::GetInstance()->nMaxBullet << std::endl;
		}
	}
	else{
		SC_KillBullet tinfo;
		tinfo.set_chair_id(chair_id);              //椅子ID
		tinfo.set_bullet_id(ClientID);
		SendTo_pb(0, tinfo);
		std::cout <<"Do not allow fire,but fired." << std::endl;
	}

	return true;
}
//发送子弹
void catch_fish_logic::SendBullet(CBullet* pBullet, bool bNew)
{
	if (pBullet == NULL) return;

	if (!m_ChairPlayers[pBullet->GetChairID()])
	{
		return;
	}

	SC_SendBullet tinfo;
	tinfo.set_chair_id(pBullet->GetChairID());
	tinfo.set_id(pBullet->GetId());
	tinfo.set_cannon_type(pBullet->GetCannonType());
	tinfo.set_multiply(pBullet->GetTypeID());
	tinfo.set_direction(pBullet->GetDirection());
	tinfo.set_x_pos(pBullet->GetPosition().x_);
	tinfo.set_y_pos(pBullet->GetPosition().y_);
	tinfo.set_score(m_ChairPlayers[pBullet->GetChairID()]->GetScore());
	tinfo.set_is_new(bNew ? 1 : 0);
	tinfo.set_is_double(pBullet->bDouble() ? 1 : 0);
	tinfo.set_server_tick(timeGetTime());
	if (bNew){
		tinfo.set_create_tick(pBullet->GetCreateTick());
	}
	else{
		tinfo.set_create_tick(timeGetTime());
	}
	SendTo_pb(0, tinfo);
}

//发送系统时间
bool catch_fish_logic::OnTimeSync(lua_tinker::table player, int	client_tick)
{
	delete_invalid_player();
	int chair_id = player.get<int>("chair_id");
	int guid = player.get<int>("guid");
	if (guid != 0){
		SC_TimeSync tinfo;
		tinfo.set_chair_id(chair_id);
		tinfo.set_client_tick(client_tick);
		tinfo.set_server_tick(timeGetTime());
		SendTo_pb(guid, tinfo);
        return true;
    }

    return false;
}

//变换大炮
bool catch_fish_logic::OnChangeCannon(lua_tinker::table player, int add){
	delete_invalid_player();
	uint32_t ChairID = player.get<uint32_t>("chair_id");
	if (ChairID > GAME_PLAYER){
		return false;
	}


	//获取Buff管理器
	BufferMgr* pBMgr = (BufferMgr*)m_ChairPlayers[ChairID]->GetComponent(ECF_BUFFERMGR);
	//查看当前大炮是否为双倍或离子炮
	if (pBMgr != NULL && (pBMgr->HasBuffer(EBT_DOUBLE_CANNON) || pBMgr->HasBuffer(EBT_ION_CANNON))){
		return true;//离子炮或能量炮时禁止换炮
	}

	//获取当前子弹类型
	int mul = m_ChairPlayers[ChairID]->GetMultiply();

	if (add){
		++mul;
	}else{
		--mul;
	}
	//循环类型
	if (mul < 0) mul = CGameConfig::GetInstance()->BulletVector.size() - 1;
	if (mul >= CGameConfig::GetInstance()->BulletVector.size()) mul = 0;
	//设置类型
	m_ChairPlayers[ChairID]->SetMultiply(mul);
	//获取子弹对应的炮类形
	int CannonType = CGameConfig::GetInstance()->BulletVector[mul].nCannonType;
	//设置炮
	m_ChairPlayers[ChairID]->SetCannonType(CannonType);
	//发送炮设置
	SendCannonSet(ChairID);
	//设置最后一次开炮时间
	m_ChairPlayers[ChairID]->SetLastFireTick(timeGetTime());

	return true;
}
//发送大炮属性
void catch_fish_logic::SendCannonSet(int wChairID){

	auto iter = m_ChairPlayers.find(wChairID);
	if (iter == m_ChairPlayers.end()){
		return;
	}

	SC_CannonSet tinfo;
	tinfo.set_chair_id(iter->first);
	tinfo.set_cannon_mul(iter->second->GetMultiply());
	tinfo.set_cannon_type(iter->second->GetCannonType());
	tinfo.set_cannon_set(iter->second->GetCannonSetType());
	SendTo_pb(0, tinfo);
}
//打开宝箱
bool catch_fish_logic::OnTreasureEND(lua_tinker::table player, int64_t score)
{
	delete_invalid_player();
	int ChairID = player.get<int>("chair_id");
	int Guid = player.get<int>("guid");

	if (ChairID > 0 && ChairID <= GAME_PLAYER && Guid != 0){
		char szInfo[512] = {0};
		std::wstring str = TEXT("恭喜%s第%d桌的玩家『%s』打中宝箱,　并从中获得%lld金币!!!");
		std::wstring_convert<std::codecvt_utf8<wchar_t>> conv;
		std::string narrowStr = conv.to_bytes(str);
		sprintf_s(szInfo, narrowStr.c_str(), "fishing",
			GetTableID(), m_GuidPlayers[Guid].GetNickname().c_str(), score);
		RaiseEvent("CatchFishBroadCast", szInfo, &m_GuidPlayers[Guid]);
	}

	return true;
}
//
void catch_fish_logic::ReturnBulletScore(int guid)
{
    {
		lua_tinker::call<void, int, int64_t>(
			catchfish_dll::sLuaState, "write_player_money", guid, m_UserWinScore[m_GuidPlayers[guid].GetChairID()]
			);
    }

#if 0
	if (wChairID >= GAME_PLAYER)
	{
		DebugString(TEXT("[Fish]ReturnBulletScore Err: wTableID %d wChairID %d"), m_pITableFrame->GetTableID(), wChairID);
		return;
	}
	try
	{
		IServerUserItem* pIServerUserItem = m_pITableFrame->GetTableUserItem(wChairID);
		if (pIServerUserItem != NULL)
		{
			// 			int64_t score = m_player[wChairID].GetScore();
			// 			if(score != 0)
			// 			{
			// 				long long  ls = score * CGameConfig::GetInstance()->nChangeRatioUserScore / CGameConfig::GetInstance()->nChangeRatioFishScore;
			// 				m_player[wChairID].AddWastage(-ls);
			// 			}
			// 
			// 			tagScoreInfo ScoreInfo;
			// 			ZeroMemory(&ScoreInfo, sizeof(tagScoreInfo));
			// 			score = -m_player[wChairID].GetWastage();
			// 			long long  lReve=0,cbRevenue=m_pGameServiceOption->wRevenueRatio;	
			// 			if (score > 0)
			// 			{	
			// 				float fRevenuePer = float(cbRevenue/1000);
			// 				lReve  = long long (score*fRevenuePer);
			// 				ScoreInfo.cbType = SCORE_TYPE_WIN;
			// 			}
			// 			else if (score < 0)
			// 				ScoreInfo.cbType = SCORE_TYPE_LOSE;
			// 			else
			// 				ScoreInfo.cbType = SCORE_TYPE_DRAW;
			// 			ScoreInfo.lScore = score;
			// 			ScoreInfo.lRevenue = lReve;
			// 
			// 			m_pITableFrame->WriteUserScore(wChairID, ScoreInfo);

			if (user_win_scores_[wChairID] != 0 || user_revenues_[wChairID] != 0) {// 有发炮过
				tagScoreInfo ScoreInfo = { 0 };
				ScoreInfo.cbType = (user_win_scores_[wChairID] > 0L) ? SCORE_TYPE_WIN : SCORE_TYPE_LOSE;
				ScoreInfo.lRevenue = user_revenues_[wChairID];
				ScoreInfo.lScore = user_win_scores_[wChairID];
				user_revenues_[wChairID] = 0;
				user_win_scores_[wChairID] = 0;
				m_pITableFrame->WriteUserScore(wChairID, ScoreInfo);
			}

			m_player[wChairID].ClearSet(wChairID);
		}
	}
	catch (...)
	{
		CTraceService::TraceString(TEXT("ReturnBulletScore错误1"), TraceLevel_Exception);
		DebugString(TEXT("[Fish]ReturnBulletScore错误1"));
	}

	std::list<uint32_t> rmList;
	m_BulletManager.Lock();
	try
	{
		obj_table_iter ibu = m_BulletManager.Begin();
		while (ibu != m_BulletManager.End())
		{
			CBullet* pBullet = (CBullet*)ibu->second;
			if (pBullet->GetChairID() == wChairID)
				rmList.push_back(pBullet->GetId());

			++ibu;
		}
	}
	catch (...)
	{
		CTraceService::TraceString(TEXT("ReturnBulletScore错误2"), TraceLevel_Exception);
		DebugString(TEXT("[Fish]ReturnBulletScore错误2"));
	}
	m_BulletManager.Unlock();

	std::list<uint32_t>::iterator it = rmList.begin();
	while (it != rmList.end())
	{
		m_BulletManager.Remove(*it);
		++it;
	}

	rmList.clear();
#endif
}
//奖励事件
void catch_fish_logic::OnAdwardEvent(CMyEvent* pEvent)
{
	//判断事件是否为本事件
	if (pEvent == NULL || pEvent->GetName() != "AdwardEvent") return;
	//奖励事件
	CEffectAward* pe = (CEffectAward*)pEvent->GetParam();
	//鱼
	CFish* pFish = (CFish*)pEvent->GetSource();
	//子弹
	CBullet* pBullet = (CBullet*)pEvent->GetTarget();

	if (pe == NULL || pFish == NULL || pBullet == NULL) return;
	//设置玩家不可开火
	m_ChairPlayers[pBullet->GetChairID()]->SetCanFire(false);

	long long  lScore = 0;
	//GetParam(1) 参数２表示实际效果 ０加金币　　１加ＢＵＦＦＥＲ
	if (pe->GetParam(1) == 0)
	{
		if (pe->GetParam(2) == 0)
			lScore = pe->GetParam(3);
		else
			lScore = pBullet->GetScore() * pe->GetParam(3);
	}
	else
	{
		//纵使子弹加BUFF
		BufferMgr* pBMgr = (BufferMgr*)m_ChairPlayers[pBullet->GetChairID()]->GetComponent(ECF_BUFFERMGR);
		if (pBMgr != NULL && !pBMgr->HasBuffer(pe->GetParam(2)))
		{
			//GetParam(2)类型 GetParam(3)持续时间
			pBMgr->Add(pe->GetParam(2), 0, pe->GetParam(3));
		}
	}
	//玩家加钱
	m_ChairPlayers[pBullet->GetChairID()]->AddScore(lScore);
}
//增加鱼BUFF
void catch_fish_logic::OnAddBuffer(CMyEvent* pEvent)
{
	if (pEvent == NULL || pEvent->GetName() != "AddBuffer") return;
	CEffectAddBuffer* pe = (CEffectAddBuffer*)pEvent->GetParam();

	CFish* pFish = (CFish*)pEvent->GetSource();
	if (pFish == NULL) return;

	if (pFish->GetMgr() != &m_FishManager) return;

	//当目标是全部鱼且类型为改变速度 改变值为0时 定屏 时间为pe->GetParam(4)
	if (pe->GetParam(0) == 0 && pe->GetParam(2) == EBT_CHANGESPEED && pe->GetParam(3) == 0)//定屏
	{//？只停止了刷新?
		m_fPauseTime = pe->GetParam(4);
	}
}
//执行鱼死亡效果
void catch_fish_logic::OnMulChange(CMyEvent* pEvent)
{
	int GuID = GetFirstPlayerGuID();
	if (GuID <= 0){
        return;
    }

	if (pEvent == NULL || pEvent->GetName() != "FishMulChange") return;

	CFish* pFish = (CFish*)pEvent->GetParam();
	if (pFish != NULL)
	{
		m_FishManager.Lock();
		obj_table_iter ifs = m_FishManager.Begin();
		while (ifs != m_FishManager.End())
		{

			CFish* pf = (CFish*)ifs->second;
			//找到一个同类的鱼，然后执行死亡效果
			if (pf != NULL && pf->GetTypeID() == pFish->GetTypeID())
			{
				CBullet bt;
				bt.SetScore(1);
				std::list<MyObject*> llt;
				llt.clear();
				//如果找到鱼死亡管理器 
				EffectMgr* pEM = (EffectMgr*)pf->GetComponent(ECF_EFFECTMGR);
                int multemp = 0;
				if (pEM != NULL)
				{//执行死亡效果
                    multemp = pEM->Execute(&bt, llt, true);
				}

				SC_FishMul tinfo;
				tinfo.set_fish_id(pf->GetId());
				tinfo.set_mul(multemp);
				SendTo_pb(0, tinfo);
			}

			++ifs;

		}
		m_FishManager.Unlock();
	}
}
//第一次开火？ 为啥是生成鱼的 第一波鱼生成吗？
void catch_fish_logic::OnFirstFire(CMyEvent* pEvent)
{
	if (pEvent == NULL || pEvent->GetName() != "FirstFire") return;

	CPlayer* pPlayer = (CPlayer*)pEvent->GetParam();

	if (m_ChairPlayers.find(pPlayer->GetChairID()) == m_ChairPlayers.end()){
		return;
	}

	int npos = 0;
	npos = CGameConfig::GetInstance()->FirstFireList.size() - 1;
	FirstFire& ff = CGameConfig::GetInstance()->FirstFireList[npos];
	//在鱼类型与权重中取最低值
	int nsz = min(ff.FishTypeVector.size(), ff.WeightVector.size());

	if (nsz <= 0) return;

	//总权重
	int WeightCount = 0;
	for (int iw = 0; iw < nsz; ++iw){
		WeightCount += ff.WeightVector[iw];
	}

	//获取大炮位置
	MyPoint pt = pPlayer->GetCannonPos();
	//获取大炮方向
	float dir = CGameConfig::GetInstance()->CannonPos[pPlayer->GetChairID()].m_Direction;
	//数量？
	for (int nc = 0; nc < ff.nCount; ++nc)
	{
		//价格计数？
		for (int ni = 0; ni < ff.nPriceCount; ++ni)
		{
			//获取 一种鱼
			int Fid = ff.FishTypeVector[RandInt(0, nsz)];
			//随机一个权重
			int nf = RandInt(0, WeightCount);
			int wpos = 0;
			//匹配一个权重
			for (; wpos < nsz; ++wpos)
			{
				if (nf > ff.WeightVector[wpos])
				{
					nf -= ff.WeightVector[wpos];
				}
				else
				{
					Fid = ff.FishTypeVector[wpos];
					break;;
				}
			}
			//如果没有匹配到则匹配第一个
			if (wpos >= nsz)
			{
				Fid = ff.FishTypeVector[0];
			}

			//运算最终角度？
			dir = CGameConfig::GetInstance()->CannonPos[pPlayer->GetChairID()].m_Direction - M_PI_2 + M_PI / ff.nPriceCount * ni;

			//查找匹配到的鱼
			std::map<int, Fish>::iterator ift = CGameConfig::GetInstance()->FishMap.find(Fid);
			if (ift != CGameConfig::GetInstance()->FishMap.end())
			{
				Fish& finf = ift->second;

				//生成鱼
				CFish* pFish = CommonLogic::CreateFish(finf, pt.x_, pt.y_, dir, RandFloat(0.0f, 1.0f) + nc, finf.nSpeed, -2);
				if (pFish != NULL)
				{
					m_FishManager.Add(pFish);
					SendFish(pFish);
				}
			}
		}
	}
}
//生成鱼
void catch_fish_logic::OnProduceFish(CMyEvent* pEvent)
{
	if (pEvent == NULL || pEvent->GetName() != "ProduceFish") return;

	CEffectProduce* pe = (CEffectProduce*)pEvent->GetParam();
	//Source为鱼
	CFish* pFish = (CFish*)pEvent->GetSource();
	if (pFish == NULL) return;

	if (pFish->GetMgr() != &m_FishManager) return;
	//获取坐标
	MyPoint& pt = pFish->GetPosition();
    list<SC_stSendFish> msg;
	//通过ID查找鱼
	std::map<int, Fish>::iterator ift = CGameConfig::GetInstance()->FishMap.find(pe->GetParam(0));
	if (ift != CGameConfig::GetInstance()->FishMap.end()){
		Fish finf = ift->second;
		float fdt = M_PI * 2.0f / (float)pe->GetParam(2);
		//类型为普通
		int fishtype = ESFT_NORMAL;
		int ndif = -1;
		//批次循环
		for (int i = 0; i < pe->GetParam(1); ++i){
			//当最后一批，且总批次大于2 刷新数量大于10只时 随机一条鱼刷新为鱼王
			if ((i == pe->GetParam(1) - 1) && (pe->GetParam(1) > 2) && (pe->GetParam(2) > 10)){
				ndif = RandInt(0, pe->GetParam(2));
			}

			//刷新数量
			for (int j = 0; j < pe->GetParam(2); ++j){
				if (j == ndif){
					fishtype = ESFT_KING;
				}else{
					fishtype = ESFT_NORMAL;
				}

				//创建鱼
				CFish* pf = CommonLogic::CreateFish(finf, pt.x_, pt.y_, fdt*j, 1.0f + pe->GetParam(3)*i, finf.nSpeed, -2, false, fishtype);
				if (pf != NULL){
					m_FishManager.Add(pf);
					//换成只处理数据
                    SC_stSendFish fish;
					fish.fish_id = pf->GetId();
                    fish.type_id = pf->GetTypeID();
                    fish.create_tick = pf->GetCreateTick();
                    fish.fis_type = pf->GetFishType();
                    fish.refersh_id = pf->GetRefershID();
					//添加移动组件
					MoveCompent* pMove = (MoveCompent*)pf->GetComponent(ECF_MOVE);
					if (pMove != NULL){
						fish.path_id = pMove->GetPathID();
						fish.offest_x = pMove->GetOffest().x_;
						fish.offest_y = pMove->GetOffest().y_;
						if (pMove->GetID() == EMCT_DIRECTION){
							fish.offest_x = pMove->GetPostion().x_;
							fish.offest_y = pMove->GetPostion().y_;
						}
						fish.dir = pMove->GetDirection();
						fish.delay = pMove->GetDelay();
						fish.fish_speed = pMove->GetSpeed();
						fish.troop = pMove->bTroop() ? 1 : 0;
					}

					BufferMgr* pBM = (BufferMgr*)pf->GetComponent(ECF_BUFFERMGR);
					if (pBM != NULL && pBM->HasBuffer(EBT_ADDMUL_BYHIT)){//找到BUFF管理器，且有BUFF 被击 吃子弹 添加事件
						PostEvent("FishMulChange", pf);
					}

					fish.server_tick = timeGetTime();
                    msg.push_back(fish);
				}
			}
		}
	}

	if (msg.size() == 0){
		return;
	}


	int fish_size = msg.size();
	std::vector<SC_SendFishList> t_tinfo;
	t_tinfo.resize(8);

	int this_count = 0;
	for (list<SC_stSendFish>::iterator it = msg.begin(); it != msg.end(); ++it)
	{
		SC_SendFish* pff = t_tinfo[this_count].add_pb_fishes();
		this_count++;
		if (this_count >= 8){
			this_count = 0;
		}
		SC_stSendFish &temp = *it;
		pff->set_fish_id(temp.fish_id); //鱼ID
		pff->set_type_id(temp.type_id);  //类型？
		pff->set_path_id(temp.path_id);  //路径ID
		pff->set_create_tick(temp.create_tick);  //创建时间
		pff->set_offest_x(temp.offest_x);  //X坐标
		pff->set_offest_y(temp.offest_y);  //Y坐标
		pff->set_dir(temp.dir);  //方向
		pff->set_delay(temp.delay);  //延时
		pff->set_server_tick(temp.server_tick);  //系统时间
		pff->set_fish_speed(temp.fish_speed);  //鱼速度
		pff->set_fis_type(temp.fis_type);  //鱼类型？
		pff->set_troop(temp.troop);      //是否鱼群
		pff->set_refersh_id(temp.refersh_id);  //获取刷新ID？
	}

	for (auto& item : t_tinfo)
	{
		if (!item.pb_fishes().empty())
		{
			SendTo_pb(0, item);
		}
	}

}
//锁定鱼
void catch_fish_logic::LockFish(unsigned int wChairID)
{
	uint32_t dwFishID = 0;

	CFish* pf = NULL;
	//获取当前锁定ID
	dwFishID = m_ChairPlayers[wChairID]->GetLockFishID();
	if (dwFishID != 0){
		pf = (CFish*)m_FishManager.Find(dwFishID);
	}

	if (pf != NULL){
		//判断当前锁定鱼 是否已经不可锁定了
		MoveCompent* pMove = (MoveCompent*)pf->GetComponent(ECF_MOVE);
		if (pf->GetState() >= EOS_DEAD || pMove == NULL || pMove->IsEndPath()){
			pf = NULL;
		}
	}

	dwFishID = 0;

	CFish* pLock = NULL;

	//轮询可锁定列表
	for (std::list<uint32_t>::iterator iw = m_CanLockList.begin(); iw != m_CanLockList.end();++iw){
		//查找鱼
		CFish* pFish = (CFish*)m_FishManager.Find(*iw);
		//当前鱼有效 且 没死亡 且 锁定等级大于0 且 没有游出屏幕
		if (pFish != NULL && pFish->GetState() < EOS_DEAD && pFish->GetLockLevel() > 0 && pFish->InSideScreen()){
			//获取能锁定的最大等级的鱼
			if (pf == NULL || (pf != pFish && !m_ChairPlayers[wChairID]->HasLocked(pFish->GetId()))){
				pf = pFish;

				if (pLock == NULL){
					pLock = pf;
				}else if (pf->GetLockLevel() > pLock->GetLockLevel()){
					pLock = pf;
				}
			}
		}
	}

	if (pLock != NULL){
		dwFishID = pLock->GetId();
	}

	//设置锁定ID 
	m_ChairPlayers[wChairID]->SetLockFishID(dwFishID);
	if (m_ChairPlayers[wChairID]->GetLockFishID() == 0){
		return;
	}

	SC_LockFish tinfo;
	tinfo.set_chair_id(wChairID);
	tinfo.set_lock_id(dwFishID);
	SendTo_pb(0, tinfo);
}
//锁定鱼
bool catch_fish_logic::OnLockFish(lua_tinker::table player, int isLock)
{
	int guid = player.get<int>("guid");
	int chair_id = player.get<int>("chair_id");
	//椅子子位置是否合理
	//如果没有玩家退出
	if (!HasRealPlayer()) return true;

	if (isLock){
		//设置玩家锁定
		m_GuidPlayers[guid].SetLocking(true);
		//锁定鱼
		LockFish(chair_id);
	}else{
		m_GuidPlayers[guid].SetLocking(false);
		m_GuidPlayers[guid].SetLockFishID(0);

		SC_LockFish tinfo;
		tinfo.set_chair_id(chair_id);
		tinfo.set_lock_id(0);
		SendTo_pb(0, tinfo);
	}
	m_GuidPlayers[guid].SetLastFireTick(timeGetTime());

	return true;

}

bool catch_fish_logic::OnLockSpecFish(lua_tinker::table player, int fishID){
	delete_invalid_player();
	int guid = player.get<int>("guid");
	int chair_id = player.get<int>("chair_id");
	if (!HasRealPlayer()) return true;

	if (fishID > 0){
		CFish* pLockFish = (CFish*)m_FishManager.Find(fishID);
		if (!pLockFish){
			m_GuidPlayers[guid].SetLocking(false);
			m_GuidPlayers[guid].SetLockFishID(0);
			fishID = 0;
		}else{
			m_GuidPlayers[guid].SetLocking(true);
			m_GuidPlayers[guid].SetLockFishID(fishID);
		}
	}else{
		m_GuidPlayers[guid].SetLocking(false);
		m_GuidPlayers[guid].SetLockFishID(0);
	}

	SC_LockFish tinfo;
	tinfo.set_chair_id(chair_id);
	tinfo.set_lock_id(fishID);
	SendTo_pb(0, tinfo);

	m_GuidPlayers[guid].SetLastFireTick(timeGetTime());

	return true;
}

//发送 玩家大炮属性    并不是改变大炮？
void catch_fish_logic::OnCannonSetChange(CMyEvent* pEvent)
{
	if (pEvent == NULL || pEvent->GetName() != "CannonSetChanaged"){
		return;
	}

	CPlayer* pp = (CPlayer*)pEvent->GetParam();
	if (!pp){
		return;
	}

	SendCannonSet(pp->GetChairID());
}
//网鱼
bool catch_fish_logic::OnNetCast(lua_tinker::table player, int bullet_id, int data, int fish_id)
{
	delete_invalid_player();
	int chair_id = player.get<int>("chair_id");
	int guid = player.get<int>("guid");

	if (m_ChairPlayers.find(chair_id) == m_ChairPlayers.end()){
		std::cout << "can not find chair id:" << chair_id << std::endl;
		return true;
	}

	m_BulletManager.Lock();
	//获取子弹
	CBullet* pBullet = (CBullet*)m_BulletManager.Find(bullet_id);
	if (pBullet != NULL){
		int bulletChairID = pBullet->GetChairID();
		//获取子弹所属玩家座位
		if (m_ChairPlayers.find(bulletChairID) == m_ChairPlayers.end()){
			return true;
		}

		m_FishManager.Lock();
		CFish* pFish = (CFish*)m_FishManager.Find(fish_id);
		if (pFish != NULL){
			CatchFish(pBullet, pFish, 1, 0);
		}

		m_FishManager.Unlock();

		//发送子弹消失
        {
			SC_KillBullet tinfo;
			tinfo.set_chair_id(chair_id);
			tinfo.set_bullet_id(bullet_id);
			SendTo_pb(0, tinfo);
        }

		//玩家子弹-1
		m_ChairPlayers[bulletChairID]->ADDBulletCount(-1);
		//移除子弹
		m_BulletManager.Remove(bullet_id);
	}
	else
	{
		//std::cout << "invalid bullet id:" << bullet_id << std::endl;
		{
			SC_KillBullet tinfo;
			tinfo.set_chair_id(chair_id);
			tinfo.set_bullet_id(bullet_id);
			SendTo_pb(0, tinfo);
		}
		// TODO: 如果子弹不存在，也可能导致一些问题,有可能是上一个玩家已经打掉某个鱼把子弹已经消掉了，接着又收到捕中鱼的消息
	}
	m_BulletManager.Unlock();

	return true;
}

//打中鱼广播 无处理，只发送？ 可优
void catch_fish_logic::OnCatchFishBroadCast(CMyEvent* pEvent)
{
	if (pEvent != NULL && pEvent->GetName() == "CatchFishBroadCast"){
		//获取玩家
		CPlayer* pp = (CPlayer*)pEvent->GetSource();
		if (pp != NULL){
			SC_SystemMessage tinfo;
			tinfo.set_wtype(SMT_TABLE_ROLL);
			tinfo.set_szstring((char*)pEvent->GetParam());
			SendTo_pb(0, tinfo);
		}
	}
}
// 设置网关 可优 不再关心网关层
void catch_fish_logic::SetGuidAndGateID(int chair_id, int guid, int gate_id)
{
	if (chair_id >= 0 && chair_id < (int)m_ChairPlayers.size()){
		m_ChairPlayers[chair_id]->SetGuidGateID(guid, gate_id);
		m_ChairPlayers[chair_id]->SetChairID(chair_id);
	}
}


int catch_fish_logic::GetTableID(){
	return m_TableID;
}


