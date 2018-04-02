#include "common.h"
#include "PathManager.h"
#include "CommonLogic.h"
#include "MathAide.h"
#include "GameConfig.h"
//#include "../消息定义/CMD_Fish.h"
#include <math.h>
#include "BezierCurve.h"

SingletonInstance(PathManager);

PathManager::PathManager()
:m_bLoaded(false)
{
}

PathManager::~PathManager()
{
	m_NormalPaths.clear();
}

SPATH* PathManager::GetNormalPath(int id)
{
	if(!m_bLoaded || id < 0)
	{
		return NULL;
	}

	return &(m_NormalPaths[id % m_NormalPaths.size()]);
}

MovePoints* PathManager::GetPathData(int id, bool bTroop)
{
	if(!m_bLoaded || id < 0)
	{
		return NULL;
	}

	if(bTroop)
	{
		if(m_TroopPathMap.find(id) != m_TroopPathMap.end())
			return &(m_TroopPathMap[id]);
		else
			return NULL;
	}
	else
		return &(m_NormalPathVector[id % m_NormalPathVector.size()]);
}

SPATH* PathManager::GetTroopPath(int id)
{
	std::map<int, SPATH>::iterator it = m_TroopPath.find(id);
	if(it != m_TroopPath.end())
		return &(it->second);

	return NULL;
}

Troop* PathManager::GetTroop(int id)
{
	std::map<int, Troop>::iterator it = m_TroopMap.find(id);
	if(it == m_TroopMap.end()) return NULL;

	return &(it->second);
}

int PathManager::GetRandNormalPathID()
{
	if(!m_bLoaded)
		return 0;

	return RandInt(0, m_NormalPathVector.size()-1);
}

void PathManager::CreatTroopByData(TroopData& td, Troop& tp)
{
	tp.Describe.clear();
	tp.Shape.clear();
	tp.nStep.clear();

	tp.nTroopID = td.nTroopID;

	std::vector<std::string>::iterator ids = td.szDescrib.begin();
	while(ids != td.szDescrib.end())
	{
		if((*ids).length() > 0)
		{
			/*TCHAR szinof[256];
			uint32_t	nLen = MultiByteToWideChar(CP_UTF8, 0, (*ids).c_str(), (*ids).length(), NULL, 0);
			MultiByteToWideChar(CP_UTF8, 0,(*ids).c_str(), (*ids).length(), szinof, nLen);
			szinof[nLen] = TCHAR('\0');

			tp.Describe.push_back(szinof);*/
			tp.Describe.push_back(*ids);
		}
		++ids;
	}

	for (ShapeLine sl:td.LineData)
	{
		MovePoints TraceVector;

		int nc = sl.m_nCount-1;
		if(nc <= 0) nc = 1;
		CMathAide::BuildLinear(sl.x, sl.y, 2, TraceVector, CMathAide::CalcDistance(sl.x[0],sl.y[0],sl.x[1],sl.y[1])/nc);
		nc = TraceVector.size();

		for(int i = 0; i < nc; ++i)
		{
			ShapePoint tt;
			tt.x = TraceVector[i].m_Position.x_;
			tt.y = TraceVector[i].m_Position.y_;
			tt.m_bSame = sl.m_bSame;
			tt.m_nCount = sl.m_PriceCount;
			tt.m_nPathID = sl.m_nPathID;
			tt.m_fInterval = sl.m_fInterval;
			tt.m_fSpeed = sl.m_fSpeed;

			int nt = min(sl.m_lTypeList.size(), sl.m_lWeight.size());
			for(int j = 0; j < nt; ++j)
			{
				tt.m_lTypeList.push_back(sl.m_lTypeList[j]);
				tt.m_lWeight.push_back(sl.m_lWeight[j]);
			}
			tp.Shape.push_back(tt);
		}
		tp.nStep.push_back(nc);
	}

	for (ShapeCircle sc: td.CircleData)
	{
		MovePoints TraceVector;

		int nc = sc.m_nCount;
		if(nc <= 0) nc = 1;
		CMathAide::BuildCircle(sc.x, sc.y, sc.r, TraceVector, nc);
		nc = TraceVector.size();

		for(int i = 0; i < nc; ++i)
		{
			ShapePoint tt;
			tt.x = TraceVector[i].m_Position.x_;
			tt.y = TraceVector[i].m_Position.y_;
			tt.m_bSame = sc.m_bSame;
			tt.m_nCount = sc.m_PriceCount;
			tt.m_nPathID = sc.m_nPathID;
			tt.m_fInterval = sc.m_fInterval;
			tt.m_fSpeed = sc.m_fSpeed;

			int nt = min(sc.m_lTypeList.size(), sc.m_lWeight.size());
			for(int j = 0; j < nt; ++j)
			{
				tt.m_lTypeList.push_back(sc.m_lTypeList[j]);
				tt.m_lWeight.push_back(sc.m_lWeight[j]);
			}
			tp.Shape.push_back(tt);
		}
		tp.nStep.push_back(nc);
	}

	std::vector<ShapePoint>::iterator ip = td.PointData.begin();
	while(ip != td.PointData.end())
	{
		tp.Shape.push_back(*ip);
		tp.nStep.push_back(1);
		++ip;
	}
}

