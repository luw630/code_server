/*
SQLyog Ultimate v12.09 (64 bit)
MySQL - 5.7.17-log : Database - log
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`log` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `log`;

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

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
