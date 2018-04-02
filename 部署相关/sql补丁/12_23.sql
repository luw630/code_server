alter table log.t_log_login modify column login_time timestamp;
ALTER TABLE log.t_log_play_keep CHANGE registered registered INT(11) NOT NULL COMMENT '注册数';
