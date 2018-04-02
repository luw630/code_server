#ifndef GAME_LOGIC_HEAD_FILE
#define GAME_LOGIC_HEAD_FILE

#pragma once
#include <wtypes.h>
#include <assert.h>
#define ASSERT assert
#define CountArray(x) sizeof(x)/sizeof(x[0])
#define INVALID_CHAIR 10
#define SCORE						LONGLONG							//积分类型
#pragma pack(1)

//////////////////////////////////////////////////////////////////////////////////
//服务定义

//游戏属性
#define KIND_ID						200									//游戏 I D
#define GAME_NAME					TEXT("斗地主")						//游戏名字

//组件属性
#define GAME_PLAYER					3									//游戏人数
#define VERSION_SERVER				PROCESS_VERSION(6,0,3)				//程序版本
#define VERSION_CLIENT				PROCESS_VERSION(6,0,3)				//程序版本

//////////////////////////////////////////////////////////////////////////////////

//数目定义
#define MAX_COUNT					20									//最大数目
#define FULL_COUNT					54									//全牌数目

//逻辑数目
#define NORMAL_COUNT				17									//常规数目
#define DISPATCH_COUNT				51									//派发数目
#define GOOD_CARD_COUTN				38									//好牌数目

//数值掩码
#define	MASK_COLOR					0xF0								//花色掩码
#define	MASK_VALUE					0x0F								//数值掩码

//逻辑类型
#define CT_ERROR					0									//错误类型
#define CT_SINGLE					1									//单牌类型
#define CT_DOUBLE					2									//对牌类型
#define CT_THREE					3									//三条类型
#define CT_SINGLE_LINE				4									//单连类型
#define CT_DOUBLE_LINE				5									//对连类型
#define CT_THREE_LINE				6									//三连类型
#define CT_THREE_TAKE_ONE			7									//三带一单
#define CT_THREE_TAKE_TWO			8									//三带一对
#define CT_FOUR_TAKE_ONE			9									//四带两单
#define CT_FOUR_TAKE_TWO			10									//四带两对
#define CT_BOMB_CARD				11									//炸弹类型
#define CT_MISSILE_CARD				12									//火箭类型

//////////////////////////////////////////////////////////////////////////////////

//空闲状态
struct CMD_S_StatusFree
{
	//游戏属性
	LONG							lCellScore;							//基础积分

	//时间信息
	BYTE							cbTimeOutCard;						//出牌时间
	BYTE							cbTimeCallScore;					//叫分时间
	BYTE							cbTimeStartGame;					//开始时间
	BYTE							cbTimeHeadOutCard;					//首出时间

	//历史积分
	SCORE							lTurnScore[GAME_PLAYER];			//积分信息
	SCORE							lCollectScore[GAME_PLAYER];			//积分信息
};

//叫分状态
struct CMD_S_StatusCall
{
	//时间信息
	BYTE							cbTimeOutCard;						//出牌时间
	BYTE							cbTimeCallScore;					//叫分时间
	BYTE							cbTimeStartGame;					//开始时间
	BYTE							cbTimeHeadOutCard;					//首出时间

	//游戏信息
	LONG							lCellScore;							//单元积分
	WORD							wCurrentUser;						//当前玩家
	BYTE							cbBankerScore;						//庄家叫分
	BYTE							cbScoreInfo[GAME_PLAYER];			//叫分信息
	BYTE							cbHandCardData[NORMAL_COUNT];		//手上扑克

	//历史积分
	SCORE							lTurnScore[GAME_PLAYER];			//积分信息
	SCORE							lCollectScore[GAME_PLAYER];			//积分信息
};

//游戏状态
struct CMD_S_StatusPlay
{
	//时间信息
	BYTE							cbTimeOutCard;						//出牌时间
	BYTE							cbTimeCallScore;					//叫分时间
	BYTE							cbTimeStartGame;					//开始时间
	BYTE							cbTimeHeadOutCard;					//首出时间

	//游戏变量
	LONG							lCellScore;							//单元积分
	BYTE							cbBombCount;						//炸弹次数
	WORD							wBankerUser;						//庄家用户
	WORD							wCurrentUser;						//当前玩家
	BYTE							cbBankerScore;						//庄家叫分

	//出牌信息
	WORD							wTurnWiner;							//胜利玩家
	BYTE							cbTurnCardCount;					//出牌数目
	BYTE							cbTurnCardData[MAX_COUNT];			//出牌数据

