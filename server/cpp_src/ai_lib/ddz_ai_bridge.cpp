#include "ddz_ai_bridge.h"
#include <stdio.h>

#define TIME_LESS					1									
#define TIME_DISPATCH				5									

#define TIME_OUT_CARD				3									
#define TIME_START_GAME				8									
#define TIME_CALL_SCORE				5									

#define IDI_OUT_CARD				(0)			
#define IDI_START_GAME				(1)			
#define IDI_CALL_SCORE				(2)			

extern const BYTE transform_to_local_value[FULL_COUNT];
extern BYTE transform_to_remote_value(BYTE local_value);
extern lua_State* g_LuaState;

ddz_ai_bridge::ddz_ai_bridge()
{
	m_wBankerUser=INVALID_CHAIR;
	m_wOutCardUser = INVALID_CHAIR ;
	m_cbTurnCardCount=0;
	ZeroMemory(m_cbTurnCardData,sizeof(m_cbTurnCardData));
	ZeroMemory(m_cbHandCardData,sizeof(m_cbHandCardData));
	ZeroMemory(m_cbHandCardCount,sizeof(m_cbHandCardCount));

	return;
}

ddz_ai_bridge::~ddz_ai_bridge()
{
}

VOID * ddz_ai_bridge::QueryInterface(REFGUID Guid, DWORD dwQueryVer)
{
	return NULL;
}

bool ddz_ai_bridge::Initialization()
{
	return true;
}

bool ddz_ai_bridge::RepositionSink()
{
	m_wBankerUser=INVALID_CHAIR;
	m_cbTurnCardCount=0;
	ZeroMemory(m_cbTurnCardData,sizeof(m_cbTurnCardData));
	ZeroMemory(m_cbHandCardData,sizeof(m_cbHandCardData));
	ZeroMemory(m_cbHandCardCount,sizeof(m_cbHandCardCount));
	return true;
}
bool ddz_ai_bridge::UserOutCard(lua_tinker::table msg_back)
{
	tagOutCardResult OutCardResult;
	try
	{
		WORD wMeChairID = m_self_ChairID;		
		m_GameLogic.SearchOutCard(m_cbHandCardData, m_cbHandCardCount[wMeChairID], m_cbTurnCardData, m_cbTurnCardCount, m_wOutCardUser, m_self_ChairID, OutCardResult);
	}
	catch(...)
	{
		ZeroMemory(OutCardResult.cbResultCard, sizeof(OutCardResult.cbResultCard)) ;
		OutCardResult.cbCardCount = 10 ;
	}
	if (m_cbHandCardCount[m_self_ChairID] == OutCardResult.cbCardCount)
	{
		if(OutCardResult.cbCardCount>0 && CT_FOUR_TAKE_ONE==m_GameLogic.GetCardType(OutCardResult.cbResultCard, OutCardResult.cbCardCount))
		{
			BYTE card_val[6] = {0};
			for (size_t i = 0; i < OutCardResult.cbCardCount; i++)
			{
				card_val[i] = m_GameLogic.GetCardValue(OutCardResult.cbResultCard[i]);
			}

			BYTE min_card = 1000;
			for (size_t i = 0; i < 6; i++)
			{
				int same_count = 0;
				for (size_t j = 0; j < 6; j++)
				{
					if (card_val[i] == card_val[j])
					{
						same_count += 0;
					}
				}
				if (same_count != 4 && min_card > OutCardResult.cbResultCard[i])
				{
					min_card = OutCardResult.cbResultCard[i];
				}
			}

			OutCardResult.cbResultCard[0] = min_card;
			OutCardResult.cbCardCount = 1;
		}
		if(OutCardResult.cbCardCount>0 && CT_FOUR_TAKE_TWO==m_GameLogic.GetCardType(OutCardResult.cbResultCard, OutCardResult.cbCardCount))
		{
			//四代两对要不要做同样的处理？
			BYTE card_val[8] = {0};
			for (size_t i = 0; i < OutCardResult.cbCardCount; i++)
			{
				card_val[i] = m_GameLogic.GetCardValue(OutCardResult.cbResultCard[i]);
			}

			BYTE min_card = 1000;
			for (size_t i = 0; i < 8; i++)
			{
				int same_count = 0;
				for (size_t j = 0; j < 8; j++)
				{
					if (card_val[i] == card_val[j])
					{
						same_count += 0;
					}
				}
				if (same_count != 4 && min_card > card_val[i])
				{
					min_card = card_val[i];
				}
			}
			int cut_index = 0;
			for (size_t i = 0; i < 8; i++)
			{
				if (card_val[i] == min_card)
				{
					OutCardResult.cbResultCard[cut_index] = OutCardResult.cbResultCard[i];
					cut_index += 1;
				}
			}

			OutCardResult.cbCardCount = 2;
		}
	}
	

	if(OutCardResult.cbCardCount>0 && CT_ERROR==m_GameLogic.GetCardType(OutCardResult.cbResultCard, OutCardResult.cbCardCount))
	{
		ASSERT(false) ;
		ZeroMemory(&OutCardResult, sizeof(OutCardResult)) ;
	}

	if(m_cbTurnCardCount==0)
	{
		if(OutCardResult.cbCardCount==0)
		{
			WORD wMeChairID = m_self_ChairID;
			OutCardResult.cbCardCount = 1 ;
			OutCardResult.cbResultCard[0]=m_cbHandCardData[m_cbHandCardCount[wMeChairID]-1] ;
		}
	}
	else
	{
		if(!m_GameLogic.CompareCard(m_cbTurnCardData,OutCardResult.cbResultCard,m_cbTurnCardCount,OutCardResult.cbCardCount))
		{
			msg_back.set("give_up", true);
			ASSERT(msg_back.get<int>("turn_over") == 0);
			return true;
		}				
	}

	if (OutCardResult.cbCardCount>0 && m_cbHandCardCount[m_self_ChairID] >= OutCardResult.cbCardCount)
	{
		WORD wMeChairID = m_self_ChairID;
		m_cbHandCardCount[wMeChairID]-=OutCardResult.cbCardCount;
		ASSERT(m_cbHandCardCount[wMeChairID] <= 20);
		m_GameLogic.RemoveCard(OutCardResult.cbResultCard,OutCardResult.cbCardCount,m_cbHandCardData,m_cbHandCardCount[wMeChairID]+OutCardResult.cbCardCount);

		CMD_C_OutCard OutCard;
		ZeroMemory(&OutCard,sizeof(OutCard));

		OutCard.cbCardCount=OutCardResult.cbCardCount;
		CopyMemory(OutCard.cbCardData,OutCardResult.cbResultCard,OutCardResult.cbCardCount*sizeof(BYTE));

		WORD wHeadSize=sizeof(OutCard)-sizeof(OutCard.cbCardData);
		
		msg_back.set("cbCardCount", OutCard.cbCardCount);
		for (int i = 0; i < OutCard.cbCardCount; i++)
		{
			int tmp = transform_to_remote_value(OutCard.cbCardData[i]);
			(msg_back.get<lua_tinker::table>("cbCardData")).seti<int>(i + 1, transform_to_remote_value(OutCard.cbCardData[i]));
		}
	}
	else
	{
		msg_back.set("give_up", true);
		return true;
	}

	return true;
}

