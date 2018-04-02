USE `log`;
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
) ENGINE=MyISAM AUTO_INCREMENT=84 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='库存统计表'