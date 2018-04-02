#include "MyObjectFactory.h"
#include "IDGenerator.h"

SingletonInstance(MyObjFactory);

MyObjFactory::MyObjFactory()
{
	m_nPoolSize = 10003;
}

MyObjFactory::~MyObjFactory()
{

}

MyObject* MyObjFactory::Create(int objType)
{
	MyObject* obj = Factory<int, MyObject>::Create(objType);
	if (obj)
	{
		obj->SetObjType(objType);
		obj->SetId(IDGenerator::GetInstance()->GetID64());
		obj->SetCreateTick(timeGetTime());
	}
	return obj;
}