bool ddz_ai_bridge::OnEventGameMessage(const char* msg_name, lua_tinker::table msg, lua_tinker::table msg_back)
{
	if (strcmp(msg_name,"GAME_START") == 0)
	{
		OnSubGameStart(msg,msg_back);
	}
	else if (strcmp(msg_name, "SC_LandCallScore") == 0)
	{
		OnSubCallScore(msg, msg_back);
	}
	else if (strcmp(msg_name, "SC_LandInfo") == 0)
	{
		OnSubBankerInfo(msg, msg_back);
	}
	else if (strcmp(msg_name, "SC_LandCallDoubleFinish") == 0)
	{
		int land_chair_id = msg.get<int>("land_chair_id") - 1;
		if (land_chair_id == m_self_ChairID)
		{
			UserOutCard(msg_back);
		}
	}
	else if (strcmp(msg_name, "SC_LandOutCard") == 0)
	{
		OnSubOutCard(msg, msg_back);
	}
	else if (strcmp(msg_name, "SC_LandPassCard") == 0)
	{
		OnSubPassCard(msg, msg_back);
	}
	else if (strcmp(msg_name, "SC_LandConclude") == 0)
	{
		OnSubGameEnd(msg, msg_back);
	}
	return true;
}

bool ddz_ai_bridge::OnSubGameStart(lua_tinker::table msg, lua_tinker::table msg_back)
{
	CMD_S_AndroidCard tmp_struct;
	ZeroMemory(&tmp_struct, sizeof(tmp_struct));
	tmp_struct.wCurrentUser = msg.get<int>("wCurrentUser") - 1;
	lua_tinker::table cbHandCard = msg.get<lua_tinker::table>("cbHandCard");
	lua_tinker::table cbHandCard01 = cbHandCard.geti<lua_tinker::table>(1);
	lua_tinker::table cbHandCard02 = cbHandCard.geti<lua_tinker::table>(2);
	lua_tinker::table cbHandCard03 = cbHandCard.geti<lua_tinker::table>(3);

	for (int i = 0; i < NORMAL_COUNT; i++)
	{
		if (cbHandCard01.getlen() >= (i + 1)) tmp_struct.cbHandCard[0][i] = transform_to_local_value[cbHandCard01.geti<int>(i + 1)];
		if (cbHandCard02.getlen() >= (i + 1)) tmp_struct.cbHandCard[1][i] = transform_to_local_value[cbHandCard02.geti<int>(i + 1)];
		if (cbHandCard03.getlen() >= (i + 1)) tmp_struct.cbHandCard[2][i] = transform_to_local_value[cbHandCard03.geti<int>(i + 1)];
	}

	lua_tinker::table landcards = msg.get<lua_tinker::table>("landcards");
	for (int i = 0; i < 3; i++)
	{
		m_landcards[i] = transform_to_local_value[landcards.geti<int>(i + 1)];
	}
	
	CMD_S_AndroidCard * pAndroidCard = (CMD_S_AndroidCard *)&tmp_struct;

	m_cbTurnCardCount=0;
	ZeroMemory(m_cbTurnCardData,sizeof(m_cbTurnCardData));

	WORD wMeChairID = m_self_ChairID;
	for (WORD i=0;i<GAME_PLAYER;i++) m_cbHandCardCount[i]=NORMAL_COUNT;

	for(WORD wChairID=0; wChairID<GAME_PLAYER; ++wChairID)
	{
		if(wChairID==wMeChairID)
            CopyMemory(m_cbHandCardData,pAndroidCard->cbHandCard[wChairID],sizeof(BYTE)*NORMAL_COUNT);

		m_GameLogic.SetUserCard(wChairID, pAndroidCard->cbHandCard[wChairID], NORMAL_COUNT) ;
	}

	BYTE cbLandScoreCardData[MAX_COUNT] ;
	CopyMemory(cbLandScoreCardData, m_cbHandCardData,m_cbHandCardCount[wMeChairID]) ;
	CopyMemory(cbLandScoreCardData + NORMAL_COUNT, m_landcards, 3);
	m_GameLogic.SetLandScoreCardData(cbLandScoreCardData, sizeof(cbLandScoreCardData)) ;
	m_GameLogic.SortCardList(m_cbHandCardData,m_cbHandCardCount[wMeChairID],ST_ORDER);

	return true;
}

