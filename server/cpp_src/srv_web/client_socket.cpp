#include "stdafx.h" 
#include "client_socket.h"

client_socket::client_socket()
{
	memset(m_bufOutput, 0, sizeof(m_bufOutput));
	memset(m_bufInput, 0, sizeof(m_bufInput));
}
void client_socket::closeSocket()
{
#ifdef WIN32 
	closesocket(m_sockClient);
	//WSACleanup();
#else 
	close(m_sockClient);
#endif 
}

bool client_socket::Create(const char* pszServerIP, int nServerPort, int nBlockSec, bool bKeepAlive /*= FALSE*/)
{
	if (pszServerIP == 0 || strlen(pszServerIP) > 15) {
		return false;
	}
	m_sockClient = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	if (m_sockClient == INVALID_SOCKET) {
		closeSocket();
		return false;
	}
	if (bKeepAlive)
	{
		int     optval = 1;
		if (setsockopt(m_sockClient, SOL_SOCKET, SO_KEEPALIVE, (char *)&optval, sizeof(optval)))
		{
			closeSocket();
			return false;
		}
	}

#ifdef WIN32 
	DWORD nMode = 1;
	int nRes = ioctlsocket(m_sockClient, FIONBIO, &nMode);
	if (nRes == SOCKET_ERROR) {
		closeSocket();
		return false;
	}
#else 
	fcntl(m_sockClient, F_SETFL, O_NONBLOCK);
#endif 
	unsigned long serveraddr = inet_addr(pszServerIP);
	if (serveraddr == INADDR_NONE) 
	{
		closeSocket();
		return false;
	}
	sockaddr_in addr_in;
	memset((void *)&addr_in, 0, sizeof(addr_in));
	addr_in.sin_family = AF_INET;
	addr_in.sin_port = htons(nServerPort);
	addr_in.sin_addr.s_addr = serveraddr;

	if (connect(m_sockClient, (sockaddr *)&addr_in, sizeof(addr_in)) == SOCKET_ERROR) {
		if (hasError()) {
			closeSocket();
			return false;
		}
		else    // WSAWOLDBLOCK 
		{
			timeval timeout;
			timeout.tv_sec = nBlockSec;
			timeout.tv_usec = 0;
			fd_set writeset, exceptset;
			FD_ZERO(&writeset);
			FD_ZERO(&exceptset);
			FD_SET(m_sockClient, &writeset);
			FD_SET(m_sockClient, &exceptset);

			int ret = select(FD_SETSIZE, NULL, &writeset, &exceptset, &timeout);
			if (ret == 0 || ret < 0) {
				closeSocket();
				return false;
			}
			else  // ret > 0 
			{
				ret = FD_ISSET(m_sockClient, &exceptset);
				if (ret)     // or (!FD_ISSET(m_sockClient, &writeset) 
				{
					closeSocket();
					return false;
				}
			}
		}
	}

	m_nInbufLen = 0;
	m_nInbufStart = 0;
	m_nOutbufLen = 0;

	struct linger so_linger;
	so_linger.l_onoff = 1;
	so_linger.l_linger = 500;
	setsockopt(m_sockClient, SOL_SOCKET, SO_LINGER, (const char*)&so_linger, sizeof(so_linger));

	return true;
}

bool client_socket::SendMsg(void* pBuf, int nSize)
{
	if (pBuf == 0 || nSize <= 0) {
		return false;
	}

	if (m_sockClient == INVALID_SOCKET) {
		return false;
	}

	int packsize = 0;
	packsize = nSize;

	if (m_nOutbufLen + nSize > OUTBUFSIZE) {
		Flush();
		if (m_nOutbufLen + nSize > OUTBUFSIZE) {
			Destroy();
			return false;
		}
	}
	memcpy(m_bufOutput + m_nOutbufLen, pBuf, nSize);
	m_nOutbufLen += nSize;
	return true;
}

