#include "CommonLogic.h"
#include "EffectManager.h"
#include "EffectFactory.h"
#include "MyObjectFactory.h"
#include "MyComponentFactory.h"
#include "MoveCompent.h"
#include "PathManager.h"
#include "BufferManager.h"

#define FORWARD 100
//鱼被捕效果
int64_t  CommonLogic::GetFishEffect(CBullet* pBullet, CFish* pFish, std::list<MyObject*>& list, bool bPretreating)
{
	int64_t  lScore = 0;
	if (pFish != NULL)
	{
		EffectMgr* pEM = (EffectMgr*)pFish->GetComponent(ECF_EFFECTMGR);
		if (pEM != NULL)
		{
			lScore = pEM->Execute(pBullet, list, bPretreating);
		}
	}
	return lScore;
}
//创建子弹
CBullet* CommonLogic::CreateBullet(Bullet binf, const MyPoint& pos, float fDirection, int CannonType, int CannonMul, bool bForward)
{
	//生成对象
	CBullet* pBullet = (CBullet*)CreateObject(EOT_BULLET);
	//设置初始值
	if (pBullet != NULL){
		pBullet->SetScore(binf.nMulriple);
		pBullet->SetCannonType(CannonType);
		pBullet->SetCatchRadio(binf.nCatchRadio);
		pBullet->SetMaxCatch(binf.nMaxCatch);
		pBullet->SetTypeID(CannonMul);
		pBullet->SetSize(binf.nBulletSize);

		std::map<int, float>::iterator it = binf.ProbabilitySet.begin();
		while (it != binf.ProbabilitySet.end()){
			pBullet->AddProbilitySet(it->first, it->second);
			++it;
		}

		//增加一个BUFF组件
		BufferMgr* pBM = (BufferMgr*)CreateComponent(EBCT_BUFFERMGR);
		if (pBM != NULL)
			pBullet->SetComponent(pBM);
		//增加一个移动组件
		MoveCompent* pMove = (MoveCompent*)CreateComponent(EMCT_DIRECTION);
		if (pMove != NULL){
			pMove->SetSpeed(binf.nSpeed);
			pMove->SetDirection(fDirection);
			pMove->SetPosition(pos);
			pMove->InitMove();
			pBullet->SetComponent(pMove);
			if (bForward){
				//运算当前移动距离
				pMove->OnUpdate(FORWARD * 1000 / binf.nSpeed * CGameConfig::GetInstance()->fHScale);
			}
		}
	}

	return pBullet;
}