bool ddz_ai_bridge::OnSubCallScore(lua_tinker::table msg, lua_tinker::table msg_back)
{
	if (m_self_ChairID == (msg.get<int>("cur_chair_id") - 1))
	{
		msg_back.set<int>("score", m_GameLogic.LandScore(m_self_ChairID, msg.get<int>("call_score"),m_landcards));
	}
	return true;
}

bool ddz_ai_bridge::OnSubBankerInfo(lua_tinker::table msg, lua_tinker::table msg_back)
{
	CMD_S_BankerInfo pData;
	pData.wBankerUser = msg.get<int>("land_chair_id") - 1;
	pData.wCurrentUser = msg.get<int>("land_chair_id") - 1;
	pData.cbBankerScore = msg.get<int>("call_score");

	pData.cbBankerCard[0] = transform_to_local_value[msg.get<lua_tinker::table>("cards").geti<int>(1)];
	pData.cbBankerCard[1] = transform_to_local_value[msg.get<lua_tinker::table>("cards").geti<int>(2)];
	pData.cbBankerCard[2] = transform_to_local_value[msg.get<lua_tinker::table>("cards").geti<int>(3)];
	
	CMD_S_BankerInfo * pBankerInfo=&pData;

	m_wBankerUser=pBankerInfo->wBankerUser;
	m_cbHandCardCount[m_wBankerUser]+=CountArray(pBankerInfo->cbBankerCard);

	if (pBankerInfo->wBankerUser == m_self_ChairID)
	{
		CopyMemory(&m_cbHandCardData[NORMAL_COUNT],pBankerInfo->cbBankerCard,sizeof(pBankerInfo->cbBankerCard));
		WORD wMeChairID = m_self_ChairID;
		m_GameLogic.SortCardList(m_cbHandCardData,m_cbHandCardCount[wMeChairID],ST_ORDER);
	}
	m_GameLogic.SetBackCard(pBankerInfo->wBankerUser, pBankerInfo->cbBankerCard, 3) ;
	m_GameLogic.SetBanker(pBankerInfo->wBankerUser);

	return true;
}

