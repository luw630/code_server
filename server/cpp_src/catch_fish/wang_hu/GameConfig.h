#ifndef __GAME_CONFIG_H__
#define __GAME_CONFIG_H__

#include "TSingleton.h"
#include "Size.h"
#include "MovePoint.h"
#include <string>
#include <map>
#include <vector>
#include <list>
#include "VisualCompent.h"
#include "XMLDecrypt.h"

//特殊鱼类型
enum SpecialFishType
{
	ESFT_NORMAL = 0,                        //普通
	ESFT_KING,                              //鱼王
	ESFT_KINGANDQUAN,                       //鱼后
	ESFT_SANYUAN,                           //大三元
	ESFT_SIXI,                              //大四喜
	ESFT_MAX,                               //最大
};

struct Effect
{
	int					nTypeID;            //效果ID
	std::vector<int>	nParam;             //参数
};

struct Buffer
{
	int					nTypeID;            //ID
	float				fParam;             //增加值
	float				fLife;              //持续时间
};

//可优 前端 视觉
struct Visual
{
	int							nID;
	int							nTypeID;
	std::list<ImageInfo>		ImageInfoLive;
	std::list<ImageInfo>		ImageInfoDead;
};
//绑定体 单点
struct BB
{
	float			fRadio;             //半径
	int				nOffestX;           //X坐标偏移
	int				nOffestY;           //Y坐标偏移
};
//绑定体
struct BBX
{
	int				nID;                // ID
	std::list<BB>	BBList;             // 各点列表
};
//鱼
struct Fish
{
	int					nTypeID;
	TCHAR				szName[256];			//名字
	bool				bBroadCast;				//是否广播
	float				fProbability;			//概率
	int					nVisualID;				//视觉ID
	int					nSpeed;					//速度
	int					nBoundBox;				//绑定盒子
	std::list<Effect>	EffectSet;				//效果列表
	std::list<Buffer>	BufferSet;				//buffer列表
	bool				bShowBingo;				//显示效果
	std::string			szParticle;				//品质
	bool				bShakeScree;			//搅动？  可优
	int					nLockLevel;				//锁定等级
};

struct Bullet
{
	int						nMulriple;				//子弹价格
	int						nSpeed;					//速度
	int						nMaxCatch;				//最大抓捕值？ 无调用 可优
	int						nBulletSize;			//子弹大小
	int						nCatchRadio;			//抓捕 广播？半径？
	int						nCannonType;			//子弹类型
	std::map<int, float>	ProbabilitySet;			//概率集？
};
//刷新类型
enum RefershType
{
	ERT_NORMAL = 0,
	ERT_GROUP,					//鱼群
	ERT_LINE,					//鱼队
	ERT_SNAK,					//大蛇
};
//干扰鱼群集
struct DistrubFishSet
{
	float				ftime;              //时间
	int					nMinCount;          //最小数量
	int					nMaxCount;          //最大数量
	int					nRefershType;       //刷新的类型
	std::vector<int>	FishID;             //鱼ID列表
	std::vector<int>	Weight;             //权重
	float				OffestX;            //X坐标偏移
    float				OffestY;            //Y坐标偏移
	float				OffestTime;         //时间偏移
};
//刷鱼时间设置
struct TroopSet
{
	float				fBeginTime;         //开始时间
	float				fEndTime;           //结束时间
	int					nTroopID;           //鱼群ID
};
//场景设置
struct SceneSet
{
	int							nID;                //当前场景ID
	int							nNextID;            //下一场景ID
	std::string					szMap;              //场景名字？ 可优
	float						fSceneTime;         //场景时间
	std::list<TroopSet>			TroopList;          //刷鱼时间列表
	std::list<DistrubFishSet>	DistrubList;        //干扰鱼列表 
};

struct SoundSet
{
	std::string	szFoundName;			//名字
	int			m_nProbility;			//概率
};

//特殊设置
struct SpecialSet
{
	int			nTypeID;
	int			nSpecialType;			//类型
	float		fProbability;			//概率
	int			nMaxScore;				//最大分数
	float		fCatchProbability;		//捕捉概率
	float		fVisualScale;			//视觉尺度
	int			nVisualID;				//视觉ID
	int			nBoundingBox;			//绑定盒子
	int			nLockLevel;				//锁定等级
};
//第一次开火
struct FirstFire
{
	int						nLevel;                 //等级
	int						nCount;                 //数量
	int						nPriceCount;            //价格总数
	std::vector<int>		FishTypeVector;         //鱼类型
	std::vector<int>		WeightVector;           //权重
};
//资源类型  前端资源 可优
enum ResourceType
{
	ERST_Sprite = 0,               //
	ERST_Animation,                //
	ERST_Particle,                 //
};
//渲染 可优
enum RenderState
{
	ERSS_Normal = 1,
	ERSS_FIRE	= 2,
	ERSS_Mul	= 4,
	ERSS_Score	= 8,
};
//部位类型
enum PartType
{
	EPT_BASE = 0,
	EPT_CANNON,
	EPT_EFFECT,
	EPT_CANNUM,
	EPT_SCORE,
	EPT_TAG,
};
//大炮
struct CannonPart
{
    std::string		szResourceName;         //名字
    int				nResType;               //资源类型
    int				nType;                  //类型
    MyPoint			Pos;                    //坐标
    int				FireOfffest;            //开火偏移？
    float			RoateSpeed;             //子弹 速度 ？
};

