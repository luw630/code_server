#include "MovePoint.h"

CMovePoint::CMovePoint()
:m_Position(0, 0)
,m_Direction(0.0f)
{

}

CMovePoint::CMovePoint(MyPoint pos, float dir)
:m_Position(pos)
,m_Direction(dir)
{

}

CMovePoint::~CMovePoint()
{

}

