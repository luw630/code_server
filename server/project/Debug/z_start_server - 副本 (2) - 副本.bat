@echo off


start srv_mysql.exe 2 save_sql_to_log
ping 1.1.1.1 -n 1 -w 1500 > nul



