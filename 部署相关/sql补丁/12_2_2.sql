USE `frame`;
CREATE TABLE `complaints` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `account` varchar(100) DEFAULT '' COMMENT '玩家账号',
  `agent_id` int(10) DEFAULT NULL COMMENT '被投诉代理/客服ID',
  `type` tinyint(2) NOT NULL DEFAULT '0' COMMENT '0投诉客服 1投诉代理',
  `product` varchar(255) NOT NULL DEFAULT '' COMMENT '投诉所属产品 万豪 GG 王者 麻将 乐游',
  `content` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '投诉内容',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=12 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='投诉表'
