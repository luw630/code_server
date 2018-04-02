////
#ifndef _MY_OBJECT_FACTORY_H_
#define _MY_OBJECT_FACTORY_H_

#include "MyObject.h"
#include "Factory.h"
#include "TSingleton.h"

class MyObjFactory: public Factory< int, MyObject >, public Singleton< MyObjFactory >
{
protected:
	MyObjFactory();
	virtual ~MyObjFactory();
	FriendBaseSingleton(MyObjFactory);

public:
	virtual MyObject* Create(int objType);
};


template < class _Ty >
class MyObjCreator: public Creator< MyObject >
{
public:
	virtual _Ty* Create()
	{
		return new _Ty;
	}
};

#define REGISTER_OBJ_TYPE( typeID, type ) {std::auto_ptr< Creator< MyObject > > ptr( new MyObjCreator< type >()); MyObjFactory::GetInstance()->Register(typeID, ptr);}

inline MyObject* CreateObject( int objType )
{
	return MyObjFactory::GetInstance()->Create(objType);
}

#endif

