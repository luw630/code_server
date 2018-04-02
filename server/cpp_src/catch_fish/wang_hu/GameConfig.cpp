#include "common.h"
#include "GameConfig.h"
#include "pugixml.hpp"
#include "lua_tinker_ex.h"

SingletonInstance(CGameConfig);

CGameConfig::CGameConfig()
	:nDefaultWidth(1440)
	, nDefaultHeight(900)
	, nWidth(1440)
	, nHeight(900)
	, nChangeRatioUserScore(1)
	, nChangeRatioFishScore(1)
	, nExchangeOnce(10000)
	, nFireInterval(300)
	, fHScale(1.0f)
	, fVScale(1.0f)
	, ShowDebugInfo(false)
	, ShowShadow(false)
	, nShowGoldMinMul(10)
	, nMinNotice(200)
	, nMaxBullet(20)
	, nMaxSpecailCount(0)
	, m_MaxCannon(0)
	, nPlayerCount(4)
	, fAndroidProbMul(1.2f)
	, nAddMulBegin(40)
	, nAddMulCur(0)
	, nSnakeHeadType(901)
	, nSnakeTailType(902)
	, bImitationRealPlayer(false)
{
	nSpecialProb[0] = 100;
	for (int i = 1; i < ESFT_MAX; ++i)
		nSpecialProb[i] = 0;
}

CGameConfig::~CGameConfig()
{
}