	//扑克信息
	BYTE							cbBankerCard[3];					//游戏底牌
	BYTE							cbHandCardData[MAX_COUNT];			//手上扑克
	BYTE							cbHandCardCount[GAME_PLAYER];		//扑克数目

	//历史积分
	SCORE							lTurnScore[GAME_PLAYER];			//积分信息
	SCORE							lCollectScore[GAME_PLAYER];			//积分信息
};

//////////////////////////////////////////////////////////////////////////////////
//命令定义

#define SUB_S_GAME_START			100									//游戏开始
#define SUB_S_CALL_SCORE			101									//用户叫分
#define SUB_S_BANKER_INFO			102									//庄家信息
#define SUB_S_OUT_CARD				103									//用户出牌
#define SUB_S_PASS_CARD				104									//用户放弃
#define SUB_S_GAME_CONCLUDE			105									//游戏结束
#define SUB_S_SET_BASESCORE			106									//设置基数

//发送扑克
struct CMD_S_GameStart
{
	WORD							wStartUser;							//开始玩家
	WORD				 			wCurrentUser;						//当前玩家
	BYTE							cbValidCardData;					//明牌扑克
	BYTE							cbValidCardIndex;					//明牌位置
	BYTE							cbCardData[NORMAL_COUNT];			//扑克列表
};

//机器人扑克
struct CMD_S_AndroidCard
{
	BYTE							cbHandCard[GAME_PLAYER][NORMAL_COUNT];//手上扑克
	WORD							wCurrentUser;						//当前玩家
};

//用户叫分
struct CMD_S_CallScore
{
	WORD				 			wCurrentUser;						//当前玩家
	WORD							wCallScoreUser;						//叫分玩家
	BYTE							cbCurrentScore;						//当前叫分
	BYTE							cbUserCallScore;					//上次叫分
};

//庄家信息
struct CMD_S_BankerInfo
{
	WORD				 			wBankerUser;						//庄家玩家
	WORD				 			wCurrentUser;						//当前玩家
	BYTE							cbBankerScore;						//庄家叫分
	BYTE							cbBankerCard[3];					//庄家扑克
};

//用户出牌
struct CMD_S_OutCard
{
	BYTE							cbCardCount;						//出牌数目
	WORD				 			wCurrentUser;						//当前玩家
	WORD							wOutCardUser;						//出牌玩家
	BYTE							cbCardData[MAX_COUNT];				//扑克列表
};

//放弃出牌
struct CMD_S_PassCard
{
	BYTE							cbTurnOver;							//一轮结束
	WORD				 			wCurrentUser;						//当前玩家
	WORD				 			wPassCardUser;						//放弃玩家
};

//游戏结束
struct CMD_S_GameConclude
{
	//积分变量
	LONG							lCellScore;							//单元积分
	SCORE							lGameScore[GAME_PLAYER];			//游戏积分

	//春天标志
	BYTE							bChunTian;							//春天标志
	BYTE							bFanChunTian;						//春天标志

	//炸弹信息
	BYTE							cbBombCount;						//炸弹个数
	BYTE							cbEachBombCount[GAME_PLAYER];		//炸弹个数

	//游戏信息
	BYTE							cbBankerScore;						//叫分数目
	BYTE							cbCardCount[GAME_PLAYER];			//扑克数目
	BYTE							cbHandCardData[FULL_COUNT];			//扑克列表
};

//////////////////////////////////////////////////////////////////////////////////
//命令定义

#define SUB_C_CALL_SCORE			1									//用户叫分
#define SUB_C_OUT_CARD				2									//用户出牌
#define SUB_C_PASS_CARD				3									//用户放弃

//用户叫分
struct CMD_C_CallScore
{
	BYTE							cbCallScore;						//叫分数目
};

//用户出牌
struct CMD_C_OutCard
{
	BYTE							cbCardCount;						//出牌数目
	BYTE							cbCardData[MAX_COUNT];				//扑克数据
};

//////////////////////////////////////////////////////////////////////////////////

#pragma pack()


//////////////////////////////////////////////////////////////////////////

//排序类型
#define ST_ORDER					0									//大小排序
#define ST_COUNT					1									//数目排序
#define ST_CUSTOM					2									//自定排序

