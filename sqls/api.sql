DROP DATABASE if exists `api`;
CREATE DATABASE `api` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `api`;

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for action_log
-- ----------------------------
DROP TABLE IF EXISTS `action_log`;
CREATE TABLE `action_log` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `table` varchar(255) NOT NULL DEFAULT '' COMMENT '表名字',
  `table_id` varchar(255) NOT NULL DEFAULT '0' COMMENT '记录的主键',
  `description` varchar(255) NOT NULL DEFAULT '' COMMENT '描述',
  `old_json` varchar(2000) NOT NULL DEFAULT '' COMMENT '修改之前的数据',
  `new_json` varchar(2000) NOT NULL DEFAULT '' COMMENT '修改之后的数据',
  `username` varchar(255) NOT NULL DEFAULT '' COMMENT '审核人',
  `account` varchar(255) NOT NULL DEFAULT '' COMMENT '审核人账号',
  `ip` char(15) NOT NULL DEFAULT '' COMMENT 'IP',
  `url` varchar(255) NOT NULL DEFAULT '' COMMENT '操作的url',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='后台操作日志表';

-- ----------------------------
-- Records of action_log
-- ----------------------------

-- ----------------------------
-- Table structure for menus
-- ----------------------------
DROP TABLE IF EXISTS `menus`;
CREATE TABLE `menus` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `pid` int(11) NOT NULL DEFAULT '0' COMMENT '菜单关系',
  `name` varchar(255) NOT NULL DEFAULT '' COMMENT '菜单名称',
  `icon` varchar(255) NOT NULL DEFAULT '' COMMENT '图标',
  `slug` varchar(255) NOT NULL DEFAULT '' COMMENT '菜单对应的权限',
  `url` varchar(255) NOT NULL DEFAULT '' COMMENT '菜单链接地址',
  `active` varchar(255) NOT NULL DEFAULT '' COMMENT '菜单高亮地址',
  `description` varchar(255) NOT NULL DEFAULT '' COMMENT '描述',
  `sort` tinyint(4) NOT NULL DEFAULT '0' COMMENT '排序',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of menus
-- ----------------------------
INSERT INTO `menus` VALUES ('1', '0', '控制台', 'fa fa-dashboard', 'index.index', 'index/index', 'index/index', '后台首页', '0', null, null);
INSERT INTO `menus` VALUES ('2', '0', '系统管理', 'fa fa-cog', 'system.*', '#', 'users/*,roles/*,permissions/*,log/*,gameConfig/*', '系统功能管理', '0', null, null);
INSERT INTO `menus` VALUES ('3', '2', '用户管理', '', 'users.index', 'users/index', 'users/*', '显示用户管理', '0', null, null);
INSERT INTO `menus` VALUES ('4', '2', '角色管理', '', 'roles.index', 'roles/index', 'roles/*', '显示角色管理', '0', null, null);
INSERT INTO `menus` VALUES ('5', '2', '权限管理', '', 'permissions.index', 'permissions/index', 'permissions/*', '显示权限管理', '0', null, null);
INSERT INTO `menus` VALUES ('8', '0', '客户端设置', 'fa fa-cogs', 'clientConfig.*', '#', 'version/*,client/*,', '客户端功能设置', '0', null, null);
INSERT INTO `menus` VALUES ('9', '8', '框架版本列表', '', 'version.frame', 'version/frame', 'version/frame', '框架版本列表', '0', null, null);
INSERT INTO `menus` VALUES ('10', '8', '大厅版本列表', '', 'version.hall', 'version/hall', 'version/hall', '大厅版本列表', '0', null, null);
INSERT INTO `menus` VALUES ('11', '8', '游戏版本列表', '', 'version.game', 'version/game', 'version/game', '游戏版本列表', '0', null, null);
INSERT INTO `menus` VALUES ('12', '8', '渠道配置列表', '', 'client.channelList', 'client/channelList', 'client/viewConfig,client/listConfig,client/channelList', '客户端配置', '0', null, null);
INSERT INTO `menus` VALUES ('13', '8', '模板配置列表', '', 'client.template', 'client/template', 'client/template,client/templateCreate,client/templateConfigCreate', '配置模板列表', '0', null, null);
INSERT INTO `menus` VALUES ('14', '8', '清除配置缓存', '', 'client.channelCacheList', 'client/channelCacheList', 'client/channelCacheList', '清除配置缓存', '0', null, null);

