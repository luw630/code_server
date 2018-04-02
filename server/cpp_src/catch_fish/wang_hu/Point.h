#ifndef __POINT_H__
#define __POINT_H__

class MyPoint
{
public:
	MyPoint():x_(0), y_(0) {}
	MyPoint(float x, float y):x_(x), y_(y) {}
	MyPoint(const MyPoint &point):x_(point.x_), y_(point.y_) {}
	~MyPoint() {}

public:
	void offset(float x, float y) { x_+= x; y_+=y; }

	void set_point(float x, float y) { x_=x; y_=y; }

	bool operator == (const MyPoint &point) const { return (x_==point.x_&&y_==point.y_); }
	bool operator != (const MyPoint &point) const { return (x_!=point.x_||y_!=point.y_); }

	MyPoint &operator = (const MyPoint &point) { x_=point.x_; y_=point.y_; return *this; }

	void operator += (const MyPoint &point) { x_+=point.x_; y_+=point.y_; }
	void operator -= (const MyPoint &point) { x_-=point.x_; y_-=point.y_; }

	MyPoint operator + (const MyPoint &point) { return MyPoint(x_+point.x_, y_+point.y_); }
	MyPoint operator - (const MyPoint &point) { return MyPoint(x_-point.x_, y_-point.y_); }
	MyPoint operator - () { return MyPoint(-x_, -y_); }

	MyPoint operator * (float multip) { return MyPoint(x_*multip, y_*multip); }

public:
	float x_;
	float y_;
};


#endif
