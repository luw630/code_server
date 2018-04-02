USE `account`;
set global log_bin_trust_function_creators=TRUE;
DROP FUNCTION IF EXISTS `get_guest_id`;
DELIMITER ;;
CREATE FUNCTION `get_guest_id`() RETURNS bigint(20)
BEGIN
	DECLARE ret INT DEFAULT 0;
	REPLACE INTO t_guest_id SET id_key = 0;
	#RETURN LAST_INSERT_ID();
	SELECT MAX(guid) INTO ret FROM t_account;
	RETURN ret - 25000 + 1;
END
;;
