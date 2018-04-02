/*
SQLyog Ultimate v12.09 (64 bit)
MySQL - 5.7.17-log : Database - game
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`game` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `game`;

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

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
