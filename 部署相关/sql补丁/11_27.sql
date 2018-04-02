use log;
DROP TABLE IF EXISTS `t_log_agent_money`;
CREATE TABLE `t_log_agent_money` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `total_money` varchar(32) NOT NULL COMMENT '当日所有代理总金额',
  `created_at` date DEFAULT NULL COMMENT '统计日期',
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
