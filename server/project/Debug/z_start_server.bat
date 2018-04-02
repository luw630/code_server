@echo off

start srv_cfg.exe save_sql_to_log
ping 1.1.1.1 -n 1 -w 1500 > nul

start srv_mysql.exe 1 save_sql_to_log
ping 1.1.1.1 -n 1 -w 1500 > nul

start srv_login.exe 1
ping 1.1.1.1 -n 1 -w 1500 > nul

start srv_game.exe 1 da_ting
ping 1.1.1.1 -n 1 -w 1500 > nul

start srv_game.exe 3 pu_yu
ping 1.1.1.1 -n 1 -w 1500 > nul
start srv_game.exe 4 pu_yu
ping 1.1.1.1 -n 1 -w 1500 > nul
start srv_game.exe 5 pu_yu
ping 1.1.1.1 -n 1 -w 1500 > nul
start srv_game.exe 6 pu_yu
ping 1.1.1.1 -n 1 -w 1500 > nul

start srv_game.exe 20 dou_di_zhu
ping 1.1.1.1 -n 1 -w 1500 > nul
start srv_game.exe 21 dou_di_zhu
ping 1.1.1.1 -n 1 -w 1500 > nul
start srv_game.exe 22 dou_di_zhu
ping 1.1.1.1 -n 1 -w 1500 > nul


start srv_game.exe 30 zha_jing_hua
ping 1.1.1.1 -n 1 -w 1500 > nul
start srv_game.exe 31 zha_jing_hua
ping 1.1.1.1 -n 1 -w 1500 > nul
start srv_game.exe 32 zha_jing_hua
ping 1.1.1.1 -n 1 -w 1500 > nul
start srv_game.exe 33 zha_jing_hua
ping 1.1.1.1 -n 1 -w 1500 > nul



start srv_game.exe 50 bai_ren_niu_niu
ping 1.1.1.1 -n 1 -w 1500 > nul
start srv_game.exe 51 bai_ren_niu_niu
ping 1.1.1.1 -n 1 -w 1500 > nul

start srv_game.exe 110 qiang_zhuang_niu_niu
ping 1.1.1.1 -n 1 -w 1500 > nul
start srv_game.exe 111 qiang_zhuang_niu_niu
ping 1.1.1.1 -n 1 -w 1500 > nul
start srv_game.exe 112 qiang_zhuang_niu_niu
ping 1.1.1.1 -n 1 -w 1500 > nul
start srv_game.exe 113 qiang_zhuang_niu_niu
ping 1.1.1.1 -n 1 -w 1500 > nul


start srv_game.exe 150 san_gong
ping 1.1.1.1 -n 1 -w 1500 > nul
start srv_game.exe 151 san_gong
ping 1.1.1.1 -n 1 -w 1500 > nul
start srv_game.exe 152 san_gong
ping 1.1.1.1 -n 1 -w 1500 > nul
start srv_game.exe 153 san_gong
ping 1.1.1.1 -n 1 -w 1500 > nul




start srv_gateway.exe 1
ping 1.1.1.1 -n 1 -w 1500 > nul

start srv_web.exe
ping 1.1.1.1 -n 1 -w 1500 > nul