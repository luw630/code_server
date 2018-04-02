#pragma once
#include "MovePoint.h"

class CBezierCurve
{
public:
	CBezierCurve();
	~CBezierCurve();

	static CBezierCurve* GetInstance(void)
	{
		static CBezierCurve* ret = new CBezierCurve;
		return ret;
	}

	void Bezier2D(double* b, int npts, int cpts, double* p);
	void Bezier2D(float initX[], float initY[], int posCount, int initCount, MovePoints& outVector, float fDistance);
private:
	void CreateFactorialTable(void);
	double factorial(int n);
	double Ni(int n, int i);
	double Bernstein(int n, int i, double t);
private:
	double FactorialLookup[33];
};