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

/*Table structure for table `t_log_count` */

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

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
