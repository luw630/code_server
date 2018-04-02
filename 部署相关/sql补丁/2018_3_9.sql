use game;
ALTER TABLE t_player_bank_info ADD COLUMN bank_code varchar(256) NOT NULL DEFAULT '' COMMENT '银行代码' AFTER bank_addr;
use recharge;
ALTER TABLE t_cash ADD COLUMN cash_type int(11) UNSIGNED NOT NULL DEFAULT '1' COMMENT '提现类型';
