USE `api`;
ALTER TABLE t_frame_version_cfg ADD is_new int(10) DEFAULT '1';
ALTER TABLE t_game_version_cfg ADD is_new int(10) DEFAULT '1';
ALTER TABLE t_hall_version_cfg ADD is_new int(10) DEFAULT '1';