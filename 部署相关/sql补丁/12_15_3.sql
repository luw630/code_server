USE `account`;
ALTER TABLE t_channel_form ADD profit double(9,2) NOT NULL DEFAULT '0.00' AFTER chargeType;