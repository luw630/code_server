USE account;
CREATE TABLE IF NOT EXISTS `t_playerip_201801` (
  `tid` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `guid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '推广的玩家ID',
    `ip` varchar(50) NOT NULL DEFAULT '' COMMENT '用户IP',
    `times` int(10) unsigned NOT NULL DEFAULT '0',
    `times_index` int(10) unsigned NOT NULL DEFAULT '0',
    `ck` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'IP被匹配到修改为1',

  PRIMARY KEY (`tid`),
  KEY `times` (`times`),
  KEY `guid` (`guid`),KEY `ck` (`ck`),
  KEY `times_index` (`times_index`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '玩家分享链接IP记录表';


CREATE TABLE `t_player_guid` (
  `tid` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `guid` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '推广玩家ID',
  `zguid` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '被推广玩家ID',
  `phone` tinyint(1) NOT NULL DEFAULT '1' COMMENT '手机类型 2 ios or 1 android',
  `times_index` int(10) unsigned NOT NULL DEFAULT '0',

   PRIMARY KEY (`tid`),
   KEY `guid` (`guid`),KEY `zguid` (`zguid`),KEY `times_index` (`times_index`),KEY `phone` (`phone`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '玩家推广总记录表';