USE `frame`;
CREATE TABLE customer_chat (
  id int(11) NOT NULL AUTO_INCREMENT COMMENT '会话ID',
  cs_id int(11) NOT NULL COMMENT '客服ID',
  guid int(11) NOT NULL COMMENT '用户ID',
  created_at timestamp NULL DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;


CREATE TABLE customer_msg (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  chat_id int(10) unsigned NOT NULL COMMENT '会话id',
  username varchar(100) DEFAULT '' COMMENT '玩家昵称',
  account varchar(100) DEFAULT '' COMMENT '玩家账号',
  is_read tinyint(2) NOT NULL DEFAULT '0' COMMENT '0未读 1已读',
  type tinyint(2) NOT NULL DEFAULT '0' COMMENT '0玩家发送 1客服发送',
  content varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '消息内容',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='消息表';


CREATE TABLE customer_service (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  name varchar(255) NOT NULL,
  email varchar(255) NOT NULL,
  password varchar(255) NOT NULL,
  is_online int(11) NOT NULL DEFAULT '0' COMMENT '是否在线',
  created_at timestamp NULL DEFAULT NULL,
  updated_at timestamp NULL DEFAULT NULL,
  PRIMARY KEY (id) USING BTREE,
  UNIQUE KEY users_email_unique (email) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;