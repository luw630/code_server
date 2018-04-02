////
#ifndef MATH_AIDE_H_
#define MATH_AIDE_H_

#include "MovePoint.h"

class CMathAide 
{
public:
  //阶乘
  static int Factorial(int number);
  //组合
  static int Combination(int count, int r);
  //计算距离
  static float CalcDistance(float x1, float y1, float x2, float y2);
  //计算角度
  static float CalcAngle(float x1, float y1, float x2, float y2);
  //创建线
  static void BuildLinear(float initX[], float initY[], int initCount, std::vector<MyPoint>& TraceVector, float fDistance);
  //创建线
  static void BuildLinear(float initX[], float initY[], int initCount, MovePoints& TraceVector, float fDistance);
  //创建贝赛尔
  static void BuildBezier(float initX[], float initY[], int initCount, MovePoints& TraceVector, float fDistance);
  //创建圆形
  static void BuildCircle(float centerX, float centerY, float radius, MovePoints& FishPos, int FishCount);
  //通过便宜获得旋转
  static MyPoint GetRotationPosByOffest(float xPos, float yPos, float xOffest, float yOffest, float dir, float fHScale=1.0f, float fVScale=1.0f);
  //创建循环路径
  static void BuildCirclePath(float centerX, float centerY, float radius, MovePoints& FishPos, float begin, float fAngle, int nStep = 1, float fAdd = 0);
};

#endif // MATH_AIDE_H_