bool CGameConfig::LoadSystemConfig(std::string szXmlFile, CXMLDecrypt* pcd)
{
	pugi::xml_document doc;
	if (pcd == NULL)
	{
		if (!doc.load_file(szXmlFile.c_str())) return false;
	}
	else
	{
		uint32_t nSize = 0;
		void* pData = pcd->ParseXMLFile(szXmlFile, &nSize);
		if (!doc.load_buffer(pData, nSize)) return false;
	}

	pugi::xml_node SystemSet = doc.child("SystemSet");

	ShowDebugInfo = SystemSet.attribute("ShowDebugInfo").as_bool(false);
	ShowShadow = SystemSet.attribute("Shadow").as_bool(false);
	bImitationRealPlayer = SystemSet.attribute("ImitationRealPlayer").as_bool(false);

	pugi::xml_node sets = SystemSet.child("DefaultScreenSet");

	nDefaultWidth = sets.attribute("width").as_int(1440);
	nDefaultHeight = sets.attribute("height").as_int(900);

	sets = SystemSet.child("ExchangeScore");
	char* temp = NULL;
	const char* rat = sets.attribute("Ratio").as_string("0");
	nChangeRatioUserScore = strtoul(rat, &temp, 10);
	if (nChangeRatioUserScore <= 0) nChangeRatioUserScore = 1;
	nChangeRatioFishScore = strtoul(temp + 1, NULL, 10);
	if (nChangeRatioFishScore <= 0) nChangeRatioFishScore = 1;
	nExchangeOnce = sets.attribute("Once").as_int(10000);
	if (nExchangeOnce <= 0) nExchangeOnce = 10000;
	nShowGoldMinMul = sets.attribute("ShowGoldMinMul").as_int(10);

	sets = SystemSet.child("Fire");
	nFireInterval = sets.attribute("Interval").as_int(300);
	nMaxInterval = sets.attribute("MaxInterval").as_int(90000);
	nMinInterval = sets.attribute("MinInterval").as_int(10);
	nMaxBullet = sets.attribute("MaxBullet").as_int(20);

	sets = SystemSet.child("IonSet");
	nIonMultiply = sets.attribute("Multiple").as_int(20);
	nIonProbability = sets.attribute("Probability").as_int(10);
	fDoubleTime = sets.attribute("time").as_float(20);

	sets = SystemSet.child("Catch");
	nMinNotice = sets.attribute("NoticeLevel").as_int(200);
	fAndroidProbMul = sets.attribute("AndroidProbMul").as_float(1.2f);

	sets = SystemSet.child("Special");
	nMaxSpecailCount = sets.attribute("MaxCount").as_int(3);
	nSpecialProb[ESFT_KING] = sets.attribute("King").as_int(0);
	nSpecialProb[ESFT_KINGANDQUAN] = sets.attribute("KingQuan").as_int(0);
	nSpecialProb[ESFT_SANYUAN] = sets.attribute("SanYuan").as_int(0);
	nSpecialProb[ESFT_SIXI] = sets.attribute("SiXi").as_int(0);

	sets = SystemSet.child("AddMul");
	//nAddMulBegin = sets.attribute("Begin").as_int(40);
	nAddMulBegin = sets.attribute("Begin").as_int(0);

	sets = SystemSet.child("SNAKE");
	nSnakeHeadType = sets.attribute("Head").as_int(901);
	nSnakeTailType = sets.attribute("Tail").as_int(902);

	FirstFireList.clear();
	sets = SystemSet.child("FirstFire");
	while (sets)
	{
		FirstFire ff;

		ff.nLevel = sets.attribute("level").as_int(0);
		ff.nCount = sets.attribute("Count").as_int(0);
		ff.nPriceCount = sets.attribute("PirceCount").as_int(0);

		int tc = sets.attribute("TypeCount").as_int(1);
		int n = 0, s = 1;
		const char* ts = sets.attribute("TypeList").as_string("0");
		const char* tw = sets.attribute("WeightList").as_string("0");
		char* temp1 = NULL;
		char* temp2 = NULL;
		for (int i = 0; i < tc; ++i)
		{
			if (i == 0)
			{
				n = strtoul(ts, &temp1, 10);
				s = strtoul(tw, &temp2, 10);
			}
			else
			{
				n = strtoul(temp1 + 1, &temp1, 10);
				s = strtoul(temp2 + 1, &temp2, 10);
			}

			ff.FishTypeVector.push_back(n);
			ff.WeightVector.push_back(s);
		}

		FirstFireList.push_back(ff);

		sets = sets.next_sibling("FirstFire");
	}

	sets = SystemSet.child("GIVE");
	fGiveRealPlayTime = sets.attribute("interval").as_float(1800);
	fGiveTime = sets.attribute("time").as_float(180);

	int tc = sets.attribute("TypeCount").as_int(1);
	int n = 0, s = 1;
	const char* ts = sets.attribute("TypeList").as_string("0");
	const char* tw = sets.attribute("Probability").as_string("0");
	char* temp1 = NULL;
	char* temp2 = NULL;
	vGiveFish.clear();
	vGiveProb.clear();
	for (int i = 0; i < tc; ++i)
	{
		if (i == 0)
		{
			n = strtoul(ts, &temp1, 10);
			s = strtoul(tw, &temp2, 10);
		}
		else
		{
			n = strtoul(temp1 + 1, &temp1, 10);
			s = strtoul(temp2 + 1, &temp2, 10);
		}

		vGiveFish.push_back(n);
		vGiveProb.push_back(s);
	}

	return true;
}