//鱼，X，Y，半径，延时，速度，路径，是否鱼群，是否普通鱼
CFish* CommonLogic::CreateFish(Fish& finf, float x, float y, float r, float d, int s, int p, bool bTroop, int ft)
{
	uint32_t tt = timeGetTime();//可优  做创建耗时查询

	//创建鱼对象
	CFish* pFish = (CFish*)CreateObject(EOT_FISH);
	if (!pFish){
		return pFish;
	}

	pFish->SetTypeID(finf.nTypeID);
	pFish->SetFishType(ft);
	pFish->SetProbability(finf.fProbability);
	pFish->SetBoundingBox(finf.nBoundBox);
	pFish->SetLockLevel(finf.nLockLevel);
	pFish->SetBroadCast(finf.bBroadCast);
	pFish->SetName(finf.szName);
	if (ft != ESFT_NORMAL){
		pFish->SetBroadCast(true);
		//特殊鱼地图？
		std::map<int, SpecialSet>* pMap = NULL;
		if (ft == ESFT_KINGANDQUAN || ft == ESFT_KING){
			pMap = &(CGameConfig::GetInstance()->KingFishMap);
			TCHAR szName[256];
			_sntprintf_s(szName, _TRUNCATE, TEXT("%s鱼王"), finf.szName);
			pFish->SetName(szName);
		}
		else if (ft == ESFT_SANYUAN){
			pMap = &(CGameConfig::GetInstance()->SanYuanFishMap);
			pFish->SetName(TEXT("大三元"));
		}
		else if (ft == ESFT_SIXI){
			pMap = &(CGameConfig::GetInstance()->SiXiFishMap);
			pFish->SetName(TEXT("大四喜"));
		}

		if (pMap != NULL){
			std::map<int, SpecialSet>::iterator ist = pMap->find(finf.nTypeID);
			if (ist != pMap->end()){
				SpecialSet& kks = ist->second;

				if (ft == ESFT_KINGANDQUAN || ft == ESFT_KING){
					pFish->SetProbability(ft == ESFT_KINGANDQUAN ? finf.fProbability / 5.0f : kks.fCatchProbability);
				}
				else if (ft == ESFT_SANYUAN){
					pFish->SetProbability(finf.fProbability / 3.0f);
				}
				else if (ft == ESFT_SIXI){
					pFish->SetProbability(finf.fProbability / 4.0f);
				}

				pFish->SetLockLevel(kks.nLockLevel);

				if (ft == ESFT_KINGANDQUAN || ft == ESFT_SANYUAN || ft == ESFT_SIXI){
					pFish->SetBoundingBox(kks.nBoundingBox);
				}
			}
		}
	}
	//路径ID大于0 有移动路径
	if (p >= 0){
		MoveCompent* pMove = (MoveCompent*)CreateComponent(EMCT_PATH);
		if (pMove != NULL){
			pMove->SetOffest(MyPoint(x, y));
			pMove->SetDelay(d);
			pMove->SetPathID(p, bTroop);
			pMove->SetSpeed(s);
			pMove->InitMove();

			pFish->SetComponent(pMove);
		}
	}
	else {//无指定路径，按方向移动
		MoveCompent* pMove = (MoveCompent*)CreateComponent(EMCT_DIRECTION);
		if (pMove != NULL){
			pMove->SetPosition(x, y);
			pMove->SetDirection(r);
			pMove->SetDelay(d);
			pMove->SetRebound(p == -1);
			pMove->SetSpeed(s);
			pMove->SetPathID(p);
			pMove->InitMove();

			pFish->SetComponent(pMove);
		}
	}

	//增加BUFF管理器
	BufferMgr* pBM = (BufferMgr*)CreateComponent(EBCT_BUFFERMGR);
	if (pBM != NULL){
		pFish->SetComponent(pBM);
		if (finf.BufferSet.size() > 0){
			//增加所有buffer
			for (std::list<Buffer>::iterator ib = finf.BufferSet.begin(); ib != finf.BufferSet.end(); ++ib){
				pBM->Add(ib->nTypeID, ib->fParam, ib->fLife);
			}
		}
	}

	//当前鱼效果集大于1
	if (finf.EffectSet.size() > 0){
		//增加效果管理器
		EffectMgr* pEmgre = (EffectMgr*)CreateComponent(EECT_MGR);
		if (pEmgre != NULL){
			pFish->SetComponent(pEmgre);

			if (ft == ESFT_KINGANDQUAN || ft == ESFT_KING){
				//创建杀死后效果
				CEffect* pef = CreateEffect(ETP_KILL);
				if (pef != NULL){
					pef->SetParam(0, 2);
					pef->SetParam(1, finf.nTypeID);
					std::map<int, SpecialSet>::iterator ist = CGameConfig::GetInstance()->KingFishMap.find(finf.nTypeID);
					if (ist != CGameConfig::GetInstance()->KingFishMap.end()){
						pef->SetParam(2, ist->second.nMaxScore);
					}
					pEmgre->Add(pef);
				}

				//增加金币效果
				pef = CreateEffect(ETP_ADDMONEY);
				if (pef != NULL){
					pef->SetParam(0, 1);
					pef->SetParam(1, 10);
					pEmgre->Add(pef);
				}
			}

			//增加所有效果
			for (std::list<Effect>::iterator iet = finf.EffectSet.begin(); iet != finf.EffectSet.end(); ++iet){
				CEffect* pef = CreateEffect(iet->nTypeID);
				if (pef != NULL){
					for (int i = 0; i < pef->GetParamSize(); ++i){
						int nValue = 0;
						if (i < iet->nParam.size()){
							nValue = iet->nParam[i];
						}

						if (ft == ESFT_SANYUAN && i == 1){
							pef->SetParam(i, nValue * 3);
						}
						else if (ft == ESFT_SIXI && i == 1){
							pef->SetParam(i, nValue * 4);
						}
						else{
							pef->SetParam(i, nValue);
						}
					}

					pEmgre->Add(pef);
				}
			}

			//如果等于鱼王
			if (ft == ESFT_KINGANDQUAN){
				CEffect* pef = CreateEffect(ETP_PRODUCE);
				if (pef != NULL){
					//增加一个类型Buff
					pef->SetParam(0, finf.nTypeID);
					pef->SetParam(1, 3);
					pef->SetParam(2, 30);
					pef->SetParam(3, 1);
					pEmgre->Add(pef);
				}
			}
		}
	}

	//可优
	tt = timeGetTime() - tt;

	return pFish;
}

//替换字符串
const char* CommonLogic::ReplaceString(unsigned int wChairID, std::string& str)
{
	static char str1[64];
	if (str.find("%d") != -1)
	{
		//sprintf_s(str1, 64, str.c_str(), wChairID+1);
		_snprintf_s(str1, _TRUNCATE, str.c_str(), wChairID + 1);

	}
	else
	{
		return str.c_str();
	}

	return str1;
}

