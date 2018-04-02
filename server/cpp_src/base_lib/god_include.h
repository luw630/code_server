#pragma once

#if defined(_WIN32) || defined(_WIN64)
#define PLATFORM_WINDOWS
#endif


#include <boost/asio.hpp>
#include <boost/format.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/algorithm/string.hpp>
#include <boost/make_shared.hpp>
#include <boost/bind.hpp>

#ifdef PLATFORM_WINDOWS
#include <Windows.h>
#define WIN32_LEAN_AND_MEAN
#include <process.h>
#include <psapi.h>
#pragma comment(lib,"psapi.lib")
#endif

#ifdef PLATFORM_LINUX
#include <unistd.h>

#define DWORD uint32_t
#define MAX_PATH 260

DWORD timeGetTime();
#endif

// c
#include <cstdlib>
#include <cstdio>
#include <malloc.h>
#include <memory.h>
#include <cassert>
#include <cctype>
#include <cmath>
#include <ctime>
#include <stdarg.h>

// stl
#include <limits>
#include <algorithm>
#include <array>
#include <bitset>
#include <complex>
#include <deque>
#include <exception>
#include <fstream>
#include <functional>
#include <iomanip>
#include <iostream>
#include <list>
#include <map>
#include <memory>
#include <new>
#include <numeric>
#include <queue>
#include <random>
#include <regex>
#include <set>
#include <sstream>
#include <stack>
#include <string>
#include <tuple>
#include <type_traits>
#include <valarray>
#include <vector>
#include <unordered_set>
#include <unordered_map>
#include <thread>
#include <mutex>

#ifdef PLATFORM_WINDOWS
#define _CRTDBG_MAP_ALLOC
#include <stdlib.h>
#include <crtdbg.h>

#ifdef _DEBUG
#define DEBUG_NEW new(_CLIENT_BLOCK, __FILE__, __LINE__)
#endif  // _DEBUG


#endif

#ifdef PLATFORM_LINUX
#define DEBUG_NEW new
#endif
#ifdef _DEBUG
	#define MSG_TIMEOUT_LIMIT 300000
#else
	#define MSG_TIMEOUT_LIMIT 30
#endif
#define SERVER_HEARTBEAT_TIME 10
#define DO_RECVMSG_PER_TICK_LIMIT 30
#define DO_MYSQL_PER_TICK_LIMIT 30
#define DO_REDIS_PER_TICK_LIMIT 100
#define SERVER_TICK_TIMEOUT_GUARD 100

