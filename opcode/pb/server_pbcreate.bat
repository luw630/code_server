for /r %%s in (*.proto) do (
	protoc3.3.exe --cpp_out ../../server/cpp_src/op_lib --proto_path . ./%%~ns.proto
)

if not exist "../../server/project/data/opcode" md "../../server/project/data/opcode"

for /r %%s in (*.proto) do (
	protoc3.3.exe -I . --descriptor_set_out ../../server/project/data/opcode/%%~ns.proto %%~ns.proto
)

if not exist "../../server/project/game_logs" md "../../server/project/game_logs"

pause
