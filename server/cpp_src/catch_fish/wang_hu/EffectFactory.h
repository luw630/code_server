#ifndef __EFFECT_FACTORY_H__
#define __EFFECT_FACTORY_H__

#include "Effect.h"
#include "Factory.h"
#include "TSingleton.h"

class EffectFactory: public Factory< int, CEffect>, public Singleton< EffectFactory >
{
protected:
	EffectFactory();
	virtual ~EffectFactory();
	FriendBaseSingleton(EffectFactory);

public:
	virtual CEffect* Create(int effType);
};


template < class _Ty >
class EffectCreator: public Creator< CEffect >
{
public:
	virtual _Ty* Create()
	{
		return new _Ty;
	}
};

#define REGISTER_EFFECT_TYPE( typeID, type ) {std::auto_ptr< Creator< CEffect > > ptr( new EffectCreator< type >()); EffectFactory::GetInstance()->Register(typeID, ptr);}

inline CEffect* CreateEffect( int effType )
{
	return EffectFactory::GetInstance()->Create(effType);
}

#endif

