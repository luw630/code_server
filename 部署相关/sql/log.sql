SET FOREIGN_KEY_CHECKS=0;

DROP DATABASE IF EXISTS `log`;
CREATE DATABASE `log` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `log`;

-- ----------------------------
-- Table structure for `t_log_bank`
-- ----------------------------
DROP TABLE IF EXISTS `t_log_bank`;
CREATE TABLE `t_log_bank` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `time` timestamp NULL DEFAULT NULL COMMENT '记录发生时间',
  `guid` int(11) NOT NULL DEFAULT '0' COMMENT '全局唯一标识符',
  `nickname` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '昵称',
  `phone` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '手机名字：ios，android',
  `opt_type` int(11) NOT NULL DEFAULT '0' COMMENT '交易类型：0存入，1取出',
  `money` int(11) DEFAULT NULL COMMENT '变动金币',
  `old_money` int(11) DEFAULT NULL COMMENT '开始金币',
  `new_money` int(11) DEFAULT NULL COMMENT '结束金币',
  `old_bank` int(11) DEFAULT NULL COMMENT '开始银行金币',
  `new_bank` int(11) DEFAULT NULL COMMENT '结束银行金币',
  `ip` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT 'IP地址',
  PRIMARY KEY (`id`),
  KEY `index_id` (`id`),
  KEY `index_time` (`time`),
  KEY `index_guid` (`guid`),
  KEY `index_opt_type` (`opt_type`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='银行志表';


DROP TABLE IF EXISTS `t_log_play_keep`;
CREATE TABLE `t_log_play_keep` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `time` varchar(50) NOT NULL COMMENT '时间',
  `registered` INT(11) NOT NULL COMMENT '注册数',
  `keep_one` varchar(50) DEFAULT NULL COMMENT '昨日留存',
  `keep_two` varchar(50) DEFAULT NULL COMMENT '2日留存',
  `keep_three` varchar(50) DEFAULT NULL COMMENT '3日留存',
  `keep_four` varchar(50) DEFAULT NULL COMMENT '4日留存',
  `keep_five` varchar(50) DEFAULT NULL COMMENT '5日留存',
  `keep_six` varchar(50) DEFAULT NULL COMMENT '6日留存',
  `keep_seven` varchar(50) DEFAULT NULL COMMENT '7日留存',
  `keep_eight` varchar(50) DEFAULT NULL COMMENT '8日留存',
  `keep_nine` varchar(50) DEFAULT NULL COMMENT '9日留存',
  `keep_ten` varchar(50) DEFAULT NULL COMMENT '10日留存',
  `crate_time` datetime NOT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
 
 
DROP TABLE IF EXISTS `t_log_money`;
CREATE TABLE `t_log_money` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `guid` int(11) NOT NULL DEFAULT '0' COMMENT '全局唯一标识符',
  `old_money` bigint(20) NOT NULL DEFAULT '0' COMMENT '操作前的钱',
  `new_money` bigint(20) NOT NULL DEFAULT '0' COMMENT '操作后的钱',
  `old_bank` bigint(20) NOT NULL DEFAULT '0' COMMENT '操作前的银行存款',
  `new_bank` bigint(20) NOT NULL DEFAULT '0' COMMENT '操作后的银行存款',
  `opt_type` int(11) NOT NULL DEFAULT '0' COMMENT '操作类型',
  `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `index_id` (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='钱日志表';

-- ----------------------------
-- Table structure for t_log_recharge
-- ----------------------------
DROP TABLE IF EXISTS `t_log_recharge`;
CREATE TABLE `t_log_recharge` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `platform_id` tinyint(4) NOT NULL DEFAULT '1' COMMENT '充值平台ID,与recharge.r_platform表关联',
  `guid` int(11) DEFAULT NULL COMMENT '账号ID,与account.t_account关联',
  `interactive` tinyint(1) NOT NULL DEFAULT '1' COMMENT '交互：1 服务端 2支付端 3客户端',
  `param` varchar(5000) COLLATE utf8_general_ci DEFAULT NULL COMMENT '发送参数',
  `returns` varchar(5000) COLLATE utf8_general_ci DEFAULT NULL COMMENT '返回参数',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_id` (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='充值日志表';

-- ----------------------------
-- Table structure for `t_log_channel_invite_tax`
-- ----------------------------
DROP TABLE IF EXISTS `t_log_channel_invite_tax`;
CREATE TABLE `t_log_channel_invite_tax` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `guid` int(11) NOT NULL COMMENT '获奖励者的guid',
  `guid_contribute` int(11) NOT NULL COMMENT '贡献者的id',
  `val` int(11) NOT NULL COMMENT '具体的值',
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `index_id` (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_log_money_TJ
-- ----------------------------
DROP TABLE IF EXISTS `t_log_money_tj`;
CREATE TABLE `t_log_money_tj` (
  `t_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `guid` int(11) NOT NULL COMMENT '用户ID,与account.t_account',
  `type` int(11) NOT NULL COMMENT '1 loss 2 win',
  `gameid` int(11) NOT NULL COMMENT 'gameid',
  `game_name` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '游戏名字',
  `phone_type` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '终端类型',
  `old_money` bigint(20) NOT NULL DEFAULT '0' COMMENT '游戏前的钱',
  `new_money` bigint(20) NOT NULL DEFAULT '0' COMMENT '游戏后的钱',
  `tax` bigint(20) DEFAULT NULL COMMENT '游戏扣税',
  `change_money` bigint(20) NOT NULL DEFAULT '0' COMMENT '变动金币',
  `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `IP` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT 'IP',
  `id` varchar(64) COLLATE utf8_general_ci NOT NULL COMMENT '牌局id',
  `channel_id` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT 'channel_id',
  PRIMARY KEY (`t_id`),
  KEY `index_name` (`gameid`,`created_time`),
  KEY `index_guid` (`guid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='金钱变动日志表';

-- ----------------------------
-- Table structure for t_log_player_count_top
-- ----------------------------
DROP TABLE IF EXISTS `t_log_player_count_top`;
CREATE TABLE `t_log_player_count_top` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `player_count_top` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '在线人数  最高峰',
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '时间点',
  `ex_info` varchar(255) DEFAULT '' COMMENT '其他信息',
  PRIMARY KEY (`id`)
)  ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='在线人数  最高峰表';


-- ----------------------------
-- Table structure for t_log_player_game_record
-- ----------------------------
DROP TABLE IF EXISTS `t_log_player_game_record`;
CREATE TABLE `t_log_player_game_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `guid` int(11) unsigned NOT NULL COMMENT '用户guid',
  `game_id` int(11) unsigned NOT NULL COMMENT '游戏id',
  `channel_id` varchar(255) NOT NULL COMMENT '渠道id',
  `first_game_type` int(11) NOT NULL COMMENT '游戏 type',
  `second_game_type` int(11) NOT NULL COMMENT '游戏子 type',
  `time` timestamp NOT NULL DEFAULT NOW() COMMENT '时间点',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- ----------------------------
-- Table structure for t_AgentsTransfer_tj
-- ----------------------------
DROP TABLE IF EXISTS `t_AgentsTransfer_tj`;
CREATE TABLE `t_AgentsTransfer_tj` (		
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `agents_guid` int(11) NOT NULL COMMENT '用户ID,与account.t_account',
  `player_guid` int(11) NOT NULL COMMENT '用户ID,与account.t_account',
  `transfer_id` int(11) NOT NULL COMMENT '交易id',
  `transfer_type` int(11) NOT NULL COMMENT '1进货 2出售 3回收',
  `transfer_money` bigint(20) NOT NULL DEFAULT '0' COMMENT '交易金额',
  `agents_old_bank` bigint(20) NOT NULL DEFAULT '0' COMMENT '操作前的银行存款',
  `agents_new_bank` bigint(20) NOT NULL DEFAULT '0' COMMENT '操作后的银行存款',
  `player_old_bank` bigint(20) NOT NULL DEFAULT '0' COMMENT '操作前的银行存款',
  `player_new_bank` bigint(20) NOT NULL DEFAULT '0' COMMENT '操作后的银行存款',
  `transfer_status` int(4) NOT NULL COMMENT '处理结果',
  `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `agents_guid` (`agents_guid`),
  KEY `player_guid` (`player_guid`),
  KEY `type_s` (`transfer_type`,`transfer_status`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='代理商转账表';

-- ----------------------------
-- Records of t_AgentsTransfer_tj
-- ----------------------------

-- ----------------------------
-- Table structure for t_log_recharge
-- ----------------------------
DROP TABLE IF EXISTS `t_log_recharge`;
CREATE TABLE `t_log_recharge` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `platform_id` tinyint(4) NOT NULL DEFAULT '1' COMMENT '充值平台ID,与recharge.r_platform表关联',
  `guid` int(11) DEFAULT NULL COMMENT '账号ID,与account.t_account关联',
  `interactive` tinyint(1) NOT NULL DEFAULT '1' COMMENT '交互：1 服务端 2支付端 3客户端',
  `param` varchar(5000) COLLATE utf8_general_ci DEFAULT NULL COMMENT '发送参数',
  `returns` varchar(5000) COLLATE utf8_general_ci DEFAULT NULL COMMENT '返回参数',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_id` (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='充值日志表';


-- ----------------------------
-- Table structure for t_erro_sql
-- ----------------------------
DROP TABLE IF EXISTS `t_erro_sql`;
CREATE TABLE `t_erro_sql` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `sql` text NOT NULL COMMENT 'sql 语句',
  `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `index_time` (`created_time`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='错误sql';
-- ----------------------------
-- Records of t_erro_sql
-- ----------------------------

-- ----------------------------
-- Table structure for t_log_game_tj
-- ----------------------------
DROP TABLE IF EXISTS `t_log_game_tj`;
CREATE TABLE `t_log_game_tj` (
  `t_key` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(64) COLLATE utf8_general_ci NOT NULL COMMENT '牌局id',
  `type` varchar(64) COLLATE utf8_general_ci NOT NULL COMMENT '游戏类型 斗地主 炸金花 等',
  `log`  text NOT NULL COMMENT '日志',
  `start_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `end_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '结束时间',
  `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `hdck` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`t_key`),
  KEY `index_id` (`id`),
  KEY `index_Type` (`type`),
  KEY `index_time` (`created_time`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='牌局日志记录';
-- ----------------------------
-- Records of t_log_game_tj
-- ----------------------------


-- ----------------------------
-- Table structure for t_log_robot_money_tj
-- ----------------------------
DROP TABLE IF EXISTS `t_log_robot_money_tj`;
CREATE TABLE `t_log_robot_money_tj` (
  `t_key` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `guid` int(20) NOT NULL COMMENT '用户ID',
  `is_banker` int(11) NOT NULL COMMENT '是否庄家1是,0不是',
  `winorlose` int(11) NOT NULL COMMENT '1 loss 2 win',
  `gameid` int(11) NOT NULL,
  `game_name` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '游戏名字',
  `old_money` bigint(20) NOT NULL COMMENT '游戏前的钱',
  `new_money` bigint(20) NOT NULL COMMENT '游戏后的钱',
  `tax` bigint(20) DEFAULT '0' COMMENT '游戏扣税',
  `money_change` bigint(20) NOT NULL DEFAULT '0' COMMENT '变动金币',
  `id` varchar(64) COLLATE utf8_general_ci NOT NULL COMMENT '牌局id',
   `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`t_key`),
  KEY `index_name` (`gameid`,`created_time`) USING BTREE,
  KEY `index_guid` (`guid`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='机器人金币变动日志表';


 -- ----------------------------
-- Records of t_log_robot_money_tj
-- ----------------------------
DROP TABLE IF EXISTS `t_money_log`;
CREATE TABLE `t_money_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `admin_name` varchar(255) DEFAULT NULL,
  `user_guid` varchar(255) DEFAULT NULL,
  `before_money` varchar(255) DEFAULT NULL,
  `after_money` varchar(255) DEFAULT NULL,
  `addtime` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `ip` varchar(255) DEFAULT NULL,
  `contents` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `t_bank_log`;
CREATE TABLE `t_bank_log` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`admin_name`  varchar(255) NULL ,
`user_guid`  varchar(255) NULL ,
`before_bank`  varchar(255) NULL ,
`after_bank`  varchar(255) NULL ,
`addtime`  datetime NULL ON UPDATE CURRENT_TIMESTAMP ,
`ip`  varchar(255) NULL ,
`contents`  varchar(255) NULL ,
`status`  varchar(255) NULL ,
PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `t_log_login`;
CREATE TABLE `t_log_login` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `guid` int(11) NOT NULL,
  `gate_id` int(11) NOT NULL,
  `game_id` int(11) NOT NULL,
  `account` varchar(64) NOT NULL,
  `ip_str` varchar(128) NOT NULL,
  `ip_area` varchar(128) NOT NULL,
  `mac_str` varchar(256) NOT NULL,
  `channel_id` varchar(128) NOT NULL,
  `version` varchar(128) NOT NULL,
  `phone` varchar(128) NOT NULL,
  `phone_type` varchar(128) NOT NULL,
  `login_time` varchar(128) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `t_log_change_storage`;
CREATE TABLE `t_log_change_storage` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `game_id` int(11) NOT NULL,
	`change_storage` int(11) NOT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `t_log_bind_tel`;
CREATE TABLE `t_log_bind_tel` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `guid` int(11) unsigned NOT NULL,
  `account` varchar(256) NOT NULL,
  `channel_id` varchar(256) NOT NULL,
  `version` varchar(128) NOT NULL,
  `phone` varchar(64) NOT NULL,
  `phone_type` varchar(64) NOT NULL,
  `time` varchar(64) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `t_log_agent_money`;
CREATE TABLE `t_log_agent_money` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `total_money` varchar(32) NOT NULL COMMENT '当日所有代理总金额',
  `created_at` date DEFAULT NULL COMMENT '统计日期',
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `t_log_count`;
CREATE TABLE `t_log_count` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tj_time` varchar(10) DEFAULT NULL COMMENT '统计时间',
  `revenue` text CHARACTER SET armscii8 COMMENT '营收',
  `recharge` text COMMENT '充值统计',
  `cash` text COMMENT '兑换统计',
  `total_coin` text COMMENT '金币统计',
  `total_regist` text COMMENT '注册用户数',
  `total_login` text COMMENT '登录统计',
  `total_tax` text COMMENT '总税收统计',
  `game_time` text COMMENT '游戏记录统计',
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `tj_time` (`tj_time`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=77 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='数据统计表';


/*Table structure for table `t_channel_count` */

DROP TABLE IF EXISTS `t_channel_count`;

CREATE TABLE `t_channel_count` (
  `id` int(50) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `time` varchar(50) NOT NULL COMMENT '统计时间',
  `channel` varchar(50) NOT NULL COMMENT '渠道',
  `f_channel` varchar(50) DEFAULT NULL COMMENT '关联渠道（父类）',
  `money` varchar(50) DEFAULT NULL COMMENT '营收',
  `recharge` varchar(50) DEFAULT NULL COMMENT '充值',
  `withdraw` varchar(50) DEFAULT NULL COMMENT '兑换',
  `newRegist` int(10) DEFAULT NULL COMMENT '新增用户',
  `oldRegist` int(10) DEFAULT NULL COMMENT '老用户',
  `todayLogin` int(10) DEFAULT NULL COMMENT '登陆用户数',
  `todayBound` int(10) DEFAULT NULL COMMENT '绑定用户数',
  `bound` varchar(50) DEFAULT NULL COMMENT '绑定率',
  `ali` varchar(50) DEFAULT NULL COMMENT '绑定用户数（支付宝）',
  `newRecharge` varchar(50) DEFAULT NULL COMMENT '新增充值人数',
  `oldRecharge` varchar(50) DEFAULT NULL COMMENT '老充值人数',
  `newAvg` varchar(50) DEFAULT NULL COMMENT '新用户平均充值',
  `oldAvg` varchar(50) DEFAULT NULL COMMENT '老用户平均充值',
  `avg` varchar(50) DEFAULT NULL COMMENT '平均充值',
  `online` int(10) DEFAULT NULL COMMENT '在线人数',
  `tax` varchar(50) CHARACTER SET ascii DEFAULT NULL COMMENT '总税收',
  `taxAvg` varchar(50) DEFAULT NULL COMMENT '人均营收',
  `zkeep` varchar(50) DEFAULT NULL COMMENT '昨日留存',
  `skeep` varchar(50) DEFAULT NULL COMMENT '3日留存',
  `qkeep` varchar(50) DEFAULT NULL COMMENT '7日留存',
  `update_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

/*Table structure for table `t_game_keep` */

DROP TABLE IF EXISTS `t_game_keep`;

CREATE TABLE `t_game_keep` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `time` varchar(50) NOT NULL COMMENT '时间',
  `name` varchar(50) NOT NULL COMMENT '游戏',
  `keep_one` tinyint(50) DEFAULT NULL COMMENT '昨日留存',
  `keep_two` tinyint(50) DEFAULT NULL COMMENT '2日留存',
  `keep_three` tinyint(50) DEFAULT NULL COMMENT '3日留存',
  `keep_seven` tinyint(50) DEFAULT NULL COMMENT '7日留存',
  `keep_fifteen` tinyint(50) DEFAULT NULL COMMENT '15日留存',
  `keep_thirty` tinyint(50) DEFAULT NULL COMMENT '30日留存',
  `crate_time` datetime NOT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8;


/*Table structure for table `t_log_count_coin` */

DROP TABLE IF EXISTS `t_log_count_coin`;

CREATE TABLE `t_log_count_coin` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tj_time` varchar(10) DEFAULT NULL COMMENT '统计时间',
  `total_coin` text CHARACTER SET armscii8 COMMENT '金币总量',
  `money` text COMMENT '玩家现金',
  `bank` text COMMENT '保险箱',
  `total_inflows` text COMMENT '总流入',
  `total_outflow` text COMMENT '总流出',
  `circulation` text COMMENT '流通量',
  `net_inflows` text COMMENT '净流入',
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `tj_time` (`tj_time`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=15 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='金币统计表';

/*Table structure for table `t_log_player_time` */

DROP TABLE IF EXISTS `t_log_player_time`;

CREATE TABLE `t_log_player_time` (
  `index_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `guid` int(11) DEFAULT NULL,
  `first_game_type` int(11) DEFAULT NULL,
  `table_count` int(11) DEFAULT NULL,
  `play_date` datetime DEFAULT NULL,
  `days` int(11) DEFAULT NULL,
  PRIMARY KEY (`index_id`)
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `t_log_robot_cfg`;
CREATE TABLE t_log_robot_cfg (
  id int(11) NOT NULL AUTO_INCREMENT,
  tj_time varchar(10) DEFAULT NULL COMMENT '统计时间',
  total text COMMENT '总库存',
  lobby text COMMENT '大厅',
  land text COMMENT '斗地主',
  zhajinhua text COMMENT '扎金花',
  fishing text COMMENT '捕鱼',
  ox text COMMENT '百人牛牛',
  banker_ox text COMMENT '抢庄牛牛',
  sansong text COMMENT '三公',
  created_at datetime DEFAULT NULL,
  PRIMARY KEY (id) USING BTREE,
  KEY tj_time (tj_time) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=84 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='库存统计表';


DROP TABLE IF EXISTS `t_log_agent_balance`;
CREATE TABLE t_log_agent_balance (
  id int(11) NOT NULL AUTO_INCREMENT,
  tj_time varchar(10) DEFAULT NULL COMMENT '统计时间',
  recharge text COMMENT '充值',
  balance text COMMENT '余额',
  created_at datetime DEFAULT NULL,
  PRIMARY KEY (id) USING BTREE,
  KEY tj_time (tj_time) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=84 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='代理充值余额统计表';