bool CGameConfig::LoadScenes(std::string szXmlFile, CXMLDecrypt* pcd)
{
	pugi::xml_document doc;

	if (pcd == NULL)
	{
		if (!doc.load_file(szXmlFile.c_str())) return false;
	}
	else
	{
		uint32_t nSize = 0;
		void* pData = pcd->ParseXMLFile(szXmlFile, &nSize);
		if (!doc.load_buffer(pData, nSize)) return false;
	}

	pugi::xml_node sst = doc.child("scene");
	char* temp1 = NULL;
	char* temp2 = NULL;

	SceneSets.clear();

	while (sst)
	{
		SceneSet SceSet;
		SceSet.nID = sst.attribute("id").as_int(0);
		SceSet.fSceneTime = sst.attribute("time").as_float(600.0f);
		SceSet.szMap = sst.attribute("map").as_string("0");
		SceSet.nNextID = sst.attribute("next").as_int(1);

		pugi::xml_node tps = sst.child("TroopSet");
		while (tps)
		{
			TroopSet ts;

			ts.fBeginTime = tps.attribute("BeginTime").as_float(0.0f);
			ts.fEndTime = tps.attribute("EndTime").as_float(0.0f);
			ts.nTroopID = tps.attribute("id").as_int(0);

			SceSet.TroopList.push_back(ts);

			tps = tps.next_sibling("TroopSet");
		}

		pugi::xml_node sets = sst.child("DistrubFish");
		SceSet.DistrubList.clear();
		while (sets)
		{
			DistrubFishSet dis;
			dis.ftime = sets.attribute("Time").as_float(10.0f);
			dis.nMinCount = sets.attribute("MinCount").as_int(1);
			dis.nMaxCount = max(dis.nMinCount, sets.attribute("MaxCount").as_int(1));
			dis.nRefershType = sets.attribute("RefershType").as_int(ERT_NORMAL);
			int tc = sets.attribute("TypeCount").as_int(1);
			int n = 0, s = 1;
			const char* ts = sets.attribute("TypeList").as_string("0");
			const char* tw = sets.attribute("WeightList").as_string("0");
			for (int i = 0; i < tc; ++i)
			{
				if (i == 0)
				{
					n = strtoul(ts, &temp1, 10);
					s = strtoul(tw, &temp2, 10);
				}
				else
				{
					n = strtoul(temp1 + 1, &temp1, 10);
					s = strtoul(temp2 + 1, &temp2, 10);
				}

				dis.FishID.push_back(n);
				dis.Weight.push_back(s);
			}

			dis.OffestX = sets.attribute("OffestX").as_float(0.0f);
			dis.OffestY = sets.attribute("OffestY").as_float(0.0f);
			dis.OffestTime = sets.attribute("OffestTime").as_float(0.0f);

			SceSet.DistrubList.push_back(dis);

			sets = sets.next_sibling("DistrubFish");
		}

		SceneSets[SceSet.nID] = SceSet;

		sst = sst.next_sibling("scene");
	}

	return true;
}

bool CGameConfig::LoadFish(std::string szXmlFile, CXMLDecrypt* pcd)
{
	pugi::xml_document doc;

	if (pcd == NULL)
	{
		if (!doc.load_file(szXmlFile.c_str())) return false;
	}
	else
	{
		uint32_t nSize = 0;
		void* pData = pcd->ParseXMLFile(szXmlFile, &nSize);
		if (!doc.load_buffer(pData, nSize)) return false;
	}

	pugi::xml_node FishSet = doc.child("FishSet");
	pugi::xml_node fish = FishSet.child("Fish");
	FishMap.clear();
	while (fish)
	{
		Fish ff;
		ff.nTypeID = fish.attribute("TypeID").as_int();

		std::string sname = fish.attribute("Name").as_string();
		uint32_t nLen = MultiByteToWideChar(CP_UTF8, 0, sname.c_str(), sname.length(), NULL, 0);
		MultiByteToWideChar(CP_UTF8, 0, sname.c_str(), sname.length(), ff.szName, nLen);
		ff.szName[nLen] = TCHAR('\0');

		ff.bBroadCast = fish.attribute("BroadCast").as_bool(false);
		ff.fProbability = fish.attribute("Probability").as_float(MAX_PROBABILITY);
		ff.nSpeed = fish.attribute("Speed").as_int(0);

		ff.nVisualID = fish.attribute("VisualID").as_int(0);
		ff.nBoundBox = fish.attribute("BoundingBox").as_int(1);

		ff.bShowBingo = fish.attribute("ShowBingo").as_bool(false);
		ff.szParticle = fish.attribute("Particle").as_string("0");
		ff.bShakeScree = fish.attribute("ShakeScreen").as_bool(false);
		ff.nLockLevel = fish.attribute("LockLevel").as_int(0);

		pugi::xml_node effect = fish.child("Effect");
		while (effect)
		{
			Effect ecf;
			ecf.nTypeID = effect.attribute("TypeID").as_int(0);

			char szt[32];
			for (int i = 0; i < 10; ++i)
			{
				//sprintf_s(szt, 32, "Param%d", i+1);
				_snprintf_s(szt, _TRUNCATE, "Param%d", i + 1);
				pugi::xml_attribute& par = effect.attribute(szt);
				if (par.empty()) break;
				ecf.nParam.push_back(par.as_int(0));
			}

			ff.EffectSet.push_back(ecf);

			effect = effect.next_sibling("Effect");
		}

		pugi::xml_node buf = fish.child("Buffer");
		while (buf)
		{
			Buffer but;

			but.nTypeID = buf.attribute("TypeID").as_int(0);
			but.fParam = buf.attribute("Param").as_float(0.0f);
			but.fLife = buf.attribute("Life").as_int(0.0f);

			ff.BufferSet.push_back(but);

			buf = buf.next_sibling("Buffer");
		}

		FishMap[ff.nTypeID] = ff;

		fish = fish.next_sibling("Fish");
	}
	
	return true;
}

