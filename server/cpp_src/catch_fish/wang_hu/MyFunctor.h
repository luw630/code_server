////
#ifndef __FUNCTOR_H__
#define __FUNCTOR_H__

#include <algorithm>

template< typename _Ty >
class FuncDelete
{
public:
	void operator()(_Ty* ptr)
	{
		delete ptr;
	}
};

template< typename _Ty >
class FuncMapDelete
{
public:
	void operator()(typename _Ty::value_type& it)
	{
		delete it.second;
	}
};

template< typename _Ty >
class FuncRelease
{
public:
	void operator()( _Ty* ptr)
	{
		ptr->Release();
	}
};

template< typename _Ty >
class FuncUpdate
{
public:
	FuncUpdate(int ms)
		:_ms(ms)
	{}

	void operator()( _Ty* ptr)
	{
		ptr->OnUpdate(_ms);
	}
private:
	int _ms;
};

template< typename _Ty >
class FuncMapUpdate
{
public:
	FuncMapUpdate(int ms)
		:_ms(ms)
	{}

	void operator()(typename _Ty::value_type& it)
	{
		it.second.OnUpdate(_ms);
	}
private:
	int _ms;
};

template< typename _Ty >
class FuncMapUpdatePtr
{
public:
	FuncMapUpdatePtr(int ms)
		:_ms(ms)
	{}

	void operator()(typename _Ty::value_type& it)
	{
		it.second->OnUpdate(_ms);
	}
private:
	int _ms;
};

#endif//__FUNCTOR_H__
