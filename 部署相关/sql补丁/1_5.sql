USE `log`;
CREATE TABLE t_log_agent_balance (
  id int(11) NOT NULL AUTO_INCREMENT,
  tj_time varchar(10) DEFAULT NULL COMMENT '统计时间',
  recharge text COMMENT '充值',
  balance text COMMENT '余额',
  created_at datetime DEFAULT NULL,
  PRIMARY KEY (id) USING BTREE,
  KEY tj_time (tj_time) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=84 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='代理充值余额统计表'