bool PathManager::LoadTroop(std::string szFileName, CXMLDecrypt* pcd)
{
	pugi::xml_document doc;

	if(pcd == NULL)
	{
		if(!doc.load_file(szFileName.c_str())) return false;
	}
	else
	{
		uint32_t nSize = 0;
		void* pData = pcd->ParseXMLFile(szFileName, &nSize);
		if(!doc.load_buffer(pData, nSize)) return false;
	}
	pugi::xml_node TPS = doc.child("TroopSet");
	while(!TPS.empty())
	{
		TroopData td;
	
		td.nTroopID = TPS.attribute("id").as_int(0);
		pugi::xml_node des = TPS.child("DescribeText");
		while(!des.empty())
		{
			td.szDescrib.push_back(des.attribute("content").as_string("0"));
			if(td.szDescrib.size() >= 4) break;
			des = des.next_sibling("DescribeText");
		}

		pugi::xml_node shape = TPS.child("Shape");
		while(!shape.empty())
		{
			int type = shape.attribute("type").as_int(0);
			if(type == 0)//直线
			{
				ShapeLine sl;
				sl.x[0] = shape.attribute("PosX1").as_float();
				sl.x[1] = shape.attribute("PosX2").as_float();
				sl.y[0] = shape.attribute("PosY1").as_float();
				sl.y[1] = shape.attribute("PosY2").as_float();
				sl.m_bSame = shape.attribute("Same").as_bool();
				sl.m_PriceCount = shape.attribute("PiceCount").as_int(1);
				sl.m_nCount = shape.attribute("Count").as_int(0);
				sl.m_nPathID = shape.attribute("Path").as_int(0);
				sl.m_fInterval = shape.attribute("interval").as_float(0);
				sl.m_fSpeed = shape.attribute("Speed").as_int(0);

				int nt = shape.attribute("TypeCount").as_int(0);
				const char* ts = shape.attribute("FishType").as_string("0");
				const char* tw = shape.attribute("Weigth").as_string("0");
				char* temp = NULL;
				char* twmp = NULL;
				for(int j = 0; j < nt; ++j)
				{
					int nn = 0;
					if(j == 0)
						nn = strtoul(ts, &temp, 10);
					else
						nn = strtoul(temp+1, &temp, 10);

					sl.m_lTypeList.push_back(nn);

					if(j == 0)
						nn = strtoul(tw, &twmp, 10);
					else
						nn = strtoul(twmp+1, &twmp, 10);

					if(nn <= 0 || nn > 100) nn = 1;
					sl.m_lWeight.push_back(nn);
				}

				td.LineData.push_back(sl);
			}
			else if(type == 1)//圆
			{
				ShapeCircle sc;
				sc.x = shape.attribute("CenterX").as_float();
				sc.y = shape.attribute("CenterY").as_float();
				sc.r = shape.attribute("Radio").as_float();
				sc.m_bSame = shape.attribute("Same").as_bool();
				sc.m_PriceCount = shape.attribute("PiceCount").as_int(1);
				sc.m_nCount = shape.attribute("Count").as_int(0);
				sc.m_nPathID = shape.attribute("Path").as_int(0);
				sc.m_fInterval = shape.attribute("interval").as_float(0);
				sc.m_fSpeed = shape.attribute("Speed").as_int(0);

				int nt = shape.attribute("TypeCount").as_int(0);
				const char* ts = shape.attribute("FishType").as_string("0");
				const char* tw = shape.attribute("Weigth").as_string("0");
				char* temp = NULL;
				char* twmp = NULL;
				for(int j = 0; j < nt; ++j)
				{
					int nn = 0;
					if(j == 0)
						nn = strtoul(ts, &temp, 10);
					else
						nn = strtoul(temp+1, &temp, 10);

					sc.m_lTypeList.push_back(nn);

					if(j == 0)
						nn = strtoul(tw, &twmp, 10);
					else
						nn = strtoul(twmp+1, &twmp, 10);

					if(nn <= 0 || nn > 100) nn = 1;
					sc.m_lWeight.push_back(nn);
				}

				td.CircleData.push_back(sc);
			}

			shape = shape.next_sibling("Shape");
		}

		pugi::xml_node pt = TPS.child("Point");
		while(!pt.empty())
		{
			ShapePoint tt;
			tt.x = pt.attribute("PosX").as_float(0);
			tt.y = pt.attribute("PosY").as_float(0);
			tt.m_bSame = pt.attribute("Same").as_bool();
			tt.m_nCount = pt.attribute("Count").as_int(1);
			tt.m_nPathID = pt.attribute("Path").as_int(0);
			tt.m_fInterval = pt.attribute("interval").as_float(0);
			tt.m_fSpeed = pt.attribute("Speed").as_int(0);

			int nt = pt.attribute("TypeCount").as_int(0);
			const char* ts = pt.attribute("FishType").as_string("0");
			const char* tw = pt.attribute("Weigth").as_string("0");
			char* temp = NULL;
			char* twmp = NULL;
			for(int j = 0; j < nt; ++j)
			{
				int nn = 0;
				if(j == 0)
					nn = strtoul(ts, &temp, 10);
				else
					nn = strtoul(temp+1, &temp, 10);

				tt.m_lTypeList.push_back(nn);

				if(j == 0)
					nn = strtoul(tw, &twmp, 10);
				else
					nn = strtoul(twmp+1, &twmp, 10);

				if(nn <= 0 || nn > 100) nn = 1;
				tt.m_lWeight.push_back(nn);
			}

			td.PointData.push_back(tt);
			pt = pt.next_sibling("Point");
		}
		m_TroopData[td.nTroopID] = td;

		Troop trp;
		CreatTroopByData(td, trp);
		m_TroopMap[td.nTroopID] = trp;

		TPS = TPS.next_sibling("TroopSet");
	}

	pugi::xml_node TPP = doc.child("Path");
	while(!TPP.empty())
	{
		int id = TPP.attribute("id").as_int(0);

		SPATH pd;
		ZeroMemory(&pd, sizeof(SPATH));

		pd.type = TPP.attribute("Type").as_int(0);
		pd.PointCount = 0;

		pugi::xml_node pt = TPP.child("Position");
		while(!pt.empty())
		{
			pd.xPos[pd.PointCount] = pt.attribute("x").as_float(0.0f);

			pd.yPos[pd.PointCount++] = pt.attribute("y").as_float(0.0f);

			pt = pt.next_sibling("Position");
		}

		if(pd.type == NPT_LINE)
		{
			pd.PointCount = 2;
		}
		else if(pd.type == NPT_BEZIER)
		{
			if(pd.xPos[3] == 0.0f && pd.yPos[3] == 0.0f)
				pd.PointCount = 3;
		}
		else
		{
			pd.PointCount = PTCOUNT;
		}

		pd.nNext = TPP.attribute("Next").as_int(0);
		pd.nDelay = TPP.attribute("Delay").as_int(0);

		m_TroopPath[id] = pd;
		
		TPP = TPP.next_sibling("Path");
	}

 	std::list<int> exclude;
 
 	std::map<int, SPATH>::iterator itp = m_TroopPath.begin();
 	while(itp != m_TroopPath.end())
 	{
 		SPATH& sph = itp->second;
 
 		std::list<int>::iterator ie = exclude.begin();
 		while(ie != exclude.end())
 		{
 			if(itp->first == *ie)
 				break;
 			++ie;
 		}
 		if(ie != exclude.end()) 
 		{
 			++itp;
 			continue;
 		}
 
 		int nxt = sph.nNext;
 		while(nxt > 0 && m_TroopPath.find(nxt) != m_TroopPath.end())
 		{
 			exclude.push_back(nxt);
 			nxt = m_TroopPath[nxt].nNext;
 		}
 
 		MovePoints path;
 		CreatePathByData(&sph, false, false, false, false, true, path);		
 
 		m_TroopPathMap[itp->first] = path;
 
 		++itp;
 	}

	return true;
}



