#pragma once
// 游戏人数
#define GAME_PLAYER			CGameConfig::GetInstance()->nPlayerCount

#define MAX_PROBABILITY		10000
//#define GAME_FPS			60
#define GAME_FPS			30
#define MAX_TABLE_CHAIR	4// 每张桌子椅子个数

#define SCENE_CHANAGE_NONE	 -1

#define	SWITCH_SCENE_END	8

#define M_E        2.71828182845904523536
#define M_LOG2E    1.44269504088896340736
#define M_LOG10E   0.434294481903251827651
#define M_LN2      0.693147180559945309417
#define M_LN10     2.30258509299404568402
#define M_PI       3.14159265358979323846
#define M_PI_2     1.57079632679489661923
#define M_PI_4     0.785398163397448309616
#define M_1_PI     0.318309886183790671538
#define M_2_PI     0.636619772367581343076
#define M_2_SQRTPI 1.12837916709551257390
#define M_SQRT2    1.41421356237309504880
#define M_SQRT1_2  0.707106781186547524401



#define SAFE_DELETE(x) { if (NULL != (x)) { delete (x); (x) = NULL; } }

#include "boost/asio.hpp"
#include <stdio.h>
#include <cstdint>
#include <windows.h>
#include <timeapi.h>

#define min(a,b)            (((a) < (b)) ? (a) : (b))
#define max(a,b)            (((a) > (b)) ? (a) : (b))
//#define timeGetTime() 1

#pragma comment(lib, "winmm.lib")

//////////////////////////////////////////////////////////////////////////
inline void DebugString(LPCTSTR lpszFormat, ...)
{
    va_list   args;
    int       nBuf;
    TCHAR     szBuffer[1024];

    va_start(args, lpszFormat);

#if _MSC_VER>1400
    nBuf = _vsnwprintf_s(szBuffer, _TRUNCATE, lpszFormat, args);
#else
    nBuf = _vsnwprintf(szBuffer, CountArray(szBuffer), lpszFormat, args);
#endif

    OutputDebugString(szBuffer);

    va_end(args);
}

static unsigned int g_seed = 0;
static void RandSeed(int seed)
{
    if (!seed) g_seed = GetTickCount();
    else g_seed = seed;
}

static int RandInt(int min, int max)
{
    if (min == max) return min;

    g_seed = 214013 * g_seed + 2531011;

    return min + (g_seed ^ g_seed >> 15) % (max - min);
}

static float RandFloat(float min, float max)
{
    if (min == max) return min;

    g_seed = 214013 * g_seed + 2531011;

    return min + (g_seed >> 16) * (1.0f / 65535.0f) * (max - min);
}

enum enMsgType
{
    enMsgType_NULL = 0,
    enMsgType_TreasureEnd,
    enMsgType_ChangeCannonSet,
    enMsgType_Netcast,
    enMsgType_LockFish,
    enMsgType_Fire,
    enMsgType_ChangeCannon,
    enMsgType_TimeSync,    
    enMsgType_RepositionSink,
    enMsgType_ActionUserSitDown,
    enMsgType_ActionUserStandUp,
    enMsgType_EventGameStart,
    enMsgType_EventGameConclude,
    enMsgType_EventSendGameScene,
    enMsgType_SetNickNameAndMoney,
    enMsgType_AddPlayerTable,
    enMsgType_RemovePlayerTable,
    enMsgType_Auto
};
