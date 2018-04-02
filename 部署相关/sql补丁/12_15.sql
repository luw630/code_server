USE `account`;
ALTER TABLE t_channel_account ADD tax_buckle int(11) NOT NULL DEFAULT "100" AFTER CommissionRate;
ALTER TABLE t_channel_account ADD tax_display tinyint(1) NOT NULL DEFAULT "0" AFTER CommissionRate;