USE `account`;
CREATE TABLE t_channel_guid (
  tid int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  uid int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '渠道ID包',
  guid int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '玩家ID包',
  phone tinyint(1) NOT NULL DEFAULT '1' COMMENT '手机类型 2 ios or 1 android',
  times_index int(10) unsigned NOT NULL DEFAULT '0',

   PRIMARY KEY (tid),
   KEY uid (uid),KEY guid (guid),KEY times_index (times_index),KEY phone (phone)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '渠道总推广玩家记录表';