bool CGameConfig::LoadFishSound(std::string szXmlFile, CXMLDecrypt* pcd)
{
	pugi::xml_document doc;

	if (pcd == NULL)
	{
		if (!doc.load_file(szXmlFile.c_str())) return false;
	}
	else
	{
		uint32_t nSize = 0;
		void* pData = pcd->ParseXMLFile(szXmlFile, &nSize);
		if (!doc.load_buffer(pData, nSize)) return false;
	}

	pugi::xml_node nbbx = doc.child("FishSound");
	if (nbbx)
	{
		pugi::xml_node fs = nbbx.child("Fish");
		while (fs)
		{
			int id = fs.attribute("id").as_int(0);

			SoundSet ss;

			ss.szFoundName = fs.attribute("Sound").as_string();
			ss.m_nProbility = fs.attribute("Probility").as_int(20);

			FishSound[id] = ss;

			fs = fs.next_sibling("Fish");
		}
	}

	return true;
}

bool CGameConfig::LoadBoundBox(std::string szXmlFile, CXMLDecrypt* pcd)
{
	BBXMap.clear();
	pugi::xml_document doc;
	if (pcd == NULL)
	{
		if (!doc.load_file(szXmlFile.c_str())) return false;
	}
	else
	{
		uint32_t nSize = 0;
		void* pData = pcd->ParseXMLFile(szXmlFile, &nSize);
		if (!doc.load_buffer(pData, nSize)) return false;
	}

	pugi::xml_node nbbx = doc.child("BoundingBox");
	while (nbbx)
	{
		BBX boubx;
		boubx.nID = nbbx.attribute("id").as_int(0);

		pugi::xml_node nbb = nbbx.child("BB");
		while (nbb)
		{
			BB b;
			b.fRadio = nbb.attribute("Radio").as_float(0.0f);
			b.nOffestX = nbb.attribute("OffestX").as_int(0);
			b.nOffestY = nbb.attribute("OffestY").as_int(0);

			boubx.BBList.push_back(b);

			nbb = nbb.next_sibling("BB");
		}

		BBXMap[boubx.nID] = boubx;

		nbbx = nbbx.next_sibling("BoundingBox");
	}

	return true;
}

