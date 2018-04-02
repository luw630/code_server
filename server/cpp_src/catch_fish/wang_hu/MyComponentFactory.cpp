#include "MyComponentFactory.h"

SingletonInstance( MyComponentFactory );


MyComponentFactory::MyComponentFactory()
{
	m_nPoolSize = 10002;
}
