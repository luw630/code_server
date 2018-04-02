#include "catchfish.h"

using namespace lua_tinker;
int64_t			AddEarnings(int64_t toAdd);


int Init(lua_State *L)
{
	std::cout << "init......" << std::endl;

	//Lua定义桌子接口
	lua_tinker::class_add<catch_fish_logic>(L, "FishingTable");
	lua_tinker::class_con<catch_fish_logic>(L, lua_tinker::constructor<catch_fish_logic>);
	lua_tinker::class_def<catch_fish_logic>(L, "Initialization", &catch_fish_logic::Initialization);
	lua_tinker::class_def<catch_fish_logic>(L, "OnEventGameStart", &catch_fish_logic::OnEventGameStart);
	lua_tinker::class_def<catch_fish_logic>(L, "OnEventGameConclude", &catch_fish_logic::OnEventGameConclude);
	lua_tinker::class_def<catch_fish_logic>(L, "OnEventSendGameScene", &catch_fish_logic::OnEventSendGameScene);
	lua_tinker::class_def<catch_fish_logic>(L, "OnGameUpdate", &catch_fish_logic::OnGameUpdate);
	lua_tinker::class_def<catch_fish_logic>(L, "OnLockFish", &catch_fish_logic::OnLockFish);
	lua_tinker::class_def<catch_fish_logic>(L, "OnLockSpecFish", &catch_fish_logic::OnLockSpecFish);
	lua_tinker::class_def<catch_fish_logic>(L, "OnNetCast", &catch_fish_logic::OnNetCast);
	lua_tinker::class_def<catch_fish_logic>(L, "OnTimeSync", &catch_fish_logic::OnTimeSync);
	lua_tinker::class_def<catch_fish_logic>(L, "OnChangeCannon", &catch_fish_logic::OnChangeCannon);
	lua_tinker::class_def<catch_fish_logic>(L, "OnChangeCannonSet", &catch_fish_logic::OnChangeCannonSet);
	lua_tinker::class_def<catch_fish_logic>(L, "OnFire", &catch_fish_logic::OnFire);
	lua_tinker::class_def<catch_fish_logic>(L, "SetGameBaseScore", &catch_fish_logic::SetGameBaseScore);
	lua_tinker::class_def<catch_fish_logic>(L, "OnActionUserSitDown", &catch_fish_logic::OnActionUserSitDown);
	lua_tinker::class_def<catch_fish_logic>(L, "OnActionUserStandUp", &catch_fish_logic::OnActionUserStandUp);
	lua_tinker::class_def<catch_fish_logic>(L, "OnActionUserOnReady", &catch_fish_logic::OnActionUserOnReady);
	lua_tinker::class_def<catch_fish_logic>(L, "OnActionUserOffLine", &catch_fish_logic::OnActionUserOffLine);
	lua_tinker::class_def<catch_fish_logic>(L, "OnReady", &catch_fish_logic::OnReady);
	lua_tinker::def(L, "AddEarnings", AddEarnings);

    REGISTER_OBJ_TYPE(EOT_PLAYER, CPlayer);
    REGISTER_OBJ_TYPE(EOT_BULLET, CBullet);
    REGISTER_OBJ_TYPE(EOT_FISH, CFish);

    REGISTER_EFFECT_TYPE(ETP_ADDMONEY, CEffectAddMoney);
    REGISTER_EFFECT_TYPE(ETP_KILL, CEffectKill);
    REGISTER_EFFECT_TYPE(ETP_ADDBUFFER, CEffectAddBuffer);
    REGISTER_EFFECT_TYPE(ETP_PRODUCE, CEffectProduce);
    REGISTER_EFFECT_TYPE(ETP_BLACKWATER, CEffectBlackWater);
    REGISTER_EFFECT_TYPE(ETP_AWARD, CEffectAward);

    REGISTER_BUFFER_TYPE(EBT_CHANGESPEED, CSpeedBuffer);
    REGISTER_BUFFER_TYPE(EBT_DOUBLE_CANNON, CDoubleCannon);
    REGISTER_BUFFER_TYPE(EBT_ION_CANNON, CIonCannon);
    REGISTER_BUFFER_TYPE(EBT_ADDMUL_BYHIT, CAddMulByHit);

    REGISTER_MYCOMPONENT_TYPE(EMCT_PATH, MoveByPath);
    REGISTER_MYCOMPONENT_TYPE(EMCT_DIRECTION, MoveByDirection);

    REGISTER_MYCOMPONENT_TYPE(EECT_MGR, EffectMgr);
    REGISTER_MYCOMPONENT_TYPE(EBCT_BUFFERMGR, BufferMgr);
    return 1;
}

catchfish_dll* catchfish_dll::sInstance = nullptr;
lua_State* catchfish_dll::sLuaState;

//dll通过函数luaI_openlib导出，然后lua使用package.loadlib导入库函数  
extern "C" __declspec(dllexport) int luaopen_catchfish(lua_State* L)//需要注意的地方,此函数命名与库名一致  
{
	catchfish_dll::GetInstance(L);
    return 1;
}

int64_t	AddEarnings(int64_t toAdd)
{
	Earnings::getInstance().addEarnings(toAdd);
	return Earnings::getInstance().getEarnings();
}

#ifdef WIN32
BOOL WINAPI DllMain(HINSTANCE hinstDLL, uint32_t fdwReason,LPVOID lpReserved) 
{
	// Perform actions based on the reason for calling.
	switch (fdwReason)
	{
	case DLL_PROCESS_ATTACH:
		{
			
		}
		break;

	case DLL_THREAD_ATTACH:
		// Do thread-specific initialization.
		break;

	case DLL_THREAD_DETACH:
		// Do thread-specific cleanup.
		break;

	case DLL_PROCESS_DETACH:
		// Perform any necessary cleanup.
		break;
	}
	return TRUE;  // Successful DLL_PROCESS_ATTACH.
}
#endif