//////////////////////////////////////////////////////////////////////////

//分析结构
struct tagAnalyseResult
{
	BYTE 							cbBlockCount[4];					//扑克数目
	BYTE							cbCardData[4][MAX_COUNT];			//扑克数据
};

//出牌结果
struct tagOutCardResult
{
	BYTE							cbCardCount;						//扑克数目
	BYTE							cbResultCard[MAX_COUNT];			//结果扑克
};

//分布信息
struct tagDistributing
{
	BYTE							cbCardCount;						//扑克数目
	BYTE							cbDistributing[15][6];				//分布信息
};

#define MAX_TYPE_COUNT 254
struct tagOutCardTypeResult 
{
	BYTE							cbCardType;							//扑克类型
	BYTE							cbCardTypeCount;					//牌型数目
	BYTE							cbEachHandCardCount[MAX_TYPE_COUNT];//每手个数
	BYTE							cbCardData[MAX_TYPE_COUNT][MAX_COUNT];//扑克数据
};

//////////////////////////////////////////////////////////////////////////

//游戏逻辑类
class ddz_ai_logic
{
	//变量定义
protected:
	static const BYTE				m_cbCardData[FULL_COUNT];			//扑克数据

	//AI变量
public:
	static const BYTE				m_cbGoodcardData[GOOD_CARD_COUTN];	//好牌数据
	BYTE							m_cbAllCardData[GAME_PLAYER][MAX_COUNT];//所有扑克
	BYTE							m_cbLandScoreCardData[MAX_COUNT];	//叫牌扑克
	BYTE							m_cbUserCardCount[GAME_PLAYER];		//扑克数目
	WORD							m_wBankerUser;						//地主玩家

	//函数定义
public:
	//构造函数
	ddz_ai_logic();
	//析构函数
	virtual ~ddz_ai_logic();

	//类型函数
public:
	//获取类型
	BYTE GetCardType(const BYTE cbCardData[], BYTE cbCardCount);
	//获取数值
	BYTE GetCardValue(BYTE cbCardData) { return cbCardData&MASK_VALUE; }
	//获取花色
	BYTE GetCardColor(BYTE cbCardData) { return cbCardData&MASK_COLOR; }

	//控制函数
public:
	//混乱扑克
	VOID RandCardList(BYTE cbCardBuffer[], BYTE cbBufferCount);
	//排列扑克
	VOID SortCardList(BYTE cbCardData[], BYTE cbCardCount, BYTE cbSortType);
	//删除扑克
	bool RemoveCard(const BYTE cbRemoveCard[], BYTE cbRemoveCount, BYTE cbCardData[], BYTE cbCardCount);

	//逻辑函数
public:
	//有效判断
	bool IsValidCard(BYTE cbCardData);
	//逻辑数值
	BYTE GetCardLogicValue(BYTE cbCardData);
	//对比扑克
	bool CompareCard(const BYTE cbFirstCard[], const BYTE cbNextCard[], BYTE cbFirstCount, BYTE cbNextCount);
	//出牌搜索
	bool SearchOutCard(const BYTE cbHandCardData[], BYTE cbHandCardCount, const BYTE cbTurnCardData[], BYTE cbTurnCardCount, tagOutCardResult & OutCardResult);

	//内部函数
public:
	//构造扑克
	BYTE MakeCardData(BYTE cbValueIndex, BYTE cbColorIndex);
	//分析扑克
	VOID AnalysebCardData(const BYTE cbCardData[], BYTE cbCardCount, tagAnalyseResult & AnalyseResult);
	//分析分布
	VOID AnalysebDistributing(const BYTE cbCardData[], BYTE cbCardCount, tagDistributing & Distributing);



	//////////////////////////////////////////////////////////////////////////
	//AI函数

	//设置函数
public:
	//设置扑克
	VOID SetUserCard(WORD wChairID, BYTE cbCardData[], BYTE cbCardCount) ;
	//设置底牌
	VOID SetBackCard(WORD wChairID, BYTE cbBackCardData[], BYTE cbCardCount) ;
	//设置庄家
	VOID SetBanker(WORD wBanker) ;
	//叫牌扑克
	VOID SetLandScoreCardData(BYTE cbCardData[], BYTE cbCardCount) ;
	//删除扑克
	VOID RemoveUserCardData(WORD wChairID, BYTE cbRemoveCardData[], BYTE cbRemoveCardCount) ;

