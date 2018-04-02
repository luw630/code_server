for /r %%s in (public_*.proto) do (
	protoc.exe -I . --descriptor_set_out client/%%~ns.proto %%~ns.proto
)

pause