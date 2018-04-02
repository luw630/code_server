#include "BufferFactory.h"

SingletonInstance(BufferFactory);

BufferFactory::BufferFactory()
{
	m_nPoolSize = 10000;
}

BufferFactory::~BufferFactory()
{

}

CBuffer* BufferFactory::Create(int objType)
{
	CBuffer* buff = Factory<int, CBuffer>::Create(objType);
	if(buff != NULL)
	{
		buff->SetType((BUFFER_TYPE)objType);
		buff->SetLife(1.0f);
	}
	return buff;
}