	//辅助函数
public:
	//组合算法
	VOID Combination(BYTE cbCombineCardData[], BYTE cbResComLen,  BYTE cbResultCardData[254][5], BYTE &cbResCardLen,BYTE cbSrcCardData[] , BYTE cbCombineLen1, BYTE cbSrcLen, const BYTE cbCombineLen2);
	//排列算法
	VOID Permutation(BYTE *list, INT m, INT n, BYTE result[][4], BYTE &len) ;
	//分析炸弹
	VOID GetAllBomCard(BYTE const cbHandCardData[], BYTE const cbHandCardCount, BYTE cbBomCardData[], BYTE &cbBomCardCount);
	//分析顺子
	VOID GetAllLineCard(BYTE const cbHandCardData[], BYTE const cbHandCardCount, BYTE cbLineCardData[], BYTE &cbLineCardCount);
	//分析三条
	VOID GetAllThreeCard(BYTE const cbHandCardData[], BYTE const cbHandCardCount, BYTE cbThreeCardData[], BYTE &cbThreeCardCount);
	//分析对子
	VOID GetAllDoubleCard(BYTE const cbHandCardData[], BYTE const cbHandCardCount, BYTE cbDoubleCardData[], BYTE &cbDoubleCardCount);
	//分析单牌
	VOID GetAllSingleCard(BYTE const cbHandCardData[], BYTE const cbHandCardCount, BYTE cbSingleCardData[], BYTE &cbSingleCardCount);

	//主要函数
public:
	//分析牌型（后出牌调用）
	VOID AnalyseOutCardType(BYTE const cbHandCardData[], BYTE const cbHandCardCount, BYTE const cbTurnCardData[], BYTE const cbTurnCardCount, tagOutCardTypeResult CardTypeResult[12+1]);
	//分析牌牌（先出牌调用）
	VOID AnalyseOutCardType(BYTE const cbHandCardData[], BYTE const cbHandCardCount, tagOutCardTypeResult CardTypeResult[12+1]);
	//单牌个数
	BYTE AnalyseSinleCardCount(BYTE const cbHandCardData[], BYTE const cbHandCardCount, BYTE const cbWantOutCardData[], BYTE const cbWantOutCardCount, BYTE cbSingleCardData[]=NULL);

	//出牌函数
public:
	//地主出牌（先出牌）
	VOID BankerOutCard(const BYTE cbHandCardData[], BYTE cbHandCardCount, tagOutCardResult & OutCardResult) ;
	//地主出牌（后出牌）
	VOID BankerOutCard(const BYTE cbHandCardData[], BYTE cbHandCardCount, WORD wOutCardUser, const BYTE cbTurnCardData[], BYTE cbTurnCardCount, tagOutCardResult & OutCardResult) ;
	//地主上家（先出牌）
	VOID UpsideOfBankerOutCard(const BYTE cbHandCardData[], BYTE cbHandCardCount, WORD wMeChairID,tagOutCardResult & OutCardResult) ;
	//地主上家（后出牌）
	VOID UpsideOfBankerOutCard(const BYTE cbHandCardData[], BYTE cbHandCardCount, WORD wOutCardUser,  const BYTE cbTurnCardData[], BYTE cbTurnCardCount, tagOutCardResult & OutCardResult) ;
	//地主下家（先出牌）
	VOID UndersideOfBankerOutCard(const BYTE cbHandCardData[], BYTE cbHandCardCount, WORD wMeChairID,tagOutCardResult & OutCardResult) ;
	//地主下家（后出牌）
	VOID UndersideOfBankerOutCard(const BYTE cbHandCardData[], BYTE cbHandCardCount, WORD wOutCardUser, const BYTE cbTurnCardData[], BYTE cbTurnCardCount, tagOutCardResult & OutCardResult) ;
	//出牌搜索
	bool SearchOutCard(const BYTE cbHandCardData[], BYTE cbHandCardCount, const BYTE cbTurnCardData[], BYTE cbTurnCardCount, WORD wOutCardUser, WORD wMeChairID, tagOutCardResult & OutCardResult);

	//叫分函数
public:
	//叫分判断
	BYTE LandScore(WORD wMeChairID, BYTE cbCurrentLandScore, BYTE landcards[]);

};

//////////////////////////////////////////////////////////////////////////

#endif