void PathManager::SaveTroop(std::string szFileName)
{
	pugi::xml_document doc;
	std::map<int, TroopData>::iterator it = m_TroopData.begin();
	while(it != m_TroopData.end())
	{
		TroopData td = it->second;
		
		pugi::xml_node TPS = doc.append_child("TroopSet");
		pugi::xml_attribute tid = TPS.append_attribute("id");
		tid.set_value(td.nTroopID);

		std::vector<std::string>::iterator ids = td.szDescrib.begin();
		while(ids != td.szDescrib.end())
		{
			pugi::xml_node des = TPS.append_child("DescribeText");
			pugi::xml_attribute con = des.append_attribute("content");
			con.set_value(ids->c_str());
			++ids;
		}

		std::vector<ShapeLine>::iterator idl = td.LineData.begin();
		while(idl != td.LineData.end())
		{
			ShapeLine sl = *idl;

			pugi::xml_node sp = TPS.append_child("Shape");
			pugi::xml_attribute type = sp.append_attribute("type");
			type.set_value(0);

			pugi::xml_attribute  x1= sp.append_attribute("PosX1");
			x1.set_value(sl.x[0]);
			pugi::xml_attribute  x2= sp.append_attribute("PosX2");
			x2.set_value(sl.x[1]);

			pugi::xml_attribute  y1= sp.append_attribute("PosY1");
			y1.set_value(sl.y[0]);
			pugi::xml_attribute  y2= sp.append_attribute("PosY2");
			y2.set_value(sl.y[1]);

			pugi::xml_attribute cnt = sp.append_attribute("Count");
			cnt.set_value(sl.m_nCount);

			pugi::xml_attribute pcnt = sp.append_attribute("PiceCount");
			pcnt.set_value(sl.m_PriceCount);

			pugi::xml_attribute pid = sp.append_attribute("Path");
			pid.set_value(sl.m_nPathID);

			pugi::xml_attribute bsam = sp.append_attribute("Same");
			bsam.set_value(sl.m_bSame);

			pugi::xml_attribute speed = sp.append_attribute("Speed");
			speed.set_value(sl.m_fSpeed);

			pugi::xml_attribute interval = sp.append_attribute("interval");
			interval.set_value(sl.m_fInterval);

			int nsize = min(sl.m_lTypeList.size(), sl.m_lWeight.size());
			if(nsize > 0)
			{
				pugi::xml_attribute fnt = sp.append_attribute("TypeCount");
				fnt.set_value(nsize);

				char fish[256], weigth[256], temp[32];
				fish[0] = weigth[0] = temp[0] = '\0';

				for(int i = 0; i < nsize; ++i)
				{
					if(i == 0)
						_snprintf_s(temp, _TRUNCATE, "%d", sl.m_lTypeList[i]);
					else
						_snprintf_s(temp, _TRUNCATE, ",%d", sl.m_lTypeList[i]);

					strncat_s(fish,temp,_TRUNCATE);

					if(i == 0)
						_snprintf_s(temp, _TRUNCATE, "%d", sl.m_lWeight[i]);
					else
						_snprintf_s(temp, _TRUNCATE, ",%d", sl.m_lWeight[i]);

					strncat_s(weigth,temp,_TRUNCATE);
				}

				pugi::xml_attribute ftl = sp.append_attribute("FishType");
				ftl.set_value(fish);
				
				pugi::xml_attribute wgl = sp.append_attribute("Weigth");
				wgl.set_value(weigth);
			}
			++idl;
		}

		std::vector<ShapeCircle>::iterator idc = td.CircleData.begin();
		while(idc != td.CircleData.end())
		{
			ShapeCircle sl = *idc;

			pugi::xml_node sp = TPS.append_child("Shape");
			pugi::xml_attribute type = sp.append_attribute("type");
			type.set_value(1);

			pugi::xml_attribute  x= sp.append_attribute("CenterX");
			x.set_value(sl.x);
		
			pugi::xml_attribute  y= sp.append_attribute("CenterY");
			y.set_value(sl.y);

			pugi::xml_attribute  r= sp.append_attribute("Radio");
			r.set_value(sl.r);

			pugi::xml_attribute cnt = sp.append_attribute("Count");
			cnt.set_value(sl.m_nCount);

			pugi::xml_attribute pcnt = sp.append_attribute("PiceCount");
			pcnt.set_value(sl.m_PriceCount);

			pugi::xml_attribute bsam = sp.append_attribute("Same");
			bsam.set_value(sl.m_bSame);

			pugi::xml_attribute pid = sp.append_attribute("Path");
			pid.set_value(sl.m_nPathID);

			pugi::xml_attribute speed = sp.append_attribute("Speed");
			speed.set_value(sl.m_fSpeed);

			pugi::xml_attribute interval = sp.append_attribute("interval");
			interval.set_value(sl.m_fInterval);

			int nsize = min(sl.m_lTypeList.size(), sl.m_lWeight.size());
			if(nsize > 0)
			{
				pugi::xml_attribute fnt = sp.append_attribute("TypeCount");
				fnt.set_value(nsize);

				char fish[256], weigth[256], temp[32];
				fish[0] = weigth[0] = temp[0] = '\0';

				for(int i = 0; i < nsize; ++i)
				{
					if(i == 0)
						_snprintf_s(temp, _TRUNCATE, "%d", sl.m_lTypeList[i]);
					else
						_snprintf_s(temp, _TRUNCATE, ",%d", sl.m_lTypeList[i]);

					strncat_s(fish,temp,_TRUNCATE);
					
					if(i == 0)
						_snprintf_s(temp, _TRUNCATE, "%d", sl.m_lWeight[i]);
					else
						_snprintf_s(temp, _TRUNCATE, ",%d", sl.m_lWeight[i]);

					strncat_s(weigth,temp,_TRUNCATE);
				}

				pugi::xml_attribute ftl = sp.append_attribute("FishType");
				ftl.set_value(fish);

				pugi::xml_attribute wgl = sp.append_attribute("Weigth");
				wgl.set_value(weigth);
			}
			++idc;
		}

		std::vector<ShapePoint>::iterator idp = td.PointData.begin();
		while(idp != td.PointData.end())
		{
			ShapePoint sl = *idp;

			pugi::xml_node sp = TPS.append_child("Point");

			pugi::xml_attribute  x= sp.append_attribute("PosX");
			x.set_value(sl.x);

			pugi::xml_attribute  y= sp.append_attribute("PosY");
			y.set_value(sl.y);

			pugi::xml_attribute cnt = sp.append_attribute("Count");
			cnt.set_value(sl.m_nCount);

			pugi::xml_attribute pid = sp.append_attribute("Path");
			pid.set_value(sl.m_nPathID);

			pugi::xml_attribute speed = sp.append_attribute("Speed");
			speed.set_value(sl.m_fSpeed);

			pugi::xml_attribute bsam = sp.append_attribute("Same");
			bsam.set_value(sl.m_bSame);

			pugi::xml_attribute interval = sp.append_attribute("interval");
			interval.set_value(sl.m_fInterval);

			int nsize = min(sl.m_lTypeList.size(), sl.m_lWeight.size());
			if(nsize > 0)
			{
				pugi::xml_attribute fnt = sp.append_attribute("TypeCount");
				fnt.set_value(nsize);

				char fish[256], weigth[256], temp[32];
				fish[0] = weigth[0] = temp[0] = '\0';

				for(int i = 0; i < nsize; ++i)
				{
					if(i == 0)
						_snprintf_s(temp, _TRUNCATE, "%d", sl.m_lTypeList[i]);
					else
						_snprintf_s(temp, _TRUNCATE, ",%d", sl.m_lTypeList[i]);

					strncat_s(fish,temp,_TRUNCATE);

					if(i == 0)
						_snprintf_s(temp, _TRUNCATE, "%d", sl.m_lWeight[i]);
					else
						_snprintf_s(temp, _TRUNCATE, ",%d", sl.m_lWeight[i]);

					strncat_s(weigth,temp,_TRUNCATE);
				}

				pugi::xml_attribute ftl = sp.append_attribute("FishType");
				ftl.set_value(fish);

				pugi::xml_attribute wgl = sp.append_attribute("Weigth");
				wgl.set_value(weigth);
			}
			++idp;
		}

		++it;
	}

	std::map<int, SPATH>::iterator ipp = m_TroopPath.begin();
	while(ipp != m_TroopPath.end())
	{
		SPATH sp = ipp->second;

		pugi::xml_node path = doc.append_child("Path");

		pugi::xml_attribute id = path.append_attribute("id");
		id.set_value(ipp->first);

		pugi::xml_attribute type = path.append_attribute("Type");
		type.set_value(sp.type);

		pugi::xml_attribute next = path.append_attribute("Next");
		next.set_value(sp.nNext);

		pugi::xml_attribute delay = path.append_attribute("Delay");
		delay.set_value(sp.nDelay);

		for(int i = 0; i < PTCOUNT; ++i)
		{
			pugi::xml_node post = path.append_child("Position");

			pugi::xml_attribute xpos = post.append_attribute("x");	
			xpos.set_value(sp.xPos[i]);

			pugi::xml_attribute ypos= post.append_attribute("y");
			ypos.set_value(sp.yPos[i]);
		}

		++ipp;
	}


	doc.save_file(szFileName.c_str(),  PUGIXML_TEXT("\t"), pugi::format_default, pugi::encoding_utf8);
}

