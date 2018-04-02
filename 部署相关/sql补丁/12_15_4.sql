USE `account`;
ALTER TABLE t_channel_form ADD tax_shi double(9,2) NOT NULL DEFAULT '0.00' AFTER tax;
CREATE TABLE t_channel_anios (
  tid int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  uid_one int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '渠道ID包',
  uid_two int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '渠道ID包',

   PRIMARY KEY (tid),
   KEY uid_one (uid_one),KEY uid_two (uid_two)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '安卓IOS关联表';