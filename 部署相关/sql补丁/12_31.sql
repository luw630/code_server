USE `game`;
CREATE TABLE t_game_maintain_cfg (
  id int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  game_id int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '游戏ID',
  first_game_type int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '游戏一级ID',
  second_game_type int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '游戏二级ID',
  open tinyint(1) NOT NULL DEFAULT '1' COMMENT '维护开关 1 正常 or 2 维护',
   PRIMARY KEY (id),
   KEY game_id (game_id),KEY first_game_type (first_game_type),KEY second_game_type (second_game_type)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '维护开关表';