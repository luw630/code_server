--桌子的状态
ETableState = {
	TABLE_STATE_UNKNOW = 0,
	TABLE_STATE_WAIT_MIN_PLAYER = 1,        --等待最小玩家数
	TABLE_STATE_WAIT_ALL_READY = 2,			--等待所有玩家准备好
	TABLE_STATE_WAIT_GAME_START = 3,        --等待桌主开始游戏
	TABLE_STATE_WAIT_CLIENT_ACTION = 4,     --等待client操作
	TABLE_STATE_WAIT_CLIENT_ACTION_PLAY = 7,    --等待出牌
	TABLE_STATE_WAIT_ONE_GAME_REAL_END = 8, --等待一局游戏真正结束
	TABLE_STATE_WAIT_GAME_END = 9,      --等待游戏结束
	TABLE_STATE_GAME_START = 10,        --游戏开始状态
	TABLE_STATE_ONE_GAME_START = 11,    --一局游戏开始
	TABLE_STATE_CONTINUE = 12,
	TABLE_STATE_GETBANKER = 13,		--玩家抢庄
	TABLE_STATE_WAITBANKER = 14,		--等待玩家抢庄
	TABLE_STATE_BET = 15,			--玩家下注
	TABLE_STATE_WAITBET = 16,			--等待玩家下注
}

--座位状态
ESeatState = {
	SEAT_STATE_UNKNOW = 0,
	SEAT_STATE_NO_PLAYER = 1,  --没有玩家
	SEAT_STATE_WAIT_START = 2, --等待开局
	SEAT_STATE_READY = 3, --等待开局
	SEAT_STATE_STANDUP = 4,    --站起
	SEAT_STATE_ESCAPE = 5, 		--逃跑
	SEAT_STATE_PLAYING  = 6,   --正在游戏中
	SEAT_STATE_FINISH = 7,     --比牌后等待下局游戏
}

CardType = {
	SANGONG_DI = 1,		--低点牌 0-7 点
	SANGONG_GAO = 2,	--高点牌 8，9点
	SANGONG_HUN = 3,	--混三公
	SANGONG_XIAO = 4,	--小三公
	SANGONG_DA = 5,		--大三公
}

CardColor={
	COLOR_DIAMOND 	= 1,	--方块
	COLOR_CLUB 		= 2,	--梅花
	COLOR_HEARTS 	= 3,	--红桃
	COLOR_SPADES 	= 4,	--黑桃
}





--扑克牌点数 1-52 方块A=1