-- ----------------------------
-- Table structure for migrations
-- ----------------------------
DROP TABLE IF EXISTS `migrations`;
CREATE TABLE `migrations` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of migrations
-- ----------------------------
INSERT INTO `migrations` VALUES ('1', '2014_10_12_000000_create_users_table', '1');
INSERT INTO `migrations` VALUES ('2', '2014_10_12_100000_create_password_resets_table', '1');
INSERT INTO `migrations` VALUES ('3', '2015_01_15_105324_create_roles_table', '1');
INSERT INTO `migrations` VALUES ('4', '2015_01_15_114412_create_role_user_table', '1');
INSERT INTO `migrations` VALUES ('5', '2015_01_26_115212_create_permissions_table', '1');
INSERT INTO `migrations` VALUES ('6', '2015_01_26_115523_create_permission_role_table', '1');
INSERT INTO `migrations` VALUES ('7', '2015_02_09_132439_create_permission_user_table', '1');
INSERT INTO `migrations` VALUES ('8', '2016_11_03_173731_create_menus_table', '1');

-- ----------------------------
-- Table structure for password_resets
-- ----------------------------
DROP TABLE IF EXISTS `password_resets`;
CREATE TABLE `password_resets` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  KEY `password_resets_email_index` (`email`),
  KEY `password_resets_token_index` (`token`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for permissions
-- ----------------------------
DROP TABLE IF EXISTS `permissions`;
CREATE TABLE `permissions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `model` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `permissions_slug_unique` (`slug`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of permissions
-- ----------------------------
INSERT INTO `permissions` VALUES ('1', '后台首页显示', 'index.index', '后台首页', null, null, null);
INSERT INTO `permissions` VALUES ('2', '系统管理显示', 'system.*', '系统管理', null, null, null);
INSERT INTO `permissions` VALUES ('3', '角色列表显示', 'roles.index', '角色列表', null, null, null);
INSERT INTO `permissions` VALUES ('4', '权限列表显示', 'permissions.index', '显示权限列表', null, null, null);
INSERT INTO `permissions` VALUES ('5', '用户列表显示', 'users.index', '用户列表', null, null, null);
INSERT INTO `permissions` VALUES ('6', '用户创建显示', 'users.create', '用户创建显示', null, null, null);
INSERT INTO `permissions` VALUES ('7', '用户创建功能', 'users.store', '用户创建功能', null, null, null);
INSERT INTO `permissions` VALUES ('8', '用户修改显示', 'users.edit', '用户修改页面', null, null, null);
INSERT INTO `permissions` VALUES ('9', '用户修改功能', 'users.update', '用户修改功能', null, null, null);
INSERT INTO `permissions` VALUES ('10', '用户删除功能', 'users.destroy', '用户删除功能', null, null, null);
INSERT INTO `permissions` VALUES ('11', '用户重置密码功能', 'users.resetPassword', '用户重置密码功能', null, null, null);
INSERT INTO `permissions` VALUES ('12', '客户端设置显示', 'clientConfig.*', '客户端设置', null, null, null);
INSERT INTO `permissions` VALUES ('13', '大厅版本显示', 'version.hall', '大厅版本', null, null, null);
INSERT INTO `permissions` VALUES ('14', '框架版本显示', 'version.frame', '框架版本', null, null, null);
INSERT INTO `permissions` VALUES ('15', '游戏版本显示', 'version.game', '游戏版本', null, null, null);
INSERT INTO `permissions` VALUES ('16', '客户端具体配置显示', 'client.listConfig', '客户端具体配置显示', null, null, null);
INSERT INTO `permissions` VALUES ('17', '用户信息查看显示', 'users.show', '用户信息查看显示', null, null, null);
INSERT INTO `permissions` VALUES ('18', '角色列表功能', 'roles.ajaxIndex', '角色列表功能', null, null, null);
INSERT INTO `permissions` VALUES ('19', '角色创建显示', 'roles.create', '角色创建显示', null, null, null);
INSERT INTO `permissions` VALUES ('20', '角色创建功能', 'roles.store', '角色创建功能', null, null, null);
INSERT INTO `permissions` VALUES ('21', '角色详情显示', 'roles.show', '角色详情显示', null, null, null);
INSERT INTO `permissions` VALUES ('22', '角色修改显示', 'roles.edit', '角色修改显示', null, null, null);
INSERT INTO `permissions` VALUES ('23', '角色修改功能', 'roles.update', '角色修改功能', null, null, null);
INSERT INTO `permissions` VALUES ('24', '权限列表功能', 'permissions.ajaxIndex', '权限列表功能', null, null, null);
INSERT INTO `permissions` VALUES ('25', '权限修改显示', 'permissions.edit', '权限修改显示', null, null, null);
INSERT INTO `permissions` VALUES ('26', '权限修改功能', 'permissions.update', '权限修改功能', null, null, null);
INSERT INTO `permissions` VALUES ('27', '权限创建显示', 'permissions.create', '权限创建显示', null, null, null);
INSERT INTO `permissions` VALUES ('28', '权限创建功能', 'permissions.store', '权限创建功能', null, null, null);
INSERT INTO `permissions` VALUES ('29', '客户端配置创建显示', 'client.viewConfig', '客户端配置创建显示', null, null, null);
INSERT INTO `permissions` VALUES ('30', '客户端配置创建功能', 'client.addConfig', '客户端配置创建功能', null, null, null);
INSERT INTO `permissions` VALUES ('31', '客户端配置列表功能', 'client.ajaxConfig', '客户端配置列表功能', null, null, null);
INSERT INTO `permissions` VALUES ('32', '客户端配置删除功能', 'client.deleteConfig', '客户端配置删除功能', null, null, null);
INSERT INTO `permissions` VALUES ('33', '客户端配置批量删除功能', 'client.deleteAll', '客户端配置批量删除功能', null, null, null);
INSERT INTO `permissions` VALUES ('34', '语言包', 'index.dash', '语言包', null, null, null);
INSERT INTO `permissions` VALUES ('35', '客户端版本创建显示', 'version.view', '客户端版本创建显示', null, null, null);
INSERT INTO `permissions` VALUES ('36', '客户端版本创建功能', 'version.add', '客户端版本创建功能', null, null, null);
INSERT INTO `permissions` VALUES ('37', '客户端版本列表功能', 'version.ajaxVersion', '客户端版本列表功能', null, null, null);
INSERT INTO `permissions` VALUES ('38', '客户端版本删除功能', 'version.delete', '客户端版本删除功能', null, null, null);
INSERT INTO `permissions` VALUES ('39', '客户端配置模板', 'client.template', '客户端配置模板', null, null, null);
INSERT INTO `permissions` VALUES ('40', '清除缓存配置页面', 'client.channelCacheList', '清除缓存配置页面', null, null, null);
INSERT INTO `permissions` VALUES ('41', '清除缓存配置功能', 'client.channelCacheClear', '清除缓存配置功能', null, null, null);
INSERT INTO `permissions` VALUES ('42', '客户端渠道配置列表', 'client.channelList', '客户端渠道配置列表', null, null, null);
INSERT INTO `permissions` VALUES ('43', '客户端渠道配置列表数据', 'client.ajaxChannelList', '客户端渠道配置列表数据', null, null, null);
INSERT INTO `permissions` VALUES ('44', '客户端渠道列表删除', 'client.deleteChannel', '客户端渠道列表删除', null, null, null);

-- ----------------------------
-- Table structure for permission_role
-- ----------------------------
DROP TABLE IF EXISTS `permission_role`;
CREATE TABLE `permission_role` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `permission_id` int(10) unsigned NOT NULL,
  `role_id` int(10) unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `permission_role_permission_id_index` (`permission_id`),
  KEY `permission_role_role_id_index` (`role_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of permission_role
-- ----------------------------
INSERT INTO `permission_role` VALUES ('1', '1', '1', null, null);
INSERT INTO `permission_role` VALUES ('2', '2', '1', null, null);
INSERT INTO `permission_role` VALUES ('3', '3', '1', null, null);
INSERT INTO `permission_role` VALUES ('4', '4', '1', null, null);
INSERT INTO `permission_role` VALUES ('5', '5', '1', null, null);
INSERT INTO `permission_role` VALUES ('6', '6', '1', null, null);
INSERT INTO `permission_role` VALUES ('7', '7', '1', null, null);
INSERT INTO `permission_role` VALUES ('8', '8', '1', null, null);
INSERT INTO `permission_role` VALUES ('9', '9', '1', null, null);
INSERT INTO `permission_role` VALUES ('10', '10', '1', null, null);
INSERT INTO `permission_role` VALUES ('11', '11', '1', null, null);
INSERT INTO `permission_role` VALUES ('12', '12', '1', null, null);
INSERT INTO `permission_role` VALUES ('13', '13', '1', null, null);
INSERT INTO `permission_role` VALUES ('14', '14', '1', null, null);
INSERT INTO `permission_role` VALUES ('15', '15', '1', null, null);
INSERT INTO `permission_role` VALUES ('16', '16', '1', null, null);
INSERT INTO `permission_role` VALUES ('17', '17', '1', null, null);
INSERT INTO `permission_role` VALUES ('18', '18', '1', null, null);
INSERT INTO `permission_role` VALUES ('19', '19', '1', null, null);
INSERT INTO `permission_role` VALUES ('20', '20', '1', null, null);
INSERT INTO `permission_role` VALUES ('21', '21', '1', null, null);
INSERT INTO `permission_role` VALUES ('22', '22', '1', null, null);
INSERT INTO `permission_role` VALUES ('23', '23', '1', null, null);
INSERT INTO `permission_role` VALUES ('24', '24', '1', null, null);
INSERT INTO `permission_role` VALUES ('25', '25', '1', null, null);
INSERT INTO `permission_role` VALUES ('26', '26', '1', null, null);
INSERT INTO `permission_role` VALUES ('27', '27', '1', null, null);
INSERT INTO `permission_role` VALUES ('28', '28', '1', null, null);
INSERT INTO `permission_role` VALUES ('29', '29', '1', null, null);
INSERT INTO `permission_role` VALUES ('30', '30', '1', null, null);
INSERT INTO `permission_role` VALUES ('31', '31', '1', null, null);
INSERT INTO `permission_role` VALUES ('32', '32', '1', null, null);
INSERT INTO `permission_role` VALUES ('33', '33', '1', null, null);
INSERT INTO `permission_role` VALUES ('34', '34', '1', null, null);
INSERT INTO `permission_role` VALUES ('35', '35', '1', null, null);
INSERT INTO `permission_role` VALUES ('36', '36', '1', null, null);
INSERT INTO `permission_role` VALUES ('37', '37', '1', null, null);
INSERT INTO `permission_role` VALUES ('38', '38', '1', null, null);
INSERT INTO `permission_role` VALUES ('39', '39', '1', null, null);
INSERT INTO `permission_role` VALUES ('40', '40', '1', null, null);
INSERT INTO `permission_role` VALUES ('41', '41', '1', null, null);
INSERT INTO `permission_role` VALUES ('42', '42', '1', null, null);
INSERT INTO `permission_role` VALUES ('43', '43', '1', null, null);
INSERT INTO `permission_role` VALUES ('44', '44', '1', null, null);

-- ----------------------------
-- Table structure for permission_user
-- ----------------------------
DROP TABLE IF EXISTS `permission_user`;
CREATE TABLE `permission_user` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `permission_id` int(10) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `permission_user_permission_id_index` (`permission_id`),
  KEY `permission_user_user_id_index` (`user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of permission_user
-- ----------------------------

-- ----------------------------
-- Table structure for roles
-- ----------------------------
DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `level` int(11) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `roles_slug_unique` (`slug`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of roles
-- ----------------------------
INSERT INTO `roles` VALUES ('1', '超级管理员', 'admin', '超级管理员', '1', '2016-11-16 16:00:22', '2017-03-06 17:10:14');

-- ----------------------------
-- Table structure for role_user
-- ----------------------------
DROP TABLE IF EXISTS `role_user`;
CREATE TABLE `role_user` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `role_id` int(10) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `role_user_role_id_index` (`role_id`),
  KEY `role_user_user_id_index` (`user_id`)
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of role_user
-- ----------------------------
INSERT INTO `role_user` VALUES ('1', '1', '1', '2016-11-16 16:00:23', '2016-11-16 16:00:23');

-- ----------------------------
-- Table structure for t_client_config_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_client_config_cfg`;
CREATE TABLE `t_client_config_cfg` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `channel` text NOT NULL COMMENT '渠道号',
  `version` varchar(255) NOT NULL DEFAULT '' COMMENT '版本号',
  `father` varchar(255) NOT NULL DEFAULT '' COMMENT '父级',
  `key` varchar(500) NOT NULL COMMENT '键名',
  `value` varchar(2000) NOT NULL DEFAULT '' COMMENT '键值',
  `description` varchar(255) NOT NULL DEFAULT '' COMMENT '描述',
  `group`      varchar(255) NOT NULL DEFAULT '' COMMENT '描述',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='客户端配置表';

-- ----------------------------
-- Table structure for t_config_template_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_config_template_cfg`;
CREATE TABLE `t_config_template_cfg` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `father` varchar(255) NOT NULL DEFAULT '' COMMENT '父级',
  `key` varchar(75) NOT NULL COMMENT '键名',
  `value` varchar(2000) NOT NULL DEFAULT '' COMMENT '键值',
  `description` varchar(255) NOT NULL DEFAULT '' COMMENT '描述',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_key_father` (`key`,`father`)
) ENGINE=MyISAM AUTO_INCREMENT=29 DEFAULT CHARSET=utf8 COMMENT='客户端配置模板表';

-- ----------------------------
-- Records of t_config_template_cfg
-- ----------------------------
INSERT INTO `t_config_template_cfg` VALUES (1, 'hall_info', 'addr', '[\"192.168.1.160#7788\"]', 'C++服务器ip', '2017-03-07 17:35:06', '2017-07-12 14:39:17');
INSERT INTO `t_config_template_cfg` VALUES (2, 'config', 'inviter_code', 'true', '邀请码版本', '2017-03-20 18:33:26', '2017-03-24 10:50:44');
INSERT INTO `t_config_template_cfg` VALUES (5, 'config', 'gold_to_money_ratio', '100', '金币兑换成钱的比率', '2017-03-07 17:35:07', NULL);
INSERT INTO `t_config_template_cfg` VALUES (6, 'config', 'exchange_min_remain_money', '6.0', '兑换需要剩余的钱 单位是元', '2017-03-07 17:35:07', NULL);
INSERT INTO `t_config_template_cfg` VALUES (7, 'config', 'exchange_multiple', '50', '兑换的 整数倍配置', '2017-03-07 17:35:07', NULL);
INSERT INTO `t_config_template_cfg` VALUES (8, 'config', 'agents_info', '[{\"qq\":\"63864124\",\"zfb\":\"zfb_1\",\"phone\":\"13666666666\",\"weixin\":\"agents_1\",\"name\":\"代理商1\"},\r\n{\"qq\":\"63864124\",\"zfb\":\"zfb_1\",\"phone\":\"13666666666\",\"weixin\":\"agents_1\",\"name\":\"代理商2\"},\r\n{\"qq\":\"63864124\",\"zfb\":\"zfb_1\",\"phone\":\"13666666666\",\"weixin\":\"agents_1\",\"name\":\"代理商3\"},\r\n{\"qq\":\"63864124\",\"zfb\":\"zfb_1\",\"phone\":\"13666666666\",\"weixin\":\"agents_1\",\"name\":\"代理商4\"},\r\n{\"qq\":\"63864124\",\"zfb\":\"zfb_1\",\"phone\":\"13666666666\",\"weixin\":\"agents_1\",\"name\":\"代理商5\"},\r\n{\"qq\":\"63864124\",\"zfb\":\"zfb_1\",\"phone\":\"13666666666\",\"weixin\":\"agents_1\",\"name\":\"代理商6\"},\r\n{\"qq\":\"63864124\",\"zfb\":\"zfb_1\",\"phone\":\"13666666666\",\"weixin\":\"agents_1\",\"name\":\"代理商7\"},\r\n{\"qq\":\"63864124\",\"zfb\":\"zfb_1\",\"phone\":\"13666666666\",\"weixin\":\"agents_1\",\"name\":\"代理商8\"},\r\n{\"qq\":\"63864124\",\"zfb\":\"zfb_1\",\"phone\":\"13666666666\",\"weixin\":\"agents_1\",\"name\":\"代理商9\"},\r\n{\"qq\":\"63864124\",\"zfb\":\"zfb_1\",\"phone\":\"13666666666\",\"weixin\":\"agents_1\",\"name\":\"代理商10\"},\r\n{\"qq\":\"63864124\",\"zfb\":\"zfb_1\",\"phone\":\"13666666666\",\"weixin\":\"agents_1\",\"name\":\"代理商11\"},\r\n{\"qq\":\"63864124\",\"zfb\":\"zfb_1\",\"phone\":\"13666666666\",\"weixin\":\"agents_1\",\"name\":\"代理商12\"},\r\n{\"qq\":\"63864124\",\"zfb\":\"zfb_1\",\"phone\":\"13666666666\",\"weixin\":\"agents_1\",\"name\":\"代理商13\"},\r\n{\"qq\":\"63864124\",\"zfb\":\"zfb_1\",\"phone\":\"13666666666\",\"weixin\":\"agents_1\",\"name\":\"代理商14\"}]', '充值代理商信息', '2017-03-07 17:35:07', NULL);
INSERT INTO `t_config_template_cfg` VALUES (9, 'config', 'recharge_types', '{\"zfb\":true,\"weixin\":true,\"iospay\":false}', '充值界面显示的类型', '2017-03-07 17:35:07', NULL);
INSERT INTO `t_config_template_cfg` VALUES (10, 'config', 'agents_zhaoshang', ' {\"qq\":[123456,123456,123456,123456],\"weixin\":[\"weixin_1\",\"weixin_1\",\"weixin_1\"]}', '代理招商联系方式', '2017-03-07 17:35:07', NULL);
INSERT INTO `t_config_template_cfg` VALUES (11, 'config', 'personal_center_btns', '[{\"account_bind_view_btn\":true},{\"person_info_view_btn\":true},{\"alipay_bind_view_btn\":true}]', '个人中心界面按钮配置', '2017-03-07 17:35:07', NULL);
INSERT INTO `t_config_template_cfg` VALUES (12, 'client_info', 'server_urls', '[ \"http://192.168.1.116/api/index/index\"]', 'PHP接口', '2017-03-07 17:35:07', '2017-07-12 14:40:02');
INSERT INTO `t_config_template_cfg` VALUES (29, 'logConfig_info', 'logServerAdress', 'http://192.168.1.116:8230', 'log服务器地址', '2017-08-05 17:57:09', '2017-08-05 17:57:09');
INSERT INTO `t_config_template_cfg` VALUES (13, 'client_info', 'channel', 'new_baobo', '客户端渠道号', '2017-03-07 17:35:07', NULL);
INSERT INTO `t_config_template_cfg` VALUES (14, 'client_info', 'version', '1.0.0', '客户端渠道版本号', '2017-03-07 17:35:07', NULL);
INSERT INTO `t_config_template_cfg` VALUES (15, 'client_info', 'is_must_update', 'false', '用于标志是否需要强制更新', '2017-03-07 17:35:08', NULL);
INSERT INTO `t_config_template_cfg` VALUES (16, 'client_info', 'update_url', 'http://127.0.0.1/test/hall.zip', '客户端端包更新地址', '2017-03-07 17:35:08', NULL);
INSERT INTO `t_config_template_cfg` VALUES (17, 'config', 'hall_ui_other_btns_config', '{\"btn_kaifu\":true,\"more_game_back_btn\":true,\"more_game_btn\":true}', '大厅其他按钮配置', '2017-03-07 17:35:08', NULL);
INSERT INTO `t_config_template_cfg` VALUES (18, 'config', 'hall_ui_btns_config', '[{\"btn_account\":true},{\"bank_center_btn\":true},{\"btn_exchange\":true},{\"btn_message\":true},{\"btn_feedback\":true},{\"btn_custom_service\":true},{\"setting_btn\":true},{\"btn_notice\":true}]', '大厅主要按钮功能 开关配置', '2017-03-07 17:35:08', NULL);
INSERT INTO `t_config_template_cfg` VALUES (19, 'config', 'custom_service_url', 'http://baidu.com', '客服url配置', '2017-03-07 17:35:08', NULL);
INSERT INTO `t_config_template_cfg` VALUES (20, 'config', 'feedback_create_url', 'http://127.0.0.1/api/feedback/create', '反馈创建url配置', '2017-03-07 17:35:08', NULL);
INSERT INTO `t_config_template_cfg` VALUES (21, 'config', 'feedback_login_url', 'http://127.0.0.1/api/feedback/loginInit', '反馈登录url', '2017-03-07 17:35:08', NULL);
INSERT INTO `t_config_template_cfg` VALUES (22, 'config', 'feedback_list_url', 'http://127.0.0.1/api/feedback/messageList', '反馈列表url', '2017-03-07 17:35:08', NULL);
INSERT INTO `t_config_template_cfg` VALUES (28, 'config', 'pay_url', '{\"ios_create_order\":\"http://127.0.0.1/api/apple/store\",\"ios_query_order\":\"http://127.0.0.1/api/apple/apple_pay\",\"web_create_order\":\"http://127.0.0.1/api/pay/store\",\"web_query_order\":\"http://127.0.0.1/api/pay/show\"}', '支付URL', '2017-03-08 17:11:13', '2017-03-08 17:11:13');
INSERT INTO `t_config_template_cfg` VALUES (30, 'logConfig_info', 'writeLog', 'true', '是否记录日志', '2017-08-05 17:57:27', '2017-08-05 17:57:27');
INSERT INTO `t_config_template_cfg` VALUES (31, 'logConfig_info', 'UploadLog', 'false', '是否上传日志', '2017-08-05 17:57:40', '2017-08-05 17:57:40');
INSERT INTO `t_config_template_cfg` VALUES (32, 'logConfig_info', 'dialogLog', 'false', '回话Log', '2017-08-05 17:58:11', '2017-08-05 17:58:11');
INSERT INTO `t_config_template_cfg` VALUES (33, 'logConfig_info', 'OpenHydump', 'true', 'OpenHydump', '2017-08-05 17:58:25', '2017-08-08 19:26:38');
INSERT INTO `t_config_template_cfg` VALUES (34, 'logConfig_info', 'logfileSize', '20480', 'logfileSize', '2017-08-05 17:58:38', '2017-08-08 19:26:44');
INSERT INTO `t_config_template_cfg` VALUES (35, 'logConfig_info', 'logfileName', 'hygame.log', 'logfileName', '2017-08-05 17:58:47', '2017-08-08 19:26:49');
INSERT INTO `t_config_template_cfg` VALUES (36, 'config', 'only_show_agent_recharge_url', 'http://192.168.1.116/sn/index', '判断是否只展示代理', '2017-09-16 19:22:40', '2017-09-16 19:22:40');

-- ----------------------------
-- Table structure for t_frame_version_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_frame_version_cfg`;
CREATE TABLE `t_frame_version_cfg` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `version` varchar(255) NOT NULL DEFAULT '' COMMENT '版本号',
  `channel` text NOT NULL COMMENT '渠道号',
  `update_url` varchar(255) NOT NULL DEFAULT '' COMMENT '下载地址',
  `describe` varchar(255) NOT NULL DEFAULT '' COMMENT '框架更新说明',
  `filename` varchar(255) NOT NULL DEFAULT '' COMMENT '包文件名字',
  `md5` varchar(50) NOT NULL DEFAULT '' COMMENT '包内容md5加密',
  `size` int(10) NOT NULL DEFAULT '0' COMMENT '包大小',
  `version_code` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_game_version_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_game_version_cfg`;
CREATE TABLE `t_game_version_cfg` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `game_id` int(10) NOT NULL DEFAULT '0' COMMENT '游戏id',
  `channel` text NOT NULL COMMENT '渠道号',
  `game_name` varchar(255) NOT NULL DEFAULT '' COMMENT '游戏名字',
  `version` varchar(255) NOT NULL DEFAULT '' COMMENT '版本号',
  `update_url` varchar(255) NOT NULL DEFAULT '' COMMENT '下载地址',
  `describe` varchar(255) NOT NULL DEFAULT '' COMMENT '游戏更新说明',
  `filename` varchar(255) NOT NULL DEFAULT '' COMMENT '包文件名字',
  `md5` varchar(50) NOT NULL DEFAULT '' COMMENT '包内容md5加密',
  `size` int(10) NOT NULL DEFAULT '0' COMMENT '包大小',
  `version_code` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_hall_version_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_hall_version_cfg`;
CREATE TABLE `t_hall_version_cfg` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `version` varchar(255) NOT NULL DEFAULT '' COMMENT '版本号',
  `channel` text NOT NULL COMMENT '渠道号',
  `update_url` varchar(255) NOT NULL DEFAULT '' COMMENT '下载地址',
  `describe` varchar(255) NOT NULL DEFAULT '' COMMENT '大厅更新说明',
  `filename` varchar(255) NOT NULL DEFAULT '' COMMENT '包文件名字',
  `md5` varchar(50) NOT NULL DEFAULT '' COMMENT '包内容md5加密',
  `size` int(10) NOT NULL DEFAULT '0' COMMENT '包大小',
  `version_code` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of t_hall_version_cfg
-- ----------------------------

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_email_unique` (`email`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of users
-- ----------------------------
INSERT INTO `users` VALUES ('1', 'admin', 'admin@admin.com', '$2y$10$pYtEfW5QWKsQoBIDTGq14.mS4WXz1AMPgc/MXwS6cA4EM9aKhOmMG', 'sRgeda3zTQO3FpgEsS5tlXhOynbZ7wMW0TDYp8Uh8LGVuZgk2dmp2jQmNyam', '2017-02-07 15:59:30', '2017-03-13 17:43:18');
