#pragma once

#ifdef WIN32
#include <windows.h>
#include <WinSock.h>
#else
#include <sys/socket.h>
#include <fcntl.h>
#include <errno.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define SOCKET int
#define SOCKET_ERROR -1
#define INVALID_SOCKET -1

#endif

#ifndef CHECKF
#define CHECKF(x) \
    do \
			{ \
		if (!(x)) { \
			printf("%s, file:%s, line:%d\n", #x, __FILE__, __LINE__); \
			return 0; \
						} \
			} while (0)
#endif

#define _MAX_MSGSIZE 16 * 1024        
#define BLOCKSECONDS    30            
#define INBUFSIZE    (64*1024)        
#define OUTBUFSIZE    (8*1024)        

class client_socket
{
public:
	client_socket(void);
	bool    Create(const char* pszServerIP, int nServerPort, int nBlockSec = BLOCKSECONDS, bool bKeepAlive = false);
	bool    SendMsg(void* pBuf, int nSize);
	bool    ReceiveMsg(void* pBuf, int& nSize);
	bool    Flush(void);
	bool    Check(void);
	void    Destroy(void);
	SOCKET    GetSocket(void) const { return m_sockClient; }
private:
	bool    recvFromSock(void);   
	bool    hasError();           
	void    closeSocket();
	SOCKET    m_sockClient;
	char    m_bufOutput[OUTBUFSIZE];  
	int        m_nOutbufLen;
	char    m_bufInput[INBUFSIZE];
	int        m_nInbufLen;
	int        m_nInbufStart;        
};
