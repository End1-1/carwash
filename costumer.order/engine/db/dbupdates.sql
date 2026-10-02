/* db - 146 09.03.2024 */
update s_app set f_version='147' where f_app='DB';
ALTER TABLE c_groups ADD COLUMN lu TIMESTAMP;
ALTER TABLE c_goods ADD COLUMN lu TIMESTAMP;
ALTER TABLE c_goods_prices ADD COLUMN lu TIMESTAMP;
ALTER TABLE o_header ADD COLUMN lu TIMESTAMP;
ALTER TABLE a_header ADD COLUMN lu TIMESTAMP;
ALTER TABLE c_units ADD COLUMN lu TIMESTAMP;
ALTER TABLE o_goods ADD COLUMN lu TIMESTAMP;
UPDATE o_goods SET lu='2020-01-01 00:00:00';
ALTER TABLE a_header_cash ADD COLUMN lu TIMESTAMP;
UPDATE a_header_cash SET lu='2020-01-01 08:00:00';
ALTER TABLE a_header_store ADD COLUMN lu TIMESTAMP;
UPDATE a_header_store SET lu='2020-01-01 08:00:00';
ALTER TABLE a_store_draft ADD COLUMN lu TIMESTAMP;
UPDATE a_store_draft SET lu='2020-01-01 08:00:00';
ALTER TABLE a_store ADD COLUMN lu TIMESTAMP;
UPDATE a_store SET lu='2020-01-01 08:00:00';
ALTER TABLE e_cash ADD COLUMN lu TIMESTAMP;
UPDATE e_cash SET lu='2020-01-01 08:00:00';
ALTER TABLE s_user_group ADD COLUMN lu TIMESTAMP;
UPDATE s_user_group SET lu='2020-01-01 08:00:00';
ALTER TABLE s_user ADD COLUMN lu TIMESTAMP;
UPDATE s_user SET lu='2020-01-01 08:00:00';
ALTER TABLE o_tax ADD COLUMN lu TIMESTAMP;
UPDATE o_tax SET lu=CURRENT_TIMESTAMP;
delimiter $$
CREATE TRIGGER c_groups_trigger_bi 
BEFORE INSERT ON c_groups
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER c_groups_trigger_bu 
BEFORE UPDATE ON c_groups
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER c_goods_bi 
BEFORE INSERT ON c_goods
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER c_goods_bu 
BEFORE UPDATE ON c_goods
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER c_goods_prices_trigger_bi 
BEFORE INSERT ON c_goods_prices
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER c_goods_prices_trigger_bu 
BEFORE UPDATE ON c_goods_prices
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER o_header_trigger_bi 
BEFORE INSERT ON o_header
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER o_header_trigger_bu 
BEFORE UPDATE ON o_header
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER a_header_trigger_bi 
BEFORE INSERT ON a_header
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER a_header_trigger_bu 
BEFORE UPDATE ON a_header
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER c_units_trigger_bi 
BEFORE INSERT ON c_units
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER c_units_trigger_bu 
BEFORE UPDATE ON c_units
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER o_goods_trigger_bi 
BEFORE INSERT ON o_goods
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER o_goods_trigger_bu 
BEFORE UPDATE ON o_goods
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER a_header_cash_trigger_bi 
BEFORE INSERT ON a_header_cash
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER a_header_cash_trigger_bu 
BEFORE UPDATE ON a_header_cash
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER a_store_draft_trigger_bi 
BEFORE INSERT ON a_header_cash
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER a_header_cash_trigger_bu 
BEFORE UPDATE ON a_header_cash
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER a_store_trigger_bi 
BEFORE INSERT ON a_store
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER a_store_trigger_bu 
BEFORE UPDATE ON a_store
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER e_cash_trigger_bi 
BEFORE INSERT ON e_cash
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER e_cash_trigger_bu 
BEFORE UPDATE ON e_cash
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER s_user_group_trigger_bi 
BEFORE INSERT ON s_user_group
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER s_user_group_trigger_bu 
BEFORE UPDATE ON s_user_group
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER s_user_trigger_bi 
BEFORE INSERT ON s_user
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER s_user_trigger_bu 
BEFORE UPDATE ON s_user
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER o_tax_trigger_bi 
BEFORE INSERT ON o_tax
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$

CREATE TRIGGER o_tax_trigger_bu 
BEFORE UPDATE ON o_tax
for each row BEGIN
set NEW.lu = CURRENT_TIMESTAMP();
END$$
delimiter ;


UPDATE c_groups SET f_name=f_name;
UPDATE c_goods SET f_name=f_name;
UPDATE c_goods_prices SET f_goods=f_goods;
UPDATE c_units SET f_name=f_name;
CREATE TABLE if not exists s_sync_version (f_id INTEGER PRIMARY KEY AUTO_INCREMENT, f_table TINYTEXT, f_version TIMESTAMP);
DELETE FROM s_sync_version;
INSERT INTO s_sync_version(f_table, f_version) VALUES 
	('s_user_group', '2020-01-01'),
	('s_user', '2020-01-01'),
	('c_units', '2020-01-01'), 
	('c_groups', '2020-01-01'), 
	('c_goods', '2020-01-01'), 
	('c_goods_prices', '2020-01-01'), 
	('o_header', '2020-01-01'), 
	('o_tax', '2020-01-01'),
	('a_header', '2020-01-01'),
	('a_header_cash', '2020-01-01'),
	('o_goods', '2020-01-01'),
	('a_header_store', '2020-01-01'),
	('a_store_draft', '2020-01-01'),
	('a_store', '2020-01-01'),
	('e_cash', '2020-01-01');