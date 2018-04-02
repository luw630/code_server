USE account;
CREATE TABLE t_player_form (
  tid int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  guid int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '玩家ID',
  times int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '日期',
  register_num int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '注册量',
  login_num int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '登陆人数',
  revenue double(11,2) NOT NULL DEFAULT '0.00' COMMENT '新用户兑换',
  revenue_zon double(11,2) NOT NULL DEFAULT '0.00' COMMENT '新老用户兑换',
  Bank_num int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '今日新绑定量',
  Pay_num int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '今日新充值人数',
  Pay_zon_num int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '今日新老用户充值数',
  Pay_money int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '今日新充值金额',
  Pay_zon_money int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '今日新老用户充值金额',
  tax int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '今日游戏新玩家实际税收',
  tax_zon int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '今日游戏新老玩家实际税收',
  CommissionRate int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '当日提成率',
  profit int(10) NOT NULL DEFAULT '0.00' COMMENT '预计支付',
  Pay_ck tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否支付',
  Cheat tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否作弊',
   PRIMARY KEY (tid),
   KEY guid (guid),
   KEY times (times)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '玩家报表';