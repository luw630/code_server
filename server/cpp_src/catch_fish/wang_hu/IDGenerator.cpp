#include "IDGenerator.h"

SingletonInstance(IDGenerator);

IDGenerator::IDGenerator()
:id64_(0)
{

}

uint32_t IDGenerator::GetID64()
{
	return ++id64_;
}