#include "xn_test_mgr.h"

int main(int argc, char* argv[])
{
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);

	xn_test_mgr theApp;
	theApp.startup();

	system("pause");

	return 0;
}