bool ddz_ai_bridge::OnSubOutCard(lua_tinker::table msg, lua_tinker::table msg_back)
{

	 CMD_S_OutCard pData;
	 pData.cbCardCount = msg.get<lua_tinker::table>("cards").getlen();
	 pData.wCurrentUser = msg.get<int>("cur_chair_id") - 1;
	 pData.wOutCardUser = msg.get<int>("out_chair_id") - 1;
	 for (int i = 0; i < pData.cbCardCount; i++)
	 {
		 pData.cbCardData[i] = transform_to_local_value[msg.get<lua_tinker::table>("cards").geti<int>(i + 1)];
	 }

	CMD_S_OutCard * pOutCard= &pData;
	WORD wHeadSize=sizeof(CMD_S_OutCard)-sizeof(pOutCard->cbCardData);

	if (pOutCard->wCurrentUser==pOutCard->wOutCardUser)
	{
		m_cbTurnCardCount=0;
		ZeroMemory(m_cbTurnCardData,sizeof(m_cbTurnCardData));
	}
	else
	{
		m_cbTurnCardCount=pOutCard->cbCardCount;
		CopyMemory(m_cbTurnCardData,pOutCard->cbCardData,pOutCard->cbCardCount*sizeof(BYTE));
		m_wOutCardUser = pOutCard->wOutCardUser ;
	}

	if (pOutCard->wOutCardUser != m_self_ChairID)
	{
		m_cbHandCardCount[pOutCard->wOutCardUser]-=pOutCard->cbCardCount;
	}

	if (m_self_ChairID == pOutCard->wCurrentUser)
	{
		bool is_team = false;
		bool has_card_big_than_k = false;
		if (pOutCard->wOutCardUser != m_wBankerUser && m_self_ChairID != m_wBankerUser && pOutCard->wOutCardUser != m_self_ChairID)
		{
			is_team = true;
		}

		const BYTE big_cards[10] = {
			0x01, 0x02,//A 2
			0x11, 0x12,//A 2
			0x21, 0x22,//A 2
			0x31, 0x32,//A 2
			0x4E, 0x4F,// 大小王
		};
		for (int i = 0; i < pData.cbCardCount; i++)
		{
			if (pData.cbCardData[i] == big_cards[0] || pData.cbCardData[i] == big_cards[1] || pData.cbCardData[i] == big_cards[2]
				|| pData.cbCardData[i] == big_cards[3] || pData.cbCardData[i] == big_cards[4] || pData.cbCardData[i] == big_cards[5]
				|| pData.cbCardData[i] == big_cards[6] || pData.cbCardData[i] == big_cards[7] || pData.cbCardData[i] == big_cards[8]
				|| pData.cbCardData[i] == big_cards[9])
			{
				has_card_big_than_k = true;
				break;;
			}			
		}
		
		if (is_team && has_card_big_than_k)
		{
			msg_back.set("give_up", true);
		}
		else
		{
			UserOutCard(msg_back);
		}
	}

	m_GameLogic.RemoveUserCardData(pOutCard->wOutCardUser, pOutCard->cbCardData, pOutCard->cbCardCount) ;
	return true;
}

bool ddz_ai_bridge::OnSubPassCard(lua_tinker::table msg, lua_tinker::table msg_back)
{
	CMD_S_PassCard pData;
	pData.cbTurnOver = msg.get<int>("turn_over");
	pData.wCurrentUser = msg.get<int>("cur_chair_id") - 1;
	pData.wPassCardUser = msg.get<int>("pass_chair_id") - 1;
	CMD_S_PassCard * pPassCard=(CMD_S_PassCard *)&pData;
	if (pPassCard->cbTurnOver==TRUE)
	{
		m_cbTurnCardCount=0;
		ZeroMemory(m_cbTurnCardData,sizeof(m_cbTurnCardData));
		msg_back.set<int>("turn_over",1);
	}
	else
	{
		msg_back.set<int>("turn_over", 0);
	}

	if (m_self_ChairID == pPassCard->wCurrentUser)
	{
		UserOutCard(msg_back);
	}

	return true;
}

bool ddz_ai_bridge::OnSubGameEnd(lua_tinker::table msg, lua_tinker::table msg_back)
{
	m_cbTurnCardCount=0;
	ZeroMemory(m_cbTurnCardData,sizeof(m_cbTurnCardData));
	ZeroMemory(m_cbHandCardData,sizeof(m_cbHandCardData));
	ZeroMemory(m_cbHandCardCount,sizeof(m_cbHandCardCount));

	return true;
}

