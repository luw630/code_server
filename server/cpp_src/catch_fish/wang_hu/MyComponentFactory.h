////
#ifndef __MY_COMPONENT_FACTORY_H__
#define __MY_COMPONENT_FACTORY_H__

#include "MyComponent.h"
#include "Factory.h"
#include "TSingleton.h"

class MyComponentFactory: public Factory< int, MyComponent >, public Singleton< MyComponentFactory >
{
protected:
	MyComponentFactory();
	~MyComponentFactory(){};
	FriendBaseSingleton(MyComponentFactory);

public:
	virtual MyComponent* Create(int soc_id)
	{
		MyComponent* soc = Factory<int, MyComponent>::Create(soc_id);
		if(soc)soc->SetID(soc_id);
		return soc;
	}
};



template < class _Ty >
class MyComponentCreator: public Creator< MyComponent >
{
public:
	virtual _Ty* Create()
	{
		return new _Ty;
	}
};

#define REGISTER_MYCOMPONENT_TYPE( typeID, type ) {std::auto_ptr< Creator< MyComponent > > ptr( new MyComponentCreator< type >()); MyComponentFactory::GetInstance()->Register(typeID, ptr);}

inline MyComponent* CreateComponent(const int idSoc)
{
	return MyComponentFactory::GetInstance()->Create(idSoc);
}
#endif//__CLIENT_COMPONENT_FACTORY_H__
