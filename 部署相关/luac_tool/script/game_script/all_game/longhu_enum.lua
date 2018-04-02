--龙虎大战投注类型
LONGHUBET =  {
	BET_DRAGON_WIN = 1,  --//龙赢
	BET_TIGER_WIN = 2, -- //虎赢
	BET_DRAW_WIN = 3,  --//和局
	BET_DUI_WIN = 4,  --//对9-A赢
	BET_SHUN_WIN = 5,  --//顺赢
	BET_JINHUA_WIN = 6,  --//金花赢
	BET_SHUNJIN_WIN = 7,  --//顺金赢
	BET_BAOZI_WIN = 8,  --//豹子赢
}
--牌类型
LONGHUTYPE = {
	HONGHEI_NULL = 1, --占位对应投注类型
	HONGHEI_GAOPAI = 2, --高牌
	HONGHEI_DUIZI = 3, --对子
	HONGHEI_SHUNZI = 4, --顺子
	HONGHEI_JINHUA = 5, --金花
	HONGHEI_SHUNJIN = 6, --顺金
	HONGHEI_BAOZI = 7, --豹子
}

--牌花色
CARDCOLOR={
	COLOR_DIAMOND 	= 1,	--方块
	COLOR_CLUB 		= 2,	--梅花
	COLOR_HEARTS 	= 3,	--红桃
	COLOR_SPADES 	= 4,	--黑桃
}

--桌子状态
LONGHUTABLESTATE = {
	TABLE_WAIT_BETS = 1,	--等待下注
	TABLE_POST_CARDS = 2,	--发牌阶段
	TABLE_POST_RESULT = 3,	--结算阶段
	TABLE_REST = 4,	--牌局结束
}


--各个阶段需要的时间
LONGHUTABLETIME = {
	TABLE_BETS_TIME = 15,	--等待下注时间
	TABLE_CARDS_TIME = 5,	--发牌阶段时间
	TABLE_RESULT_TIME = 3,	--结算阶段时间
	TABLE_REST_TIME = 1,	--牌局结束时间
}

--桌子状态阶段
LONGHUSTATE = {
	TABLE_STSTE_INIT = 1,	--牌局初始化
	TABLE_STSTE_CARDS = 2,	--发牌
	TABLE_STSTE_RESULE = 3,	--结算
	TABLE_STSTE_REST = 4,	--结算
}


--投注倍率
LONGHUMULTIPLE = {2,2,8,3,4,6,11}

