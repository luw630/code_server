DROP DATABASE if exists `web_config`;
CREATE DATABASE `web_config` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `web_config`;

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for t_print_card_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_print_card_cfg`;
CREATE TABLE `t_print_card_cfg` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `goods_id` varchar(100) NOT NULL COMMENT '商品ID',
  `goods_amt` double(11,2) NOT NULL DEFAULT '0.00' COMMENT '订单价格',
  `goods_gold` varchar(50) NOT NULL COMMENT '转换金币(万)',
  `goods_desc` varchar(500) NOT NULL COMMENT '描述',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8 COMMENT='点卡配置';

-- ----------------------------
-- Records of t_print_card_cfg
-- ----------------------------
INSERT INTO `t_print_card_cfg` VALUES ('1', 'com.wzyx.game.third.productfour.product1', '6.00', '6', '6元礼包', '2017-01-04 20:03:56', '2017-01-04 20:03:59');
INSERT INTO `t_print_card_cfg` VALUES ('2', 'com.wzyx.game.third.productfour.product2', '12.00', '15', '12元礼包', '2017-01-04 20:05:01', '2017-01-04 20:05:04');
INSERT INTO `t_print_card_cfg` VALUES ('3', 'com.wzyx.game.third.productfour.product3', '30.00', '40', '30元礼包', '2017-01-04 20:05:48', '2017-01-04 20:05:51');
INSERT INTO `t_print_card_cfg` VALUES ('4', 'com.wzyx.game.third.productfour.product4', '60.00', '70', '50元礼包', '2017-01-04 20:06:21', '2017-01-04 20:06:24');
INSERT INTO `t_print_card_cfg` VALUES ('5', 'com.wzyx.game.third.productfour.product5', '128.00', '180', '218元礼包', '2017-01-04 20:07:07', '2017-01-04 20:07:10');
INSERT INTO `t_print_card_cfg` VALUES ('6', 'com.wzyx.game.third.productfour.product6', '328.00', '500', '328元礼包', '2017-01-04 20:07:55', '2017-01-04 20:07:57');
INSERT INTO `t_print_card_cfg` VALUES ('7', 'com.wzyx.game.third.productfour.product7', '618.00', '1000', '618元礼包', '2017-01-04 20:08:40', '2017-01-04 20:08:42');

-- ----------------------------
-- Table structure for t_system_config_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_system_config_cfg`;
CREATE TABLE `t_system_config_cfg` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `key` varchar(255) NOT NULL COMMENT '键名',
  `value` text NOT NULL COMMENT '键值',
  `description` varchar(255) NOT NULL DEFAULT '' COMMENT '描述',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='管理后台配置表';


DROP DATABASE if exists `frame`;
CREATE DATABASE `frame` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `frame`;

SET FOREIGN_KEY_CHECKS=0;

/*Table structure for table `channel_pack_game` */

DROP TABLE IF EXISTS `channel_pack_game`;

CREATE TABLE `channel_pack_game` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `channel_id` varchar(255) NOT NULL COMMENT '渠道',
  `pack_id` varchar(255) DEFAULT NULL COMMENT '渠道包',
  `phone_type` varchar(55) DEFAULT NULL COMMENT '平台',
  `first_game_type_list` tinytext COMMENT '游戏',
  `version` varchar(55) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

/*Table structure for table `complaints` */

DROP TABLE IF EXISTS `complaints`;

CREATE TABLE `complaints` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `account` varchar(100) DEFAULT '' COMMENT '玩家账号',
  `respondent` varchar(100) DEFAULT '' COMMENT '被投诉微信/QQ',
  `type` tinyint(2) NOT NULL DEFAULT '0' COMMENT '0投诉客服 1投诉代理',
  `product` varchar(255) NOT NULL DEFAULT '' COMMENT '投诉所属产品 万豪 GG 王者 麻将',
  `content` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '投诉内容',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='投诉表';

