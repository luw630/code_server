SET FOREIGN_KEY_CHECKS=0;

DROP DATABASE IF EXISTS `account`;
CREATE DATABASE `account` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `account`;


DROP TABLE IF EXISTS `t_player_form`;
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


DROP TABLE IF EXISTS `t_player_total`;
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


DROP TABLE IF EXISTS `t_channel_guid`;
CREATE TABLE t_channel_guid (
  tid int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  uid int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '渠道ID包',
  guid int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '玩家ID包',
  phone tinyint(1) NOT NULL DEFAULT '1' COMMENT '手机类型 2 ios or 1 android',
  times_index int(10) unsigned NOT NULL DEFAULT '0',

   PRIMARY KEY (tid),
   KEY uid (uid),KEY guid (guid),KEY times_index (times_index),KEY phone (phone)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '渠道总推广玩家记录表';


DROP TABLE IF EXISTS `t_channel_payagent`;
CREATE TABLE t_channel_payagent (
  id bigint(20) unsigned NOT NULL AUTO_INCREMENT ,
  uid varchar(64) NOT NULL DEFAULT '' COMMENT '渠道id',
  agent_id int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '代理id',
  orders int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '排序',
  status int(10) UNSIGNED NOT NULL DEFAULT '1' COMMENT '状态',
  PRIMARY KEY (id),
  KEY uid (uid),KEY agent_id (agent_id)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='渠道充值代理列表';





DROP TABLE IF EXISTS `t_channel_account`;
CREATE TABLE `t_channel_account` (
  `uid` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` varchar(60) NOT NULL DEFAULT '' COMMENT '渠道帐号',
  `password` varchar(100) NOT NULL DEFAULT '' COMMENT '渠道密码',
  `Payment` varchar(50) NOT NULL DEFAULT '' COMMENT '备注',
  `chargeType` tinyint(1) NOT NULL DEFAULT '0' COMMENT '计费类型 1 安装计费 2 提成',
  `price` double(9,2) NOT NULL DEFAULT '0.00' COMMENT '安装出量则用单价计费',
  `CommissionRate` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '提成率',
  `tax_display` tinyint(1) NOT NULL DEFAULT "0" ,
  `tax_buckle` int(11) NOT NULL DEFAULT "100" ,
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


DROP TABLE IF EXISTS `t_channelIos_201712`;
CREATE TABLE IF NOT EXISTS `t_channelIos_201712` (
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
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '渠道安装IOS详细表';

DROP TABLE IF EXISTS `t_channelIosIp_201712`;
CREATE TABLE IF NOT EXISTS `t_channelIosIp_201712` (
  `tid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '渠道ID',
  `pid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '渠道父ID',
  `ip` varchar(50) NOT NULL DEFAULT '' COMMENT '用户IP',
  `times` int(10) unsigned NOT NULL DEFAULT '0',
  `times_index` int(10) unsigned NOT NULL DEFAULT '0',
  `ck` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'IP被匹配到修改为1',

  PRIMARY KEY (`tid`),
  KEY `times` (`times`),
  KEY `uid` (`uid`),KEY `pid` (`pid`),KEY `ck` (`ck`),
  KEY `times_index` (`times_index`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '渠道安装IOS_IP详细表';


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
  `tax_shi` double(9,2) NOT NULL DEFAULT '0.00' ,
  `CommissionRate` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '提成率',
  `tax_buckle` int(11) NOT NULL DEFAULT "100",
  `price` double(9,2) NOT NULL DEFAULT '0.00' COMMENT '安装出量则用单价计费',
  `chargeType` tinyint(1) NOT NULL DEFAULT '0' COMMENT '计费类型 1 安装计费 2 提成',
  `Pay_ck` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否支付',
  `Cheat` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否作弊',
   PRIMARY KEY (`tid`),
   KEY `uid` (`uid`),KEY `father_id` (`father_id`),
   KEY `ck_pid` (`ck_pid`),
   KEY `times` (`times`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '渠道报表';


DROP TABLE IF EXISTS `t_channel_anios`;
CREATE TABLE `t_channel_anios` (
  tid int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  uid_one int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '渠道ID包',
  uid_two int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '渠道ID包',

   PRIMARY KEY (tid),
   KEY uid_one (uid_one),KEY uid_two (uid_two)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '安卓IOS关联表';


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
-- ----------------------------
-- Table structure for anti_money_laundering_config
-- ----------------------------
DROP TABLE IF EXISTS `anti_money_laundering_config`;
CREATE TABLE `anti_money_laundering_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `key` varchar(255) DEFAULT NULL,
  `value` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `anti_money_laundering_config_i_b0eafe` (`key`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of anti_money_laundering_config
-- ----------------------------
INSERT INTO `anti_money_laundering_config` VALUES ('1', '当日提现总额', '当日提现超过这个数额则进入异常名单', 'total_cash_withdrawal', '50000', '2017-08-12 14:06:17', '2017-08-12 15:56:45');
INSERT INTO `anti_money_laundering_config` VALUES ('2', '充值后游戏局数', '充值后游戏局数不超过此次数即申请提现，则进入异常名单', 'games_number_after_recharging', '5', '2017-08-12 14:16:03', '2017-08-12 14:16:05');
INSERT INTO `anti_money_laundering_config` VALUES ('3', '提现总充值比例(单位%)', '提现/总充值比例', 'cash_recharge_ratio', '80', '2017-08-12 14:18:39', '2017-08-12 15:56:30');

-- ----------------------------
-- Table structure for `t_account`
-- ----------------------------
DROP TABLE IF EXISTS `t_account`;
CREATE TABLE `t_account` (
  `guid` int(11) NOT NULL AUTO_INCREMENT COMMENT '全局唯一标识符',
  `account` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '账号',
  `password` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '密码',
  `is_guest` int(11) NOT NULL DEFAULT '0' COMMENT '是否是游客 1是游客',
  `nickname` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '昵称',
  `enable_transfer` int(11) NOT NULL DEFAULT '0' COMMENT '1能够转账，0不能给其他玩家转账',
  `bank_password` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '银行密码',
  `vip` int(11) NOT NULL DEFAULT '0' COMMENT 'vip等级',
  `alipay_name` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '加了星号的支付宝姓名',
  `alipay_name_y` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '支付宝姓名',
  `alipay_account` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '加了星号的支付宝账号',
  `alipay_account_y` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '支付宝账号',
  `bang_alipay_time` timestamp NULL DEFAULT NULL COMMENT '支付宝绑时间',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '创建时间',
  `register_time` timestamp NULL DEFAULT NULL COMMENT '注册时间',
  `login_time` timestamp NULL DEFAULT NULL COMMENT '登陆时间',
  `logout_time` timestamp NULL DEFAULT NULL COMMENT '退出时间',
  `online_time` int(11) DEFAULT '0' COMMENT '累计在线时间',
  `login_count` int(11) DEFAULT '1' COMMENT '登录次数',
  `phone` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '手机名字：ios，android',
  `phone_type` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '手机具体型号',
  `version` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '版本号',
  `channel_id` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '渠道号',
  `package_name` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '安装包名字',
  `imei` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '设备唯一码',
  `ip` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '客户端ip',
  `last_login_phone` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '最后登录手机名字：ios，android',
  `last_login_phone_type` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '最后登录手机具体型号',
  `last_login_version` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '最后登录版本号',
  `last_login_channel_id` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '最后登录渠道号',
  `last_login_package_name` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '最后登录安装包名字',
  `last_login_imei` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '最后登录设备唯一码',
  `last_login_ip` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '最后登录IP',
  `change_alipay_num` int(11) DEFAULT '6' COMMENT '允许修改支付宝账号次数',
  `disabled` tinyint(4) DEFAULT '0' COMMENT '0启用  1禁用',
  `risk` tinyint(4) DEFAULT '0' COMMENT '危险等级0-9  9最危险',
  `recharge_count` bigint(20) DEFAULT '0' COMMENT '总充值金额',
  `inviter_guid` int(11) DEFAULT '0' COMMENT '邀请人的id',
  `invite_code` varchar(32) DEFAULT '0' COMMENT '邀请码',
  PRIMARY KEY (`guid`),
  UNIQUE KEY `index_nickname` (`nickname`) USING BTREE,
  UNIQUE KEY `index_account` (`account`) USING BTREE,
  UNIQUE KEY `index_imei` (`imei`) USING BTREE,
  KEY `index_is_guest` (`is_guest`),
  KEY `index_password` (`password`),
  KEY `index_invite_code` (`invite_code`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=25001 DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='账号表';

-- ----------------------------
-- Table structure for `t_channel_invite`
-- ----------------------------
DROP TABLE IF EXISTS `t_channel_invite`;
CREATE TABLE `t_channel_invite` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `channel_id` varchar(255) DEFAULT NULL COMMENT '渠道号',
  `channel_lock` tinyint(3) DEFAULT '0' COMMENT '1开启 0关闭',
  `big_lock` tinyint(3) DEFAULT '1' COMMENT '1开启 0关闭',
  `tax_rate` int(11) unsigned NOT NULL DEFAULT '1' COMMENT '税率 百分比',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of t_channel_invite
-- ----------------------------
INSERT INTO `t_channel_invite` VALUES ('1', 'hehehe', '1', '1', '50');

-- ----------------------------
-- Table structure for `t_guest_id`
-- ----------------------------
DROP TABLE IF EXISTS `t_guest_id`;
CREATE TABLE `t_guest_id` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `id_key` int(11) NOT NULL DEFAULT '0' COMMENT '用于更新',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_id_key` (`id_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci;

-- ----------------------------
-- Table structure for `t_online_account`
-- ----------------------------
DROP TABLE IF EXISTS `t_online_account`;
CREATE TABLE `t_online_account` (
  `guid` int(11) NOT NULL DEFAULT '0' COMMENT '全局唯一标识符',
  `first_game_type` int(11) DEFAULT NULL COMMENT '5斗地主 6炸金花 8百人牛牛',
  `second_game_type` int(11) DEFAULT NULL COMMENT '1新手场 2初级场 3 高级场 4富豪场',
  `game_id` int(11) DEFAULT NULL COMMENT '游戏ID',
  `in_game` int(11) NOT NULL DEFAULT '0' COMMENT '1在玩游戏，0在大厅',
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='在线账号表';

-- ----------------------------
-- Procedure structure for `create_test_account`
-- ----------------------------
DROP PROCEDURE IF EXISTS `create_test_account`;
DELIMITER ;;
CREATE PROCEDURE `create_test_account`()
BEGIN
	DECLARE account_ VARCHAR(64) DEFAULT '0';
	DECLARE i INT DEFAULT 0;
	WHILE i < 3000 DO
		SET i = i + 1;
		SET account_ = CONCAT("test_",i);
		INSERT INTO t_account (account,password,nickname,create_time,phone,phone_type,version,channel_id,package_name,imei,ip) VALUES (account_,MD5("123456"),account_,NOW(),"windows", "windows-test", "1.1", "test", "package-test", account_, "127.0.0.1");
	END WHILE;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `FreezeAccount`
-- ----------------------------
DROP PROCEDURE IF EXISTS `FreezeAccount`;
DELIMITER ;;
CREATE PROCEDURE `FreezeAccount`(IN `guid_` int(11),
								 IN `status_` tinyint(4))
    COMMENT '封号，参数guid_：账号id，status_：设置的状态'
BEGIN
	DECLARE ret INT DEFAULT 0;
	DECLARE guid_t int(11);
	DECLARE status_t tinyint(4);
	
	update account.t_account set disabled = status_ where guid = guid_;
	
	select guid , disabled into guid_t , status_t from account.t_account where guid = guid_;
	
	if guid_t is null then
		set guid_t = -1;
	end if;
	if status_t is null then
		set status_t = -1;
	end if;
	
	if guid_t != guid_ or status_t != status_ then
		set ret = 1;
	else
		set ret = 0;
	end if;
	select ret as retCode , concat(guid_t,'|',status_t) as  retData;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `create_account`
-- ----------------------------
DROP PROCEDURE IF EXISTS `create_account`;
DELIMITER ;;
CREATE PROCEDURE `create_account`(IN `account_` VARCHAR(64), IN `phone_` varchar(256), IN `phone_type_` varchar(256), IN `version_` varchar(256), IN `channel_id_` varchar(256), IN `package_name_` varchar(256), IN `imei_` varchar(256), IN `ip_` varchar(256))
    COMMENT '创建账号'
BEGIN
	DECLARE password_ VARCHAR(32) DEFAULT '0';
	DECLARE nickname_ VARCHAR(32) DEFAULT '0';
	SET password_ = MD5(account_);
	SET nickname_ = CONCAT("玩家", get_guest_id()+25000);

	INSERT INTO t_account (account,password,is_guest,nickname,create_time,phone,phone_type,version,channel_id,package_name,imei,ip) VALUES (account_,password_,0,nickname_,NOW(),phone_,phone_type_,version_,channel_id_,package_name_,imei_,ip_);
	SELECT account_ AS account, password_ AS password, LAST_INSERT_ID() AS guid, nickname_ AS nickname;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `create_guest_account`
-- ----------------------------
DROP PROCEDURE IF EXISTS `create_guest_account`;
DELIMITER ;;
CREATE PROCEDURE `create_guest_account`(IN `phone_` varchar(256), IN `phone_type_` varchar(256), IN `version_` varchar(256), IN `channel_id_` varchar(256), IN `package_name_` varchar(256), IN `imei_` varchar(256), IN `ip_` varchar(256))
    COMMENT '创建游客账号'
BEGIN
	DECLARE guest_id_ BIGINT;

	DECLARE ret INT DEFAULT 0;
	DECLARE guid_ INT DEFAULT 0;
	DECLARE account_ VARCHAR(64) DEFAULT '0';
	DECLARE no_bank_password INT DEFAULT 0;
	DECLARE vip_ INT DEFAULT 0;
	DECLARE login_time_ INT;
	DECLARE logout_time_ INT;
	DECLARE is_guest_ INT DEFAULT 0;
	DECLARE nickname_ VARCHAR(32) DEFAULT '0';
	DECLARE password_ VARCHAR(32) DEFAULT '0';
	DECLARE alipay_account_ VARCHAR(32) DEFAULT '0';
	DECLARE alipay_name_ VARCHAR(32) DEFAULT '0';
	DECLARE change_alipay_num_ INT DEFAULT 0;
	DECLARE disabled_ INT DEFAULT 0;
	DECLARE risk_ INT DEFAULT 0;
	DECLARE enable_transfer_ INT DEFAULT 0;
	DECLARE is_first INT DEFAULT 1;
	DECLARE channel_lock_ INT DEFAULT 0;
	DECLARE exit_flag_ INT DEFAULT 0;

	SELECT guid, account, ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, password, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer INTO guid_, account_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, password_, alipay_account_, alipay_name_, change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_ FROM t_account WHERE imei = imei_;
	IF guid_ = 0 THEN
		SET guid_ = get_guest_id();

		SET account_ = CONCAT("玩家", guid_+25000);
		SELECT guid INTO exit_flag_ FROM t_account WHERE account=account_ or nickname=account_;
		IF exit_flag_ != 0 THEN
			SET account_ = CONCAT(account_, "A");
		END IF;
		
		SET password_ = MD5(account_);
		SET nickname_ = account_;#CONCAT("玩家", guid_+25000);

		SELECT channel_lock INTO channel_lock_ FROM t_channel_invite WHERE channel_id=channel_id_ AND big_lock=1;
		IF channel_lock_ != 1 THEN
			SET is_first = 1;#SET is_first = 2;
		END IF;

		INSERT INTO t_account (account,password,is_guest,nickname,create_time,phone,phone_type,version,channel_id,package_name,imei,ip,invite_code) VALUES (account_,password_,1,nickname_,NOW(),phone_,phone_type_,version_,channel_id_,package_name_,imei_,ip_,HEX(guid_));
		SELECT guid, account, ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, password, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer INTO guid_, account_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, password_, alipay_account_, alipay_name_, change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_ FROM t_account WHERE imei = imei_;
	ELSE
		SET is_first = 2;
		IF disabled_ = 1 THEN
			SET ret = 15;
		ELSE
			UPDATE t_account SET login_count = login_count+1 WHERE guid=guid_;
		END IF;
	END IF;
		
	SELECT is_first,ret, guid_ as guid, account_ as account, no_bank_password, vip_ as vip, IFNULL(login_time_, 0) as login_time, IFNULL(logout_time_, 0) as logout_time, nickname_ as nickname, is_guest_ as is_guest, password_ as password, alipay_account_ as alipay_account, alipay_name_ as alipay_name, change_alipay_num_ as change_alipay_num, risk_ as risk, channel_id_ as channel_id, enable_transfer_ as enable_transfer;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `sms_login`
-- ----------------------------
DROP PROCEDURE IF EXISTS `sms_login`;
DELIMITER ;;
CREATE PROCEDURE `sms_login`(IN `account_` varchar(64))
    COMMENT '验证账号，参数account_：账号，password_：密码'
BEGIN
	DECLARE ret INT DEFAULT 0;
	DECLARE guid_ INT DEFAULT 0;
	DECLARE no_bank_password INT DEFAULT 0;
	DECLARE vip_ INT DEFAULT 0;
	DECLARE login_time_ INT;
	DECLARE logout_time_ INT;
	DECLARE is_guest_ INT DEFAULT 0;
	DECLARE nickname_ VARCHAR(32) DEFAULT '0';
	DECLARE password_ VARCHAR(32) DEFAULT '0';
	DECLARE alipay_account_ VARCHAR(32) DEFAULT '0';
	DECLARE alipay_name_ VARCHAR(32) DEFAULT '0';
	DECLARE change_alipay_num_ INT DEFAULT 0;
	DECLARE disabled_ INT DEFAULT 0;
	DECLARE risk_ INT DEFAULT 0;
	DECLARE channel_id_ VARCHAR(256) DEFAULT '0';
	DECLARE enable_transfer_ INT DEFAULT 0;
	DECLARE invite_code_ VARCHAR(32) DEFAULT '0';
	DECLARE inviter_guid_ INT DEFAULT 0;

	SELECT guid, ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, password, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer,inviter_guid,invite_code INTO guid_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, password_, alipay_account_, alipay_name_, change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_,inviter_guid_,invite_code_ FROM t_account WHERE account = account_;
	IF guid_ = 0 THEN
		SET ret = 3;
	END IF;
	
	IF disabled_ = 1 THEN
		SET ret = 15;
	END IF;
	
	IF ret = 0 THEN
		UPDATE t_account SET login_count = login_count+1 WHERE guid=guid_;
	END IF;
	
	SELECT ret, guid_ as guid, no_bank_password, vip_ as vip, IFNULL(login_time_, 0) as login_time, IFNULL(logout_time_, 0) as logout_time, nickname_ as nickname, is_guest_ as is_guest, password_ as password, alipay_account_ as alipay_account, alipay_name_ as alipay_name, change_alipay_num_ as change_alipay_num, risk_ as risk, channel_id_ as channel_id, enable_transfer_ as enable_transfer, inviter_guid_ as inviter_guid, invite_code_ as invite_code;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `verify_account`
-- ----------------------------
DROP PROCEDURE IF EXISTS `verify_account`;
DELIMITER ;;
CREATE PROCEDURE `verify_account`(IN `account_` varchar(64),IN `password_` varchar(32))
    COMMENT '验证账号，参数account_：账号，password_：密码'
BEGIN
  DECLARE ret INT DEFAULT 0;
  DECLARE guid_ INT DEFAULT 0;
  DECLARE no_bank_password INT DEFAULT 0;
  DECLARE vip_ INT DEFAULT 0;
  DECLARE login_time_ INT;
  DECLARE logout_time_ INT;
  DECLARE is_guest_ INT DEFAULT 0;
  DECLARE nickname_ VARCHAR(32) DEFAULT '0';
  DECLARE alipay_account_ VARCHAR(32) DEFAULT '0';
  DECLARE alipay_name_ VARCHAR(32) DEFAULT '0';
  DECLARE change_alipay_num_ INT DEFAULT 0;
  DECLARE disabled_ INT DEFAULT 0;
  DECLARE risk_ INT DEFAULT 0;
  DECLARE channel_id_ VARCHAR(256) DEFAULT '0';
  DECLARE enable_transfer_ INT DEFAULT 0;
  DECLARE invite_code_ VARCHAR(32) DEFAULT '0';
  DECLARE inviter_guid_ INT DEFAULT 0;
  
  SELECT guid, ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer,inviter_guid,invite_code INTO guid_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, alipay_account_, alipay_name_, change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_,inviter_guid_,invite_code_ FROM t_account WHERE account = account_ AND password = password_;
  IF guid_ = 0 THEN
    SET ret = 27;
    SELECT 3 INTO ret FROM t_account WHERE account = account_ LIMIT 1;
  END IF;

  IF disabled_ = 1 THEN
    SET ret = 15;
  END IF;
  
  IF ret = 0 THEN
    UPDATE t_account SET login_count = login_count+1 WHERE guid=guid_;
  END IF;
  
  SELECT ret, guid_ as guid, no_bank_password, vip_ as vip, IFNULL(login_time_, 0) as login_time, IFNULL(logout_time_, 0) as logout_time, nickname_ as nickname, is_guest_ as is_guest, alipay_account_ as alipay_account, alipay_name_ as alipay_name, change_alipay_num_ as change_alipay_num, risk_ as risk, channel_id_ as channel_id, enable_transfer_ as enable_transfer, inviter_guid_ as inviter_guid, invite_code_ as invite_code;
END
;;
DELIMITER ;

-- ----------------------------
-- Function structure for `get_guest_id`
-- ----------------------------
DROP FUNCTION IF EXISTS `get_guest_id`;
DELIMITER ;;
CREATE FUNCTION `get_guest_id`() RETURNS bigint(20)
BEGIN
	DECLARE ret INT DEFAULT 0;
	REPLACE INTO t_guest_id SET id_key = 0;
	SELECT MAX(guid) INTO ret FROM t_account;
	if ret is null then
		RETURN LAST_INSERT_ID();
	else
		RETURN ret - 25000 + 1;
	end if;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `check_is_Agent`
-- ----------------------------
DROP PROCEDURE IF EXISTS `check_is_agent`;
DELIMITER ;;
CREATE PROCEDURE `check_is_agent`(IN `guid_1` int,IN `guid_2` int)
    COMMENT '查询guid1，guid2 是否为代理商却是否支持转账功能'
label_pro:BEGIN
	DECLARE guidAflg int;
	DECLARE guidBflg int;
	select enable_transfer into guidAflg from t_account where guid = guid_1;
	select enable_transfer into guidBflg from t_account where guid = guid_2;
	if guidAflg is null then
		set guidAflg = 9;
	end if;
	if guidBflg is null then
		set guidBflg = 9;
	end if;
	
	select guidAflg * 10 + guidBflg as retCode;
END
;;
DELIMITER ;

DROP TABLE IF EXISTS `yes_login_time`;
CREATE TABLE `yes_login_time`  (
  `guid` int(11) NULL DEFAULT NULL,
  `login_time` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

DROP DATABASE IF EXISTS `game`;
CREATE DATABASE `game` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `game`;

-- ----------------------------
-- Table structure for `t_bag`
-- ----------------------------
DROP TABLE IF EXISTS `t_bag`;
CREATE TABLE `t_bag` (
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `pb_items` blob COMMENT '所有物品',
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='背包表';

-- ----------------------------
-- Table structure for `t_channel_invite_tax`
-- ----------------------------
DROP TABLE IF EXISTS `t_channel_invite_tax`;
CREATE TABLE `t_channel_invite_tax` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT 'id',
  `guid` int(11) NOT NULL COMMENT 'guid',
  `val` int(11) NOT NULL DEFAULT '0' COMMENT '获得的收益',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for `t_bank_statement`
-- ----------------------------
DROP TABLE IF EXISTS `t_bank_statement`;
CREATE TABLE `t_bank_statement` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '银行流水ID',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `time` timestamp NULL DEFAULT NULL COMMENT '记录时间',
  `opt` int(11) NOT NULL DEFAULT '0' COMMENT '操作类型',
  `target` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '目标',
  `money` int(11) NOT NULL DEFAULT '0' COMMENT '改变的钱',
  `bank_balance` int(11) NOT NULL DEFAULT '0' COMMENT '当前剩余的钱',
  PRIMARY KEY (`id`),
  KEY `index_guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='银行流水表';

DROP TABLE IF EXISTS `t_game_maintain_cfg`;
CREATE TABLE t_game_maintain_cfg (
  id int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  game_id int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '游戏ID',
  first_game_type int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '游戏一级ID',
  second_game_type int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '游戏二级ID',
  open tinyint(1) NOT NULL DEFAULT '1' COMMENT '维护开关 1 正常 or 2 维护',
   PRIMARY KEY (id),
   KEY game_id (game_id),KEY first_game_type (first_game_type),KEY second_game_type (second_game_type)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 COMMENT '维护开关表';
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('1','1','1','1','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('2','3','3','1','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('3','4','3','2','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('4','5','3','3','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('5','6','3','4','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('6','20','5','1','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('7','21','5','2','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('8','22','5','3','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('9','30','6','1','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('10','31','6','2','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('11','32','6','3','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('12','33','6','4','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('13','40','7','1','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('14','41','7','2','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('15','42','7','3','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('16','43','7','4','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('17','50','8','1','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('18','51','8','2','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('19','80','11','1','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('20','81','11','2','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('21','82','11','3','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('22','83','11','4','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('23','110','14','1','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('24','111','14','2','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('25','112','14','3','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('26','113','14','4','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('27','130','16','1','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('28','131','16','2','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('29','132','16','3','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('30','133','16','4','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('31','140','17','1','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('32','141','17','2','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('33','142','17','3','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('34','143','17','4','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('35','150','18','1','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('36','151','18','2','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('37','152','18','3','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('38','153','18','4','1');
insert into t_game_maintain_cfg (id, game_id, first_game_type, second_game_type, open) values('39','2','1','2','1');


-- ----------------------------
-- Table structure for `t_daily_earnings_rank`
-- ----------------------------
DROP TABLE IF EXISTS `t_daily_earnings_rank`;
CREATE TABLE `t_daily_earnings_rank` (
  `rank` int(11) NOT NULL AUTO_INCREMENT COMMENT '排行榜',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `nickname` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '昵称',
  `money` int(11) NOT NULL DEFAULT '0' COMMENT '钱',
  PRIMARY KEY (`rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='日盈利榜表';

-- ----------------------------
-- Table structure for `t_earnings`
-- ----------------------------
DROP TABLE IF EXISTS `t_earnings`;
CREATE TABLE `t_earnings` (
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `daily_earnings` bigint(20) NOT NULL DEFAULT '0' COMMENT '日盈利',
  `weekly_earnings` bigint(20) NOT NULL DEFAULT '0' COMMENT '周盈利',
  `monthly_earnings` bigint(20) NOT NULL DEFAULT '0' COMMENT '月盈利',
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='盈利榜表';

-- ----------------------------
-- Table structure for `t_fortune_rank`
-- ----------------------------
DROP TABLE IF EXISTS `t_fortune_rank`;
CREATE TABLE `t_fortune_rank` (
  `rank` int(11) NOT NULL AUTO_INCREMENT COMMENT '排行榜',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `nickname` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '昵称',
  `money` int(11) NOT NULL DEFAULT '0' COMMENT '钱',
  PRIMARY KEY (`rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='总财富榜表';

-- ----------------------------
-- Table structure for `t_mail`
-- ----------------------------
DROP TABLE IF EXISTS `t_mail`;
CREATE TABLE `t_mail` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '邮件ID',
  `expiration_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '过期时间',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `send_guid` int(11) NOT NULL DEFAULT '0' COMMENT '发件人的全局唯一标识符',
  `send_name` varchar(32) COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '发件人的名字',
  `title` varchar(32) COLLATE utf8_general_ci NOT NULL COMMENT '标题',
  `content` varchar(128) COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '内容',
  `pb_attachment` blob COMMENT '附件',
  PRIMARY KEY (`id`),
  KEY `index_expiration_time_guid` (`expiration_time`,`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='邮件表';

-- ----------------------------
-- Table structure for `t_monthly_earnings_rank`
-- ----------------------------
DROP TABLE IF EXISTS `t_monthly_earnings_rank`;
CREATE TABLE `t_monthly_earnings_rank` (
  `rank` int(11) NOT NULL AUTO_INCREMENT COMMENT '排行榜',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `nickname` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '昵称',
  `money` int(11) NOT NULL DEFAULT '0' COMMENT '钱',
  PRIMARY KEY (`rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='月盈利榜表';

-- ----------------------------
-- Table structure for `t_notice`
-- ----------------------------
DROP TABLE IF EXISTS `t_notice`;
CREATE TABLE `t_notice` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `number` int(11) DEFAULT '0' COMMENT '轮播次数',
  `interval_time` int(11) DEFAULT '0' COMMENT '轮播时间间隔（秒）',
  `type` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '通知类型 1：消息通知 2：公告通知 3跑马灯',
  `send_range` tinyint(1) DEFAULT '0' COMMENT '发送范围 0：全部',
  `name` varchar(1024) COLLATE utf8_general_ci DEFAULT NULL COMMENT '标题',
  `content` text DEFAULT NULL COMMENT '内容',
  `author` varchar(20) COLLATE utf8_general_ci DEFAULT NULL COMMENT '发布者',
  `start_time` timestamp NULL DEFAULT NULL COMMENT '发送时间',
  `end_time` timestamp NULL DEFAULT NULL COMMENT '结束时间',
  `created_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `index_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='通知表';

-- ----------------------------
-- Table structure for `t_notice_private`
-- ----------------------------
DROP TABLE IF EXISTS `t_notice_private`;
CREATE TABLE `t_notice_private` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) DEFAULT NULL COMMENT '用户ID,与account.t_account',
  `account` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '用户账号',
  `nickname` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '用户昵称',
  `type` varchar(20) COLLATE utf8_general_ci DEFAULT NULL COMMENT '通知类型 1：消息通知',
  `name` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '标题',
  `content` text DEFAULT NULL COMMENT '内容',
  `author` varchar(20) COLLATE utf8_general_ci DEFAULT NULL COMMENT '发布者',
  `start_time` timestamp NULL DEFAULT NULL COMMENT '开始时间',
  `end_time` timestamp NULL DEFAULT NULL COMMENT '结束时间',
  `created_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `is_read` tinyint(1) DEFAULT '0' COMMENT '是否阅读 1:已读 0:未读',
  PRIMARY KEY (`id`),
  KEY `index_name` (`name`),
  KEY `index_guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='私信通知表';

-- ----------------------------
-- Table structure for `t_notice_read`
-- ----------------------------
DROP TABLE IF EXISTS `t_notice_read`;
CREATE TABLE `t_notice_read` (
  `guid` int(11) NOT NULL COMMENT '用户ID,与account.t_account',
  `n_id` int(11) NOT NULL COMMENT '通知ID',
  `is_read` tinyint(1) DEFAULT '1' COMMENT '是否阅读 1：已读， 0：未读',
  `read_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '阅读时间',
  PRIMARY KEY (`guid`,`n_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='通知阅读明细表';

-- ----------------------------
-- Table structure for `t_ox_player_info`
-- ----------------------------
DROP TABLE IF EXISTS `t_ox_player_info`;
CREATE TABLE `t_ox_player_info` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '全局唯一标识符',
  `guid` int(11) NOT NULL COMMENT '用户ID',
  `is_android` int(11) NOT NULL COMMENT '是否机器人',
  `table_id` int(11) NOT NULL COMMENT '桌子ID',
  `banker_id` int(11) NOT NULL COMMENT '庄家ID',
  `nickname` varchar(64) COLLATE utf8_general_ci NOT NULL COMMENT '昵称',
  `money` bigint(20) NOT NULL COMMENT '金币数',
  `win_money` bigint(20) NOT NULL COMMENT '该局输赢',
  `bet_money` int(11) NOT NULL COMMENT '玩家下注金币',
  `tax` int(11) NOT NULL COMMENT '玩家台费',
  `curtime` int(11) NOT NULL COMMENT '当前时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='百人牛牛收益表';

-- ----------------------------
-- Table structure for `t_many_ox_server_config`
-- ----------------------------
DROP TABLE IF EXISTS `t_many_ox_server_config`;
CREATE TABLE `t_many_ox_server_config` (
  `id` int(11) NOT NULL,
  `FreeTime` int(11) NOT NULL COMMENT '空闲时间',
  `BetTime` int(11) NOT NULL COMMENT '下注时间',
  `EndTime` int(11) NOT NULL COMMENT '结束时间',
  `MustWinCoeff` int(11) NOT NULL COMMENT '系统必赢系数',
  `BankerMoneyLimit` int(11) NOT NULL COMMENT '上庄条件限制',
  `SystemBankerSwitch` int(11) NOT NULL COMMENT '系统当庄开关',
  `BankerCount` int(11) NOT NULL COMMENT '连庄次数',
  `RobotBankerInitUid` int(11) NOT NULL COMMENT '系统庄家初始UID',
  `RobotBankerInitMoney` bigint(20) NOT NULL COMMENT '系统庄家初始金币',
  `BetRobotSwitch` int(11) NOT NULL COMMENT '下注机器人开关',
  `BetRobotInitUid` int(11) NOT NULL COMMENT '下注机器人初始UID',
  `BetRobotInitMoney` bigint(20) NOT NULL COMMENT '下注机器人初始金币',
  `BetRobotNumControl` int(11) NOT NULL COMMENT '下注机器人个数限制',
  `BetRobotTimesControl` int(11) NOT NULL COMMENT '机器人下注次数限制',
  `RobotBetMoneyControl` int(11) NOT NULL COMMENT '机器人下注金币限制',
  `BasicChip` varchar(64) COLLATE utf8_general_ci NOT NULL COMMENT '筹码信息',
  `ExtendA` int(11) NOT NULL COMMENT '预留字段A',
  `ExtendB` int(11) NOT NULL COMMENT '预留字段B',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='百人牛牛基础配置表';
INSERT INTO t_many_ox_server_config VALUES(1,3,18,15,30,1000000,1,5,100000,10000000,1,200000,35000,5,10,10000,'10,100,500,1000,5000',0,0); 

-- ----------------------------
-- Table structure for `t_player`
-- ----------------------------
DROP TABLE IF EXISTS `t_robot_cfg`;
CREATE TABLE `t_robot_cfg` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'id',
  `game_id` int(10) unsigned NOT NULL COMMENT '游戏id',
  `use_robot` tinyint(3) unsigned NOT NULL COMMENT '0关闭 1打开',
  `storage` bigint(20) NOT NULL COMMENT '库存',
  `robot_level` int(10) NOT NULL COMMENT '智能等级',
  `storage_before`  bigint(20) DEFAULT NULL ,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO `t_robot_cfg` VALUES ('1', '1', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('2', '20', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('3', '21', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('4', '22', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('6', '30','1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('7', '31', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('8', '32', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('9', '33', '1', '0', '0', null);

INSERT INTO `t_robot_cfg` VALUES ('10', '40','1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('11', '41', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('12', '42', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('13', '43', '1', '0', '0', null);


INSERT INTO `t_robot_cfg` VALUES ('14', '80', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('15', '81', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('16', '82', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('17', '83', '1', '0', '0', null);

INSERT INTO `t_robot_cfg` VALUES ('18', '130', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('19', '131', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('20', '132', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('21', '133', '1', '0', '0', null);

INSERT INTO `t_robot_cfg` VALUES ('22', '140', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('23', '141', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('24', '142', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('25', '143', '1', '0', '0', null);

INSERT INTO `t_robot_cfg` VALUES ('26', '150', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('27', '151', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('28', '152', '1', '0', '0', null);
INSERT INTO `t_robot_cfg` VALUES ('29', '153', '1', '0', '0', null);

-- ----------------------------
-- Table structure for t_game_blacklist
-- ----------------------------
DROP TABLE IF EXISTS `t_game_blacklist`;
CREATE TABLE `t_game_blacklist` (
  `id` BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '黑名单ID',
  `guid` INT(11) NOT NULL COMMENT '全局唯一标识符',
  `game_name` VARCHAR(64) NOT NULL DEFAULT 'all' COMMENT '游戏类型为游戏名字(all为所有游戏)',
  `revenue` BIGINT(20) NOT NULL DEFAULT '0' COMMENT '进入黑名单前总营收',
  `create_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `index_guid` (`guid`)
) ENGINE=INNODB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COMMENT='游戏黑名单表';

-- ----------------------------
-- Records of t_game_blacklist
-- ----------------------------

-- ----------------------------
-- Table structure for t_account
-- ----------------------------
DROP TABLE IF EXISTS `t_game_white`;
CREATE TABLE `t_game_white` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '白名单ID',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `game_name` varchar(64) NOT NULL DEFAULT 'all' COMMENT '游戏名字(all为所有游戏)',
  PRIMARY KEY (`id`),
  KEY `index_guid` (`guid`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COMMENT='游戏白名单表';

-- ----------------------------
-- Records of t_game_white
-- ----------------------------

-- ----------------------------
-- Table structure for `t_game_tax_total`
-- ----------------------------
DROP TABLE IF EXISTS `t_game_tax_total`;
CREATE TABLE `t_game_tax_total` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `game_id` int(11) unsigned NOT NULL COMMENT '游戏id',
  `first_game_type` int(11) unsigned NOT NULL,
  `second_game_type` int(11) unsigned NOT NULL,
  `total_tax` bigint(20) NOT NULL COMMENT '总共的税收',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for `t_brnn_chi_cfg`
-- ----------------------------
DROP TABLE IF EXISTS `t_brnn_chi_cfg`;
CREATE TABLE `t_brnn_chi_cfg` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `game_id` int(11) unsigned NOT NULL COMMENT '游戏id',
  `begin_range` int(11) NOT NULL COMMENT '开始区间',
  `end_range` int(11) NOT NULL COMMENT '结束区间',
  `range_prob` int(11) NOT NULL COMMENT '概率',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

insert into t_brnn_chi_cfg(game_id, begin_range, end_range, range_prob) value('50','0','500000','5');
insert into t_brnn_chi_cfg(game_id, begin_range, end_range, range_prob) value('50','500000','1000000','3');
insert into t_brnn_chi_cfg(game_id, begin_range, end_range, range_prob) value('51','0','500000','5');
insert into t_brnn_chi_cfg(game_id, begin_range, end_range, range_prob) value('51','500000','1000000','3');


-- ----------------------------
-- Table structure for `t_player`
-- ----------------------------
DROP TABLE IF EXISTS `t_player`;
CREATE TABLE `t_player` (
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `is_android` int(11) NOT NULL DEFAULT '0' COMMENT '是机器人',
  `account` varchar(64) COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '账号',
  `nickname` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '昵称',
  `level` int(11) NOT NULL DEFAULT '0' COMMENT '玩家等级',
  `money` bigint(20) NOT NULL DEFAULT '0' COMMENT '有多少钱',
  `bank` bigint(20) NOT NULL DEFAULT '0' COMMENT '银行存款',
  `login_award_day` int(11) NOT NULL DEFAULT '1' COMMENT '登录奖励，该领取那一天',
  `login_award_receive_day` int(11) NOT NULL DEFAULT '0' COMMENT '登录奖励，最近领取在那一天',
  `online_award_time` int(11) NOT NULL DEFAULT '0' COMMENT '在线奖励，今天已经在线时间',
  `online_award_num` int(11) NOT NULL DEFAULT '0' COMMENT '在线奖励，该领取哪个奖励',
  `relief_payment_count` int(11) NOT NULL DEFAULT '0' COMMENT '救济金，今天领取次数',
  `header_icon` int(11) NOT NULL DEFAULT '0' COMMENT '头像',
  `slotma_addition` int(11) NOT NULL DEFAULT '0' COMMENT '老虎机中奖权重',
  `recharge_total` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '累计充值',
  `cash_total` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '累计提现',
  `bet_total` bigint(20) NOT NULL DEFAULT '0' COMMENT '累计下注',
  `last_recharge_game_total` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '上次充值后的游戏局数',
  `newplayer_reward` int(11) NOT NULL DEFAULT '1' COMMENT '新玩家奖励',
  PRIMARY KEY (`guid`),
  UNIQUE KEY `index_account` (`account`),
  KEY `index_is_android` (`is_android`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='玩家表';

-- ----------------------------
-- Table structure for `t_player_bank_info`
-- ----------------------------
DROP TABLE IF EXISTS `t_player_bank_info`;
CREATE TABLE `t_player_bank_info` (
  `guid` int(11) unsigned NOT NULL,
  `account` varchar(64) NOT NULL,
  `card_num` varchar(64) NOT NULL,
  `user_name` varchar(64) NOT NULL,
  `bank_name` varchar(64) DEFAULT '',
  `bank_addr` varchar(256) DEFAULT '',
  `bank_code` varchar(64) NOT NULL,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for `t_private_room`
-- ----------------------------
DROP TABLE IF EXISTS `t_private_room`;
CREATE TABLE `t_private_room` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  `room_id` int(11) NOT NULL COMMENT '房间号',
  `owner_guid` int(11) NOT NULL COMMENT '房主号',
  `player_guid` text COLLATE utf8_general_ci COMMENT '桌子上所有玩家guid，以逗号隔开',
  `first_game_type` int(11) NOT NULL COMMENT '一级菜单',
  `chair_max` int(11) NOT NULL COMMENT '人数上限',
  `chair_count` int(11) NOT NULL COMMENT '参与人数',
  `cell_money` int(11) NOT NULL COMMENT '底注',
  `room_cost` int(11) NOT NULL COMMENT '房费',
  `money_limit` int(11) NOT NULL COMMENT '入场限制',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `finish_time` timestamp NULL DEFAULT NULL COMMENT '结束时间',
  `room_state` int(11) NOT NULL COMMENT '房间状态 1 创建 2 游戏中 10 结束 11 取消',
  PRIMARY KEY (`id`),
  KEY `index_room_id` (`room_id`),
  KEY `index_room_state` (`room_state`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='私人房间表';

-- ----------------------------
-- Table structure for `t_rank_update_time`
-- ----------------------------
DROP TABLE IF EXISTS `t_rank_update_time`;
CREATE TABLE `t_rank_update_time` (
  `rank_type` int(11) NOT NULL COMMENT '排行榜类型',
  `update_time` timestamp NULL DEFAULT NULL COMMENT '上次更新时间',
  PRIMARY KEY (`rank_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='排行榜更新时间表';

-- ----------------------------
-- Table structure for `t_weekly_earnings_rank`
-- ----------------------------
DROP TABLE IF EXISTS `t_weekly_earnings_rank`;
CREATE TABLE `t_weekly_earnings_rank` (
  `rank` int(11) NOT NULL AUTO_INCREMENT COMMENT '排行榜',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `nickname` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '昵称',
  `money` int(11) NOT NULL DEFAULT '0' COMMENT '钱',
  PRIMARY KEY (`rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='周盈利榜表';


DROP TABLE IF EXISTS `t_game_black_ip`;
CREATE TABLE t_game_black_ip (
  id bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '黑名单ID',
  ip varchar(64) NOT NULL DEFAULT '' COMMENT 'ip',
  gameid int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '游戏ID',
  game_name varchar(64) NOT NULL DEFAULT '' COMMENT '游戏类型为游戏名字(all为所有游戏)',

  PRIMARY KEY (id),
  KEY ip (ip),KEY gameid (gameid),KEY game_name (game_name)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='游戏IP黑名单表,根据IP拉黑让玩家拿不到大牌';



-- ----------------------------
-- Procedure structure for `update_game_total_tax`
-- ----------------------------
DROP PROCEDURE IF EXISTS `update_game_total_tax`;
DELIMITER ;;
CREATE PROCEDURE `update_game_total_tax`(IN `game_id_` int, IN `first_game_type_` int, IN `second_game_type_` int, IN `tax_add_` int)
BEGIN
	DECLARE game_id_select_ INT DEFAULT 0;

	SELECT game_id INTO game_id_select_ FROM t_game_tax_total WHERE game_id = game_id_;
	IF game_id_select_ = 0 THEN
		INSERT INTO t_game_tax_total (game_id,first_game_type,second_game_type,total_tax) VALUES (game_id_,first_game_type_,second_game_type_,0);
	END IF;
	UPDATE t_game_tax_total	SET total_tax = total_tax + tax_add_ WHERE game_id = game_id_;
END
;;
DELIMITER ;
-- ----------------------------
-- Procedure structure for `get_robot_cfg`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_robot_cfg`;
DELIMITER ;;
CREATE PROCEDURE `get_robot_cfg`(IN `game_id_select_` int)
    COMMENT '获取机器人配置'
BEGIN
	DECLARE game_id_ INT DEFAULT 0;
	DECLARE use_robot_ INT DEFAULT 0;
	DECLARE storage_ BIGINT DEFAULT 0;
	DECLARE robot_level_ INT DEFAULT 0;

	SELECT game_id,use_robot,storage,robot_level INTO game_id_, use_robot_, storage_, robot_level_ FROM t_robot_cfg WHERE game_id = game_id_select_;
	IF game_id_ = 0 THEN
		SET game_id_ = game_id_select_;
		SET use_robot_ = 1;
		SET storage_ = 0;
		SET robot_level_ = 0;

		INSERT INTO t_robot_cfg (game_id,use_robot,storage,robot_level) VALUES (game_id_,use_robot_,storage_,robot_level_);
	END IF;
		
	SELECT game_id_ as game_id,use_robot_ as use_robot,storage_ as storage,robot_level_ as robot_level;
END
;;
DELIMITER ;
-- ----------------------------
-- Procedure structure for `bank_transfer`
-- ----------------------------
DROP PROCEDURE IF EXISTS `bank_transfer`;
DELIMITER ;;
CREATE PROCEDURE `bank_transfer`(IN `guid_` int,IN `time_` int,IN `target_` varchar(64),IN `money_` int,IN `bank_balance_` int)
    COMMENT '银行转账，参数guid_：转账guid，time_：时间，target_：收款guid，money_：转多少钱，bank_balance_：剩下多少'
BEGIN
	DECLARE target_guid_ INT DEFAULT 0;
	DECLARE target_bank_ INT DEFAULT 0;

	UPDATE t_player SET bank = bank + money_ WHERE account = target_;
	IF ROW_COUNT() = 0 THEN
		SELECT 1 as ret, 0 as id;
	ELSE
		SELECT guid, bank INTO target_guid_, target_bank_ FROM t_player WHERE account = target_;
		#INSERT INTO t_bank_statement (guid,bank_balance,time,opt,target,money) VALUES(target_guid_,target_bank_,FROM_UNIXTIME(time_),3,(SELECT account FROM t_player WHERE guid = guid_),money_);
		#INSERT INTO t_bank_statement (guid,time,opt,target,money,bank_balance) VALUES(guid_,FROM_UNIXTIME(time_),2,target_,money_,bank_balance_);
		SELECT 0 as ret, LAST_INSERT_ID() as id;
	END IF;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `del_msg`
-- ----------------------------
DROP PROCEDURE IF EXISTS `del_msg`;
DELIMITER ;;
CREATE PROCEDURE `del_msg`(IN `ID_` int,
 IN `TYPE_` int)
    COMMENT 'ID_ 消息ID,TYPE_ 消息类型'
BEGIN
  DECLARE guid_ INT DEFAULT 0;
    IF TYPE_ = 1 THEN -- 消息
        select guid into guid_ from t_notice_private where id = ID_;
        delete from t_notice_private where id = ID_;
        IF ROW_COUNT() > 0 then
            select 0 as ret, guid_ as guid ;
        ELSE
            select 1 as ret, 1 as guid ;
        END IF;
    ELSEIF TYPE_ = 2 or TYPE_ = 3 THEN -- 公告及跑马灯
        delete from t_notice where id = ID_;
        IF ROW_COUNT() > 0 then
            delete from t_notice_read where n_id = ID_;
            select 0 as ret, 1 as guid;
        ELSE
            select 1 as ret, 1 as guid;
        END IF;
    END IF;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `get_daily_earnings_rank`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_daily_earnings_rank`;
DELIMITER ;;
CREATE PROCEDURE `get_daily_earnings_rank`()
    COMMENT '得到日盈利榜'
BEGIN
	DECLARE last_time_ TIMESTAMP DEFAULT 0;
	SELECT update_time INTO last_time_ FROM t_rank_update_time WHERE rank_type = 2;
	IF last_time_ = 0 OR TO_DAYS(NOW()) != TO_DAYS(last_time_) THEN
		TRUNCATE TABLE t_daily_earnings_rank;
		INSERT INTO t_daily_earnings_rank (guid, nickname, money) SELECT t_earnings.guid, t_player.nickname, t_earnings.daily_earnings FROM t_earnings, t_player WHERE t_earnings.daily_earnings > 0 AND t_earnings.guid = t_player.guid ORDER BY t_earnings.daily_earnings DESC LIMIT 50;
		REPLACE INTO t_rank_update_time SET rank_type = 2, update_time = NOW();
		UPDATE t_earnings SET daily_earnings = 0;
	END IF;
	SELECT * FROM t_daily_earnings_rank;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `get_fortune_rank`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_fortune_rank`;
DELIMITER ;;
CREATE PROCEDURE `get_fortune_rank`()
    COMMENT '总财富榜'
BEGIN
	DECLARE last_time_ TIMESTAMP DEFAULT 0;
	SELECT update_time INTO last_time_ FROM t_rank_update_time WHERE rank_type = 1;
	IF last_time_ = 0 OR TO_DAYS(NOW()) != TO_DAYS(last_time_) THEN
		TRUNCATE TABLE t_fortune_rank;
		INSERT INTO t_fortune_rank (guid, nickname, money) SELECT guid, nickname, money+bank FROM t_player WHERE money+bank > 0 ORDER BY money+bank DESC LIMIT 50;
		REPLACE INTO t_rank_update_time SET rank_type = 1, update_time = NOW();
	END IF;
	SELECT * FROM t_fortune_rank;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `get_monthly_earnings_rank`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_monthly_earnings_rank`;
DELIMITER ;;
CREATE PROCEDURE `get_monthly_earnings_rank`()
    COMMENT '得到月盈利榜'
BEGIN
	DECLARE last_time_ TIMESTAMP DEFAULT 0;
	SELECT update_time INTO last_time_ FROM t_rank_update_time WHERE rank_type = 4;
	IF last_time_ = 0 OR EXTRACT(YEAR_MONTH FROM NOW()) != EXTRACT(YEAR_MONTH FROM last_time_) THEN
		TRUNCATE TABLE t_monthly_earnings_rank;
		INSERT INTO t_monthly_earnings_rank (guid, nickname, money) SELECT t_earnings.guid, t_player.nickname, t_earnings.monthly_earnings FROM t_earnings, t_player WHERE t_earnings.monthly_earnings > 0 AND t_earnings.guid = t_player.guid ORDER BY t_earnings.monthly_earnings DESC LIMIT 50;
		REPLACE INTO t_rank_update_time SET rank_type = 4, update_time = NOW();
		UPDATE t_earnings SET monthly_earnings = 0;
	END IF;
	SELECT * FROM t_monthly_earnings_rank;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `get_player_data`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_player_data`;
DELIMITER ;;
CREATE PROCEDURE `get_player_data`(IN `guid_` int,IN `account_` varchar(64),IN `nick_` varchar(64),IN `money_` int)
BEGIN
	DECLARE guid_tmp INTEGER DEFAULT 0; 
	DECLARE t_error INTEGER DEFAULT 0; 
	DECLARE done INT DEFAULT 0; 
	DECLARE suc INT DEFAULT 1; 
	DECLARE tmp_val INTEGER DEFAULT 0; 
	DECLARE tmp_total INTEGER DEFAULT 0;
	DECLARE updateNum INT DEFAULT 1;
	DECLARE deleteNum INT DEFAULT 0;
	DECLARE selectNum INT DEFAULT 0;

	DECLARE mycur CURSOR FOR SELECT `val` FROM t_channel_invite_tax WHERE guid=guid_;#定义光标 
	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET t_error=1;  
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
					

	SELECT guid INTO guid_tmp FROM t_player WHERE guid=guid_;
	IF guid_tmp = 0 THEN
		REPLACE INTO t_player SET guid=guid_,account=account_,nickname=nick_,money=money_;
	ELSE
			#START TRANSACTION; #打开光标  
			#OPEN mycur; #开始循环 
			#REPEAT 
			#		FETCH mycur INTO tmp_val;
			#		 IF NOT done THEN
			#				SET selectNum = selectNum+1;
			#				SET tmp_total = tmp_total + tmp_val;
			#				IF t_error = 1 THEN 
			#					SET suc = 0;
			#				END IF;  
			#		 END IF; 
			#UNTIL done END REPEAT;
			#CLOSE mycur;


			#IF tmp_total > 0 THEN
			#	UPDATE t_player SET money=money+(tmp_total) WHERE guid=guid_;
			#	SET updateNum = row_count();
			#END IF;

			#DELETE FROM t_channel_invite_tax WHERE guid=guid_;
			#SET deleteNum = row_count();

			
			#IF suc = 0 OR updateNum < 1 OR deleteNum != selectNum THEN
			#		ROLLBACK;
			#ELSE
			#		COMMIT; 
			#END IF;
			SET suc = 1;
	END IF;
	SELECT level, money, bank, login_award_day, login_award_receive_day, online_award_time, online_award_num, relief_payment_count, header_icon, slotma_addition ,newplayer_reward FROM t_player WHERE guid=guid_;
	
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `get_player_invite_reward`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_player_invite_reward`;
DELIMITER ;;
CREATE PROCEDURE `get_player_invite_reward`(IN `guid_` int)
BEGIN
	DECLARE t_error INTEGER DEFAULT 0; 
	DECLARE done INT DEFAULT 0; 
	DECLARE suc INT DEFAULT 1; 
	DECLARE tmp_val INTEGER DEFAULT 0; 
	DECLARE tmp_total INTEGER DEFAULT 0;
	DECLARE deleteNum INT DEFAULT 0;
	DECLARE selectNum INT DEFAULT 0;

	DECLARE mycur CURSOR FOR SELECT `val` FROM t_channel_invite_tax WHERE guid=guid_;#定义光标 
	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET t_error=1;  
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
					
	START TRANSACTION; #打开光标  
	OPEN mycur; #开始循环 
	REPEAT 
		FETCH mycur INTO tmp_val;
	  IF NOT done THEN
					SET selectNum = selectNum+1;
					SET tmp_total = tmp_total + tmp_val;
					IF t_error = 1 THEN 
						SET suc = 0;
					END IF;  
			 END IF; 
	UNTIL done END REPEAT;
	CLOSE mycur;


	DELETE FROM t_channel_invite_tax WHERE guid=guid_;
	SET deleteNum = row_count();

	IF suc = 0 OR deleteNum != selectNum THEN
		ROLLBACK;
	ELSE
		COMMIT; 
	END IF;

	SELECT tmp_total as total_reward;
	
END
;;
DELIMITER ;


-- ----------------------------
-- Procedure structure for `get_weekly_earnings_rank`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_weekly_earnings_rank`;
DELIMITER ;;
CREATE PROCEDURE `get_weekly_earnings_rank`()
    COMMENT '得到周盈利榜'
BEGIN
	DECLARE last_time_ TIMESTAMP DEFAULT 0;
	SELECT update_time INTO last_time_ FROM t_rank_update_time WHERE rank_type = 3;
	IF last_time_ = 0 OR YEARWEEK(NOW()) != YEARWEEK(last_time_) THEN
		TRUNCATE TABLE t_weekly_earnings_rank;
		INSERT INTO t_weekly_earnings_rank (guid, nickname, money) SELECT t_earnings.guid, t_player.nickname, t_earnings.weekly_earnings FROM t_earnings, t_player WHERE t_earnings.weekly_earnings > 0 AND t_earnings.guid = t_player.guid ORDER BY t_earnings.weekly_earnings DESC LIMIT 50;
		REPLACE INTO t_rank_update_time SET rank_type = 3, update_time = NOW();
		UPDATE t_earnings SET weekly_earnings = 0;
	END IF;
	SELECT * FROM t_weekly_earnings_rank;
END
;;
DELIMITER ;



-- ----------------------------
-- Procedure structure for `save_bank_statement`
-- ----------------------------
DROP PROCEDURE IF EXISTS `save_bank_statement`;
DELIMITER ;;
CREATE PROCEDURE `save_bank_statement`(IN `guid_` int,IN `time_` int,IN `opt_` int,IN `target_` varchar(64),IN `money_` int,IN `bank_balance_` int)
    COMMENT '保存银行流水，参数guid_：操作guid，time_：时间，opt_：操作类型，target_：目标guid，money_：操作多少钱，bank_balance_：剩下多少'
BEGIN
	INSERT INTO t_bank_statement (guid,time,opt,target,money,bank_balance) VALUES(guid_,FROM_UNIXTIME(time_),opt_,target_,money_,bank_balance_);
	SELECT LAST_INSERT_ID() as id;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `send_mail`
-- ----------------------------
DROP PROCEDURE IF EXISTS `send_mail`;
DELIMITER ;;
CREATE PROCEDURE `send_mail`(IN `expiration_time_` int,IN `guid_` int,IN `send_guid_` int,IN `send_name_` varchar(32),IN `title_` varchar(32),IN `content_` varchar(128),IN `attachment_` blob)
    COMMENT '发送邮件，参数expiration_time_：过期时间，guid_：收件guid，send_guid_：发件guid，send_name_：发件名字，title_：标题，content_：内容， attachment_：附件'
BEGIN
	IF NOT EXISTS(SELECT 1 FROM t_player WHERE guid = guid_) THEN
		SELECT 1 as ret, 0 as id;
	ELSE
		INSERT INTO t_mail (expiration_time, guid, send_guid, send_name, title, content, attachment) VALUES (FROM_UNIXTIME(expiration_time_), guid_, send_guid_, send_name_, title_, content_, attachment_);
		SELECT 0 as ret, LAST_INSERT_ID() as id;
	END IF;
END
;;
DELIMITER ;


-- ----------------------------
-- Procedure structure for `change_player_bank_money`
-- ----------------------------
DROP PROCEDURE IF EXISTS `change_player_bank_money`;
DELIMITER ;;
CREATE PROCEDURE `change_player_bank_money`(IN `guid_` int,IN `money_` bigint(20))
    COMMENT '银行转账，参数guid_：转账guid，money_：金钱'
label_pro:BEGIN
	DECLARE oldbank bigint(20);
	select bank into oldbank from t_player where guid = guid_;
	if oldbank is not null then
		if money_ < 0 then
			if oldbank + money_ < 0 then
				select 2 as ret;
				leave label_pro;
			end if;
		end if;
		update t_player set bank = bank + money_ where guid = guid_;
		IF ROW_COUNT() = 0 THEN
			select 5 as ret;
		else
			select 0 as ret, oldbank , (oldbank + money_) as newbank;
		END IF;
	else
		select 4 as ret;
		leave label_pro;
	end if;
END
;;
DELIMITER ;

DROP DATABASE IF EXISTS `config`;
CREATE DATABASE `config` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `config`;

DROP TABLE IF EXISTS `t_game_server_cfg`;
CREATE TABLE `t_game_server_cfg` (
  `game_id` int(11) NOT NULL COMMENT '游戏ID',
  `game_name` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '游戏名字',
  `is_start` int(11) NOT NULL DEFAULT '0' COMMENT '1启动服务器，0已经关闭',
  `is_open` int(11) NOT NULL COMMENT '是否开启该游戏配置',
  `ip` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT 'ip',
  `port` int(11) NOT NULL COMMENT '端口',
  `using_login_validatebox` int(11) NOT NULL COMMENT '是否开启登陆验证框',
  `default_lobby` int(11) NOT NULL COMMENT '是否拥有默认大厅',
  `first_game_type` int(11) NOT NULL DEFAULT '0' COMMENT '一级菜单：1大厅，3捕鱼，5斗地主，6扎金花，7梭哈，8百人牛牛，11德州扑克，12老虎机，13二人麻将，14抢庄牛牛',
  `second_game_type` int(11) NOT NULL DEFAULT '0' COMMENT '二级菜单：斗地主（1新手场2初级场3高级场4富豪场）,扎金花（1乞丐场2平民场3中端场4富豪场5贵宾场）,百人牛牛（1高倍场,2低倍场）,老虎机(1练习场,3发财场,4爆机场)',
  `player_limit` int(11) NOT NULL COMMENT '人数限制',
  `table_count` int(11) NOT NULL DEFAULT '0' COMMENT '多少桌子',
  `money_limit` int(11) NOT NULL DEFAULT '0' COMMENT '进入房间钱限制',
  `cell_money` int(11) NOT NULL DEFAULT '0' COMMENT '底注',
  `tax_open` int(11) NOT NULL DEFAULT '1' COMMENT '是否开启税收',
  `tax_show` int(11) NOT NULL DEFAULT '1' COMMENT '客户端是否显示税收',
  `tax` int(11) NOT NULL DEFAULT '0' COMMENT '多少税',
  `room_lua_cfg` text COMMENT '房间lua配置',
  `room_list` text COMMENT '是否开启该游戏配置',
  PRIMARY KEY (`game_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci ;

INSERT INTO `t_game_server_cfg` VALUES ('1', 'lobby', '0', '1', '127.0.0.1', '7001', '0', '1', '1', '1', '2000', '0', '0', '0', '0', '0', '0', '', '');

INSERT INTO `t_game_server_cfg` VALUES ('3', 'fishing', '0', '1', '127.0.0.1', '7703', '0', '0', '3', '1', '200', '50', '1000', '1', '1', '1', '1', 'cfg={chi_line = 6000,tu_line = 9000} return cfg', '');
INSERT INTO `t_game_server_cfg` VALUES ('4', 'fishing', '0', '1', '127.0.0.1', '7704', '0', '0', '3', '2', '200', '50', '5000', '10', '1', '1', '1', 'cfg={chi_line = 30000,tu_line = 50000} return cfg', '');
INSERT INTO `t_game_server_cfg` VALUES ('5', 'fishing', '0', '1', '127.0.0.1', '7705', '0', '0', '3', '3', '200', '50', '20000', '100', '1', '1', '1', 'cfg={chi_line = 200000,tu_line = 300000} return cfg', '');
INSERT INTO `t_game_server_cfg` VALUES ('6', 'fishing', '0', '1', '127.0.0.1', '7706', '0', '0', '3', '4', '200', '50', '50000', '1000', '1', '1', '1', 'cfg={chi_line = 700000,tu_line = 900000} return cfg', '');

INSERT INTO `t_game_server_cfg` VALUES ('20', 'land', '0', '1', '127.0.0.1', '7020', '0', '0', '5', '1', '900', '300', '200', '10', '1', '1', '5', 'cfg={ GameLimitCdTime = 6 } return cfg', '');
INSERT INTO `t_game_server_cfg` VALUES ('21', 'land', '0', '1', '127.0.0.1', '7021', '0', '0', '5', '2', '900', '300', '1200', '30', '1', '1', '5', 'cfg={ GameLimitCdTime = 5 } return cfg', '');
INSERT INTO `t_game_server_cfg` VALUES ('22', 'land', '0', '1', '127.0.0.1', '7022', '0', '0', '5', '3', '900', '300', '2400', '50', '1', '1', '5', 'cfg={ GameLimitCdTime = 4 } return cfg', '');

INSERT INTO `t_game_server_cfg` VALUES ('30', 'zhajinhua', '0', '1', '127.0.0.1', '7030', '0', '0', '6', '1', '500', '100', '2000', '10', '1', '1', '5', 'y = {[1] = {[10] = 10, [20] = 20, [50] =50, [80] = 80, [100] = 100}, [2] = {[100] = 100, [200] = 200, [500] =500, [800] = 800, [1000] = 1000}, [3] = {[500] = 500, [1000] = 1000, [2500] = 2500, [4000] = 4000, [5000] = 5000}, [4] = {[1000] = 1000, [2000] = 2000, [5000] = 5000, [8000] = 8000, [10000] = 10000}, [5] = {[2000] = 2000, [5000] = 5000, [10000] = 10000, [15000] = 15000, [20000] = 20000}} return y', '');
INSERT INTO `t_game_server_cfg` VALUES ('31', 'zhajinhua', '0', '1', '127.0.0.1', '7031', '0', '0', '6', '2', '500', '100', '6000', '100', '1', '1', '5', 'y = {[1] = {[10] = 10, [20] = 20, [50] =50, [80] = 80, [100] = 100}, [2] = {[100] = 100, [200] = 200, [500] =500, [800] = 800, [1000] = 1000}, [3] = {[500] = 500, [1000] = 1000, [2500] = 2500, [4000] = 4000, [5000] = 5000}, [4] = {[1000] = 1000, [2000] = 2000, [5000] = 5000, [8000] = 8000, [10000] = 10000}, [5] = {[2000] = 2000, [5000] = 5000, [10000] = 10000, [15000] = 15000, [20000] = 20000}} return y', '');
INSERT INTO `t_game_server_cfg` VALUES ('32', 'zhajinhua', '0', '1', '127.0.0.1', '7032', '0', '0', '6', '3', '500', '100', '30000', '500', '1', '1', '5', 'y = {[1] = {[10] = 10, [20] = 20, [50] =50, [80] = 80, [100] = 100}, [2] = {[100] = 100, [200] = 200, [500] =500, [800] = 800, [1000] = 1000}, [3] = {[500] = 500, [1000] = 1000, [2500] = 2500, [4000] = 4000, [5000] = 5000}, [4] = {[1000] = 1000, [2000] = 2000, [5000] = 5000, [8000] = 8000, [10000] = 10000}, [5] = {[2000] = 2000, [5000] = 5000, [10000] = 10000, [15000] = 15000, [20000] = 20000}} return y', '');
INSERT INTO `t_game_server_cfg` VALUES ('33', 'zhajinhua', '0', '1', '127.0.0.1', '7033', '0', '0', '6', '4', '500', '100', '60000', '1000', '1', '1', '5', 'y = {[1] = {[10] = 10, [20] = 20, [50] =50, [80] = 80, [100] = 100}, [2] = {[100] = 100, [200] = 200, [500] =500, [800] = 800, [1000] = 1000}, [3] = {[500] = 500, [1000] = 1000, [2500] = 2500, [4000] = 4000, [5000] = 5000}, [4] = {[1000] = 1000, [2000] = 2000, [5000] = 5000, [8000] = 8000, [10000] = 10000}, [5] = {[2000] = 2000, [5000] = 5000, [10000] = 10000, [15000] = 15000, [20000] = 20000}} return y', '');

INSERT INTO `t_game_server_cfg` VALUES ('40', 'showhand', '0', '0', '127.0.0.1', '7040', '0', '0', '7', '1', '600', '300', '1000', '10', '1', '1', '5', 'sh_room_config = {\r\n max_call = 32 } return sh_room_config', '');
INSERT INTO `t_game_server_cfg` VALUES ('41', 'showhand', '0', '0', '127.0.0.1', '7041', '0', '0', '7', '2', '600', '300', '2000', '20', '1', '1', '5', 'sh_room_config = {\r\n max_call = 32 } return sh_room_config', '');
INSERT INTO `t_game_server_cfg` VALUES ('42', 'showhand', '0', '0', '127.0.0.1', '7042', '0', '0', '7', '3', '600', '300', '5000', '50', '1', '1', '5', 'sh_room_config = {\r\n max_call = 64 } return sh_room_config', '');
INSERT INTO `t_game_server_cfg` VALUES ('43', 'showhand', '0', '0', '127.0.0.1', '7043', '0', '0', '7', '4', '600', '300', '10000', '100', '1', '1', '5', 'sh_room_config = {\r\n max_call = 64 } return sh_room_config', '');


INSERT INTO `t_game_server_cfg` VALUES ('50', 'ox', '0', '1', '127.0.0.1', '7050', '0', '0', '8', '1', '2000', '1', '5000', '10', '1', '1', '5', 'many_ox_room_config = {\r\n Ox_FreeTime = 3, \r\n Ox_BetTime = 18,\r\n Ox_EndTime = 15,\r\n Ox_MustWinCoeff = 5,\r\n Ox_FloatingCoeff = 3,\r\n Ox_bankerMoneyLimit = 5000000,\r\n Ox_SystemBankerSwitch = 1,\r\n Ox_BankerCount = 5,\r\n Ox_RobotBankerInitUid = 500000,\r\n Ox_RobotBankerInitMoney = 10000000,\r\n Ox_BetRobotSwitch = 1,\r\n Ox_BetRobotInitUid = 600000,\r\n Ox_BetRobotInitMoney = 35000,\r\n Ox_BetRobotNumControl = 5,\r\n Ox_BetRobotTimeControl = 10,\r\n Ox_RobotBetMoneyControl = 10000,\r\n Ox_PLAYER_MIN_LIMIT = 1000,\r\n Ox_basic_chip = {100,1000,5000,10000,100000}\r\n} return many_ox_room_config\r\n', '');
INSERT INTO `t_game_server_cfg` VALUES ('51', 'ox', '0', '1', '127.0.0.1', '7051', '0', '0', '8', '2', '2000', '1', '2000', '10', '1', '1', '5', 'many_ox_room_config = {\r\n Ox_FreeTime = 3, \r\n Ox_BetTime = 18,\r\n Ox_EndTime = 15,\r\n Ox_MustWinCoeff = 5,\r\n Ox_FloatingCoeff = 3,\r\n Ox_bankerMoneyLimit = 5000000,\r\n Ox_SystemBankerSwitch = 1,\r\n Ox_BankerCount = 5,\r\n Ox_RobotBankerInitUid = 700000,\r\n Ox_RobotBankerInitMoney = 10000000,\r\n Ox_BetRobotSwitch = 1,\r\n Ox_BetRobotInitUid = 800000,\r\n Ox_BetRobotInitMoney = 15000,\r\n Ox_BetRobotNumControl = 5,\r\n Ox_BetRobotTimeControl = 10,\r\n Ox_RobotBetMoneyControl = 10000,\r\n Ox_PLAYER_MIN_LIMIT = 1000,\r\n Ox_basic_chip = {100,1000,5000,10000,100000}\r\n} return many_ox_room_config\r\n', '');

INSERT INTO `t_game_server_cfg` VALUES ('80', 'texas', '0', '0', '127.0.0.1', '7080', '0', '0', '11', '1', '500', '100', '1000', '20', '1', '1', '5', '', '');
INSERT INTO `t_game_server_cfg` VALUES ('81', 'texas', '0', '0', '127.0.0.1', '7081', '0', '0', '11', '2', '500', '100', '5000', '100', '1', '1', '5', '', '');
INSERT INTO `t_game_server_cfg` VALUES ('82', 'texas', '0', '0', '127.0.0.1', '7082', '0', '0', '11', '3', '500', '100', '10000', '200', '1', '1', '5', '', '');
INSERT INTO `t_game_server_cfg` VALUES ('83', 'texas', '0', '0', '127.0.0.1', '7083', '0', '0', '11', '4', '500', '100', '50000', '500', '1', '1', '5', '', '');

INSERT INTO `t_game_server_cfg` VALUES ('110', 'banker_ox', '0', '1', '127.0.0.1', '7110', '0', '0', '14', '1', '500', '100', '5000', '100', '1', '1', '5', '', '');
INSERT INTO `t_game_server_cfg` VALUES ('111', 'banker_ox', '0', '1', '127.0.0.1', '7111', '0', '0', '14', '2', '500', '100', '25000', '500', '1', '1', '5', '', '');
INSERT INTO `t_game_server_cfg` VALUES ('112', 'banker_ox', '0', '1', '127.0.0.1', '7112', '0', '0', '14', '3', '500', '100', '50000', '1000', '1', '1', '5', '', '');
INSERT INTO `t_game_server_cfg` VALUES ('113', 'banker_ox', '0', '1', '127.0.0.1', '7113', '0', '0', '14', '4', '500', '100', '100000', '2000', '1', '1', '5', '', '');

INSERT INTO `t_game_server_cfg` VALUES ('130', 'classic_ox', '0', '0', '127.0.0.1', '7130', '0', '0', '16', '1', '500', '100', '5000', '100', '1', '1', '5', '', '');
INSERT INTO `t_game_server_cfg` VALUES ('131', 'classic_ox', '0', '0', '127.0.0.1', '7131', '0', '0', '16', '2', '500', '100', '25000', '500', '1', '1', '5', '', '');
INSERT INTO `t_game_server_cfg` VALUES ('132', 'classic_ox', '0', '0', '127.0.0.1', '7132', '0', '0', '16', '3', '500', '100', '50000', '1000', '1', '1', '5', '', '');
INSERT INTO `t_game_server_cfg` VALUES ('133', 'classic_ox', '0', '0', '127.0.0.1', '7133', '0', '0', '16', '4', '500', '100', '100000', '2000', '1', '1', '5', '', '');

INSERT INTO `t_game_server_cfg` VALUES ('140', 'point21', '0', '0', '127.0.0.1', '7140', '0', '0', '17', '1', '600', '100', '1000', '10', '1', '1', '5', 'cfg={ bet_base = {10,20,50} } return cfg', '');
INSERT INTO `t_game_server_cfg` VALUES ('141', 'point21', '0', '0', '127.0.0.1', '7141', '0', '0', '17', '2', '600', '100', '2000', '50', '1', '1', '5', 'cfg={ bet_base = {50,100,200} } return cfg', '');
INSERT INTO `t_game_server_cfg` VALUES ('142', 'point21', '0', '0', '127.0.0.1', '7142', '0', '0', '17', '3', '600', '100', '10000', '200', '1', '1', '5', 'cfg={ bet_base = {200,500,1000} } return cfg', '');
INSERT INTO `t_game_server_cfg` VALUES ('143', 'point21', '0', '0', '127.0.0.1', '7143', '0', '0', '17', '4', '600', '100', '20000', '1000', '1', '1', '5', 'cfg={ bet_base = {1000,2000,10000} } return cfg', '');

INSERT INTO `t_game_server_cfg` VALUES ('150', 'sansong', '0', '1', '127.0.0.1', '7150', '0', '0', '18', '1', '600', '100', '1000', '10', '1', '1', '5', 'cfg={ bet_base = {10,20} } return cfg', '');
INSERT INTO `t_game_server_cfg` VALUES ('151', 'sansong', '0', '1', '127.0.0.1', '7151', '0', '0', '18', '2', '600', '100', '20000', '200', '1', '1', '5', 'cfg={ bet_base = {200,300,400,500} } return cfg', '');
INSERT INTO `t_game_server_cfg` VALUES ('152', 'sansong', '0', '1', '127.0.0.1', '7152', '0', '0', '18', '3', '600', '100', '30000', '500', '1', '1', '5', 'cfg={ bet_base = {500,600,700,800} } return cfg', '');
INSERT INTO `t_game_server_cfg` VALUES ('153', 'sansong', '0', '1', '127.0.0.1', '7153', '0', '0', '18', '4', '600', '100', '80000', '1000', '1', '1', '5', 'cfg={ bet_base = {1000,1500,1800,2000} } return cfg', '');

INSERT INTO `t_game_server_cfg` VALUES ('160', 'honghei', '0', '1', '127.0.0.1', '7160', '0', '0', '19', '1', '2000', '1', '1000', '10', '1', '1', '5', 'cfg={ bet_base = {10,100,500,1000,5000} } return cfg', '');
INSERT INTO `t_game_server_cfg` VALUES ('161', 'honghei', '0', '1', '127.0.0.1', '7161', '0', '0', '19', '2', '2000', '1', '20000', '200', '1', '1', '5', 'cfg={ bet_base = {200,300,400,500} } return cfg', '');



DROP TABLE IF EXISTS `t_client_channel_cfg`;
CREATE TABLE `t_client_channel_cfg` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `channel` varchar(128) NOT NULL DEFAULT '',
  `server_list` varchar(256) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO `t_client_channel_cfg` VALUES ('1', 'open_for_all_channel', '1');
INSERT INTO `t_client_channel_cfg` VALUES ('2', '', '1,20,21,22');
INSERT INTO `t_client_channel_cfg` VALUES ('3', 'game_joy_lyylc', '1,20,21,22');
INSERT INTO `t_client_channel_cfg` VALUES ('4', 'game_joy_lydwc', '1,30,31,32,33');
INSERT INTO `t_client_channel_cfg` VALUES ('5', 'game_joy_lytd', '1,3,4,5,20,21,22,30,31,32,33,50,51,110,111,112,113,150,151,152,153');
INSERT INTO `t_client_channel_cfg` VALUES ('6', 'game_joy_lyryqp', '1,110,111,112,113');
INSERT INTO `t_client_channel_cfg` VALUES ('7', 'game_joy_lyylchang', '1,150,151,152,153');
INSERT INTO `t_client_channel_cfg` VALUES ('8', 'game_joy_lyfhc', '1,20,21,22,30,31,32,33,50,51,110,111,112,113');
INSERT INTO `t_client_channel_cfg` VALUES ('9', 'game_joy_fish', '1,3,4,5');

DROP TABLE IF EXISTS `t_gate_server_cfg`;
CREATE TABLE `t_gate_server_cfg` (
  `gate_id` int(11) NOT NULL COMMENT '网关服务器ID',
  `is_start` int(11) NOT NULL DEFAULT '0' COMMENT '1启动服务器，0已经关闭',
  `is_open` int(11) NOT NULL COMMENT '是否开启该网关配置',
  `ip` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT 'ip',
  `port` int(11) NOT NULL COMMENT '端口',
  `timeout_limit` int(11) NOT NULL DEFAULT '0' COMMENT '超时（秒）',
  `sms_time_limit` int(11) NOT NULL DEFAULT '0' COMMENT '发短信间隔',
  `sms_url` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '短信url',
  `sms_sign_key` varchar(256) NOT NULL DEFAULT '' COMMENT '短信接口签名',
  PRIMARY KEY (`gate_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci ;

-- ----------------------------
-- Records of t_gate_server_cfg
-- ----------------------------
INSERT INTO `t_gate_server_cfg` VALUES ('1', '0', '1', '127.0.0.1', '7788', '30', '90', 'http://127.0.0.1:80/api/account/sms','c12345678');
INSERT INTO `t_gate_server_cfg` VALUES ('2', '0', '1', '127.0.0.2', '7788', '30', '90', 'http://127.0.0.1:80/api/account/sms','c12345678');

DROP TABLE IF EXISTS `t_login_server_cfg`;
CREATE TABLE `t_login_server_cfg` (
  `login_id` int(11) NOT NULL COMMENT '登陆服务器ID',
  `is_start` int(11) NOT NULL DEFAULT '0' COMMENT '1启动服务器，0已经关闭',
  `is_open` int(11) NOT NULL COMMENT '是否开启该登陆服务器配置',
  `ip` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT 'ip',
  `port` int(11) NOT NULL COMMENT '端口',
  PRIMARY KEY (`login_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci;

-- ----------------------------
-- Records of t_login_server_cfg
-- ----------------------------
INSERT INTO `t_login_server_cfg` VALUES ('1', '0', '1', '127.0.0.1', '7710');

DROP TABLE IF EXISTS `t_db_server_cfg`;
CREATE TABLE `t_db_server_cfg` (
  `id` int(11) NOT NULL,
  `is_start` int(11) NOT NULL DEFAULT '0' COMMENT '1启动服务器，0已经关闭',
  `is_open` int(11) NOT NULL COMMENT '是否开启该登陆服务器配置',
  `ip` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT 'ip',
  `port` int(11) NOT NULL COMMENT '端口',
  `login_db_host` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '登陆DB地址',
  `login_db_user` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '登陆DB账号',
  `login_db_password` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '登陆DB密码',
  `login_db_database` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '登陆DB数据库',
  `game_db_host` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '游戏DB地址',
  `game_db_user` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '游戏DB账号',
  `game_db_password` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '游戏DB密码',
  `game_db_database` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '游戏DB数据库',
  `log_db_host` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '日志DB地址',
  `log_db_user` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '日志DB账号',
  `log_db_password` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '日志DB密码',
  `log_db_database` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '日志DB数据库',
  `recharge_db_host` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '充值DB地址',
  `recharge_db_user` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '充值DB账号',
  `recharge_db_password` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '充值DB密码',
  `recharge_db_database` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '充值DB数据库',
  `php_interface_addr` varchar(255) DEFAULT NULL COMMENT 'PHP接口地址',
  `cash_money_addr` varchar(255) DEFAULT NULL COMMENT 'PHP地址',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci;

INSERT INTO `t_db_server_cfg` VALUES ('1', '0', '1', '127.0.0.1', '7700', 'tcp://127.0.0.1:3306', 'root', '123456', 'account', 'tcp://127.0.0.1:3306', 'root', '123456', 'game', 'tcp://127.0.0.1:3306', 'root', '123456', 'log', 'tcp://127.0.0.1:3306', 'root', '123456', 'recharge', 'http://127.0.0.1/api/notice/notice_server', 'http://127.0.0.1:8080/api/index/cash');


DROP TABLE IF EXISTS `t_redis_cfg`;
CREATE TABLE `t_redis_cfg` (
  `id` bigint(20) NOT NULL COMMENT 'id',
  `is_sentinel` int(11) NOT NULL DEFAULT '0' COMMENT '1是哨兵，0不是',
  `ip` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT 'ip',
  `port` int(11) NOT NULL COMMENT '端口',
  `dbnum` int(11) NOT NULL COMMENT '数据库号',
  `password` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT 'redis密码',
  `master_name` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '主redis名字',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of t_redis_cfg
-- ----------------------------
INSERT INTO `t_redis_cfg` VALUES ('1', '0', '127.0.0.1', '6379', '0', '', '');

-- ----------------------------
-- Table structure for `t_globle_int_cfg`
-- ----------------------------
DROP TABLE IF EXISTS `t_globle_int_cfg`;
CREATE TABLE `t_globle_int_cfg` (
  `key` varchar(256) COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '键',
  `value` int(11) NOT NULL COMMENT '值',
  PRIMARY KEY (`key`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of t_globle_int_cfg
-- ----------------------------
INSERT INTO `t_globle_int_cfg` VALUES ('init_money', '300');
INSERT INTO `t_globle_int_cfg` VALUES ('register_money', '300');
INSERT INTO `t_globle_int_cfg` VALUES ('private_room_bank', '600');
INSERT INTO `t_globle_int_cfg` VALUES ('bank_transfer_tax', '5');
INSERT INTO `t_globle_int_cfg` VALUES ('cash_switch', '0');
INSERT INTO `t_globle_int_cfg` VALUES ('game_switch', '0');
INSERT INTO `t_globle_int_cfg` VALUES ('login_switch', '0');
INSERT INTO `t_globle_int_cfg` VALUES ('ali_recharge_switch', '0');
INSERT INTO `t_globle_int_cfg` VALUES ('wx_recharge_switch', '0');
INSERT INTO `t_globle_int_cfg` VALUES ('agent_recharge_switch', '0');
INSERT INTO `t_globle_int_cfg` VALUES ('cash_ali_switch', '0');
INSERT INTO `t_globle_int_cfg` VALUES ('cash_bank_switch', '0');
-- ----------------------------
-- Table structure for `t_globle_string_cfg`
-- ----------------------------
DROP TABLE IF EXISTS `t_globle_string_cfg`;
CREATE TABLE `t_globle_string_cfg` (
  `key` varchar(256) COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '键',
  `value` varchar(256) COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '值',
  PRIMARY KEY (`key`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of t_globle_string_cfg
-- ----------------------------
INSERT INTO `t_globle_string_cfg` VALUES ('php_sign_key', 'c12345678');

-- ----------------------------
-- Procedure structure for `get_db_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_db_config`;
DELIMITER ;;
CREATE PROCEDURE `get_db_config`(IN `db_id_` int)
    COMMENT '得到db配置'
BEGIN
	DECLARE done INT DEFAULT 0;
	DECLARE ret_ INT DEFAULT 0;
	DECLARE port_  INT DEFAULT 0;
	DECLARE login_db_host_ varchar(256) DEFAULT '';
	DECLARE login_db_user_ varchar(256) DEFAULT '';
	DECLARE login_db_password_ varchar(256) DEFAULT '';
	DECLARE login_db_database_ varchar(256) DEFAULT '';
	DECLARE game_db_host_ varchar(256) DEFAULT '';
	DECLARE game_db_user_ varchar(256) DEFAULT '';
	DECLARE game_db_password_ varchar(256) DEFAULT '';
	DECLARE game_db_database_ varchar(256) DEFAULT '';
	DECLARE log_db_host_ varchar(256) DEFAULT '';
	DECLARE log_db_user_ varchar(256) DEFAULT '';
	DECLARE log_db_password_ varchar(256) DEFAULT '';
	DECLARE log_db_database_ varchar(256) DEFAULT '';
	DECLARE recharge_db_host_ varchar(256) DEFAULT '';
	DECLARE recharge_db_user_ varchar(256) DEFAULT '';
	DECLARE recharge_db_password_ varchar(256) DEFAULT '';
	DECLARE recharge_db_database_ varchar(256) DEFAULT '';
	DECLARE cash_money_addr_ varchar(256) DEFAULT '';
	DECLARE init_money_ INT DEFAULT 0;
	DECLARE php_interface_addr_ varchar(256) DEFAULT '';	
	DECLARE result_ TEXT DEFAULT '';	
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;
	DECLARE dbnum_temp INT DEFAULT 0;
	DECLARE password_temp varchar(256) DEFAULT '';
	DECLARE master_name_temp varchar(256) DEFAULT '';
	
	DECLARE cur1 CURSOR FOR SELECT ip, port, dbnum, password FROM t_redis_cfg WHERE is_sentinel = 0 LIMIT 1;
	DECLARE cur2 CURSOR FOR SELECT ip, port, dbnum, password, master_name FROM t_redis_cfg WHERE is_sentinel = 1;
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
	
	OPEN cur1;
	OPEN cur2;
	
	# 查询自己的配置
	SELECT 	port,
	login_db_host,login_db_user,login_db_password,login_db_database,
	game_db_host,game_db_user,game_db_password,game_db_database,
	log_db_host,log_db_user,log_db_password,log_db_database,
	recharge_db_host,recharge_db_user,recharge_db_password,recharge_db_database,
	php_interface_addr,cash_money_addr
	INTO port_,
	login_db_host_,login_db_user_,login_db_password_,login_db_database_,
	game_db_host_,game_db_user_,game_db_password_,game_db_database_,
	log_db_host_,log_db_user_,log_db_password_,log_db_database_,
	recharge_db_host_,recharge_db_user_,recharge_db_password_,recharge_db_database_,
	php_interface_addr_,cash_money_addr_
	FROM t_db_server_cfg WHERE id = db_id_ AND is_open = 1;
	IF port_ != 0 THEN
		SET ret_ = 1;
		SET result_ = CONCAT('port: ', port_,
		'\n login_db { ',
		'\nhost: "', login_db_host_,	'"\nuser: "', login_db_user_,	'"\npassword: "', login_db_password_,	'"\ndatabase: "', login_db_database_, '"\n}\n',	
		'game_db { ',
		'\nhost: "', game_db_host_,	'"\nuser: "', game_db_user_,	'"\npassword: "', game_db_password_,	'"\ndatabase: "', game_db_database_, '"\n}\n',
		'log_db { ',	
		'\nhost: "', log_db_host_,	'"\nuser: "', log_db_user_,	'"\npassword: "', log_db_password_,	'"\ndatabase: "', log_db_database_, '"\n}\n',
		'recharge_db { ',	
		'\nhost: "', recharge_db_host_,	'"\nuser: "', recharge_db_user_,	'"\npassword: "', recharge_db_password_,	'"\ndatabase: "', recharge_db_database_, '"\n}\n');

		# 通用配置
		SELECT `value` INTO ip_temp FROM t_globle_string_cfg WHERE `key` = 'php_sign_key';
		SET result_ = CONCAT(result_, 'php_sign_key: "', ip_temp, '"\n');
		SELECT `value` INTO port_temp FROM t_globle_int_cfg WHERE `key` = 'bank_transfer_tax';
		SET result_ = CONCAT(result_, 'bank_transfer_tax: ', port_temp, '\n');

		# 查询redis配置
		REPEAT
			FETCH cur1 INTO ip_temp, port_temp, dbnum_temp, password_temp;
			IF NOT done THEN
				SET result_ = CONCAT(result_, 'def_redis {\nip: "', ip_temp, '"\nport: ', port_temp, '\ndbnum: ', dbnum_temp, '\npassword: "', password_temp, '"\n}\n');
		END IF;
		UNTIL done END REPEAT;

		SET done = 0;

		REPEAT
			FETCH cur2 INTO ip_temp, port_temp, dbnum_temp, password_temp, master_name_temp;
			IF NOT done THEN
				SET result_ = CONCAT(result_, 'def_sentinel {\nip: "', ip_temp, '"\nport: ', port_temp, '\ndbnum: ', dbnum_temp, '\npassword: "', password_temp, '"\nmaster_name: "', master_name_temp, '"\n}\n');
			END IF;
		UNTIL done END REPEAT;

		SELECT `value` INTO init_money_ FROM t_globle_int_cfg WHERE `key` = "init_money";
		SET result_ = CONCAT(result_, 'init_money: ', init_money_, '\n');
		SET result_ = CONCAT(result_, 'php_interface_addr: "', php_interface_addr_, '"\n');
		SET result_ = CONCAT(result_, 'cash_money_addr: "', cash_money_addr_, '"\n');

		# 设置服务器开启
		UPDATE t_db_server_cfg SET is_start = 1 WHERE id = db_id_;
	END IF;
	
	SELECT ret_, result_;
END
;;
DELIMITER ;
-- ----------------------------
-- Procedure structure for `get_game_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_game_config`;
DELIMITER ;;
CREATE PROCEDURE `get_game_config`(IN `game_id_` int)
    COMMENT '得到login配置'
BEGIN
	DECLARE done INT DEFAULT 0;
	DECLARE ret_ INT DEFAULT 0;
	DECLARE ip_ varchar(256) DEFAULT '';
	DECLARE port_ INT DEFAULT 0;
	DECLARE using_login_validatebox_ int(11) DEFAULT '0';
	DECLARE default_lobby_ int(11) DEFAULT '0';
	DECLARE first_game_type_ int(11) DEFAULT '0';
	DECLARE second_game_type_ int(11) DEFAULT '0';
	DECLARE player_limit_ int(11) DEFAULT '0';
	DECLARE table_count_ int(11) DEFAULT '0';
	DECLARE money_limit_ int(11) DEFAULT '0';
	DECLARE cell_money_ int(11) DEFAULT '0';
	DECLARE tax_open_ int(11) DEFAULT '0';
	DECLARE tax_show_ int(11) DEFAULT '0';
	DECLARE tax_ int(11) DEFAULT '0';
	DECLARE room_lua_cfg_ TEXT DEFAULT '';
	DECLARE result_ TEXT DEFAULT '';
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;
	DECLARE dbnum_temp INT DEFAULT 0;
	DECLARE password_temp varchar(256) DEFAULT '';
	DECLARE master_name_temp varchar(256) DEFAULT '';

	DECLARE cur1 CURSOR FOR SELECT ip, port, login_id FROM t_login_server_cfg WHERE is_open = 1;
	DECLARE cur2 CURSOR FOR SELECT ip, port, id FROM t_db_server_cfg WHERE is_open = 1;
	DECLARE cur3 CURSOR FOR SELECT ip, port, dbnum, password FROM t_redis_cfg WHERE is_sentinel = 0 LIMIT 1;
	DECLARE cur4 CURSOR FOR SELECT ip, port, dbnum, password, master_name FROM t_redis_cfg WHERE is_sentinel = 1;
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;

	OPEN cur1;
	OPEN cur2;
	OPEN cur3;
	OPEN cur4;

	# 查询自己的IP端口
	SELECT ip, port, using_login_validatebox, default_lobby, first_game_type, second_game_type, player_limit, table_count, money_limit, cell_money, tax_open, tax_show, tax, room_lua_cfg INTO ip_, port_, using_login_validatebox_, default_lobby_, first_game_type_, second_game_type_, player_limit_, table_count_, money_limit_, cell_money_, tax_open_, tax_show_, tax_, room_lua_cfg_ FROM t_game_server_cfg WHERE game_id = game_id_ AND is_open = 1;
	IF port_ != 0 THEN
		SET ret_ = 1;
		SET result_ = CONCAT('game_id: ', game_id_, '\nport: ', port_, '\nusing_login_validatebox: ', using_login_validatebox_, '\ndefault_lobby: ', default_lobby_, '\nfirst_game_type: ', first_game_type_,  '\nsecond_game_type: ', second_game_type_, '\nplayer_limit: ', player_limit_, '\ntable_count: ', table_count_, '\nmoney_limit: ', money_limit_, '\ncell_money: ', cell_money_, '\ntax_open: ', tax_open_, '\ntax_show: ', tax_show_, '\ntax: ', tax_, '\n');

		# 通用配置
		SELECT `value` INTO port_temp FROM t_globle_int_cfg WHERE `key` = 'bank_transfer_tax';
		SET result_ = CONCAT(result_, 'bank_transfer_tax: ', port_temp, '\n');

		SELECT `value` INTO port_temp FROM t_globle_int_cfg WHERE `key` = 'register_money';
		SET result_ = CONCAT(result_, 'register_money: ', port_temp, '\n');

		SELECT `value` INTO port_temp FROM t_globle_int_cfg WHERE `key` = 'private_room_bank';
		SET result_ = CONCAT(result_, 'private_room_bank: ', port_temp, '\n');

		# 查询连接login的IP端口
		REPEAT
			FETCH cur1 INTO ip_temp, port_temp, dbnum_temp;
			IF NOT done THEN
				IF ip_temp = ip_ THEN
					SET ip_temp = '127.0.0.1';
				END IF;
				SET result_ = CONCAT(result_, 'login_addr {\nip: "', ip_temp, '"\nport: ', port_temp, '\nserver_id: ', dbnum_temp, '\n}\n');
			END IF;
		UNTIL done END REPEAT;

		SET done = 0;

		# 查询连接db的IP端口
		REPEAT
			FETCH cur2 INTO ip_temp, port_temp, dbnum_temp;
			IF NOT done THEN
				IF ip_temp = ip_ THEN
					SET ip_temp = '127.0.0.1';
				END IF;
				SET result_ = CONCAT(result_, 'db_addr {\nip: "', ip_temp, '"\nport: ', port_temp, '\nserver_id: ', dbnum_temp, '\n}\n');
			END IF;
		UNTIL done END REPEAT;

		SET done = 0;

		# 查询redis配置
		REPEAT
			FETCH cur3 INTO ip_temp, port_temp, dbnum_temp, password_temp;
			IF NOT done THEN
				SET result_ = CONCAT(result_, 'def_redis {\nip: "', ip_temp, '"\nport: ', port_temp, '\ndbnum: ', dbnum_temp, '\npassword: "', password_temp, '"\n}\n');
			END IF;
		UNTIL done END REPEAT;

		SET done = 0;

		REPEAT
			FETCH cur4 INTO ip_temp, port_temp, dbnum_temp, password_temp, master_name_temp;
			IF NOT done THEN
				SET result_ = CONCAT(result_, 'def_sentinel {\nip: "', ip_temp, '"\nport: ', port_temp, '\ndbnum: ', dbnum_temp, '\npassword: "', password_temp, '"\nmaster_name: "', master_name_temp, '"\n}\n');
			END IF;
		UNTIL done END REPEAT;
		
		# 设置服务器开启
		UPDATE t_game_server_cfg SET is_start = 1 WHERE game_id = game_id_;
	END IF;
	SELECT ret_, result_, room_lua_cfg_;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `get_login_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_login_config`;
DELIMITER ;;
CREATE PROCEDURE `get_login_config`(IN `login_id_` int)
    COMMENT '得到login配置'
BEGIN
	DECLARE done INT DEFAULT 0;
	DECLARE ret_ INT DEFAULT 0;
	DECLARE ip_ varchar(256) DEFAULT '';
	DECLARE port_ INT DEFAULT 0;
	DECLARE result_ TEXT DEFAULT '';
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;
	DECLARE dbnum_temp INT DEFAULT 0;
	DECLARE password_temp varchar(256) DEFAULT '';
	DECLARE master_name_temp varchar(256) DEFAULT '';

	DECLARE cur1 CURSOR FOR SELECT ip, port, id FROM t_db_server_cfg WHERE is_open = 1;
	DECLARE cur2 CURSOR FOR SELECT ip, port, dbnum, password FROM t_redis_cfg WHERE is_sentinel = 0 LIMIT 1;
	DECLARE cur3 CURSOR FOR SELECT ip, port, dbnum, password, master_name FROM t_redis_cfg WHERE is_sentinel = 1;
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;

	OPEN cur1;
	OPEN cur2;
	OPEN cur3;

	# 查询自己的IP端口
	SELECT ip, port INTO ip_, port_ FROM t_login_server_cfg WHERE login_id = login_id_ AND is_open = 1;	
	IF port_ != 0 THEN
		SET ret_ = 1;
		SET result_ = CONCAT('login_id: ', login_id_, '\nport: ', port_, '\n');

		# 查询连接db的IP端口
		REPEAT
			FETCH cur1 INTO ip_temp, port_temp, dbnum_temp;
			IF NOT done THEN
				IF ip_temp = ip_ THEN
					SET ip_temp = '127.0.0.1';
				END IF;
				SET result_ = CONCAT(result_, 'db_addr {\nip: "', ip_temp, '"\nport: ', port_temp, '\nserver_id: ', dbnum_temp, '\n}\n');
			END IF;
		UNTIL done END REPEAT;

		SET done = 0;

		# 查询redis配置
		REPEAT
			FETCH cur2 INTO ip_temp, port_temp, dbnum_temp, password_temp;
			IF NOT done THEN
				SET result_ = CONCAT(result_, 'def_redis {\nip: "', ip_temp, '"\nport: ', port_temp, '\ndbnum: ', dbnum_temp, '\npassword: "', password_temp, '"\n}\n');
		END IF;
		UNTIL done END REPEAT;

		SET done = 0;

		REPEAT
			FETCH cur3 INTO ip_temp, port_temp, dbnum_temp, password_temp, master_name_temp;
			IF NOT done THEN
				SET result_ = CONCAT(result_, 'def_sentinel {\nip: "', ip_temp, '"\nport: ', port_temp, '\ndbnum: ', dbnum_temp, '\npassword: "', password_temp, '"\nmaster_name: "', master_name_temp, '"\n}\n');
			END IF;
		UNTIL done END REPEAT;
		
		# 设置服务器开启
		UPDATE t_login_server_cfg SET is_start = 1 WHERE login_id = login_id_;
	END IF;
	SELECT ret_, result_;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `get_gate_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_gate_config`;
DELIMITER ;;
CREATE PROCEDURE `get_gate_config`(IN `gate_id_` int)
    COMMENT '得到gate配置'
BEGIN
	DECLARE done INT DEFAULT 0;
	DECLARE ret_ INT DEFAULT 0;
	DECLARE ip_ varchar(256) DEFAULT '';
	DECLARE port_ INT DEFAULT 0;
	DECLARE timeout_limit_ int(11) DEFAULT '0';
	DECLARE sms_time_limit_ int(11) DEFAULT '0';
	DECLARE sms_url_ varchar(256) DEFAULT '';
	DECLARE sms_sign_key_ varchar(256) DEFAULT '';
	DECLARE result_ TEXT DEFAULT '';
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;
	DECLARE server_id_temp INT DEFAULT 0;
	
	DECLARE cur1 CURSOR FOR SELECT ip, port, login_id FROM t_login_server_cfg WHERE is_open = 1;
	DECLARE cur2 CURSOR FOR SELECT ip, port, game_id FROM t_game_server_cfg WHERE is_open = 1;
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;

	OPEN cur1;
	OPEN cur2;

	# 查询自己的IP端口
	SELECT ip, port, timeout_limit, sms_time_limit, sms_url,sms_sign_key INTO ip_, port_, timeout_limit_, sms_time_limit_, sms_url_,sms_sign_key_ FROM t_gate_server_cfg WHERE gate_id = gate_id_ AND is_open = 1;
	IF port_ != 0 THEN
		SET ret_ = 1;
		SET result_ = CONCAT('gate_id: ', gate_id_, '\nport: ', port_, '\ntimeout_limit: ', timeout_limit_, '\nsms_time_limit: ', sms_time_limit_,  '\nsms_url: "', sms_url_,  '"\nsms_sign_key: "', sms_sign_key_, '"\n');

		# 查询连接login的IP端口
		REPEAT
		FETCH cur1 INTO ip_temp, port_temp, server_id_temp;
		IF NOT done THEN
			IF ip_temp = ip_ THEN
				SET ip_temp = '127.0.0.1';
			END IF;
			SET result_ = CONCAT(result_, 'login_addr {\nip: "', ip_temp, '"\nport: ', port_temp, '\nserver_id: ', server_id_temp, '\n}\n');
		END IF;
		UNTIL done END REPEAT;
  
		SET done = 0;
  
		# 查询连接game的IP端口
		REPEAT
		FETCH cur2 INTO ip_temp, port_temp, server_id_temp;
		IF NOT done THEN
			IF ip_temp = ip_ THEN
				SET ip_temp = '127.0.0.1';
			END IF;
			SET result_ = CONCAT(result_, 'game_addr {\nip: "', ip_temp, '"\nport: ', port_temp, '\nserver_id: ', server_id_temp, '\n}\n');
		END IF;
		UNTIL done END REPEAT;
		
		# 设置服务器开启
		UPDATE t_gate_server_cfg SET is_start = 1 WHERE gate_id = gate_id_;
	END IF;
	SELECT ret_, result_;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `update_game_db_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `update_game_db_config`;
DELIMITER ;;
CREATE PROCEDURE `update_game_db_config`(IN `game_id_` int, IN `db_id_` int)
    COMMENT '更新game连接db配置'
BEGIN
	DECLARE ip_ varchar(256) DEFAULT '';
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;

	SELECT ip INTO ip_ FROM t_game_server_cfg WHERE game_id = game_id_ AND is_open = 1;
	SELECT ip, port INTO ip_temp, port_temp FROM t_db_server_cfg WHERE id = db_id_ AND is_open = 1;
	IF ip_temp = ip_ THEN
		SET ip_temp = '127.0.0.1';
	END IF;

	SELECT ip_temp, port_temp;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `update_game_login_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `update_game_login_config`;
DELIMITER ;;
CREATE PROCEDURE `update_game_login_config`(IN `game_id_` int, IN `login_id_` int)
    COMMENT '更新game连接login配置'
BEGIN
	DECLARE ip_ varchar(256) DEFAULT '';
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;

	SELECT ip INTO ip_ FROM t_game_server_cfg WHERE game_id = game_id_ AND is_open = 1;
	SELECT ip, port INTO ip_temp, port_temp FROM t_login_server_cfg WHERE login_id = login_id_ AND is_open = 1;
	IF ip_temp = ip_ THEN
		SET ip_temp = '127.0.0.1';
	END IF;

	SELECT ip_temp, port_temp;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `update_gate_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `update_gate_config`;
DELIMITER ;;
CREATE PROCEDURE `update_gate_config`(IN `gate_id_` int, IN `game_id_` int)
    COMMENT '更新gate连接game配置'
BEGIN
	DECLARE ip_ varchar(256) DEFAULT '';
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;

	SELECT ip INTO ip_ FROM t_gate_server_cfg WHERE gate_id = gate_id_ AND is_open = 1;
	SELECT ip, port INTO ip_temp, port_temp FROM t_game_server_cfg WHERE game_id = game_id_ AND is_open = 1;
	IF ip_temp = ip_ THEN
		SET ip_temp = '127.0.0.1';
	END IF;

	SELECT ip_temp, port_temp;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `update_gate_login_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `update_gate_login_config`;
DELIMITER ;;
CREATE PROCEDURE `update_gate_login_config`(IN `gate_id_` int, IN `login_id_` int)
    COMMENT '更新gate连接login配置'
BEGIN
	DECLARE ip_ varchar(256) DEFAULT '';
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;

	SELECT ip INTO ip_ FROM t_gate_server_cfg WHERE gate_id = gate_id_ AND is_open = 1;
	SELECT ip, port INTO ip_temp, port_temp FROM t_login_server_cfg WHERE login_id = login_id_ AND is_open = 1;
	IF ip_temp = ip_ THEN
		SET ip_temp = '127.0.0.1';
	END IF;

	SELECT ip_temp, port_temp;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `update_login_db_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `update_login_db_config`;
DELIMITER ;;
CREATE PROCEDURE `update_login_db_config`(IN `login_id_` int, IN `db_id_` int)
    COMMENT '更新login连接db配置'
BEGIN
	DECLARE ip_ varchar(256) DEFAULT '';
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;

	SELECT ip INTO ip_ FROM t_login_server_cfg WHERE login_id = login_id_ AND is_open = 1;
	SELECT ip, port INTO ip_temp, port_temp FROM t_db_server_cfg WHERE id = db_id_ AND is_open = 1;
	IF ip_temp = ip_ THEN
		SET ip_temp = '127.0.0.1';
	END IF;

	SELECT ip_temp, port_temp;
END
;;
DELIMITER ;


DROP DATABASE IF EXISTS `recharge`;
CREATE DATABASE `recharge` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `recharge`;

DROP TABLE IF EXISTS `t_cash`;
CREATE TABLE `t_cash` (
`order_id`  int(11) NOT NULL AUTO_INCREMENT ,
`guid`  int(11) NOT NULL COMMENT '玩家ID' ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '渠道号' ,
`ip`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT 'IP' ,
`phone_type`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '手机类型ios，android' ,
`phone`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '手机具体类型' ,
`money`  bigint(20) NOT NULL COMMENT '提现金额' ,
`coins`  bigint(20) NOT NULL DEFAULT 0 COMMENT '提款金币' ,
`pay_money`  bigint(20) NOT NULL COMMENT '实际获得金额' ,
`status`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '0未审核 1已通知打款 2PHP已拒绝并通知退币 3打款失败 4打款成功' ,
`status_c`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '0默认 1退币成功 2无法查到此订单 3无法找到玩家所在服务器 4修改数据库bank失败 5无法找到玩家 6服务器接收成功处理中' ,
`reason`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '拒绝理由以及打款失败的理由' ,
`return_c`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT 'C++返回扣币是否成功数据' ,
`return`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '打款端返回是否打款成功数据' ,
`check_name`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '审核人' ,
`check_time`  timestamp NULL DEFAULT NULL COMMENT '审核时间' ,
`before_money`  bigint(20) NULL DEFAULT NULL COMMENT '提现前金钱' ,
`before_bank`  bigint(20) NULL DEFAULT NULL COMMENT '提现前银行金钱' ,
`after_money`  bigint(20) NULL DEFAULT NULL COMMENT '提现后金钱' ,
`after_bank`  bigint(20) NULL DEFAULT NULL COMMENT '提现后银行金钱' ,
`agent_id`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '代理人ID' ,
`statements`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '打款流水号' ,
`created_at`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
`updated_at`  timestamp NULL DEFAULT NULL COMMENT '修改时间' ,
`error_level` int(11) not null default 0 ,
`cash_type`	int(11) NOT NULL default 0 ,
PRIMARY KEY (`order_id`, `created_at`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='提现表'
ROW_FORMAT=DYNAMIC
;

DROP TABLE IF EXISTS `t_cash_black_list`;
CREATE TABLE `t_cash_black_list` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` datetime DEFAULT NULL,
  `STATUS`  VARCHAR(255) DEFAULT NULL DEFAULT "" ,
  `order_id`  VARCHAR(255)  DEFAULT NULL DEFAULT "" COMMENT '订单号',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_recharge
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge`;
CREATE TABLE `t_recharge` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `platform_id` tinyint(4) NOT NULL DEFAULT '1' COMMENT '充值平台ID,与recharge.r_platform表关联',
  `guid` int(11) DEFAULT NULL COMMENT '账号ID,与account.t_account关联',
  `interactive` tinyint(1) NOT NULL DEFAULT '1' COMMENT '交互：1 服务端 2支付端 3客户端',
  `param` varchar(5000) COLLATE utf8_general_ci DEFAULT NULL COMMENT '发送参数',
  `returns` varchar(5000) COLLATE utf8_general_ci DEFAULT NULL COMMENT '返回参数',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='充值日志表';

-- ----------------------------
-- Records of t_recharge
-- ----------------------------

-- ----------------------------
-- Table structure for t_recharge_order
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_order`;
CREATE TABLE `t_recharge_order` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `agent_id`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '代理人ID' ,
  `serial_order_no` varchar(50) COLLATE utf8_general_ci NOT NULL COMMENT '支付流水订单号',
  `guid` int(11) NOT NULL COMMENT '账号ID,与account.t_account关联',
  `bag_id` varchar(255) DEFAULT NULL COMMENT '该guid隶属的渠道包ID',
  `account_ip` varchar(16) COLLATE utf8_general_ci NOT NULL DEFAULT '0.0.0.0' COMMENT 'IP地址',
  `area` varchar(50) COLLATE utf8_general_ci DEFAULT NULL COMMENT '根据IP获得地区',
  `device` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '设备号',
  `platform_id` int(11) NOT NULL DEFAULT '0' COMMENT '充值平台号',
  `seller_id` varchar(16) COLLATE utf8_general_ci NOT NULL DEFAULT '0.0.0.0' COMMENT '商家id',
  `trade_no` varchar(200) COLLATE utf8_general_ci DEFAULT NULL COMMENT '交易订单号',
  `channel_id` int(11) DEFAULT NULL COMMENT '渠道ID',
  `recharge_type` tinyint(2) NOT NULL DEFAULT '2' COMMENT '充值类型',
  `point_card_id` varchar(255) COLLATE utf8_general_ci DEFAULT NULL COMMENT '点卡ID',
  `payment_amt` double(11,2) DEFAULT '0.00' COMMENT '支付金额',
  `actual_amt` double(11,2) DEFAULT '0.00' COMMENT '实付进金额',
  `currency` varchar(10) COLLATE utf8_general_ci NOT NULL DEFAULT 'RMB' COMMENT '支持货币',
  `exchange_gold` int(50) NOT NULL DEFAULT '0' COMMENT '实际游戏币',
  `channel` varchar(20) COLLATE utf8_general_ci DEFAULT NULL COMMENT '支付渠道编码:alipay aliwap tenpay weixi applepay',
  `callback` varchar(500) COLLATE utf8_general_ci NOT NULL COMMENT '回调服务端口地址',
  `order_status` tinyint(2) NOT NULL DEFAULT '1' COMMENT '订单状态：1 生成订单 2 支付订单 3 订单失败 4 订单补发',
  `pay_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '支付返回状态: 0默认 1充值成功 2充值失败 ',
  `pay_succ_time` timestamp NULL DEFAULT NULL COMMENT '支付成功的时间',
  `pay_returns` varchar(5000) COLLATE utf8_general_ci DEFAULT NULL COMMENT '支付回调数据',
  `server_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '服务端返回状态:0默认 1充值成功 2无法查到此订单 3无法找到玩家所在服务器 4修改数据库bank失败 5无法找到玩家 6服务器接收成功处理中',
  `server_returns` varchar(5000) COLLATE utf8_general_ci DEFAULT NULL COMMENT '服务端回调数据',
  `before_bank` bigint(20) DEFAULT NULL COMMENT '充值前银行金钱',
  `after_bank` bigint(20) DEFAULT NULL COMMENT '充值后银行金钱',
  `sign` varchar(100) COLLATE utf8_general_ci DEFAULT NULL COMMENT '签名',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`,`created_at`),
  INDEX `qipai_guid` (`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='充值订单';

-- ----------------------------
-- Records of t_recharge_order
-- ----------------------------

-- ----------------------------
-- Table structure for t_recharge_platform
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_platform`;
CREATE TABLE `t_recharge_platform` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '充值平台唯一ID',
  `name` varchar(100) COLLATE utf8_general_ci DEFAULT NULL COMMENT '接入充值平台名称',
  `developer` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '开发者',
  `client_type` varchar(20) COLLATE utf8_general_ci DEFAULT 'all' COMMENT '客户端类型：all 全部, iOS 苹果, android 安卓等 ',
  `is_online` tinyint(4) DEFAULT '0' COMMENT '是否上线：0下线 1上线',
  `desc` varchar(1000) COLLATE utf8_general_ci DEFAULT NULL COMMENT '描述',
  `object_name` varchar(50) COLLATE utf8_general_ci DEFAULT NULL COMMENT '对象名',
  `pay_select` varchar(255) COLLATE utf8_general_ci DEFAULT NULL COMMENT '支持的支付方式',
  `created_at` timestamp NULL DEFAULT NULL COMMENT '开发时间',
  `updated_at` timestamp NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='充值平台表';


-- ----------------------------
-- Table structure for t_re_recharge
-- ----------------------------
DROP TABLE IF EXISTS `t_re_recharge`;
CREATE TABLE `t_re_recharge` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) NOT NULL COMMENT '玩家ID',
  `money` bigint(20) NOT NULL COMMENT '',
  `status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '0默认 成功',
  `type` int(11) NOT NULL DEFAULT '0' COMMENT '增加类型',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '对应id',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COMMENT='补充表';

-- ----------------------------
-- Records of t_recharge_platform
-- ----------------------------
INSERT INTO `t_recharge_platform` VALUES ('1', '苹果支付平台', '', 'iOS', '1', '', 'Apple', 'ios', '2017-02-06 21:13:32', '2017-02-06 21:13:37');
INSERT INTO `t_recharge_platform` VALUES ('2', '自支付平台', '', 'all', '1', '', 'SsPay', 'alipay', '2017-02-06 21:18:04', '2017-02-06 21:18:07');
INSERT INTO `t_recharge_platform` VALUES ('3', 'BenPay支付', '', 'all', '1', '', 'BenPay', 'alipay,wxpay', '2017-09-19 15:30:39', '2017-09-19 15:30:41');

CREATE TABLE t_recharge_channel (
  id int(11) NOT NULL AUTO_INCREMENT COMMENT '(权重分配:如果该支付渠道,已经‘上线使用’,并且未超单天额度,并且金额区间囊括此次充值金额，就可以进入权重分配)',
  name varchar(255) NOT NULL COMMENT '分配的渠道名字',
  p_id int(11) NOT NULL COMMENT '平台iD(与t_recharge_platform的id对应)',
  pay_select varchar(255) NOT NULL COMMENT '支持的支付方式',
  percentage smallint(6) NOT NULL DEFAULT '0' COMMENT '百分比(越大权重越高)',
  min_money double(11,0) DEFAULT NULL COMMENT '单次最小金额(单位元)',
  max_money double(11,0) DEFAULT NULL COMMENT '单次最多金额(单位元)',
  day_limit double(11,0) DEFAULT NULL COMMENT '该支付方式每天的限额(单位元)',
  day_sum double(11,0) DEFAULT NULL COMMENT '该支付方式今天的已支付额度(单位元,每笔订单支付完成都要在此处进行累加)',
  test_statu tinyint(1) DEFAULT '0' COMMENT '0:尚未测试, 1:正在测试, 2:完成测试',
  is_online tinyint(1) DEFAULT '0' COMMENT '上线开关，1:开，0关',
  object_name varchar(255) DEFAULT NULL COMMENT '实现该充值渠道的PHP对象名',
  ratio int(11) DEFAULT '0',
  created_at timestamp NULL DEFAULT NULL,
  updated_at timestamp NULL DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY unq_name (name),
  UNIQUE KEY unq_way (p_id,pay_select)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='渠道商与充值平台中间表';

INSERT INTO `t_recharge_channel` VALUES (1, 'BenPay - alipay', 3, 'alipay', 100, 1, 500, 100000, 0, 0, 0, 'BenPay', 0,'2017-09-19 15:33:31', '2017-09-19 15:33:31');
INSERT INTO `t_recharge_channel` VALUES (2, 'BenPay - wxpay', 3, 'wxpay', 100, 1, 500, 100000, 0, 0, 0, 'BenPay', 0,'2017-09-19 15:33:55', '2017-09-19 15:33:55');

CREATE TABLE t_recharge_test_guids (
  guid int(11) NOT NULL COMMENT '(该表是充值测试白名单)',
  account varchar(64) DEFAULT NULL COMMENT '玩家账号',
  r_channel_id int(11) NOT NULL COMMENT '充值渠道ID，表t_recharge_channel中的id',
  PRIMARY KEY (guid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='充值白名单表';
DROP TABLE IF EXISTS `t_cash_black_list`;
CREATE TABLE `t_cash_black_list` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8;

/*Table structure for table `t_game_cfg` */

DROP TABLE IF EXISTS `t_game_cfg`;

CREATE TABLE `t_game_cfg` (
  `flAutoSeal` tinyint(3) unsigned NOT NULL COMMENT '伙牌斗地主自动封号开关 0关闭 1打开',
  `sealAlipay` tinyint(3) unsigned NOT NULL,
  `sealNumCk` tinyint(3) unsigned NOT NULL,
  `jGameNum` int(11) NOT NULL DEFAULT '0',
  `jLocalNum` int(11) NOT NULL DEFAULT '0',
  `jLocalTime` int(11) NOT NULL DEFAULT '0',
  `dfirst` int(11) NOT NULL DEFAULT '0',
  `jmiddle` int(11) NOT NULL DEFAULT '0',
  `dmiddle` int(11) NOT NULL DEFAULT '0',
  `dhigh` int(11) NOT NULL DEFAULT '0',
  `jfirst` int(11) NOT NULL DEFAULT '0',
  `jhigh` int(11) NOT NULL DEFAULT '0',
  `jmaster` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='游戏配置表';