void PathManager::SaveNormalPath(std::string szFileName)
{
	pugi::xml_document doc;

	pugi::xml_node FPS = doc.append_child("FishPath");

	std::vector<SPATH>::iterator it = m_NormalPaths.begin();
	while(it != m_NormalPaths.end())
	{
		SPATH sp = *it;

		pugi::xml_node path = FPS.append_child("Path");

		pugi::xml_attribute type = path.append_attribute("Type");
		type.set_value(sp.type);
	
		pugi::xml_attribute next = path.append_attribute("Next");
		next.set_value(sp.nNext);
		
		pugi::xml_attribute delay = path.append_attribute("Delay");
		delay.set_value(sp.nDelay);

		for(int i = 0; i < PTCOUNT; ++i)
		{
			pugi::xml_node post = path.append_child("Position");

			pugi::xml_attribute xpos = post.append_attribute("x");
			xpos.set_value(sp.xPos[i]);
			pugi::xml_attribute ypos= post.append_attribute("y");
			ypos.set_value(sp.yPos[i]);
		}

		++it;
	}

	doc.save_file(szFileName.c_str(),  PUGIXML_TEXT("\t"), pugi::format_default, pugi::encoding_utf8);
}

bool PathManager::LoadNormalPath(std::string szPathFile, CXMLDecrypt* pcd)
{
	pugi::xml_document doc;

	if(pcd == NULL)
	{
		if(!doc.load_file(szPathFile.c_str())) return false;
	}
	else
	{
		uint32_t nSize = 0;
		void* pData = pcd->ParseXMLFile(szPathFile, &nSize);
		if(!doc.load_buffer(pData, nSize)) return false;
	}

 	pugi::xml_node FishPath = doc.child("FishPath");
 	pugi::xml_node path = FishPath.child("Path");
 	while(!path.empty())
 	{
 		SPATH pd;
 		ZeroMemory(&pd, sizeof(SPATH));
 
 		pd.type = path.attribute("Type").as_int(0);
 		pd.PointCount = 0;
 		pd.nNext = path.attribute("Next").as_int(0);
 		pd.nDelay = path.attribute("Delay").as_int(0);
		pd.nPathType = path.attribute("Type").as_int(7);
 
 		pugi::xml_node pt = path.child("Position");
 		while(!pt.empty())
 		{
 			pd.xPos[pd.PointCount] = pt.attribute("x").as_float(0.0f);
 
 			pd.yPos[pd.PointCount++] = pt.attribute("y").as_float(0.0f);
 
 			pt = pt.next_sibling("Position");
 		}

		if(pd.type == NPT_LINE)
		{
			pd.PointCount = 2;
		}
		else if(pd.type == NPT_BEZIER)
		{
			if(pd.xPos[3] == 0.0f && pd.yPos[3] == 0.0f)
				pd.PointCount = 3;
		}
		else
		{
			pd.PointCount = PTCOUNT;
		}
 
 		m_NormalPaths.push_back(pd);
 
 		path = path.next_sibling("Path");
 	}

	int nsize = m_NormalPaths.size();
	m_bLoaded = nsize > 0;

	std::vector<int> exclude;
	for(int i = 0; i < nsize; ++i)
	{
		SPATH& sph = m_NormalPaths[i];
		
		auto ie = exclude.begin();
		while(ie != exclude.end())
		{
			if(i == *ie)
				break;
			++ie;
		}
		if(ie != exclude.end()) continue;
		
		int nxt = sph.nNext;
		while(nxt > 0 && nxt < nsize)
		{
			exclude.push_back(nxt);
			nxt = m_NormalPaths[nxt].nNext;
		}

		MovePoints path;

 		for(int x = 0; x < 2; ++x)
 		{
 			for (int y = 0; y < 2; ++y)
 			{
 				for(int xy = 0; xy < 2; ++xy)
 				{
 					for(int not = 0; not < 2; ++not)
 					{
 						CreatePathByData(&sph, x == 0, y == 0, xy == 0, not == 0, false, path);		
 						m_NormalPathVector.push_back(path);
 					}
 				}
 			}
 		}
	}

	return true;
}