DROP TABLE IF EXISTS `chat_blackid`;
CREATE TABLE chat_blackid (
  id int(11) NOT NULL AUTO_INCREMENT,
  guid int(11) NOT NULL,
  end_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `customer_chat`;
CREATE TABLE customer_chat (
  id int(11) NOT NULL AUTO_INCREMENT COMMENT '会话ID',
  cs_id int(11) NOT NULL COMMENT '客服ID',
  guid int(11) NOT NULL COMMENT '用户ID',
  created_at timestamp NULL DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `customer_msg`;
CREATE TABLE customer_msg (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  chat_id int(10) unsigned NOT NULL COMMENT '会话id',
  username varchar(100) DEFAULT '' COMMENT '玩家昵称',
  account varchar(100) DEFAULT '' COMMENT '玩家账号',
  is_read tinyint(2) NOT NULL DEFAULT '0' COMMENT '0未读 1已读',
  type tinyint(2) NOT NULL DEFAULT '0' COMMENT '0玩家发送 1客服发送',
  content varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '消息内容',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='消息表';

DROP TABLE IF EXISTS `customer_service`;
CREATE TABLE customer_service (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  name varchar(255) NOT NULL,
  email varchar(255) NOT NULL,
  password varchar(255) NOT NULL,
  is_online int(11) NOT NULL DEFAULT '0' COMMENT '是否在线',
  created_at timestamp NULL DEFAULT NULL,
  updated_at timestamp NULL DEFAULT NULL,
  PRIMARY KEY (id) USING BTREE,
  UNIQUE KEY users_email_unique (email) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;



/*Table structure for table `t_channel` */

DROP TABLE IF EXISTS `t_channel`;

CREATE TABLE `t_channel` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `channel_name` varchar(50) NOT NULL COMMENT '渠道名称',
  `channel_user` varchar(50) NOT NULL COMMENT '渠道管理员',
  `channel_pwd` varchar(255) NOT NULL COMMENT '管理员密码',
  `channel_fc` varchar(10) NOT NULL COMMENT '渠道分成，渠道需要分成百分比',
  `distribute` varchar(255) NOT NULL COMMENT '描述',
  `created_at` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='渠道列表';

/*Table structure for table `t_channel_back` */

DROP TABLE IF EXISTS `t_channel_back`;

CREATE TABLE `t_channel_back` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `channel_name` varchar(11) NOT NULL COMMENT '与渠道表ID关联字段',
  `channel_back_id` varchar(50) NOT NULL COMMENT '渠道包ID',
  `channel_back_pwd` varchar(255) NOT NULL COMMENT '渠道包密码',
  `version` varchar(10) NOT NULL COMMENT '版本号',
  `phone` varchar(20) NOT NULL COMMENT '客户端类型',
  `channel_kl` varchar(10) NOT NULL COMMENT '渠道扣量',
  `distribute` varchar(255) NOT NULL COMMENT '说明描述',
  `game_Id` varchar(50) NOT NULL DEFAULT '' COMMENT '与游戏名字关联',
  `created_at` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=90 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='渠道包表';

-- ----------------------------
-- Table structure for account_statistics
-- ----------------------------
DROP TABLE IF EXISTS `account_statistics`;
CREATE TABLE `account_statistics`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) NULL DEFAULT NULL COMMENT '唯一标识，对照account库t_account表',
  `recharge_money` double(11, 2) NULL DEFAULT 0.00 COMMENT '充值成功金额',
  `recharge_fail_money` double(11, 2) NULL DEFAULT 0.00 COMMENT '充值失败金额',
  `recharge_count` bigint(20) NULL DEFAULT 0 COMMENT '充值成功笔数',
  `recharge_fail_count` bigint(20) NULL DEFAULT 0 COMMENT '充值失败笔数',
  `lose_money` bigint(20) NULL DEFAULT 0 COMMENT '输金币数（到目前为止输的）',
  `win_money` bigint(20) NULL DEFAULT 0 COMMENT '赢金币数（到目前为止赢得）',
  `tax` bigint(20) NULL DEFAULT 0 COMMENT '扣税',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `index_guid`(`guid`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '用户统计信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for account_statistics_detail
-- ----------------------------
DROP TABLE IF EXISTS `account_statistics_detail`;
CREATE TABLE `account_statistics_detail`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) NULL DEFAULT NULL COMMENT '唯一标识，对照account库t_account表',
  `recharge_money` double(11, 2) NULL DEFAULT 0.00 COMMENT '充值成功金额',
  `recharge_fail_money` double(11, 2) NULL DEFAULT 0.00 COMMENT '充值失败金额',
  `recharge_count` bigint(20) NULL DEFAULT 0 COMMENT '充值成功笔数',
  `recharge_fail_count` bigint(20) NULL DEFAULT 0 COMMENT '充值失败笔数',
  `lose_money` bigint(20) NULL DEFAULT 0 COMMENT '输金币数（到目前为止输的）',
  `win_money` bigint(20) NULL DEFAULT 0 COMMENT '赢金币数（到目前为止赢得）',
  `tax` bigint(20) NULL DEFAULT 0 COMMENT '税收',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '用户统计信息明细表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for action_log
-- ----------------------------
DROP TABLE IF EXISTS `action_log`;
CREATE TABLE `action_log`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `table` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '表名字',
  `table_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0' COMMENT '记录的主键',
  `description` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '描述',
  `old_json` varchar(2000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '修改之前的数据',
  `new_json` varchar(2000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '修改之后的数据',
  `username` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '审核人',
  `account` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '审核人账号',
  `ip` char(15) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT 'IP',
  `url` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '操作的url',
  `created_at` timestamp(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '后台操作日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for agent
-- ----------------------------
DROP TABLE IF EXISTS `agent`;
CREATE TABLE `agent`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `is_active` tinyint(1) NULL DEFAULT 1,
  `email` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '用户名',
  `password` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '密码',
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '代理名称',
  `qq` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `wechat` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `money` int(11) NULL DEFAULT 0 COMMENT '当前拥有金额',
  `last_login_time` datetime(0) NULL DEFAULT NULL,
  `created_at` datetime(0) NULL DEFAULT NULL,
  `updated_at` datetime(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `huanyue_username_index`(`email`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of agent
-- ----------------------------
INSERT INTO `agent` VALUES (1, 1, 'guowoo', '$2y$10$hfAEaV7D1/LOZtema1t8eO8U1t1qww3ZvEji01fC2fePxDBP0NYbS', 'guoxin', '6514791', 'wechat', 78700, NULL, '2017-09-11 10:22:41', '2017-09-12 15:48:32');
INSERT INTO `agent` VALUES (2, 1, 'agent_2', '$2y$10$4TY6sVTe5shW4r5.Tjpftu8VWYLuLIjwrQF0TRfRS2Bxwb4iUBgaq', '阳光代理', '123456', 'agent_wechat_1', 0, NULL, '2017-09-12 15:50:50', '2017-09-12 15:50:50');
INSERT INTO `agent` VALUES (3, 1, 'agent_3', '$2y$10$S74Rse4p5Ajh0dXMxyH/f.r00tYeiMto.lKhlBZBrYV4nyw4o4lWi', '小草代理', '789654321', 'agent_wechat_3', 0, NULL, '2017-09-12 15:51:15', '2017-09-12 15:51:15');
INSERT INTO `agent` VALUES (4, 1, 'agent_4', '$2y$10$FPhm7uIQ7IGt97lYR7KbZuZHrIOsVirhIB4ygjhvk01vv3X7IfL1.', 'QQ秒到代理', '852963', 'agent_wechat_4', 0, NULL, '2017-09-12 15:58:34', '2017-09-12 15:58:34');
INSERT INTO `agent` VALUES (5, 1, 'agent_5', '$2y$10$vOEjUCrySUyxugPBLqrG4eXg1iHczOi1opMZnkYfPPg75YzVp36Ta', '+Q.Q.9.5.4.7.1.5.6.4禾少到充值', '95471564', 'agent_wechat_5', 0, NULL, '2017-09-12 15:59:34', '2017-09-12 15:59:34');

-- ----------------------------
-- Table structure for black_alipay_account
-- ----------------------------
DROP TABLE IF EXISTS `black_alipay_account`;
CREATE TABLE `black_alipay_account`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `alipay_account` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `admin_account` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `reason` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `created_at` datetime(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for black_alipay_name
-- ----------------------------
DROP TABLE IF EXISTS `black_alipay_name`;
CREATE TABLE `black_alipay_name`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `account` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `reason` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `created_at` datetime(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for black_guid
-- ----------------------------
DROP TABLE IF EXISTS `black_guid`;
CREATE TABLE `black_guid`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) NULL DEFAULT NULL,
  `account` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `reason` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `created_at` datetime(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  `updated_at` datetime(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for black_ip
-- ----------------------------
DROP TABLE IF EXISTS `black_ip`;
CREATE TABLE `black_ip`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `account` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `reason` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `created_at` datetime(0) NULL DEFAULT NULL,
  `updated_at` datetime(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of black_ip
-- ----------------------------
INSERT INTO `black_ip` VALUES (1, NULL, NULL, NULL, '2017-07-15 15:02:20', '2017-07-15 15:02:20');

-- ----------------------------
-- Table structure for black_mac
-- ----------------------------
DROP TABLE IF EXISTS `black_mac`;
CREATE TABLE `black_mac`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) NULL DEFAULT NULL,
  `mac` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `account` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `reason` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `created_at` datetime(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  `updated_at` datetime(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for black_phone
-- ----------------------------
DROP TABLE IF EXISTS `black_phone`;
CREATE TABLE `black_phone`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) NULL DEFAULT NULL,
  `phone` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `account` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `reason` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `created_at` datetime(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  `updated_at` datetime(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for channel_business
-- ----------------------------
DROP TABLE IF EXISTS `channel_business`;
CREATE TABLE `channel_business`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '渠道商名字',
  `description` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '描述',
  `tax` decimal(5, 4) NOT NULL DEFAULT 0.0000 COMMENT '税收比例最大是1',
  `created_at` timestamp(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  `deleted_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `unique_business_name`(`business_name`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 3 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '渠道商表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of channel_business
-- ----------------------------
INSERT INTO `channel_business` VALUES (1, 'new_baobo', 'test', 0.0000, '2017-07-13 18:11:39', '2017-07-14 17:18:11', NULL);
INSERT INTO `channel_business` VALUES (2, '1', '1', 0.0000, '2017-07-13 18:11:49', '2017-07-14 17:18:06', NULL);

-- ----------------------------
-- Table structure for channel_functions
-- ----------------------------
DROP TABLE IF EXISTS `channel_functions`;
CREATE TABLE `channel_functions`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '功能名称',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '自动打包-功能表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for channel_game
-- ----------------------------
DROP TABLE IF EXISTS `channel_game`;
CREATE TABLE `channel_game`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '游戏名字',
  `alias` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '游戏别名',
  `status` tinyint(1) NULL DEFAULT 0 COMMENT '0 - 禁止 1 - 启用',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '自动打包-游戏表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for channel_statistics
-- ----------------------------
DROP TABLE IF EXISTS `channel_statistics`;
CREATE TABLE `channel_statistics`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `c_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道ID',
  `recharge_money` double(11, 2) NULL DEFAULT 0.00 COMMENT '充值成功金额',
  `recharge_fail_money` double(11, 2) NULL DEFAULT 0.00 COMMENT '充值失败金额',
  `recharge_count` bigint(20) NULL DEFAULT 0 COMMENT '充值成功笔数',
  `recharge_fail_count` bigint(20) NULL DEFAULT 0 COMMENT '充值失败笔数',
  `agent_money` bigint(20) NULL DEFAULT NULL COMMENT '代理充值',
  `lose_money` bigint(20) NULL DEFAULT 0 COMMENT '输金币数（到目前为止输的）',
  `win_money` bigint(20) NULL DEFAULT 0 COMMENT '赢金币数（到目前为止赢得）',
  `tax` bigint(20) NULL DEFAULT 0 COMMENT '税收',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `index_guid`(`c_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '渠道统计信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for channel_statistics_detail
-- ----------------------------
DROP TABLE IF EXISTS `channel_statistics_detail`;
CREATE TABLE `channel_statistics_detail`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `c_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道ID',
  `recharge_money` double(11, 2) NULL DEFAULT 0.00 COMMENT '充值成功金额',
  `recharge_fail_money` double(11, 2) NULL DEFAULT 0.00 COMMENT '充值失败金额',
  `recharge_count` bigint(20) NULL DEFAULT 0 COMMENT '充值成功笔数',
  `recharge_fail_count` bigint(20) NULL DEFAULT 0 COMMENT '充值失败笔数',
  `agent_money` bigint(20) NULL DEFAULT NULL COMMENT '代理充值',
  `lose_money` bigint(20) NULL DEFAULT 0 COMMENT '输金币数（到目前为止输的）',
  `win_money` bigint(20) NULL DEFAULT 0 COMMENT '赢金币数（到目前为止赢得）',
  `tax` bigint(20) NULL DEFAULT 0 COMMENT '税收',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '渠道统计信息明细表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for channel_tax
-- ----------------------------
DROP TABLE IF EXISTS `channel_tax`;
CREATE TABLE `channel_tax`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `business` int(10) NOT NULL DEFAULT 0 COMMENT '渠道商户',
  `tax` decimal(5, 4) NOT NULL DEFAULT 0.0000 COMMENT '税收比例',
  `phone_type` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '终端型号ios android',
  `version` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `channel` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '渠道号',
  `show_channel` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '对外渠道号',
  `url` varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '安装包地址',
  `created_at` timestamp(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '渠道商户和安装包关联表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for channel_versions
-- ----------------------------
DROP TABLE IF EXISTS `channel_versions`;
CREATE TABLE `channel_versions`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `version` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '版本号',
  `description` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '版本简介',
  `info` text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '版本详情',
  `status` tinyint(1) NULL DEFAULT 0 COMMENT '0 - 启用  1 - 禁用',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '自动打包-版本表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for counts
-- ----------------------------
DROP TABLE IF EXISTS `counts`;
CREATE TABLE `counts`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '字段名称',
  `number` int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '数量',
  `description` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '描述',
  `created_at` timestamp(0) NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `feedback_name_unique`(`name`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 3 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '统计表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of counts
-- ----------------------------
INSERT INTO `counts` VALUES (1, '提建议', 6, '提建议', '2017-07-19 10:44:44');
INSERT INTO `counts` VALUES (2, '提建议已回复', 3, '提建议已回复', '2017-07-19 16:25:01');

-- ----------------------------
-- Table structure for feedback
-- ----------------------------
DROP TABLE IF EXISTS `feedback`;
CREATE TABLE `feedback`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `f_id` int(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT '反馈表的主键id',
  `username` varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '玩家昵称',
  `account` varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '玩家账号',
  `is_read` tinyint(2) NOT NULL DEFAULT 0 COMMENT '0未读 1已读',
  `type` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '反馈的类型 提建议 提bug 充值问题 咨询其他',
  `content` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '反馈的内容',
  `created_at` timestamp(0) NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 11 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '反馈表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of feedback
-- ----------------------------
INSERT INTO `feedback` VALUES (1, 0, 'guest_17', '17', 0, '提建议', 'DSADA', '2017-07-19 10:44:44');
INSERT INTO `feedback` VALUES (2, 0, 'guest_17', '17', 0, '提建议', 'ASASAS', '2017-07-19 10:44:59');
INSERT INTO `feedback` VALUES (3, 1, 'gx', '17', 0, '提建议', 'yrdy', '2017-07-19 16:25:01');
INSERT INTO `feedback` VALUES (4, 1, 'gx', '17', 0, '提建议', 'test', '2017-07-19 16:27:26');
INSERT INTO `feedback` VALUES (5, 0, 'guest_20', '20', 0, '提建议', 'SADASDSA', '2017-07-20 16:44:37');
INSERT INTO `feedback` VALUES (6, 0, 'guest_20', '20', 0, '提建议', 'SDADA', '2017-07-20 16:44:47');
INSERT INTO `feedback` VALUES (7, 0, 'guest_20', '20', 0, '提建议', 'SDADA', '2017-07-20 16:45:46');
INSERT INTO `feedback` VALUES (8, 7, 'gx', '20', 1, '提建议', '%E8%B0%A2%E8%B0%A2%E4%BD%A0%E7%9A%84%E5%BB%BA%E8%AE%AE', '2017-07-20 16:46:01');
INSERT INTO `feedback` VALUES (9, 0, 'guest_47', '47', 0, '提建议', 'DSADAS', '2017-07-26 16:40:30');
INSERT INTO `feedback` VALUES (10, 9, 'gx', '47', 1, '提建议', '%E8%B0%A2%E8%B0%A2%E4%BD%A0%E7%9A%84%E5%BB%BA%E8%AE%AE', '2017-07-26 16:40:48');

-- ----------------------------
-- Table structure for menus
-- ----------------------------
DROP TABLE IF EXISTS `menus`;
CREATE TABLE `menus`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `pid` int(11) NOT NULL DEFAULT 0 COMMENT '菜单关系',
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '菜单名称',
  `icon` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '图标',
  `slug` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '菜单对应的权限',
  `url` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '菜单链接地址',
  `active` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '菜单高亮地址',
  `description` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '描述',
  `sort` tinyint(4) NOT NULL DEFAULT 0 COMMENT '排序',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 93 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of menus
-- ----------------------------
INSERT INTO `menus` VALUES (1, 0, '控制台', 'fa fa-dashboard', 'index.index', 'index/index', 'index/index', '后台首页', 99, NULL, NULL);
INSERT INTO `menus` VALUES (2, 0, '系统管理', 'fa fa-cog', 'system.*', '#', 'users/*,roles/*,permissions/*,log/*,gameConfig/*,menus/*,system/*,account/withdraw/cash,account/withdraw/cash/view,account/anti/config', '系统功能管理', 98, NULL, '2017-07-15 18:11:09');
INSERT INTO `menus` VALUES (3, 2, '用户管理', 'fa fa-users', 'users.index', 'users/index', 'users/*', '显示用户管理', 0, NULL, NULL);
INSERT INTO `menus` VALUES (4, 2, '角色管理', 'fa fa-male', 'roles.index', 'roles/index', 'roles/*', '显示角色管理', 0, NULL, NULL);
INSERT INTO `menus` VALUES (5, 2, '权限管理', 'fa fa-paper-plane', 'permissions.index', 'permissions/index', 'permissions/*', '显示权限管理', 0, NULL, NULL);
INSERT INTO `menus` VALUES (6, 2, '操作日志', '', 'log.index', 'log/index', 'log/index', '操作日志', 0, NULL, NULL);
INSERT INTO `menus` VALUES (33, 0, '玩家管理', 'fa fa-users', 'account.*', '#', 'account/index,rank/gold', '玩家管理', 97, NULL, NULL);
INSERT INTO `menus` VALUES (34, 33, '玩家列表', '', 'account.index', 'account/index', 'account/index', '玩家列表', 0, NULL, NULL);
INSERT INTO `menus` VALUES (29, 28, '私信通知', '', 'notice.specify', 'notice/specify', 'notice/specify', '充值通知消息页面', 0, NULL, NULL);
INSERT INTO `menus` VALUES (43, 35, '充值渠道设置', '', 'distribution.index', 'distribution/index', 'distribution/*', '充值渠道设置', 0, NULL, NULL);
INSERT INTO `menus` VALUES (28, 0, '通知管理', 'fa fa-bell', 'notice.*', '#', 'notice/*', '通知管理', 0, NULL, NULL);
INSERT INTO `menus` VALUES (40, 39, '在线玩家列表', '', 'onlineaccount.index', 'onlineaccount/index', 'onlineaccount/index', '在线玩家列表', 0, NULL, NULL);
INSERT INTO `menus` VALUES (39, 0, 'BI管理', 'fa fa-user-secret', 'bi.*', '#', 'bi/*,onlineaccount/*', 'BI管理', 0, NULL, NULL);
INSERT INTO `menus` VALUES (92, 88, '用户向代理充值订单', '', 'agent.*', 'admin/agent/order/list', 'admin/agent/order/list', '用户向代理充值订单', 0, NULL, NULL);
INSERT INTO `menus` VALUES (35, 0, '充值管理', 'fa fa-paypal', 'rechargeorder.*', '#', 'rechargeorder/*,distribution/*', '充值管理', 0, NULL, NULL);
INSERT INTO `menus` VALUES (27, 0, '反馈管理', 'fa fa-mail-reply', 'feedback.*', '#', 'feedback/*', '反馈管理', 0, NULL, NULL);
INSERT INTO `menus` VALUES (30, 28, '系统通知', '', 'notice.system', 'notice/system', 'notice/system', '系统通知', 0, NULL, NULL);
INSERT INTO `menus` VALUES (46, 2, '游戏配置', '', 'gameConfig.index', 'gameConfig/index', 'gameConfig/index', '游戏配置', 0, NULL, NULL);
INSERT INTO `menus` VALUES (51, 37, '自动打包配置', '', 'channelSetting.index', 'channelSetting/index', 'channelSetting/index*,channelSetting/create*', '渠道商列表', 0, NULL, NULL);
INSERT INTO `menus` VALUES (52, 47, '渠道包打包', 'fa fa-gg-circle', 'operator.channelset', 'operator/channelset', 'operator/channelset', '渠道包打包', 0, NULL, NULL);
INSERT INTO `menus` VALUES (53, 47, '渠道商列表', '', 'operator.index', 'operator/index', 'operator/index', '渠道商列表', 0, NULL, NULL);
INSERT INTO `menus` VALUES (54, 0, '充值代理', 'fa fa-gg-circle', 'rechargeUsers.index', 'rechargeUsers/index', 'rechargeUsers/index,rechargeUsers/transferLog*,rechargeUsers/rechargeLog*', '充值代理', 0, NULL, NULL);
INSERT INTO `menus` VALUES (55, 0, '客户端配置', 'fa fa-gg-circle', 'client.*', '#', 'client/*', '客户端配置', 0, NULL, NULL);
INSERT INTO `menus` VALUES (56, 55, '配置管理', '', 'client.listConfig', 'client/listConfig', 'client/listConfig', '配置项列表', 0, NULL, NULL);
INSERT INTO `menus` VALUES (57, 55, '配置模板管理', '', 'client.template', 'client/template', 'client/template', '配置模板列表', 0, NULL, NULL);
INSERT INTO `menus` VALUES (59, 0, '版本管理', 'fa fa-gg-circle', 'version.*', '#', 'version/*', '游戏大厅、游戏、框架版本包', 0, NULL, NULL);
INSERT INTO `menus` VALUES (60, 59, '框架版本管理', '', 'version.frame', 'version/frame', 'version/frame', '框架版本管理', 0, NULL, NULL);
INSERT INTO `menus` VALUES (61, 59, '大厅版本管理', '', 'version.hall', 'version/hall', 'version/hall', '大厅版本管理', 0, NULL, NULL);
INSERT INTO `menus` VALUES (62, 59, '游戏版本管理', '', 'version.game', 'version/game', 'version/game', '游戏版本管理', 0, NULL, NULL);
INSERT INTO `menus` VALUES (63, 2, '菜单管理', '', 'menus.index', 'menus/index', 'menus/index,menus/create', '菜单管理', 0, NULL, NULL);
INSERT INTO `menus` VALUES (64, 59, '版本导入', '', 'version.importCreate', 'version/importCreate', 'version/importCreate', '版本导入', 0, NULL, NULL);
INSERT INTO `menus` VALUES (65, 2, '清除缓存', '', 'system.clearCache', 'system/clearCache', 'system/clearCache', '清除缓存', 0, NULL, NULL);
INSERT INTO `menus` VALUES (67, 27, '反馈管理', '', 'feedback.*', 'feedback/listFeedback', 'feedback/listFeedback', '反馈管理', 0, NULL, NULL);
INSERT INTO `menus` VALUES (84, 2, '维护开关', '', 'gameConfig.switchList', 'gameConfig/switchList', 'gameConfig/switchList', '维护开关', 0, NULL, NULL);
INSERT INTO `menus` VALUES (82, 2, '提现管理', '', 'account.cash', 'account/withdraw/cash', 'account/withdraw/cash,account/withdraw/cash/view', '提现管理', 0, NULL, NULL);
INSERT INTO `menus` VALUES (80, 27, '快捷回复', '', 'feedback.*', 'feedback/quickReplyList', 'feedback/quickReplyList', '快捷回复', 0, NULL, NULL);
INSERT INTO `menus` VALUES (85, 33, '金币排行榜', '', 'rank.gold', 'rank/gold', 'rank/gold', '', 0, NULL, NULL);
INSERT INTO `menus` VALUES (86, 55, '错误日志', '', 'client.*', 'client/errors/logs', 'client/errors/*', '', 0, NULL, NULL);
INSERT INTO `menus` VALUES (87, 2, '反洗钱设置', '', 'account.cash', 'account/anti/config', 'account/anti/config', '', 0, NULL, NULL);
INSERT INTO `menus` VALUES (88, 0, '代理管理', 'fa fa-gg-circle', 'agent.*', '#', 'admin/agent/*', '', 96, NULL, NULL);
INSERT INTO `menus` VALUES (89, 88, '代理列表', '', 'agent.*', '/admin/agent/index', 'admin/agent/index', '', 0, NULL, NULL);
INSERT INTO `menus` VALUES (90, 88, '向代理转账记录', '', 'agent.*', '/admin/agent/transfer/list', 'admin/agent/transfer/*', '', 0, NULL, NULL);
INSERT INTO `menus` VALUES (91, 88, '用户向代理提现列表', '', 'agent.*', '/admin/agent/reflect/list', 'admin/agent/reflect/list', '', 0, NULL, NULL);

-- ----------------------------
-- Table structure for migrations
-- ----------------------------
DROP TABLE IF EXISTS `migrations`;
CREATE TABLE `migrations`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `batch` int(11) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 10 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of migrations
-- ----------------------------
INSERT INTO `migrations` VALUES (1, '2014_10_12_000000_create_users_table', 1);
INSERT INTO `migrations` VALUES (2, '2014_10_12_100000_create_password_resets_table', 1);
INSERT INTO `migrations` VALUES (3, '2015_01_15_105324_create_roles_table', 1);
INSERT INTO `migrations` VALUES (4, '2015_01_15_114412_create_role_user_table', 1);
INSERT INTO `migrations` VALUES (5, '2015_01_26_115212_create_permissions_table', 1);
INSERT INTO `migrations` VALUES (6, '2015_01_26_115523_create_permission_role_table', 1);
INSERT INTO `migrations` VALUES (7, '2015_02_09_132439_create_permission_user_table', 1);
INSERT INTO `migrations` VALUES (8, '2016_11_03_173731_create_menus_table', 1);
INSERT INTO `migrations` VALUES (9, '2017_09_09_141507_create_agents_table', 2);

-- ----------------------------
-- Table structure for operator_count_statistics
-- ----------------------------
DROP TABLE IF EXISTS `operator_count_statistics`;
CREATE TABLE `operator_count_statistics`  (
  `day` date NOT NULL COMMENT '日期（平台及渠道包下用户每天注册数及每天最高在线数）',
  `channel_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '渠道号（渠道号为--all--的是全部渠道号即平台）',
  `create_sum` int(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT '该日create的guid数',
  `online_max` int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '该日最高同时在线guid数（每天获取多次只保留最大的那个在线数）',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`day`, `channel_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for password_resets
-- ----------------------------
DROP TABLE IF EXISTS `password_resets`;
CREATE TABLE `password_resets`  (
  `email` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `token` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `created_at` timestamp(0) NULL DEFAULT NULL,
  INDEX `password_resets_email_index`(`email`) USING BTREE,
  INDEX `password_resets_token_index`(`token`) USING BTREE
) ENGINE = MyISAM CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for permission_role
-- ----------------------------
DROP TABLE IF EXISTS `permission_role`;
CREATE TABLE `permission_role`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `permission_id` int(10) UNSIGNED NOT NULL,
  `role_id` int(10) UNSIGNED NOT NULL,
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `permission_role_permission_id_index`(`permission_id`) USING BTREE,
  INDEX `permission_role_role_id_index`(`role_id`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 115 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Fixed;

-- ----------------------------
-- Records of permission_role
-- ----------------------------
INSERT INTO `permission_role` VALUES (1, 1, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (2, 2, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (3, 3, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (4, 4, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (5, 5, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (99, 6, 1, '2017-07-12 10:54:51', '2017-07-12 10:54:51');
INSERT INTO `permission_role` VALUES (7, 7, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (8, 8, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (9, 9, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (16, 16, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (17, 17, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (18, 18, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (19, 19, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (20, 20, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (21, 21, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (22, 22, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (23, 23, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (24, 24, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (25, 25, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (26, 26, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (27, 27, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (28, 28, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (29, 29, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (30, 30, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (31, 31, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (32, 32, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (33, 33, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (34, 34, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (35, 35, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (36, 36, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (37, 37, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (38, 38, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (39, 39, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (42, 40, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (43, 41, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (44, 42, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (55, 43, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (56, 44, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (57, 45, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (114, 96, 1, '2017-09-09 14:48:14', '2017-09-09 14:48:14');
INSERT INTO `permission_role` VALUES (113, 69, 3, '2017-09-09 13:50:27', '2017-09-09 13:50:27');
INSERT INTO `permission_role` VALUES (111, 95, 1, '2017-08-01 18:37:25', '2017-08-01 18:37:25');
INSERT INTO `permission_role` VALUES (110, 94, 1, '2017-08-01 14:34:12', '2017-08-01 14:34:12');
INSERT INTO `permission_role` VALUES (109, 93, 1, '2017-07-31 11:36:21', '2017-07-31 11:36:21');
INSERT INTO `permission_role` VALUES (67, 55, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (68, 56, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (69, 57, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (70, 58, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (71, 59, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (108, 92, 1, '2017-07-13 18:41:29', '2017-07-13 18:41:29');
INSERT INTO `permission_role` VALUES (106, 91, 1, '2017-07-13 14:56:49', '2017-07-13 14:56:49');
INSERT INTO `permission_role` VALUES (105, 90, 1, '2017-07-12 17:38:32', '2017-07-12 17:38:32');
INSERT INTO `permission_role` VALUES (104, 89, 1, '2017-07-12 14:49:28', '2017-07-12 14:49:28');
INSERT INTO `permission_role` VALUES (76, 66, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (77, 67, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (78, 68, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (79, 69, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (80, 70, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (81, 71, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (82, 72, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (83, 73, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (103, 88, 1, '2017-07-12 14:49:28', '2017-07-12 14:49:28');
INSERT INTO `permission_role` VALUES (86, 76, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (88, 78, 1, NULL, NULL);
INSERT INTO `permission_role` VALUES (102, 87, 1, '2017-07-12 14:46:46', '2017-07-12 14:46:46');
INSERT INTO `permission_role` VALUES (101, 86, 1, '2017-07-12 14:46:46', '2017-07-12 14:46:46');
INSERT INTO `permission_role` VALUES (98, 85, 1, '2017-07-12 10:53:42', '2017-07-12 10:53:42');
INSERT INTO `permission_role` VALUES (97, 84, 1, '2017-07-12 10:53:42', '2017-07-12 10:53:42');
INSERT INTO `permission_role` VALUES (100, 83, 1, '2017-07-12 10:54:51', '2017-07-12 10:54:51');
INSERT INTO `permission_role` VALUES (95, 77, 1, '2017-07-12 10:23:15', '2017-07-12 10:23:15');

-- ----------------------------
-- Table structure for permission_user
-- ----------------------------
DROP TABLE IF EXISTS `permission_user`;
CREATE TABLE `permission_user`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `permission_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `permission_user_permission_id_index`(`permission_id`) USING BTREE,
  INDEX `permission_user_user_id_index`(`user_id`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Fixed;

-- ----------------------------
-- Table structure for permissions
-- ----------------------------
DROP TABLE IF EXISTS `permissions`;
CREATE TABLE `permissions`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `slug` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `description` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `model` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `permissions_slug_unique`(`slug`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 98 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of permissions
-- ----------------------------
INSERT INTO `permissions` VALUES (39, '玩家管理显示', 'account.*', '玩家管理', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (1, '后台首页显示', 'index.index', '后台首页', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (2, '系统管理显示', 'system.*', '系统管理', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (40, '玩家列表显示', 'account.index', '玩家列表', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (41, '充值管理显示', 'rechargeorder.*', '充值管理', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (42, '充值订单列表显示', 'rechargeorder.index', '订单列表', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (3, '角色列表显示', 'roles.index', '角色列表', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (4, '权限列表显示', 'permissions.index', '显示权限列表', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (16, '玩家详情功能', 'account.show', '玩家详情功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (17, '用户列表数据功能', 'users.ajaxIndex', '用户列表数据功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (5, '用户列表显示', 'users.index', '用户列表', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (18, '用户创建显示', 'users.create', '用户创建显示', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (19, '用户创建功能', 'users.store', '用户创建功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (20, '用户修改显示', 'users.edit', '用户修改页面', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (21, '用户修改功能', 'users.update', '用户修改功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (22, '用户删除功能', 'users.destroy', '用户删除功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (23, '用户重置密码功能', 'users.resetPassword', '用户重置密码功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (6, '通知管理显示', 'notice.*', '通知管理', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (7, '私信通知显示', 'notice.specify', '私信通知', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (8, '系统通知显示', 'notice.system', '系统通知', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (9, '反馈管理显示', 'feedback.listFeedback', '反馈管理列表显示', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (24, '用户信息查看显示', 'users.show', '用户信息查看显示', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (25, '角色列表功能', 'roles.ajaxIndex', '角色列表功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (26, '角色创建显示', 'roles.create', '角色创建显示', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (27, '角色创建功能', 'roles.store', '角色创建功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (28, '角色详情显示', 'roles.show', '角色详情显示', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (29, '角色修改显示', 'roles.edit', '角色修改显示', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (30, '角色修改功能', 'roles.update', '角色修改功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (31, '权限列表功能', 'permissions.ajaxIndex', '权限列表功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (32, '权限修改显示', 'permissions.edit', '权限修改显示', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (33, '权限修改功能', 'permissions.update', '权限修改功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (34, '权限创建显示', 'permissions.create', '权限创建显示', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (35, '权限创建功能', 'permissions.store', '权限创建功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (36, '通知创建显示', 'notice.create', '通知创建显示', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (37, '创建通知功能', 'notice.store', '创建通知功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (38, '通知列表功能', 'notice.ajaxIndex', '通知列表功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (43, '通知删除功能', 'notice.destroy', '通知删除功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (44, '通知修改显示', 'notice.edit', '通知修改页面', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (45, '玩家列表功能', 'account.ajaxIndex', '玩家列表功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (55, '反馈显示功能', 'feedback.ajaxFeedback', '反馈显示功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (56, '反馈轮询功能', 'feedback.checkNewFeed', '反馈轮询功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (57, '反馈官方回复功能', 'feedback.replyFeedback', '反馈官方回复功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (58, '反馈详情显示', 'feedback.infoFeedback', '反馈详情', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (59, '语言包', 'index.dash', '语言包', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (66, '充值订单列表功能', 'rechargeorder.ajaxIndex', '充值订单列表功能', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (67, '渠道管理', 'channel.*', '渠道管理', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (68, '渠道税收设定', 'channelTax.index', '渠道税收设定', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (69, 'BI管理', 'bi.*', 'BI管理', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (70, '玩家在线列表', 'onlineaccount.index', '玩家在线列表', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (71, '操作日志', 'log.index', '操作日志', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (72, '渠道商列表', 'channelBusiness.index', '统计用户数', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (73, '充值渠道设置', 'distribution.index', '充值渠道设置', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (76, '游戏配置', 'gameConfig.index', '游戏配置', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (77, '渠道商', 'operator.index', '渠道商', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (78, '税收结算统计', 'operatorCount.index', '税收结算统计', NULL, NULL, NULL);
INSERT INTO `permissions` VALUES (83, '客户端配置显示', 'client.*', '客户端配置', '', '2017-07-12 10:31:15', '2017-07-12 10:52:46');
INSERT INTO `permissions` VALUES (84, '客户端配置列表', 'client.listConfig', '客户端配置列表', '', '2017-07-12 10:53:12', '2017-07-12 10:55:16');
INSERT INTO `permissions` VALUES (85, '配置模板列表', 'client.template', '配置模板列表', '', '2017-07-12 10:53:32', '2017-07-12 10:53:32');
INSERT INTO `permissions` VALUES (86, '版本管理显示', 'version.*', '版本管理显示', '', '2017-07-12 14:46:12', '2017-07-12 14:46:24');
INSERT INTO `permissions` VALUES (87, '框架版本管理', 'version.frame', '框架版本管理', '', '2017-07-12 14:46:39', '2017-07-12 14:46:39');
INSERT INTO `permissions` VALUES (88, '大厅版本管理', 'version.hall', '大厅版本管理', '', '2017-07-12 14:49:09', '2017-07-12 14:49:09');
INSERT INTO `permissions` VALUES (89, '游戏版本管理', 'version.game', '游戏版本管理', '', '2017-07-12 14:49:22', '2017-07-12 14:49:22');
INSERT INTO `permissions` VALUES (90, '菜单管理', 'menus.index', '菜单管理', '', '2017-07-12 17:38:07', '2017-07-12 17:40:59');
INSERT INTO `permissions` VALUES (91, '版本导入', 'version.importCreate', '版本管理版本导入', '', '2017-07-13 14:56:42', '2017-07-13 15:00:21');
INSERT INTO `permissions` VALUES (92, '清除缓存', 'system.clearCache', '清除系统缓存', '', '2017-07-13 18:37:52', '2017-07-13 18:41:10');
INSERT INTO `permissions` VALUES (93, '提现管理', 'account.cash', '提现管理', '', '2017-07-31 11:34:14', '2017-07-31 11:34:14');
INSERT INTO `permissions` VALUES (94, '维护开关', 'gameConfig.switchList', '维护开关', '', '2017-08-01 14:33:45', '2017-08-01 14:34:57');
INSERT INTO `permissions` VALUES (95, '金币排行榜', 'rank.gold', '', '', '2017-08-01 18:37:18', '2017-08-01 18:37:18');
INSERT INTO `permissions` VALUES (96, '代理管理显示', 'agent.*', '代理管理显示', '', '2017-09-09 14:47:37', '2017-09-09 14:47:54');

-- ----------------------------
-- Table structure for phone_statistics
-- ----------------------------
DROP TABLE IF EXISTS `phone_statistics`;
CREATE TABLE `phone_statistics`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` tinyint(1) NOT NULL DEFAULT 0 COMMENT '机型标识 0-IOS 1-Android',
  `recharge_money` double(11, 2) NULL DEFAULT 0.00 COMMENT '充值成功金额',
  `recharge_fail_money` double(11, 2) NULL DEFAULT 0.00 COMMENT '充值失败金额',
  `recharge_count` bigint(20) NULL DEFAULT 0 COMMENT '充值成功笔数',
  `recharge_fail_count` bigint(20) NULL DEFAULT 0 COMMENT '充值失败笔数',
  `agent_money` bigint(20) NULL DEFAULT NULL COMMENT '代理充值',
  `lose_money` bigint(20) NULL DEFAULT 0 COMMENT '输金币数（到目前为止输的）',
  `win_money` bigint(20) NULL DEFAULT 0 COMMENT '赢金币数（到目前为止赢得）',
  `tax` bigint(20) NULL DEFAULT 0 COMMENT '税收',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `index_guid`(`type`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '手机机型统计信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for phone_statistics_detail
-- ----------------------------
DROP TABLE IF EXISTS `phone_statistics_detail`;
CREATE TABLE `phone_statistics_detail`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` tinyint(1) NOT NULL DEFAULT 0 COMMENT '机型标识 0-IOS 1-Android',
  `recharge_money` double(11, 2) NULL DEFAULT 0.00 COMMENT '充值成功金额',
  `recharge_fail_money` double(11, 2) NULL DEFAULT 0.00 COMMENT '充值失败金额',
  `recharge_count` bigint(20) NULL DEFAULT 0 COMMENT '充值成功笔数',
  `recharge_fail_count` bigint(20) NULL DEFAULT 0 COMMENT '充值失败笔数',
  `agent_money` bigint(20) NULL DEFAULT NULL COMMENT '代理充值',
  `lose_money` bigint(20) NULL DEFAULT 0 COMMENT '输金币数（到目前为止输的）',
  `win_money` bigint(20) NULL DEFAULT 0 COMMENT '赢金币数（到目前为止赢得）',
  `tax` bigint(20) NULL DEFAULT 0 COMMENT '税收',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '手机机型统计信息明细表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for plant_statistics
-- ----------------------------
DROP TABLE IF EXISTS `plant_statistics`;
CREATE TABLE `plant_statistics`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_count` bigint(20) NULL DEFAULT 0 COMMENT '总订单数',
  `order_sum` double(11, 2) NULL DEFAULT 0.00 COMMENT '总订单金额',
  `order_success_count` bigint(20) NULL DEFAULT 0 COMMENT '成功的订单数',
  `order_success_sum` double(11, 2) NULL DEFAULT 0.00 COMMENT '成功订单总金额',
  `order_fail_count` bigint(20) NULL DEFAULT 0 COMMENT '失败订单数',
  `order_fail_sum` double(11, 2) NULL DEFAULT 0.00 COMMENT '失败订单总金额',
  `order_success_user` bigint(20) NULL DEFAULT 0 COMMENT '充值成功人数',
  `tax` bigint(20) NULL DEFAULT 0 COMMENT '平台税收',
  `bank` bigint(20) NULL DEFAULT 0 COMMENT '银行存款统计',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '平台信息综合统计表' ROW_FORMAT = Fixed;

-- ----------------------------
-- Table structure for plant_statistics_detail
-- ----------------------------
DROP TABLE IF EXISTS `plant_statistics_detail`;
CREATE TABLE `plant_statistics_detail`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_count` bigint(20) NULL DEFAULT 0 COMMENT '总订单数',
  `order_sum` double(11, 2) NULL DEFAULT 0.00 COMMENT '总订单金额',
  `order_success_count` bigint(20) NULL DEFAULT 0 COMMENT '成功的订单数',
  `order_success_sum` double(11, 2) NULL DEFAULT 0.00 COMMENT '成功订单总金额',
  `order_fail_count` bigint(20) NULL DEFAULT 0 COMMENT '失败订单数',
  `order_fail_sum` double(11, 2) NULL DEFAULT 0.00 COMMENT '失败订单总金额',
  `order_success_user` bigint(20) NULL DEFAULT 0 COMMENT '充值成功人数',
  `tax` bigint(20) NULL DEFAULT 0 COMMENT '平台税收',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '平台信息综合统计明细表' ROW_FORMAT = Fixed;

-- ----------------------------
-- Table structure for propel_migration
-- ----------------------------
DROP TABLE IF EXISTS `propel_migration`;
CREATE TABLE `propel_migration`  (
  `version` int(11) NULL DEFAULT 0
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of propel_migration
-- ----------------------------
INSERT INTO `propel_migration` VALUES (1501922049);
INSERT INTO `propel_migration` VALUES (1501922770);
INSERT INTO `propel_migration` VALUES (1501922929);

-- ----------------------------
-- Table structure for quick_reply
-- ----------------------------
DROP TABLE IF EXISTS `quick_reply`;
CREATE TABLE `quick_reply`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `content` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `type` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `location` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `status` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `created_at` datetime(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  `updated_at` datetime(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of quick_reply
-- ----------------------------
INSERT INTO `quick_reply` VALUES (2, '测试快速回复', '谢谢你的建议', '提建议', '2', '0', NULL, NULL);

-- ----------------------------
-- Table structure for recharge_transfer
-- ----------------------------
DROP TABLE IF EXISTS `recharge_transfer`;
CREATE TABLE `recharge_transfer`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `guid` int(10) UNSIGNED NOT NULL COMMENT '代理商玩家guid',
  `into_guid` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '收款的玩家guid',
  `transfer_money` bigint(20) NOT NULL DEFAULT 0 COMMENT '转出金额',
  `before_money` bigint(20) NOT NULL DEFAULT 0 COMMENT '代理商转出前身上余额',
  `after_money` bigint(20) NOT NULL DEFAULT 0 COMMENT '代理商转出后身上余额',
  `into_before_money` bigint(20) NOT NULL DEFAULT 0 COMMENT '玩家转入前身上余额',
  `into_after_money` bigint(20) NOT NULL DEFAULT 0 COMMENT '玩家转入后身上余额',
  `ip` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT 'ip',
  `status` tinyint(1) NOT NULL COMMENT '0默认 1成功 2失败',
  `created_at` timestamp(0) NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '充值代理商转出金币记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for recharge_users
-- ----------------------------
DROP TABLE IF EXISTS `recharge_users`;
CREATE TABLE `recharge_users`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '代理商名称',
  `account` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '代理商账号',
  `password` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '代理商密码',
  `tax` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '代理商充值比例',
  `guid` int(10) UNSIGNED NOT NULL COMMENT '玩家id',
  `phone` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '代理商手机号码',
  `weixin` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '代理商微信号',
  `qq` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '代理商QQ',
  `transfer_money` bigint(20) NOT NULL DEFAULT 0 COMMENT '转出总金额',
  `admin` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '创建代理的管理员账号',
  `ip` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '最后登录ip',
  `created_at` timestamp(0) NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `users_account_unique`(`account`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 2 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '充值代理商登陆表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of recharge_users
-- ----------------------------
INSERT INTO `recharge_users` VALUES (1, '郭欣', 'guoxin', 'e10adc3949ba59ab', '1.0', 5, '18508230918', 'guoxin', '6514791', 0, 'gx', '', '2017-08-15 10:31:53', '2017-08-15 10:31:53');

-- ----------------------------
-- Table structure for role_user
-- ----------------------------
DROP TABLE IF EXISTS `role_user`;
CREATE TABLE `role_user`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `role_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `role_user_role_id_index`(`role_id`) USING BTREE,
  INDEX `role_user_user_id_index`(`user_id`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 12 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Fixed;

-- ----------------------------
-- Records of role_user
-- ----------------------------
INSERT INTO `role_user` VALUES (1, 1, 1, '2016-11-16 16:00:23', '2016-11-16 16:00:23');
INSERT INTO `role_user` VALUES (8, 1, 2, NULL, NULL);
INSERT INTO `role_user` VALUES (9, 5, 3, '2017-07-13 18:11:39', NULL);
INSERT INTO `role_user` VALUES (10, 5, 4, '2017-07-13 18:11:49', NULL);
INSERT INTO `role_user` VALUES (11, 3, 5, '2017-09-09 13:48:44', NULL);

-- ----------------------------
-- Table structure for roles
-- ----------------------------
DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `slug` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `description` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `level` int(11) NOT NULL DEFAULT 1,
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `roles_slug_unique`(`slug`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 4 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of roles
-- ----------------------------
INSERT INTO `roles` VALUES (1, '超级管理员', 'admin', '超级管理员', 1, '2016-11-16 16:00:22', '2017-09-09 14:48:14');
INSERT INTO `roles` VALUES (2, 'cs', 'cs', '', 1, '2017-07-29 11:48:54', '2017-07-29 11:48:54');
INSERT INTO `roles` VALUES (3, '充值代理', 'agent', '充值代理人员', 1, '2017-09-09 13:48:11', '2017-09-09 13:50:27');

-- ----------------------------
-- Table structure for sms
-- ----------------------------
DROP TABLE IF EXISTS `sms`;
CREATE TABLE `sms`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `phone` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '手机号',
  `code` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '验证码',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0默认 1成功 2失败',
  `return` varchar(2000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '短信第三方返回值',
  `created_at` timestamp(0) NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 31 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '短信验证码记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sms
-- ----------------------------
INSERT INTO `sms` VALUES (1, '18508230918', '1234', 0, '', '2017-07-15 15:46:46', '2017-07-15 15:46:46');
INSERT INTO `sms` VALUES (2, '18508230918', '1234', 0, '', '2017-07-15 16:07:53', '2017-07-15 16:07:53');
INSERT INTO `sms` VALUES (3, '18508230918', '1234', 0, '', '2017-07-15 16:09:15', '2017-07-15 16:09:15');
INSERT INTO `sms` VALUES (4, '18508230918', '1234', 0, '', '2017-07-15 16:09:17', '2017-07-15 16:09:17');
INSERT INTO `sms` VALUES (5, '18508230918', '1234', 0, '', '2017-07-15 16:09:25', '2017-07-15 16:09:25');
INSERT INTO `sms` VALUES (6, '18508230918', '1234', 0, '', '2017-07-15 16:10:36', '2017-07-15 16:10:36');
INSERT INTO `sms` VALUES (7, '18508230918', '1234', 0, '', '2017-07-15 16:13:07', '2017-07-15 16:13:07');
INSERT INTO `sms` VALUES (8, '18508230918', '1234', 0, '', '2017-07-15 16:19:31', '2017-07-15 16:19:31');
INSERT INTO `sms` VALUES (9, '18508230918', '1234', 0, '', '2017-07-15 16:20:09', '2017-07-15 16:20:09');
INSERT INTO `sms` VALUES (10, '18508230918', '1234', 1, '', '2017-07-15 16:23:31', '2017-07-15 16:23:31');
INSERT INTO `sms` VALUES (11, '18200290361', '467041', 1, '', '2017-07-17 09:48:07', '2017-07-17 09:48:07');
INSERT INTO `sms` VALUES (12, '18508230918', '1234', 0, '', '2017-07-19 15:03:52', '2017-07-19 15:03:52');
INSERT INTO `sms` VALUES (13, '18508230918', '1234', 0, '', '2017-07-19 15:05:30', '2017-07-19 15:05:30');
INSERT INTO `sms` VALUES (14, '18508230918', '1234', 0, '', '2017-07-19 15:06:31', '2017-07-19 15:06:31');
INSERT INTO `sms` VALUES (15, '18508230918', '1234', 0, '', '2017-07-19 15:07:19', '2017-07-19 15:07:19');
INSERT INTO `sms` VALUES (16, '18508230918', '1234', 0, '', '2017-07-19 15:09:25', '2017-07-19 15:09:25');
INSERT INTO `sms` VALUES (17, '18508230918', '1234', 0, '', '2017-07-19 15:09:59', '2017-07-19 15:09:59');
INSERT INTO `sms` VALUES (18, '18508230918', '1234', 0, '', '2017-07-19 15:10:00', '2017-07-19 15:10:00');
INSERT INTO `sms` VALUES (19, '18508230918', '1234', 0, '', '2017-07-19 15:13:11', '2017-07-19 15:13:11');
INSERT INTO `sms` VALUES (20, '18508230918', '1234', 0, '', '2017-07-19 15:14:04', '2017-07-19 15:14:04');
INSERT INTO `sms` VALUES (21, '18508230918', '1234', 0, '', '2017-07-19 15:34:09', '2017-07-19 15:34:09');
INSERT INTO `sms` VALUES (22, '18508230918', '1234', 0, '', '2017-07-19 15:34:44', '2017-07-19 15:34:44');
INSERT INTO `sms` VALUES (23, '18508230918', '1234', 0, '', '2017-07-19 15:35:21', '2017-07-19 15:35:21');
INSERT INTO `sms` VALUES (24, '18508230918', '1234', 1, '', '2017-07-19 15:45:48', '2017-07-19 07:45:48');
INSERT INTO `sms` VALUES (25, '18508230918', '1234', 1, '', '2017-07-19 15:46:43', '2017-07-19 15:46:45');
INSERT INTO `sms` VALUES (26, '15983690975', '724169', 1, '', '2017-07-27 15:52:58', '2017-07-27 07:52:59');
INSERT INTO `sms` VALUES (27, '18224467200', '358478', 1, '', '2017-07-27 15:54:12', '2017-07-27 07:54:13');
INSERT INTO `sms` VALUES (28, '18224467200', '464962', 1, '', '2017-07-27 16:56:49', '2017-07-27 08:56:50');
INSERT INTO `sms` VALUES (29, '18224467200', '467041', 1, '', '2017-07-28 10:32:49', '2017-07-28 02:32:49');
INSERT INTO `sms` VALUES (30, '18224467200', '500334', 1, '', '2017-07-28 12:01:25', '2017-07-28 04:01:25');

-- ----------------------------
-- Table structure for transfer_to_agent_history
-- ----------------------------
DROP TABLE IF EXISTS `transfer_to_agent_history`;
CREATE TABLE `transfer_to_agent_history`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `agent_id` int(11) NOT NULL,
  `money` int(11) NOT NULL COMMENT '转账金额',
  `before_money` int(11) NULL DEFAULT NULL COMMENT '转账前金额',
  `after_money` int(11) NULL DEFAULT NULL COMMENT '转账后金额',
  `remarks` VARCHAR(50) NULL COMMENT '备注',
  `created_at` datetime(0) NULL DEFAULT NULL,
  `updated_at` datetime(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of transfer_to_agent_history
-- ----------------------------
INSERT INTO `transfer_to_agent_history` VALUES (1, 1, 100000, 0, 100000,null, '2017-09-11 13:34:21', '2017-09-11 13:34:21');
INSERT INTO `transfer_to_agent_history` VALUES (2, 1, 100000, 100000, 200000,null, '2017-09-11 13:34:37', '2017-09-11 13:34:37');

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `email` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `password` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `remember_token` varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `users_email_unique`(`email`) USING BTREE
) ENGINE = MyISAM AUTO_INCREMENT = 7 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of users
-- ----------------------------
INSERT INTO `users` VALUES (1, 'admin', 'admin@admin.com', '$2y$10$pYtEfW5QWKsQoBIDTGq14.mS4WXz1AMPgc/MXwS6cA4EM9aKhOmMG', 'sRgeda3zTQO3FpgEsS5tlXhOynbZ7wMW0TDYp8Uh8LGVuZgk2dmp2jQmNyam', '2017-02-07 15:59:30', '2017-03-13 17:43:18');
INSERT INTO `users` VALUES (2, 'gx', 'gx', '$2y$10$D9/Mi9znz86jphOjaMD./.gnxT8kFxFWmBrmd33JrJe7A/Tctiu46', '6gxwFt424bxXeppErJs9L7XzFV83HKy8ssbQbD86Z9LEMw66ct07i0ZBO9QB', NULL, '2017-09-13 18:22:51');

SET FOREIGN_KEY_CHECKS=1;

