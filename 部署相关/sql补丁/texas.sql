USE `config`;
UPDATE t_game_server_cfg set is_open = 1 where game_id >= 80 and game_id <=83;