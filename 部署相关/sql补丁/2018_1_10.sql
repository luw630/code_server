USE `game`;
CREATE TABLE t_game_black_ip (
  id bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '黑名单ID',
  ip varchar(64) NOT NULL DEFAULT '' COMMENT 'ip',
  gameid int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '游戏ID',
  game_name varchar(64) NOT NULL DEFAULT '' COMMENT '游戏类型为游戏名字(all为所有游戏)',

  PRIMARY KEY (id),
  KEY ip (ip),KEY gameid (gameid),KEY game_name (game_name)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='游戏IP黑名单表,根据IP拉黑让玩家拿不到大牌'