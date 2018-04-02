#include "Fish.h"

CFish::CFish()
:m_bBroadCast(false)
,m_nBoundingBoxID(0)
,m_nLockLevel(0)
,m_FishType(0)
,m_nRefershID(0)
{
	SetObjType(EOT_FISH);
}

CFish::~CFish()
{

}


