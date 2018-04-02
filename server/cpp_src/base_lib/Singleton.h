#pragma once

#include "god_include.h"

template <typename T>
class TSingleton
{
	TSingleton(const TSingleton&);
	TSingleton& operator =(const TSingleton&);
public:

	TSingleton()
	{
		assert(!ms_Singleton);
		ms_Singleton = static_cast<T*>(this);
	}

	~TSingleton()
	{
		assert(ms_Singleton);
		ms_Singleton = NULL;
	}


	inline static T* instance()
	{
		return ms_Singleton;
	}

protected:
	static T* ms_Singleton;
};

template<typename T> T* TSingleton<T>::ms_Singleton = nullptr;
