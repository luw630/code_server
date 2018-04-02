@echo off

start srv_cfg.exe save_sql_to_log
ping 1.1.1.1 -n 1 -w 1500 > nul

start srv_mysql.exe 1 save_sql_to_log
ping 1.1.1.1 -n 1 -w 1500 > nul

start srv_login.exe 1
ping 1.1.1.1 -n 1 -w 1500 > nul

start srv_game.exe 1 da_ting
ping 1.1.1.1 -n 1 -w 1500 > nul


start srv_game.exe 150 san_gong
ping 1.1.1.1 -n 1 -w 1500 > nul

start srv_gateway.exe 1
ping 1.1.1.1 -n 1 -w 1500 > nul

start srv_web.exe
ping 1.1.1.1 -n 1 -w 1500 > nul