#ifndef __CALLBACK_H__
#define __CALLBACK_H__

template< typename _Ty >
class TemplateCallback
{
public:
	virtual ~TemplateCallback(){};
	virtual void operator()( _Ty ) = 0;

};

template< class _Ty, typename _Tx >
class TemplateMemFunc : public TemplateCallback< _Tx >
{
public:
	TemplateMemFunc(_Ty* obj = 0, void (_Ty::*func)(_Tx)  = 0)
		:obj_(obj),func_(func)
	{}

	void operator () (_Tx param)
	{
		(obj_->*func_)(param);
	}

	const TemplateMemFunc& operator = (const TemplateMemFunc& tc)
	{
		obj_ = tc.obj_;
		func_ = tc.func_;
		return *this;
	}
private:
	_Ty* obj_;
	void (_Ty::*func_)(_Tx);
};

template< typename _Tx, typename _Ty >
class TemplateCallback_r
{
public:
	virtual ~TemplateCallback_r(){};
	virtual _Ty operator()(_Tx) = 0;
};

template< class _Ty, typename _Tx, typename _Tz >
class TemplateMemFunc_r: public TemplateCallback_r< _Tx, _Tz >
{
public:
	TemplateMemFunc_r(_Ty* obj = 0, _Tz (_Ty::*func)(_Tx)  = 0)
		:obj_(obj),func_(func)
	{}

	_Tz operator () (_Tx param)
	{
		return (obj_->*func_)(param);
	}

	const TemplateMemFunc_r& operator = (const TemplateMemFunc_r& tc)
	{
		obj_ = tc.obj_;
		func_ = tc.func_;
		return *this;
	}
private:
	_Ty* obj_;
	_Tz (_Ty::*func_)(_Tx);
};


#endif//__CALLBACK_H__
