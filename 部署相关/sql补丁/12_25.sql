USE `account`;

DROP PROCEDURE IF EXISTS `create_guest_account`;
CREATE PROCEDURE `create_guest_account`(IN `phone_` varchar(256), IN `phone_type_` varchar(256), IN `version_` varchar(256), IN `channel_id_` varchar(256), IN `package_name_` varchar(256), IN `imei_` varchar(256), IN `ip_` varchar(256))
    COMMENT '创建游客账号'
BEGIN
	DECLARE guest_id_ BIGINT;

	DECLARE ret INT DEFAULT 0;
	DECLARE guid_ INT DEFAULT 0;
	DECLARE account_ VARCHAR(64) DEFAULT '0';
	DECLARE no_bank_password INT DEFAULT 0;
	DECLARE vip_ INT DEFAULT 0;
	DECLARE login_time_ INT;
	DECLARE logout_time_ INT;
	DECLARE is_guest_ INT DEFAULT 0;
	DECLARE nickname_ VARCHAR(32) DEFAULT '0';
	DECLARE password_ VARCHAR(32) DEFAULT '0';
	DECLARE alipay_account_ VARCHAR(32) DEFAULT '0';
	DECLARE alipay_name_ VARCHAR(32) DEFAULT '0';
	DECLARE change_alipay_num_ INT DEFAULT 0;
	DECLARE disabled_ INT DEFAULT 0;
	DECLARE risk_ INT DEFAULT 0;
	DECLARE enable_transfer_ INT DEFAULT 0;
	DECLARE is_first INT DEFAULT 1;
	DECLARE channel_lock_ INT DEFAULT 0;
	DECLARE exit_flag_ INT DEFAULT 0;

	SELECT guid, account, ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, password, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer INTO guid_, account_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, password_, alipay_account_, alipay_name_, change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_ FROM t_account WHERE imei = imei_;
	IF guid_ = 0 THEN
		SET guid_ = get_guest_id();

		SET account_ = CONCAT("玩家", guid_+25000);
		SELECT guid INTO exit_flag_ FROM t_account WHERE account=account_ or nickname=account_;
		IF exit_flag_ != 0 THEN
			SET account_ = CONCAT(account_, "A");
		END IF;
		
		SET password_ = MD5(account_);
		SET nickname_ = account_;#CONCAT("玩家", guid_+25000);

		SELECT channel_lock INTO channel_lock_ FROM t_channel_invite WHERE channel_id=channel_id_ AND big_lock=1;
		IF channel_lock_ != 1 THEN
			SET is_first = 1;#SET is_first = 2;
		END IF;

		INSERT INTO t_account (account,password,is_guest,nickname,create_time,phone,phone_type,version,channel_id,package_name,imei,ip,invite_code) VALUES (account_,password_,1,nickname_,NOW(),phone_,phone_type_,version_,channel_id_,package_name_,imei_,ip_,HEX(guid_));
		SELECT guid, account, ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, password, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer INTO guid_, account_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, password_, alipay_account_, alipay_name_, change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_ FROM t_account WHERE imei = imei_;
	ELSE
		SET is_first = 2;
		IF disabled_ = 1 THEN
			SET ret = 15;
		ELSE
			UPDATE t_account SET login_count = login_count+1 WHERE guid=guid_;
		END IF;
	END IF;
		
	SELECT is_first,ret, guid_ as guid, account_ as account, no_bank_password, vip_ as vip, IFNULL(login_time_, 0) as login_time, IFNULL(logout_time_, 0) as logout_time, nickname_ as nickname, is_guest_ as is_guest, password_ as password, alipay_account_ as alipay_account, alipay_name_ as alipay_name, change_alipay_num_ as change_alipay_num, risk_ as risk, channel_id_ as channel_id, enable_transfer_ as enable_transfer;
END
;;
