rd /s /q  sql
xcopy ..\sqls\* sql\ /s

rd /s /q  prj
xcopy ..\server\project\* prj\ /s

del prj\game_logs\* /f /s /q /a
rd /s /q  prj\Debug

rd /s /q  prj_luac
xcopy prj\* prj_luac\ /s


rd /s /q  luac_tool\script
xcopy prj\data\script\* luac_tool\script\ /s

PUSHD luac_tool
call build_lua.bat
POPD 

rd /s /q  prj_luac\data\script
xcopy luac_tool\script_out\script\* prj_luac\data\script\ /s

del prj_luac\Release\*.exp
del prj_luac\Release\*.lib
del prj_luac\Release\*.pdb
md prj_luac\game_logs

pause