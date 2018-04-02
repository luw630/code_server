USE account;
CREATE TABLE t_channel_payagent (
  id bigint(20) unsigned NOT NULL AUTO_INCREMENT ,
  uid varchar(64) NOT NULL DEFAULT '' COMMENT '渠道id',
  agent_id int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '代理id',
  orders int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT '排序',
  status int(10) UNSIGNED NOT NULL DEFAULT '1' COMMENT '状态',
  PRIMARY KEY (id),
  KEY uid (uid),KEY agent_id (agent_id)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='渠道充值代理列表';