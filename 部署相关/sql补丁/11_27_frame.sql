/*
SQLyog Ultimate v12.09 (64 bit)
MySQL - 5.7.17-log : Database - frame
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`frame` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `frame`;

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

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
