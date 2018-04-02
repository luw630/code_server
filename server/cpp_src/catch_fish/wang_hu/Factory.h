#ifndef __FACTORY_CREATOR_H__
#define __FACTORY_CREATOR_H__

#include <map>
#include <algorithm>
#include <memory>
#include <deque>
#include <list>
#include "MyFunctor.h"

 template< class _Ty >
 class Creator
 {
 public:
 	virtual ~Creator(){};
 	virtual _Ty* Create() = 0;
 };

template< typename _Tb, class _Ty >
class Factory
{
protected:
 	typedef typename std::map< _Tb, Creator< _Ty > * > MapCreator;
 	typedef typename std::map< _Tb, Creator< _Ty > * >::iterator MapCreatorIterator;
 	MapCreator mapCreator;
	typedef typename std::deque<_Ty*> FreeDeque;
	typedef typename std::map<_Tb, FreeDeque> FreeMap;

	FreeMap  m_FreeMap;

	int		m_nPoolSize;

public:
	Factory(){ m_nPoolSize = 1000; };
	virtual ~Factory()
	{
		std::for_each(mapCreator.begin(), mapCreator.end(), FuncMapDelete< MapCreator >() );
		mapCreator.clear();

// 		FreeMap::iterator ift = m_FreeMap.begin();
// 		while(ift != m_FreeMap.end())
// 		{
// 			FreeDeque& fq = ift->second;
// 
// 			FreeDeque::iterator ifq = fq.begin();
// 			while(ifq != fq.end())
// 			{
// 				delete *ifq;
// 				++ifq;
// 			}
// 			fq.clear();
// 
// 			++ift;
// 		}
// 		m_FreeMap.clear();
	}

	//根据类型创建一个对象
	virtual _Ty* Create(const _Tb& objType)
	{
  		MapCreatorIterator it = mapCreator.find( objType );
  		if(it != mapCreator.end())
  			return it->second->Create();
 
 		return NULL;

//  		_Ty* tt = NULL;
//  		FreeMap::iterator it = m_FreeMap.find(objType);
//  		if(it != m_FreeMap.end())
//  		{
//  			FreeDeque& fq = it->second;
//  			if(fq.size() > 0)
//  			{
//  				tt = fq.front();
//  				fq.pop_front();
//  			}
//  		}
//  
//  		return tt;
	}

	void Recovery(const _Tb& objType, _Ty* obj)
	{
 		delete obj;
 		obj = NULL;
 		return;

//  		FreeMap::iterator ifm = m_FreeMap.find(objType);
//  		if(ifm != m_FreeMap.end())
//  		{
//  			ifm->second.push_back(obj);
//  		}
	}

	//注册一个类型
	void Register(const _Tb& objType, std::auto_ptr< Creator< _Ty > > &pCreator)
	{
  		MapCreatorIterator it = mapCreator.find( objType );
  		if(it != mapCreator.end())
  			delete it->second;
  
  		mapCreator[objType] = pCreator.release();
 
 		return;

//  		Creator< _Ty > *pc = pCreator.release();
//  
//  		FreeMap::iterator im = m_FreeMap.find(objType);
//  		if(im == m_FreeMap.end())
//  		{
//  			FreeDeque fd;
//  			m_FreeMap[objType] = fd;
//  			for(int i = 0; i < m_nPoolSize; ++i)
//  			{
//  				m_FreeMap[objType].push_back(pc->Create());
//  			}
//  		}
	}

	//初始化，可以重载此函数来注册类型
	virtual void Initialize(){};
};

#endif//__FACTORY_CREATOR_H__
