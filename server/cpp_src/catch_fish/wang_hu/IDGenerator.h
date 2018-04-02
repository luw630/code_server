////
#ifndef __IDGENERATOR_H__
#define __IDGENERATOR_H__

#include "common.h"
#include "TSingleton.h"

class IDGenerator : public Singleton< IDGenerator >
{
public:
	uint32_t GetID64();

	void SetSeed(uint32_t seed){id64_ = seed;}

protected:
	IDGenerator();
	virtual ~IDGenerator(){};
	FriendBaseSingleton(IDGenerator);

private:
	uint32_t id64_;
};


#endif//__IDGENERATOR_H__
