////
#ifndef __PATH_MANAGER_H__
#define __PATH_MANAGER_H__

#include "TSingleton.h"
#include "pugixml.hpp"
#include "MovePoint.h"
#include "XMLDecrypt.h"
#include <vector>
#include <list>
#include <map>

#define  PTCOUNT   4

#define SMALL_PATH		1
#define BIG_PATH		2
#define HUGE_PATH		4

enum NormalPathType
{
	NPT_LINE = 0,
	NPT_BEZIER,
	NPT_CIRCLE,
};
//路径？
struct SPATH
{
	int				type;							//类型
	float			xPos[4];						//
	float			yPos[4];						//
	int				nNext;							//下一个
	int				nDelay;							//延时
	int				PointCount;						//点数量
	int				nPathType;						//路径类型
};
//线形刷鱼
struct ShapeLine
{
	float				x[2];
	float				y[2];
	int					m_nCount;					 //数量
	bool				m_bSame;					 //是否相同？
	int					m_PriceCount;				 //价值总数
    std::vector<int>	m_lTypeList;				 //鱼类型列表
    std::vector<int>	m_lWeight;					 //权重列表
	int					m_nPathID;					 //路径ID
	float				m_fSpeed;					 //速度
	float				m_fInterval;				 //间隔
};
//圆形刷鱼
struct ShapeCircle
{
	float				x;							 //
	float				y;							 //
	float				r;							 //
	int					m_nCount;					 //数量
	bool				m_bSame;					 //是否相同？
	int					m_PriceCount;				 //价值总数
    std::vector<int>	m_lTypeList;				 //鱼类型列表
    std::vector<int>	m_lWeight;					 //权重列表
	int					m_nPathID;					 //路径ID
	float				m_fSpeed;					 //速度
	float				m_fInterval;  				 //间隔
};
//形状点刷鱼
struct ShapePoint
{
	float				x;							 //
	float				y;							 //
	int					m_nCount;					 //鱼总数量
	bool				m_bSame;					 //是否相同？
	std::vector<int>	m_lTypeList;				 //鱼类型列表
	std::vector<int>	m_lWeight;					 //权重列表
	int					m_nPathID;					 //路径ID
	float				m_fSpeed;					 //速度
	float				m_fInterval;				 //间隔
};

struct TroopData
{
	int							nTroopID;				//队ID
	std::vector<std::string>	szDescrib;				//描述
	std::vector<ShapeLine>		LineData;				//线形数据
	std::vector<ShapeCircle>	CircleData;				//贺形数据
	std::vector<ShapePoint>		PointData;				//点形数据
};

struct Troop
{
	int							nTroopID;				//ID
	std::vector<std::string>	Describe;				//描述
	std::vector<int>			nStep;					//步
	std::vector<ShapePoint>		Shape;					//形状
};


class PathManager:public Singleton<PathManager>
{
protected:
	PathManager();
	virtual ~PathManager();

	friend class Singleton<PathManager>;
	friend class std::auto_ptr<PathManager>;

public:
	bool LoadNormalPath(std::string szPathFile, CXMLDecrypt* pcd = NULL);

	SPATH* GetNormalPath(int id);

	SPATH* GetTroopPath(int id);

	bool HasLoaded(){return m_bLoaded;}

	int GetRandNormalPathID();

	MovePoints* GetPathData(int id, bool bTroop);

	bool LoadTroop(std::string szFileName, CXMLDecrypt* pcd = NULL);

	void CreatTroopByData(TroopData& td, Troop& tp);

	Troop* GetTroop(int id);

	void SaveNormalPath(std::string szFileName);
	void SaveTroop(std::string szFileName);

	void CreatePathByData(SPATH* sp, bool xMirror, bool yMirror, bool xyMirror, bool Not, bool troop, MovePoints& out);

	std::vector<SPATH>		m_NormalPaths;                          //普通群体路径
	std::map<int, SPATH>	m_TroopPath;                            //鱼群路径
	std::map<int, Troop>	m_TroopMap;                             //群表
	bool					m_bLoaded;                              //是否加载

	std::map<int, TroopData>	m_TroopData;			            //群数据表

	std::vector<MovePoints>		m_NormalPathVector;					//普通路径组
	std::map<int, MovePoints>	m_TroopPathMap;						//鱼群路径
};

#endif
