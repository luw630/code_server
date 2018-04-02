@echo off
rem -----------------------------------------------
rem 加密lua脚本
rem 需要把 bat文件，luac.exe文件放到lua脚本的目标之下
rem 执行bat文件会在lua脚本的目标之下创建一个加密后的文件夹
rem 加密后的文件夹名字在bat中设定
rem -----------------------------------------------
rem lastedit 2017-8-19

rem 这里可以定义目标文件夹
set OUTDIR=script_out


rem 判断luac.exe是否存在
if not exist luac.exe  (
echo luac.exe 不在当前目录，请核实
goto l_end 
)


rem 启动延迟变量
setlocal enabledelayedexpansion 


rem 删除原有的目标文件夹
if exist %OUTDIR% (
rd /s /q %OUTDIR%
)

rem 遍历目标文件下的lua文件
set /a num=0
for /f %%x in ('dir /a-d /b /s  *.lua') do (
	echo 正在加载文件...!num!
    set /a num+=1
	rem 获取目标文件全名字符串
	set tempstr_full_out=%%x
	set "tempstr_full_out=!tempstr_full_out:%cd%=%OUTDIR%!"
	
	rem 获取源文件全名字符串
	set tempstr_full_src=%%x
	
	rem 获取目标文件夹名称字符串
	set "tempstr_path=%%~dpx"
	set "tempstr_path=!tempstr_path:%cd%=%OUTDIR%!"
	rem 创建目标文件夹
	if not exist !tempstr_path! (
	md !tempstr_path!
	)
	rem 创建目标lua文件
	cd.>!tempstr_full_out!

	rem 执行luac加密
	luac.exe -o !tempstr_full_out! !tempstr_full_src! 
	
)

echo 一共 %num% 个文件被加载

:l_end

