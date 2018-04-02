#include "common.h"
#include "MathAide.h"
#include <math.h>

int CMathAide::Factorial(int number)
{
	int factorial = 1;
	int temp = number;
	for (int i = 0; i < number; ++i) 
	{
		factorial *= temp;
		--temp;
	}

	return factorial;
}

int CMathAide::Combination(int count, int r)
{
	return Factorial(count) / (Factorial(r) * Factorial(count - r));
}
//计算距离
float CMathAide::CalcDistance(float x1, float y1, float x2, float y2)
{
	return sqrtf((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
}
//计算角度
float CMathAide::CalcAngle(float x1, float y1, float x2, float y2)
{
	float fDistance = CalcDistance(x1, y1, x2, y2);
	if (fDistance == 0.f) return 0.f;
	float cosValue = (x1 - x2) / fDistance;
	float angle = acosf(cosValue);
	if (y1 < y2) 
		angle= 2 * M_PI - angle;
	angle += M_PI_2;
	return angle;
}

void CMathAide::BuildLinear(float initX[], float initY[], int initCount, std::vector<MyPoint>& TraceVector, float fDistance)
{
	TraceVector.clear();

	if (initCount < 2) return;

	if (fDistance <= 0.0f) return;

	float disTotal = CalcDistance(initX[initCount - 1], initY[initCount - 1], initX[0], initY[0]);
	if (disTotal <= 0.0f) return;

	float cosValue = abs(initY[initCount - 1] - initY[0]) / disTotal;
	float angle = acosf(cosValue);

	MyPoint point;
	point.x_ = initX[0];
	point.y_ = initY[0];
	TraceVector.push_back(point);
	float tfDis = 0.f;

	std::vector<MyPoint>::size_type size;
	while (tfDis < disTotal)
	{
		size = TraceVector.size();

		if (initX[initCount - 1] < initX[0]) 
		{
			point.x_ = initX[0] - sinf(angle) * (fDistance * size);
		} 
		else 
		{
			point.x_ = initX[0] + sinf(angle) * (fDistance * size);
		}

		if (initY[initCount - 1] < initY[0])
		{
			point.y_ = initY[0] - cosf(angle) * (fDistance * size);
		} 
		else 
		{
			point.y_ = initY[0] + cosf(angle) * (fDistance * size);
		}

		TraceVector.push_back(point);
		tfDis = CalcDistance(point.x_, point.y_, initX[0], initY[0]);
	}

	MyPoint& tPoint = TraceVector.back();
	tPoint.x_ = initX[initCount - 1];
	tPoint.y_ = initY[initCount - 1];
}

void CMathAide::BuildLinear(float initX[], float initY[], int initCount, MovePoints& TraceVector, float fDistance)
{
	TraceVector.clear();

	if (initCount < 2) return;

	if (fDistance <= 0.0f) return;

	float disTotal = CalcDistance(initX[0], initY[0], initX[initCount - 1], initY[initCount - 1]);
	if (disTotal <= 0.0f) return;

	float tAngle = CalcAngle(initX[initCount-1], initY[initCount-1], initX[0], initY[0])-M_PI_2;

	CMovePoint point;
	point.m_Position.x_ = initX[0];
	point.m_Position.y_ = initY[0];
	point.m_Direction = tAngle;
	TraceVector.push_back(point);
	float tfDis = 0.f;

	MovePoints::size_type size;
	while (tfDis < disTotal)
	{
		size = TraceVector.size();

		point.m_Position.x_ = initX[0] + cosf(tAngle) * (fDistance * size);
		point.m_Position.y_ = initY[0] + sinf(tAngle) * (fDistance * size);  
		point.m_Direction = tAngle;

		TraceVector.push_back(point);
		tfDis = CalcDistance(point.m_Position.x_, point.m_Position.y_, initX[0], initY[0]);
	}

	CMovePoint& tPoint = TraceVector.back();
	tPoint.m_Position.x_ = initX[initCount - 1];
	tPoint.m_Position.y_ = initY[initCount - 1];
}

////#include "../消息定义/CMD_Fish.h"

void CMathAide::BuildBezier(float initX[], float initY[], int initCount, MovePoints& TraceVector, float fDistance)
{
	if (initCount < 3) return;

	TraceVector.clear();

	int index = 0;
	CMovePoint tPos0;
	float t = 0.f;
	int count = initCount - 1;
	float tfDis = fDistance;
	CMovePoint tPos;

	while (t < 1.0f)
	{
		tPos.m_Position.x_ = 0.f;
		tPos.m_Position.y_ = 0.f;
		index = 0;
		while (index <= count)
		{
			float tempValue = pow(t, index) * pow(1.f - t, count - index) * Combination(count, index);
			tPos.m_Position.x_ += initX[index] * tempValue;
			tPos.m_Position.y_ += initY[index] * tempValue;
			++index;
		}

		float fSpace = 0.f;
		if (TraceVector.size() > 0)
		{
			CMovePoint& backPos = TraceVector.back();
			fSpace = CalcDistance(backPos.m_Position.x_, backPos.m_Position.y_, tPos.m_Position.x_, tPos.m_Position.y_);
		}

		if (fSpace >= tfDis || TraceVector.size() == 0)
		{
			if (TraceVector.size() > 0) 
			{
				float temp_dis = CalcDistance(tPos.m_Position.x_, tPos.m_Position.y_, tPos0.m_Position.x_, tPos0.m_Position.y_);
				if (temp_dis != 0.f)
				{
					float tempValue = (tPos.m_Position.x_ - tPos0.m_Position.x_) / temp_dis;
					if ((tPos.m_Position.y_ - tPos0.m_Position.y_) >= 0.f)
						tPos.m_Direction = acosf(tempValue);
					else
						tPos.m_Direction = -acosf(tempValue);
				} 
				else
				{
					tPos.m_Direction = 1.f;
				}
			}
			else 
			{
				tPos.m_Direction = 1.f;
			}
			TraceVector.push_back(tPos);

			tPos0.m_Position.x_ = tPos.m_Position.x_;
			tPos0.m_Position.y_ = tPos.m_Position.y_;
		}

		t += 0.00001f;
	}
}

void CMathAide::BuildCircle(float centerX, float centerY, float radius, MovePoints& FishPos, int FishCount)
{
	if (FishCount <= 0 || radius == 0) return;
	float cell_radian = 2 * M_PI / FishCount;

	for (int i = 0; i < FishCount; ++i)
	{
		CMovePoint pp;
		pp.m_Position.x_ = centerX + radius * cosf(i * cell_radian);
		pp.m_Position.y_ = centerY + radius * sinf(i * cell_radian);
		pp.m_Direction = cell_radian;
		FishPos.push_back(pp);
	}
}

void CMathAide::BuildCirclePath(float centerX, float centerY, float radius, MovePoints& FishPos, float begin, float fAngle, int nStep, float fAdd)
{
	if(fAngle == 0.0f || radius == 0) return;
	if(nStep < 1) nStep = 1;

	int nCir = 2 * M_PI * radius / nStep;
	int nCount = nCir * abs(fAngle) / (2 * M_PI);
	float cell_radian =  2 * M_PI / nCir * fAngle / abs(fAngle);

	MyPoint pLast;
	for (int i = 0; i < nCount; ++i)
	{
		CMovePoint pp;
		pp.m_Position.x_ = centerX + radius * cosf(begin + i * cell_radian);
		pp.m_Position.y_ = centerY + radius * sinf(begin + i * cell_radian);

		if(i == 0)
		{
			pp.m_Direction = begin + i * cell_radian + M_PI_2;
		}
		else
		{
			pp.m_Direction = CalcAngle(pLast.x_, pLast.y_, pp.m_Position.x_, pp.m_Position.y_) + M_PI_2;
		}

		pLast = pp.m_Position;

		if(fAdd != 0)
		{
			radius += fAdd;
		}
		FishPos.push_back(pp);
	}
}

MyPoint CMathAide::GetRotationPosByOffest(float xPos, float yPos, float xOffest, float yOffest, float dir, float fHScale, float fVScale)
{
	MyPoint pt;

	float r = sqrtf(xOffest*xOffest+yOffest*yOffest);

	float fd = CalcAngle(0, 0, xOffest, yOffest)-M_PI_2 + dir;

	// 	if(xOffest > 0)
	pt.x_ = (xPos - r * cosf(fd)) * fHScale;
	// 	else
	//		pt.x_ = (xPos + r * cosf(fd)) * fHScale;

	// 	if(yOffest > 0)
	// 		pt.y_ = (yPos + r * sinf(fd)) * fVScale;
	// 	else
	pt.y_ = (yPos - r * sinf(fd)) * fVScale;

	return pt;
}
