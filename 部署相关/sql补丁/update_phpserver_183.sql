USE `config`;
update t_db_server_cfg SET php_interface_addr = 'http://183.60.109.156:8088/api/notice/notice_server'  ;
update t_db_server_cfg SET cash_money_addr = 'http://183.60.109.156:8088/api/index/cash'  ;
update t_gate_server_cfg SET sms_url = 'http://183.60.109.156:8088/api/account/sms' ;