bool CGameConfig::LoadBulletSet(std::string szXmlFile, CXMLDecrypt* pcd)
{
	pugi::xml_document doc;
	if (pcd == NULL)
	{
		if (!doc.load_file(szXmlFile.c_str())) return false;
	}
	else
	{
		uint32_t nSize = 0;
		void* pData = pcd->ParseXMLFile(szXmlFile, &nSize);
		if (!doc.load_buffer(pData, nSize)) return false;
	}

	pugi::xml_node BulletSet = doc.child("BulletSet");
	BulletVector.clear();
	while (BulletSet)
	{
		Bullet bt;

		bt.nMulriple = BulletSet.attribute("Mulriple").as_int(10);
		bt.nSpeed = BulletSet.attribute("Speed").as_int(500);
		bt.nMaxCatch = BulletSet.attribute("MaxCatch").as_int(1);
		bt.nCatchRadio = BulletSet.attribute("CatchRadio").as_int(50);
		bt.nCannonType = BulletSet.attribute("CannonType").as_int(0);
		bt.nBulletSize = BulletSet.attribute("BRidio").as_int(20);

		if (m_MaxCannon < bt.nMulriple)
			m_MaxCannon = bt.nMulriple;

		pugi::xml_node cat = BulletSet.child("Catch");
		while (cat)
		{
			bt.ProbabilitySet[cat.attribute("FishID").as_int(0)] = cat.attribute("Probability").as_float(MAX_PROBABILITY);
			cat = cat.next_sibling("Catch");
		}

		BulletVector.push_back(bt);

		BulletSet = BulletSet.next_sibling("BulletSet");
	}

	return true;
}

bool CGameConfig::LoadCannonSet(std::string szXmlFile, CXMLDecrypt* pcd)
{
	pugi::xml_document doc;
	if (pcd == NULL)
	{
		if (!doc.load_file(szXmlFile.c_str())) return false;
	}
	else
	{
		uint32_t nSize = 0;
		void* pData = pcd->ParseXMLFile(szXmlFile, &nSize);
		if (!doc.load_buffer(pData, nSize)) return false;
	}
	pugi::xml_node CCPOS = doc.child("CannonPos");
	pugi::xml_node Cannon = CCPOS.child("Cannon");
	CannonPos.resize(GAME_PLAYER + 1);
	while (Cannon)
	{
		int id = Cannon.attribute("id").as_int(0);

		CannonPos[id].m_Position.x_ = Cannon.attribute("PosX").as_float(0.0f);
		CannonPos[id].m_Position.y_ = Cannon.attribute("PosY").as_float(0.0f);
		CannonPos[id].m_Direction = Cannon.attribute("Direction").as_float(0.0f);

		Cannon = Cannon.next_sibling("Cannon");
	}

	pugi::xml_node cef = CCPOS.child("CannonEffect");
	szCannonEffect = cef.attribute("name").as_string();
	EffectPos.x_ = cef.attribute("PosX").as_float(0.0f);
	EffectPos.y_ = cef.attribute("PosY").as_float(0.0f);

	pugi::xml_node tnode = CCPOS.child("LOCK");
	LockInfo.szLockIcon = tnode.attribute("name").as_string();
	LockInfo.szLockLine = tnode.attribute("line").as_string();
	LockInfo.szLockFlag = tnode.attribute("flag").as_string();
	LockInfo.Pos.x_ = tnode.attribute("PosX").as_float(0.0f);
	LockInfo.Pos.y_ = tnode.attribute("PosY").as_float(0.0f);

	tnode = CCPOS.child("Jetton");
	nJettonCount = tnode.attribute("Max").as_int(3);
	JettonPos.x_ = tnode.attribute("PosX").as_float(0.0f);
	JettonPos.y_ = tnode.attribute("PosY").as_float(0.0f);


	Cannon = doc.child("CannonSet");
	CannonSetArray.clear();
	while (Cannon)
	{
		CannonSetS canset;

		canset.bRebound = Cannon.attribute("Rebound").as_bool(true);
		canset.nID = Cannon.attribute("id").as_int(0);
		canset.nNormalID = Cannon.attribute("normal").as_int(0);
		canset.nIonID = Cannon.attribute("ion").as_int(0);
		canset.nDoubleID = Cannon.attribute("double").as_int(0);

		pugi::xml_node CannonType = Cannon.child("CannonType");
		while (CannonType)
		{
			CannonSet ccs;
			ccs.nTypeID = CannonType.attribute("type").as_int(0);

			pugi::xml_node Part = CannonType.child("Part");
			while (Part)
			{
				CannonPart cpt;
				cpt.szResourceName = Part.attribute("ResName").as_string();
				cpt.nResType = Part.attribute("ResType").as_int(0);
				cpt.Pos.x_ = Part.attribute("PosX").as_float(0.0f);
				cpt.Pos.y_ = Part.attribute("PosY").as_float(0.0f);
				cpt.FireOfffest = Part.attribute("FireOffest").as_float(0.0f);
				cpt.nType = Part.attribute("type").as_int(0);
				cpt.RoateSpeed = Part.attribute("RoateSpeed").as_float(0.0f);

				ccs.vCannonParts.push_back(cpt);
				Part = Part.next_sibling("Part");
			}

			tnode = CannonType.child("Bullet");
			while (tnode)
			{
				CannonBullet cb;
				cb.szResourceName = tnode.attribute("ResName").as_string();
				cb.nResType = tnode.attribute("ResType").as_int(0);
				cb.fScale = tnode.attribute("Scale").as_float(1.0f);
				cb.Pos.x_ = tnode.attribute("PosX").as_float(0.0f);
				cb.Pos.y_ = tnode.attribute("PosY").as_float(0.0f);
				ccs.BulletSet.push_back(cb);
				tnode = tnode.next_sibling("Bullet");
			}

			tnode = CannonType.child("Net");
			while (tnode)
			{
				CannonNet ns;
				ns.szResourceName = tnode.attribute("ResName").as_string();
				ns.nResType = tnode.attribute("ResType").as_int(0);
				ns.fScale = tnode.attribute("Scale").as_float(1.0f);
				ns.Pos.x_ = tnode.attribute("PosX").as_float(0.0f);
				ns.Pos.y_ = tnode.attribute("PosY").as_float(0.0f);
				ccs.NetSet.push_back(ns);
				tnode = tnode.next_sibling("Net");
			}

			canset.Sets[ccs.nTypeID] = ccs;
			CannonType = CannonType.next_sibling("CannonType");
		}

		CannonSetArray.push_back(canset);

		Cannon = Cannon.next_sibling("CannonSet");
	}

	return true;
}