//大炮锁定 可优
struct CannonLock
{
	std::string		szLockIcon;             
	std::string		szLockLine;
	std::string		szLockFlag;
	MyPoint			Pos;
};
//可优
struct CannonIon
{
	std::string		szIonFlag;
	MyPoint			Pos;
};

//大炮子弹
typedef struct CannonBullet
{
	std::string		szResourceName;         //名字
	int				nResType;               //资源类型
	MyPoint			Pos;                    //坐标
	float			fScale;                 //规模
} CannonNet;

//大炮集
struct CannonSet
{
	int							nTypeID;             //类型ID
	std::vector<CannonPart>		vCannonParts;        //大炮类型
	std::vector<CannonBullet>	BulletSet;           //子弹集
	std::vector<CannonNet>		NetSet;              //网集
};	

//大炮设置集
struct CannonSetS
{
	int							nID;                //
	int							nNormalID;          //普通ID
	int							nIonID;             //图标ID
	int							nDoubleID;          //双倍ID
	bool						bRebound;           //是否绑定
	std::map<int, CannonSet>	Sets;               //集
};

class CGameConfig : public Singleton <CGameConfig>
{
public:	
	bool LoadSystemConfig(std::string szXmlFile, CXMLDecrypt* pcd = NULL);

	bool LoadFish(std::string szXmlFile, CXMLDecrypt* pcd = NULL);

	bool LoadVisual(std::string szXmlFile, CXMLDecrypt* pcd = NULL);
	
	bool LoadCannonSet(std::string szXmlFile, CXMLDecrypt* pcd = NULL);

	bool LoadBulletSet(std::string szXmlFile, CXMLDecrypt* pcd = NULL);

	bool LoadBoundBox(std::string szXmlFile, CXMLDecrypt* pcd = NULL);

	bool LoadScenes(std::string szXmlFile, CXMLDecrypt* pcd = NULL);

	bool LoadFishSound(std::string szXmlFile, CXMLDecrypt* pcd = NULL);

	bool LoadSpecialFish(std::string szXmlFile, CXMLDecrypt* pcd = NULL);

protected:

	CGameConfig();

	virtual ~CGameConfig();

	FriendBaseSingleton(CGameConfig);

public:
	int							nDefaultWidth;                      //默认宽度
	int							nDefaultHeight;                     //默认高度
	int							nWidth;                             //宽度
	int							nHeight;                            //高度
    //当前房间的游戏币与渔币的兑换比例为%d游戏币兑换%d渔币 nChangeRatioUserScore nChangeRatioFishScore
	int							nChangeRatioUserScore;              //游戏币兑换比率
	int							nChangeRatioFishScore;              //渔币兑换比率

	int							nExchangeOnce;                      //改变一次？
	int							nFireInterval;                      //开火区间
	int							nMaxInterval;                       //最大区间
	int							nMinInterval;                       //最小区间
	int							nMinNotice;                         //最小通知
	float						fAndroidProbMul;                    //安卓概率？
	int							nPlayerCount;                       //玩家数
	int							nSpecialProb[ESFT_MAX];             //特殊鱼刷新概率

	std::map<int, Visual>			VisualMap;                          //视觉集 可优
	std::map<int, Fish>				FishMap;                            //鱼表
	std::vector<Bullet>				BulletVector;                       //子弹队列
	std::map<int, BBX>				BBXMap;                             //绑定表

	int											nAddMulBegin;                       //
	int											nAddMulCur;
	int											m_MaxCannon;                        //最大炮
	bool										bImitationRealPlayer;               //模仿玩家？

	std::vector<FirstFire>			FirstFireList;                      //第一次开火列表

	float										fHScale;                            //？
	float										fVScale;                            // 可优

	std::map<int, SceneSet>		SceneSets;                          //场景集
	std::map<int, SoundSet>		FishSound;                          //鱼声音  可优
	std::map<int, SpecialSet>		KingFishMap;                        //鱼王表
	std::map<int, SpecialSet>		SanYuanFishMap;                     //大三元类鱼表
	std::map<int, SpecialSet>		SiXiFishMap;                        //四喜类鱼表
	std::vector<CMovePoint>		CannonPos;                          //大炮坐标
	std::vector<CannonSetS>	CannonSetArray;                     //大炮集
                                                                    
	std::string								szCannonEffect;                     // 炮效果  可优
	MyPoint									EffectPos;                          // 效果坐标？ 可优
	int											nJettonCount;                       // 筹码数量 可优
	MyPoint									JettonPos;                          // 筹码坐标 可优
	CannonLock							LockInfo;                           // 大炮锁定 可优
                                                                    
	bool										ShowDebugInfo;                      // 可优
	int											nShowGoldMinMul;                    //显示金钱位数？ 可优
	bool										ShowShadow;                         //显示阴影 可优
                                                                    
	int											nIonMultiply;                       //多重离子？
	int											nIonProbability;	                //离子概率？
	float										fDoubleTime;                        //双倍时间？
                                                                    
	int											nMaxBullet;                         //最大子弹
	int											nMaxSpecailCount;                   //最大特殊数
                                                                    
	float										fGiveRealPlayTime;                  // 可优
	float										fGiveTime;                          // 可优                         
	std::vector<int>					vGiveFish;                          // 可优
	std::vector<int>					vGiveProb;                          // 可优
                                                                    
	int											nSnakeHeadType;                     //蛇头类型
	int											nSnakeTailType;                     //蛇尾类型
};

#endif

