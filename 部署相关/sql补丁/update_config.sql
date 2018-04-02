USE config;
update t_game_server_cfg SET room_lua_cfg= 'cfg={chi_line = 500,tu_line = 1000} return cfg'  where game_id = 3;
update t_game_server_cfg SET room_lua_cfg= 'cfg={chi_line = 5000,tu_line = 10000} return cfg'  where game_id = 4;
update t_game_server_cfg SET room_lua_cfg= 'cfg={chi_line = 50000,tu_line = 100000} return cfg'  where game_id = 5;
update t_game_server_cfg SET room_lua_cfg= 'cfg={chi_line = 500000,tu_line = 1000000} return cfg'  where game_id = 6;