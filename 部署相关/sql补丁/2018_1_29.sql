use account;
CREATE TABLE t_player_total (
  tid int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  guid int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '玩家ID',
  revenue double(11,2) NOT NULL DEFAULT '0.00' COMMENT '总兑换',
  register_num int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '总注册量',
  Bank_num int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '总支付帐号绑定量',
  Pay_num int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '总充值人数',
  Pay_money int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '总充值金额',
  tax int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '总游戏税收',
  income int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '给玩家的预计总支付金额',
  income_true int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '已经给玩家支付过的金额',
   cache_times int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '更新时间',
   PRIMARY KEY (tid),
   KEY guid (guid)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '玩家总报表';