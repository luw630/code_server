USE `account`;
ALTER TABLE t_channel_form ADD tax_buckle int(11) NOT NULL DEFAULT "100" AFTER CommissionRate;