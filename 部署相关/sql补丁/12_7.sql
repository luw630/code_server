USE `recharge`;
ALTER TABLE t_cash_black_list ADD STATUS VARCHAR(255) DEFAULT NULL DEFAULT "" AFTER deleted_at;
ALTER TABLE t_cash_black_list ADD order_id VARCHAR(255) DEFAULT NULL DEFAULT "" COMMENT '订单号' AFTER deleted_at;