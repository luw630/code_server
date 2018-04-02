#ifndef __BUFFER_FACTORY_H__
#define __BUFFER_FACTORY_H__

#include "Buffer.h"
#include "Factory.h"
#include "TSingleton.h"

class BufferFactory: public Factory< int, CBuffer>, public Singleton< BufferFactory >
{
protected:
	BufferFactory();
	virtual ~BufferFactory();
	FriendBaseSingleton(BufferFactory);

public:
	virtual CBuffer* Create(int BuffType);
};


template < class _Ty >
class BufferCreator: public Creator< CBuffer >
{
public:
	virtual _Ty* Create()
	{
		return new _Ty;
	}
};

#define REGISTER_BUFFER_TYPE( typeID, type ) {std::auto_ptr< Creator< CBuffer > > ptr( new BufferCreator< type >()); BufferFactory::GetInstance()->Register(typeID, ptr);}

inline CBuffer* CreateBuffer( int BuffType )
{
	return BufferFactory::GetInstance()->Create(BuffType);
}

#endif