void PathManager::CreatePathByData(SPATH* sp, bool xMirror, bool yMirror, bool xyMirror, bool Not, bool troop, MovePoints& out)
{
	out.clear();
	while(sp != NULL)
	{
		MovePoints path;

		float x[4], y[4];
		for (int n = 0; n < sp->PointCount; ++n)
		{
			x[n] = sp->xPos[n];
			y[n] = sp->yPos[n];
		}

		if(xMirror)
		{
			if(sp->type == NPT_CIRCLE)
			{
				x[0] = 1.0f - x[0];
				x[2] = M_PI - x[2];
				y[2] = -y[2];
			}
			else
			{
				for (int n = 0; n < sp->PointCount; ++n)
				{
					x[n] = 1.0f - x[n];
				}
			}
		}
		if(yMirror)
		{
			if(sp->type == NPT_CIRCLE)
			{
				y[0] = 1.0f - y[0];
				x[2] = 2 * M_PI - x[2];
				y[2] = -y[2];
			}
			else
			{
				for (int n = 0; n < sp->PointCount; ++n)
				{
					y[n] = 1.0f - y[n];
				}
			}
		}

		if(xyMirror)
		{
			if(sp->type == NPT_CIRCLE)
			{
				float t = x[0];
				x[0] = 1.0f - y[0];
				y[0] = 1.0f - t;
				x[2] += M_PI_2;
			}
			else
			{
				for (int n = 0; n < sp->PointCount; ++n)
				{
					float t = x[n];
					x[n] = y[n];
					y[n] = t;
				}
			}
		}

		if(Not)//取反
		{
			if(sp->type == NPT_CIRCLE)
			{
				x[2] += y[2];
				y[2] = -y[2];
			}
			else
			{
				for (int n = 0; n < sp->PointCount / 2; ++n)
				{
					float t = x[n];
					x[n] = x[sp->PointCount-1-n];
					x[sp->PointCount-1-n] = t;

					t = y[n];
					y[n] = y[sp->PointCount-1-n];
					y[sp->PointCount-1-n] = t;
				}
			}
		}

		
		for (int n = 0; n < sp->PointCount; ++n)
		{
			x[n] = x[n] * CGameConfig::GetInstance()->nDefaultWidth;
			y[n] = y[n] * CGameConfig::GetInstance()->nDefaultHeight;

			if(sp->type == NPT_CIRCLE)
				break;
		}

		if(sp->type == NPT_LINE)
			CMathAide::BuildLinear(x, y, sp->PointCount, path, 1.0f);
		else if (sp->type == NPT_BEZIER)
		{
			//CMathAide::BuildBezier(x, y, sp->PointCount, path, 1.0f);
			CBezierCurve::GetInstance()->Bezier2D(x, y, sp->PointCount, 2000, path, 1.0f);
		}
		else if(sp->type == NPT_CIRCLE)
			CMathAide::BuildCirclePath(x[0], y[0], x[1], path, x[2], y[2], 1, y[1]);

// 		CMovePoint* pt = NULL;
// 		MovePoints::iterator ip = path.begin();
// 		while(ip != path.end())
// 		{
// 			pt = &(*ip);
// 			out.push_back(*ip);
// 			++ip;
// 		}
// 
// 		if(sp->nDelay != 0 && pt != NULL)
// 		{
// 			for(int i = 0; i < sp->nDelay; ++i)
// 				out.push_back(*pt);
// 		}

 		MovePoints::iterator ip = path.begin();
		while (ip != path.end())
		{
			out.push_back(*ip);
			++ip;
		}

		if (sp->nDelay != 0)
		{
			CMovePoint& pt = path[path.size() - 1];
			for (int i = 0; i < sp->nDelay; ++i)
				out.push_back(pt);
		}

		if(troop)
		{
			int nxt = sp->nNext;
			if (nxt > 0 && m_TroopPath.find(nxt) != m_TroopPath.end())
			{
				sp = &(m_TroopPath[nxt]);
			} 
			else
			{
				break;
			}
		}
		else
		{
			if(sp->nNext > 0 && sp->nNext < m_NormalPaths.size())
			{
				sp = &(m_NormalPaths[sp->nNext]);
			}
			else
			{
				break;
			}
		}
	}	
}








