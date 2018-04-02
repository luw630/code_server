//
#ifndef __VISUAL_COMPENT_H__
#define __VISUAL_COMPENT_H__

#include "MyComponent.h"
#include "MovePoint.h"
#include <string>

enum VisualType
{
	EVCT_NORMAL = (ECF_VISUAL<<8),		//ÆÕÍ¨
};

enum AniType
{
	EAT_NORMAL=0,
	EAT_ROTATION,
};

struct ImageInfo
{
	std::string		szImageName;
	float			fImageScale;
	CMovePoint		ImageOffest;
	int				nAniType;
	float			fratio;
};

class VisualCompent : public MyComponent
{
public:
	VisualCompent() : m_nVisualType(0),m_bHit(false){};

	virtual ~VisualCompent(){};

	virtual const uint32_t GetFamilyID() const{return ECF_VISUAL;}

	virtual bool InitResource() = NULL;

	virtual void Render(float x, float y, float dir, float fHScale, float fVScale) = NULL;

	void SetVisulalType(int n){m_nVisualType = n;}
	int GetVisualType(){return m_nVisualType;}

	virtual void AddImageInfo(int stat, ImageInfo &lv) = NULL;

	bool bHit(){return m_bHit;}
	void SetHit(bool b){m_bHit = b;}

protected:
	int		m_nVisualType;

	bool						m_bHit;
};

#endif