bool CGameConfig::LoadVisual(std::string szXmlFile, CXMLDecrypt* pcd)
{
	pugi::xml_document doc;

	if (pcd == NULL)
	{
		if (!doc.load_file(szXmlFile.c_str())) return false;
	}
	else
	{
		uint32_t nSize = 0;
		void* pData = pcd->ParseXMLFile(szXmlFile, &nSize);
		if (!doc.load_buffer(pData, nSize)) return false;
	}

	pugi::xml_node VisualSet = doc.child("VisualSet");
	pugi::xml_node visual = VisualSet.child("Visual");
	VisualMap.clear();
	while (visual)
	{
		Visual vs;
		vs.nID = visual.attribute("Id").as_int();
		vs.nTypeID = visual.attribute("TypeID").as_int();

		pugi::xml_node image = visual.child("LifeImage");
		while (image)
		{
			ImageInfo imi;
			imi.szImageName = image.attribute("Name").as_string();
			imi.fImageScale = image.attribute("Scale").as_float(1.0f);
			imi.ImageOffest.m_Position.x_ = image.attribute("OffestX").as_float(0.0f);
			imi.ImageOffest.m_Position.y_ = image.attribute("OffestY").as_float(0.0f);
			imi.ImageOffest.m_Direction = image.attribute("Direction").as_float(0.0f);

			imi.nAniType = image.attribute("AniType").as_int(0);

			vs.ImageInfoLive.push_back(imi);

			image = image.next_sibling("LifeImage");
		}

		image = visual.child("DeadImage");
		while (image)
		{
			ImageInfo imi;
			imi.szImageName = image.attribute("Name").as_string();
			imi.fImageScale = image.attribute("Scale").as_float(1.0f);

			imi.ImageOffest.m_Position.x_ = image.attribute("OffestX").as_float(0.0f);
			imi.ImageOffest.m_Position.y_ = image.attribute("OffestY").as_float(0.0f);
			imi.ImageOffest.m_Direction = image.attribute("Direction").as_float(0.0f);

			imi.nAniType = image.attribute("AniType").as_int(0);

			vs.ImageInfoDead.push_back(imi);

			image = image.next_sibling("DeadImage");
		}

		VisualMap[vs.nID] = vs;

		visual = visual.next_sibling("Visual");
	}
	return true;
}


