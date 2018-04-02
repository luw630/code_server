echo 需要安装7zip，将其路径加入到path中

md client
for /r %%s in (common_*.proto) do (
	protoc.exe -I . --descriptor_set_out client/%%~ns.proto %%~ns.proto
)

7z a -tzip "client" ".\client\*.*"

del /f /s /q client\*
rd client

pause
