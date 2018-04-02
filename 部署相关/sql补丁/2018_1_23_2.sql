use game;
CREATE TABLE `t_brnn_chi_cfg` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `game_id` int(11) unsigned NOT NULL COMMENT '游戏id',
  `begin_range` int(11) NOT NULL COMMENT '开始区间',
  `end_range` int(11) NOT NULL COMMENT '结束区间',
  `range_prob` int(11) NOT NULL COMMENT '概率',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

insert into t_brnn_chi_cfg(game_id, begin_range, end_range, range_prob) value('50','0','500000','5');
insert into t_brnn_chi_cfg(game_id, begin_range, end_range, range_prob) value('50','500000','1000000','3');
insert into t_brnn_chi_cfg(game_id, begin_range, end_range, range_prob) value('51','0','500000','5');
insert into t_brnn_chi_cfg(game_id, begin_range, end_range, range_prob) value('51','500000','1000000','3');