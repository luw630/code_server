////
#ifndef __MOVE_POINT_H__
#define __MOVE_POINT_H__

#include "Point.h"
#include <vector>

class CMovePoint
{
public:
	CMovePoint();
	CMovePoint(MyPoint pos, float dir);

	virtual ~CMovePoint();

public:
	MyPoint m_Position;		//×ø±ê
	float m_Direction;		//·½Ïò
};

typedef std::vector<CMovePoint> MovePoints; 


#endif