bool client_socket::ReceiveMsg(void* pBuf, int& nSize)
{
	if (pBuf == NULL || nSize <= 0) {
		return false;
	}

	if (m_sockClient == INVALID_SOCKET) {
		return false;
	}

	if (m_nInbufLen < 2) {
		if (!recvFromSock() || m_nInbufLen < 2) { 
			return false;
		}
	}

	char msgLen[2] = { 0 };
	msgLen[0] = m_bufInput[m_nInbufStart];
	msgLen[1] = m_bufInput[(m_nInbufStart + 1) % INBUFSIZE];
	int packsize = *reinterpret_cast<unsigned short*>(msgLen);
	if (packsize <= 0 || packsize > _MAX_MSGSIZE) {
		m_nInbufLen = 0;      
		m_nInbufStart = 0;
		return false;
	}

	if (packsize > m_nInbufLen) {
		if (!recvFromSock() || packsize > m_nInbufLen) {
			return false;
		}
	}

	if (m_nInbufStart + packsize > INBUFSIZE) {
		int copylen = INBUFSIZE - m_nInbufStart;
		memcpy(pBuf, m_bufInput + m_nInbufStart, copylen);
		memcpy((unsigned char *)pBuf + copylen, m_bufInput, packsize - copylen);
		nSize = packsize;
	}
	else {
		memcpy(pBuf, m_bufInput + m_nInbufStart, packsize);
		nSize = packsize;
	}
	m_nInbufStart = (m_nInbufStart + packsize) % INBUFSIZE;
	m_nInbufLen -= packsize;
	return  true;
}

bool client_socket::hasError()
{
#ifdef WIN32 
	int err = WSAGetLastError();
	if (err != WSAEWOULDBLOCK) {
#else 
	int err = errno;
	if (err != EINPROGRESS && err != EAGAIN) {
#endif 
		return true;
	}

	return false;
	}

bool client_socket::recvFromSock(void)
{
	if (m_nInbufLen >= INBUFSIZE || m_sockClient == INVALID_SOCKET) {
		return false;
	}

	int savelen, savepos;        
	if (m_nInbufStart + m_nInbufLen < INBUFSIZE)  {  
		savelen = INBUFSIZE - (m_nInbufStart + m_nInbufLen);      
	}
	else {
		savelen = INBUFSIZE - m_nInbufLen;
	}

	savepos = (m_nInbufStart + m_nInbufLen) % INBUFSIZE;
	CHECKF(savepos + savelen <= INBUFSIZE);
	int inlen = recv(m_sockClient, m_bufInput + savepos, savelen, 0);
	if (inlen > 0) {
		m_nInbufLen += inlen;

		if (m_nInbufLen > INBUFSIZE) {
			return false;
		}

		if (inlen == savelen && m_nInbufLen < INBUFSIZE) {
			int savelen = INBUFSIZE - m_nInbufLen;
			int savepos = (m_nInbufStart + m_nInbufLen) % INBUFSIZE;
			CHECKF(savepos + savelen <= INBUFSIZE);
			inlen = recv(m_sockClient, m_bufInput + savepos, savelen, 0);
			if (inlen > 0) {
				m_nInbufLen += inlen;
				if (m_nInbufLen > INBUFSIZE) {
					return false;
				}
			}
			else if (inlen == 0) {
				Destroy();
				return false;
			}
			else {
				if (hasError()) {
					Destroy();
					return false;
				}
			}
		}
	}
	else if (inlen == 0) {
		Destroy();
		return false;
	}
	else {
		if (hasError()) {
			Destroy();
			return false;
		}
	}

	return true;
}

bool client_socket::Flush(void)
{
	if (m_sockClient == INVALID_SOCKET) {
		return false;
	}

	if (m_nOutbufLen <= 0) {
		return true;
	}

	int outsize;
	outsize = send(m_sockClient, m_bufOutput, m_nOutbufLen, 0);
	if (outsize > 0) {
		if (m_nOutbufLen - outsize > 0) {
			memcpy(m_bufOutput, m_bufOutput + outsize, m_nOutbufLen - outsize);
		}

		m_nOutbufLen -= outsize;

		if (m_nOutbufLen < 0) {
			return false;
		}
	}
	else {
		if (hasError()) {
			Destroy();
			return false;
		}
	}

	return true;
}

bool client_socket::Check(void)
{
	if (m_sockClient == INVALID_SOCKET) {
		return false;
	}

	char buf[1];
	int ret = recv(m_sockClient, buf, 1, MSG_PEEK);
	if (ret == 0) {
		Destroy();
		return false;
	}
	else if (ret < 0) {
		if (hasError()) {
			Destroy();
			return false;
		}
		else {   
			return true;
		}
	}
	else {  
		return true;
	}

	return true;
}

void client_socket::Destroy(void)
{
	struct linger so_linger;
	so_linger.l_onoff = 1;
	so_linger.l_linger = 500;
	int ret = setsockopt(m_sockClient, SOL_SOCKET, SO_LINGER, (const char*)&so_linger, sizeof(so_linger));

	closeSocket();

	m_sockClient = INVALID_SOCKET;
	m_nInbufLen = 0;
	m_nInbufStart = 0;
	m_nOutbufLen = 0;

	memset(m_bufOutput, 0, sizeof(m_bufOutput));
	memset(m_bufInput, 0, sizeof(m_bufInput));
}
