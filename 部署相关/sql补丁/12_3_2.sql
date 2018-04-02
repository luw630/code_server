use account;
DROP TABLE IF EXISTS `t_channel_account`;
CREATE TABLE `t_channel_account` (
  `uid` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` varchar(60) NOT NULL DEFAULT '' COMMENT '渠道帐号',
  `password` varchar(100) NOT NULL DEFAULT '' COMMENT '渠道密码',
  `Payment` varchar(50) NOT NULL DEFAULT '' COMMENT '备注',
  `chargeType` tinyint(1) NOT NULL DEFAULT '0' COMMENT '计费类型 1 安装计费 2 提成',
  `price` double(9,2) NOT NULL DEFAULT '0.00' COMMENT '安装出量则用单价计费',
  `CommissionRate` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '提成率',
  `email` varchar(100) NOT NULL DEFAULT '' COMMENT '邮箱',
  `Grade` tinyint(4) NOT NULL DEFAULT '0' COMMENT '等级',
  `status` tinyint(4) NOT NULL DEFAULT '1' COMMENT '1正常 0 停封',
  `father_id` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '父ID',
  `login_times` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '登陆时间',
  `Rate` tinyint(4) NOT NULL DEFAULT '0' COMMENT '出量百分率 80 表示 80%出量率',
  `old_status` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否新渠道',
  `Must` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '前多少安装百分百出量',
  `qq` bigint(20) NOT NULL DEFAULT '0' COMMENT '联系QQ',
  `phone` bigint(20) NOT NULL COMMENT '联系电话',
  `name` varchar(50) NOT NULL COMMENT '姓名',
  `BankMsg` varchar(100) NOT NULL COMMENT '支付信息',
  `BankAccount` varchar(200) NOT NULL COMMENT '支付账号',
  `down` text NOT NULL,
  PRIMARY KEY (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=2 COMMENT '渠道账户表';

INSERT INTO `t_channel_account` (`uid`, `username`, `password`,`father_id`, `Payment`, `price`, `email`, `Grade`, `status`,  `login_times`, `Rate`, `old_status`, `Must`, `qq`, `phone`, `name`, `BankMsg`, `BankAccount`, `down`) VALUES
(1, 'admin', '5425621d9ce4961a91a42d12004b60ca',0, '', 0.00, '123456@qq.com', 1, 1, 1512099418, 0, 0, 0, 123456, 18888888888, 'admin', '123', '888888', '');

DROP TABLE IF EXISTS `t_default`;
CREATE TABLE IF NOT EXISTS `t_default` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `Rate` tinyint(4) NOT NULL DEFAULT '0' COMMENT '默认出量率',
  `Must` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '默认前几必出',
  `price` double(5,2) NOT NULL DEFAULT '0.00' COMMENT '默认安装单价',
  `CommissionRate` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '默认提成率',
  `cache_times` int(10) unsigned NOT NULL DEFAULT '0',
  `cache_daytimes` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=0 COMMENT '默认配置表' ;


INSERT INTO `t_default` (`id`, `Rate`, `Must`, `price`, `cache_times`, `cache_daytimes`, `CommissionRate`) VALUES
(1, 70, 100, 0.28, 1416300241, 1416300301, 30);

DROP TABLE IF EXISTS `t_channelDetailed_201712`;
CREATE TABLE IF NOT EXISTS `t_channelDetailed_201712` (
  `tid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '渠道ID',
  `pid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '渠道父ID',
  `imei` varchar(256) NOT NULL DEFAULT '' COMMENT '手机唯一硬件码',
  `guid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `phone` varchar(50) NOT NULL DEFAULT '' COMMENT '手机类型 ios or android',
  `ip` varchar(50) NOT NULL DEFAULT '' COMMENT '用户IP',
  `times` int(10) unsigned NOT NULL DEFAULT '0',
  `times_index` int(10) unsigned NOT NULL DEFAULT '0',
  `Rate` tinyint(4) NOT NULL DEFAULT '0' COMMENT '当前出量率比例',
  `effect` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1 出量 0 扣量',
  PRIMARY KEY (`tid`),
  KEY `guid` (`guid`),KEY `times` (`times`),
  KEY `uid` (`uid`),KEY `pid` (`pid`),
  KEY `times_index` (`times_index`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '渠道安装详细表';

DROP TABLE IF EXISTS `t_channelDetailed_201801`;
CREATE TABLE IF NOT EXISTS `t_channelDetailed_201801`(
  `tid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '渠道ID',
  `pid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '渠道父ID',
  `imei` varchar(256) NOT NULL DEFAULT '' COMMENT '手机唯一硬件码',
  `guid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `phone` varchar(50) NOT NULL DEFAULT '' COMMENT '手机类型 ios or android',
  `ip` varchar(50) NOT NULL DEFAULT '' COMMENT '用户IP',
  `times` int(10) unsigned NOT NULL DEFAULT '0',
  `times_index` int(10) unsigned NOT NULL DEFAULT '0',
  `Rate` tinyint(4) NOT NULL DEFAULT '0' COMMENT '当前出量率比例',
  `effect` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1 出量 0 扣量',
  PRIMARY KEY (`tid`),
  KEY `guid` (`guid`),KEY `times` (`times`),
  KEY `uid` (`uid`),KEY `pid` (`pid`),
  KEY `times_index` (`times_index`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '渠道安装详细表';

DROP TABLE IF EXISTS `t_channelDetailed_201802`;
CREATE TABLE IF NOT EXISTS `t_channelDetailed_201802` (
  `tid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '渠道ID',
  `pid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '渠道父ID',
  `imei` varchar(256) NOT NULL DEFAULT '' COMMENT '手机唯一硬件码',
  `guid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `phone` varchar(50) NOT NULL DEFAULT '' COMMENT '手机类型 ios or android',
  `ip` varchar(50) NOT NULL DEFAULT '' COMMENT '用户IP',
  `times` int(10) unsigned NOT NULL DEFAULT '0',
  `times_index` int(10) unsigned NOT NULL DEFAULT '0',
  `Rate` tinyint(4) NOT NULL DEFAULT '0' COMMENT '当前出量率比例',
  `effect` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1 出量 0 扣量',
  PRIMARY KEY (`tid`),
  KEY `guid` (`guid`),KEY `times` (`times`),
  KEY `uid` (`uid`),KEY `pid` (`pid`),
  KEY `times_index` (`times_index`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '渠道安装详细表';


DROP TABLE IF EXISTS `t_channel_form`;
CREATE TABLE `t_channel_form` (
  `tid` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `uid` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '渠道ID',
  `ck_pid` tinyint(1) NOT NULL DEFAULT '0' COMMENT '渠道等级',
  `father_id` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '代理ID',
  `times` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '日期',
  `register_num` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '注册量',
  `shi_num` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '出量',
  `Bank_num` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '手机绑定量',
  `Pay_num` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '充值人数',
  `Pay_money` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '充值金额',
  `tax` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '游戏税收',
  `CommissionRate` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '提成率',
  `price` double(9,2) NOT NULL DEFAULT '0.00' COMMENT '安装出量则用单价计费',
  `chargeType` tinyint(1) NOT NULL DEFAULT '0' COMMENT '计费类型 1 安装计费 2 提成',
  `Pay_ck` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否支付',
  `Cheat` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否作弊',
   PRIMARY KEY (`tid`),
   KEY `uid` (`uid`),KEY `father_id` (`father_id`),
   KEY `ck_pid` (`ck_pid`),
   KEY `times` (`times`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '渠道报表';

DROP TABLE IF EXISTS `t_channel_total`;
CREATE TABLE `t_channel_total` (
  `tid` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `uid` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '渠道ID',
  `register_num` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '注册量',
  `Bank_num` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '支付帐号绑定量',
  `Pay_num` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '充值人数',
  `Pay_money` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '充值金额',
  `tax` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '游戏税收',
  `CommissionRate` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '提成率',
  `income` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '收入',
  cache_times int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '更新时间',
   PRIMARY KEY (`tid`),
   KEY `uid` (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '渠道总报表';