bool CGameConfig::LoadSpecialFish(std::string szXmlFile, CXMLDecrypt* pcd)
{
	pugi::xml_document doc;
	if (pcd == NULL)
	{
		if (!doc.load_file(szXmlFile.c_str())) return false;
	}
	else
	{
		uint32_t nSize = 0;
		void* pData = pcd->ParseXMLFile(szXmlFile, &nSize);
		if (!doc.load_buffer(pData, nSize)) return false;
	}

	pugi::xml_node Kf = doc.child("FishKing");
	KingFishMap.clear();
	while (Kf)
	{
		SpecialSet ks;

		ks.nTypeID = Kf.attribute("TypeID").as_int(0);
		ks.fProbability = Kf.attribute("Probability").as_float(0);
		ks.nMaxScore = Kf.attribute("MaxScore").as_int(0);
		ks.fCatchProbability = Kf.attribute("CatchProbability").as_float(0.0f);
		ks.fVisualScale = Kf.attribute("VisualScale").as_float(1.0f);
		ks.nVisualID = Kf.attribute("VisualAttach").as_int(0);
		ks.nBoundingBox = Kf.attribute("BoundingBox").as_int(0);
		ks.nLockLevel = Kf.attribute("LockLevel").as_int(10);

		KingFishMap[ks.nTypeID] = ks;

		Kf = Kf.next_sibling("FishKing");
	}

	Kf = doc.child("FishSanYuan");
	SanYuanFishMap.clear();
	while (Kf)
	{
		SpecialSet ks;

		ks.nTypeID = Kf.attribute("TypeID").as_int(0);
		ks.fProbability = Kf.attribute("Probability").as_float(0);
		// 		ks.nMaxScore = Kf.attribute("MaxScore").as_int(0);
		// 		ks.fCatchProbability = Kf.attribute("CatchProbability").as_float(0.0f);
		ks.fVisualScale = Kf.attribute("VisualScale").as_float(1.0f);
		ks.nVisualID = Kf.attribute("VisualAttach").as_int(0);
		ks.nBoundingBox = Kf.attribute("BoundingBox").as_int(0);
		ks.nLockLevel = Kf.attribute("LockLevel").as_int(10);

		SanYuanFishMap[ks.nTypeID] = ks;

		Kf = Kf.next_sibling("FishSanYuan");
	}

	Kf = doc.child("FishSiXi");
	SiXiFishMap.clear();
	while (Kf)
	{
		SpecialSet ks;

		ks.nTypeID = Kf.attribute("TypeID").as_int(0);
		ks.fProbability = Kf.attribute("Probability").as_float(0);
		// 		ks.nMaxScore = Kf.attribute("MaxScore").as_int(0);
		// 		ks.fCatchProbability = Kf.attribute("CatchProbability").as_float(0.0f);
		ks.fVisualScale = Kf.attribute("VisualScale").as_float(1.0f);
		ks.nVisualID = Kf.attribute("VisualAttach").as_int(0);
		ks.nBoundingBox = Kf.attribute("BoundingBox").as_int(0);
		ks.nLockLevel = Kf.attribute("LockLevel").as_int(10);

		SiXiFishMap[ks.nTypeID] = ks;

		Kf = Kf.next_sibling("FishSiXi");
	}

	return true;
}





