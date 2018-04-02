USE config;
update t_game_server_cfg SET room_lua_cfg= 'cfg={chi_line = 500,tu_line = 1000} return cfg'  where game_id = 3;
update t_game_server_cfg SET room_lua_cfg= 'cfg={chi_line = 20000,tu_line = 50000} return cfg'  where game_id = 4;
update t_game_server_cfg SET room_lua_cfg= 'cfg={chi_line = 200000,tu_line = 500000} return cfg'  where game_id = 5;
update t_game_server_cfg SET room_lua_cfg= 'cfg={chi_line = 2000000,tu_line = 5000000} return cfg'  where game_id = 6;