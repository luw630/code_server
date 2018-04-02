#include "EffectFactory.h"

SingletonInstance(EffectFactory);

EffectFactory::EffectFactory()
{
	m_nPoolSize = 10001;
}

EffectFactory::~EffectFactory()
{

}

CEffect* EffectFactory::Create(int objType)
{
	CEffect* eff = Factory<int, CEffect>::Create(objType);
	if(eff != NULL)
	{
		eff->SetEffectType((EffectType)objType);
	}
	return eff;
}






