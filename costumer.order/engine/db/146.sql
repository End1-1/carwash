/*db - 134, 09.10.2023*/
update s_app set f_version='134' where f_app='DB';
alter table mf_tasks add column f_responsible int after f_workshop;

/*db - 135, 20.10.2023*/
update s_app set f_version='135' where f_app='DB';
alter table o_Header add column f_amountcredit decimal after f_amountbank;

/*db - 136, 24.10.2023*/
update s_app set f_version='136' where f_app='DB';
create table remotedb_sql (f_id integer primary key auto_increment, f_name tinytext, f_sql text);
ALTER TABLE `s_login_session` CHANGE COLUMN `f_session` `f_session` CHAR(36) NULL DEFAULT NULL AFTER `f_id`;
alter table s_salary_inout change column f_id f_id char(36);
UPDATE s_salary_inout SET f_id=UUID();
alter table s_salary_inout add column f_hall integer;
insert into o_draft_sale_state (f_id, f_name) values (6, 'Գրանցված հետվերադարձ');

/*db - 137, 24.10.2023*/
update s_app set f_version='137' where f_app='DB';
alter table o_preorder add column f_guest INT, ADD column f_comment tinytext, add column f_feedback tinytext;
alter table remotedb_sql add column f_type int after f_id;

/*db - 138, 24.10.2023*/
update s_app set f_version='138' where f_app='DB';
CREATE TABLE d_dish_set (f_id INTEGER PRIMARY KEY AUTO_INCREMENT, f_dish INTEGER, f_part INTEGER, f_qty DECIMAL(12,2));
alter table d_part2 add column f_qr tinyint;
alter table a_header_cash change column f_session f_session char(36);

/*db - 139, 13.12.2023*/
update s_app set f_version='139' where f_app='DB';
ALTER TABLE a_store_reserve ADD COLUMN f_prepaid DECIMAL(12,2), ADD COLUMN f_fiscal int;
alter table a_store_reserve add column f_prepaidcard decimal(12,2) after f_prepaid;

/*db - 140, 22.12.2023*/
update s_app set f_version='140' where f_app='DB';
create table s_images (f_id char(36) primary key, f_data mediumtext);
alter table d_part2 add f_image char(36) DEFAULT uuid();
update d_part2 set f_image=uuid();
alter table d_dish add column f_image char(36);
update d_dish set f_image=uuid();
alter table d_dish add column f_cookingtime int;
update d_dish set f_cookingtime=0;
create table o_body_process( f_id char(36) primary key, f_append timestamp default null, f_print timestamp default null, f_begin timestamp default null, f_end timestamp default null);

/*db - 141, 03.01.2024*/
update s_app set f_version='141' where f_app='DB';
alter table a_header add f_body json;
drop table a_calc_price;
drop table s_draft;
create table a_result (f_id int primary key  auto_increment, f_timestamp timestamp, f_session char(36), f_document char(36), f_result longtext);
alter table a_result add column f_request longtext after f_document, add column f_done timestamp after f_timestamp, add column f_elapsed timestamp after f_done;
ALTER TABLE `a_result` ADD INDEX `idx_session` (`f_session`);
alter table o_tax add column f_json longtext;
alter table o_tax_log add column f_elapsed int after f_time, add column f_state int;
alter table a_result drop column f_elapsed, add column f_elapsed int after f_done;
alter table a_header_store add column f_body longtext;
ALTER TABLE `a_header_store` ADD INDEX `f_saleuuid_storeout` (`f_saleuuid`, `f_storeout`);
CREATE TABLE s_notifications (f_id INTEGER PRIMARY KEY AUTO_INCREMENT,  f_created TIMESTAMP, f_delivered TIMESTAMP, f_readed TIMESTAMP, f_message JSON);
alter table s_notifications add column f_destination varchar(36) after f_readed;

/*db - 137, 24.10.2023*/
update s_app set f_version='137' where f_app='DB';
alter table o_preorder add column f_guest INT, ADD column f_comment tinytext, add column f_feedback tinytext;
alter table remotedb_sql add column f_type int after f_id;

/*db - 138, 24.10.2023*/
update s_app set f_version='138' where f_app='DB';
CREATE TABLE d_dish_set (f_id INTEGER PRIMARY KEY AUTO_INCREMENT, f_dish INTEGER, f_part INTEGER, f_qty DECIMAL(12,2));
alter table d_part2 add column f_qr tinyint;
alter table a_header_cash change column f_session f_session char(36);

/*db - 139, 13.12.2023*/
update s_app set f_version='139' where f_app='DB';
ALTER TABLE a_store_reserve ADD COLUMN f_prepaid DECIMAL(12,2), ADD COLUMN f_fiscal int;
alter table a_store_reserve add column f_prepaidcard decimal(12,2) after f_prepaid;

/*db - 140, 22.12.2023*/
update s_app set f_version='140' where f_app='DB';
create table s_images (f_id char(36) primary key, f_data mediumtext);
alter table d_part2 add f_image char(36) DEFAULT uuid();
update d_part2 set f_image=uuid();
alter table d_dish add column f_image char(36);
update d_dish set f_image=uuid();
alter table d_dish add column f_cookingtime int;
update d_dish set f_cookingtime=0;
create table o_body_process( f_id char(36) primary key, f_append timestamp default null, f_print timestamp default null, f_begin timestamp default null, f_end timestamp default null);

/*db - 141, 03.01.2024*/
update s_app set f_version='141' where f_app='DB';
alter table a_header add f_body json;
drop table a_calc_price;
drop table s_draft;
create table a_result (f_id int primary key  auto_increment, f_timestamp timestamp, f_session char(36), f_document char(36), f_result longtext);
alter table a_result add column f_request longtext after f_document, add column f_done timestamp after f_timestamp, add column f_elapsed timestamp after f_done;
ALTER TABLE `a_result` ADD INDEX `idx_session` (`f_session`);
alter table o_tax add column f_json longtext;
alter table o_tax_log add column f_elapsed int after f_time, add column f_state int;
alter table a_result drop column f_elapsed, add column f_elapsed int after f_done;
alter table a_header_store add column f_body longtext;
ALTER TABLE `a_header_store` ADD INDEX `f_saleuuid_storeout` (`f_saleuuid`, `f_storeout`);
CREATE TABLE s_notifications (f_id INTEGER PRIMARY KEY AUTO_INCREMENT,  f_created TIMESTAMP, f_delivered TIMESTAMP, f_readed TIMESTAMP, f_message JSON);
alter table s_notifications add column f_destination varchar(36) after f_readed;


/* db - 144 09.03.2024 */
update s_app set f_version='144' where f_app='DB';
alter table c_goods add column f_candiscount int;
alter table c_goods add column f_fiscalname tinytext;
alter table b_clients_debts add column f_comment tinytext;


/* db - 145 09.03.2024 */
update s_app set f_version='145' where f_app='DB';
alter table o_preorder add f_checkindate date, add f_checkoutdate date;
alter table c_goods_prices add column f_price1disc decimal(14,2);
alter table c_goods_prices add column f_price2disc decimal(14,2);


/* db - 146 09.03.2024 */
update s_app set f_version='146' where f_app='DB';
create table sys_json_config (f_id integer primary key auto_increment, f_name tinytext, f_config json);
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
	
	
	/* db - 148 09.03.2024 */
update s_app set f_version='148' where f_app='DB';
drop trigger if exists c_groups_trigger_bi;
drop trigger if exists c_groups_trigger_bu ;
drop trigger if exists c_goods_bi ;
drop trigger if exists c_goods_bu ;
drop trigger if exists c_goods_prices_trigger_bi ;
drop trigger if exists c_goods_prices_trigger_bu ;
drop trigger if exists o_header_trigger_bi ;
drop trigger if exists o_header_trigger_bu ;
drop trigger if exists a_header_trigger_bi ;
drop trigger if exists a_header_trigger_bu ;
drop trigger if exists c_units_trigger_bi ;
drop trigger if exists c_units_trigger_bu ;
drop trigger if exists o_goods_trigger_bi ;
drop trigger if exists o_goods_trigger_bu ;
drop trigger if exists a_header_cash_trigger_bi ;
drop trigger if exists a_header_cash_trigger_bu ;
drop trigger if exists a_store_draft_trigger_bi ;
drop trigger if exists a_header_cash_trigger_bu ;
drop trigger if exists a_store_trigger_bi ;
drop trigger if exists a_store_trigger_bu ;
drop trigger if exists e_cash_trigger_bi ;
drop trigger if exists e_cash_trigger_bu ;
drop trigger if exists s_user_group_trigger_bi ;
drop trigger if exists s_user_group_trigger_bu ;
drop trigger if exists s_user_trigger_bi ;
drop trigger if exists s_user_trigger_bu ;
drop trigger if exists o_tax_trigger_bi ;
drop trigger if exists o_tax_trigger_bu ;

alter table a_store_sale add column f_id integer primary key auto_increment first;
ALTER TABLE `d_stoplist` DROP PRIMARY KEY;
alter table d_stoplist add column f_id integer primary key AUTO_INCREMENT FIRST ;

#26/05/24
UPDATE s_app SET f_version ='149' WHERE f_app='DB';
ALTER TABLE d_dish_comment ADD COLUMN f_group INT AFTER f_id, ADD COLUMN f_dish int AFTER f_group;

ALTER TABLE c_storages ADD COLUMN f_have_changes INTEGER DEFAULT 0;

#04/06/24
UPDATE s_app SET f_version ='151' WHERE f_app='DB';
ALTER TABLE mf_actions_group ADD COLUMN f_data JSON;

#04/06/24
UPDATE s_app SET f_version ='152' WHERE f_app='DB';
ALTER TABLE o_header_hotel ADD f_mealplan INTEGER;
CREATE TABLE o_meal_plan (f_id INTEGER PRIMARY KEY AUTO_INCREMENT, f_name TINYTEXT);
INSERT INTO o_meal_plan (f_id, f_name) VALUES (1, 'B/O'), (2, 'B/B'), (3, 'H/B'), (4, 'F/B');
ALTER TABLE o_header_hotel ADD COLUMN f_nights INTEGER;
ALTER TABLE o_header_hotel ADD COLUMN f_remarks TEXT;


#15/06/24
UPDATE s_app SET f_version ='153' WHERE f_app='DB';
ALTER TABLE c_goods_images ADD COLUMN f_image LONGTEXT;
UPDATE c_goods_images SET f_image=to_base64(f_data);
ALTER TABLE c_goods_images DROP COLUMN f_data;
INSERT INTO c_goods_images (f_id) SELECT f_id FROM c_goods WHERE f_id NOT IN (SELECT f_id FROM c_goods_images);

ALTER TABLE s_login_session DROP COLUMN f_iplogin, ADD COLUMN f_iplogin JSON;



#20/06/24
UPDATE s_app SET f_version ='155' WHERE f_app='DB';
CREATE TABLE d_qr_list (f_id INTEGER PRIMARY KEY AUTO_INCREMENT, f_dish INTEGER, f_date DATE, f_time TIME , f_qty DECIMAL(14,2), f_remain DECIMAL(14,2), f_emarks TINYTEXT);
#23/06/24
ALTER TABLE o_body ADD COLUMN f_grandtotal DECIMAL(14,2) AFTER f_total;
UPDATE o_body SET f_grandtotal = f_total;
UPDATE o_body SET f_grandtotal = f_grandtotal+(f_total*f_service);
UPDATE o_body SET f_grandtotal = f_grandtotal-(f_grandtotal*f_discount);


#24/06/24 20:33
UPDATE s_app SET f_version ='156' WHERE f_app='DB';
ALTER TABLE o_body MODIFY f_discount FLOAT, MODIFY f_service FLOAT;
ALTER TABLE o_body MODIFY f_price FLOAT, modify f_qty1 FLOAT, modify f_qty2 FLOAT;
ALTER TABLE o_body MODIFY f_total FLOAT, modify f_grandtotal FLOAT;
ALTER TABLE `o_header`	CHANGE COLUMN `f_serviceFactor` `f_serviceFactor` DECIMAL(14,2) NULL DEFAULT '0' AFTER `f_amountDiscount`,	CHANGE COLUMN `f_discountFactor` `f_discountFactor` DECIMAL(14,2) NULL DEFAULT '0' AFTER `f_serviceFactor`;
UPDATE o_header SET f_servicefactor=0 WHERE f_servicefactor IS NULL;
UPDATE o_header SET f_discountfactor=0 WHERE f_discountfactor IS NULL;


#25/06/24 23:01
UPDATE s_app SET f_version ='157' WHERE f_app='DB';
ALTER TABLE o_header CHANGE COLUMN f_amounttotal f_amounttotal float,
CHANGE COLUMN f_amountCash f_amountcash float,
CHANGE COLUMN f_amountCard f_amountcard float,
CHANGE COLUMN f_amountBank f_amountbank float,
CHANGE COLUMN f_amountOther f_amountother float,
CHANGE COLUMN f_amountPayX f_amountpayx float,
CHANGE COLUMN f_amountIdram f_amountidram float,
CHANGE COLUMN f_serviceFactor f_servicefactor FLOAT,
CHANGE COLUMN f_discountFactor f_discountfactor FLOAT,
CHANGE COLUMN f_dateOpen f_dateopen DATE,
CHANGE COLUMN f_dateCash f_datecash DATE,
CHANGE COLUMN f_dateClose f_dateclose DATE, 
CHANGE COLUMN f_timeOpen f_timeopen TIME,
CHANGE COLUMN f_timeClose f_timeclose TIME,
CHANGE COLUMN f_otherId f_otherid INT,
CHANGE COLUMN f_amountDiscount f_amountdiscount FLOAT,
CHANGE COLUMN f_amountService f_amountservice FLOAT,
CHANGE COLUMN f_state f_state INT,
CHANGE COLUMN f_amountprepaid f_amountprepaid FLOAT,
CHANGE COLUMN f_amountcredit f_amountcredit FLOAT;

ALTER TABLE `o_body`	DROP FOREIGN KEY `fkk_body_state`;
ALTER TABLE `o_body`	DROP INDEX `fk_obody_state_idx`;
ALTER TABLE o_body CHANGE COLUMN f_state f_state INT;
ALTER TABLE o_body_state CHANGE f_id f_id INT;
ALTER TABLE `o_body`	ADD CONSTRAINT `FK_o_body_o_body_state` FOREIGN KEY (`f_state`) REFERENCES `o_body_state` (`f_id`) ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE d_menu CHANGE COLUMN f_price f_price FLOAT;
ALTER TABLE d_dish CHANGE COLUMN f_specialdiscount f_specialdiscount FLOAT;


#27/06/24 18:30
UPDATE s_app SET f_version ='158' WHERE f_app='DB';
CREATE TABLE s_working_sessions (f_id INTEGER PRIMARY KEY AUTO_INCREMENT, f_open TIMESTAMP, f_close TIMESTAMP, f_host TINYTEXT, f_user INT);
ALTER TABLE o_header ADD COLUMN f_working_session INT;
ALTER TABLE a_header_cash DROP COLUMN f_session;
ALTER TABLE e_cash ADD COLUMN f_working_session INT;

#29/06/24 18:30
UPDATE s_app SET f_version ='159' WHERE f_app='DB';
DROP FUNCTION if exists sf_check_card;
DROP FUNCTION if exists sf_shop_add_goods;
ALTER TABLE c_goods CHANGE COLUMN f_qtybox f_qtybox FLOAT;
ALTER TABLE c_goods_prices CHANGE COLUMN f_price1 f_price1 FLOAT, CHANGE COLUMN f_price2 f_price2 FLOAT, CHANGE COLUMN f_price1disc f_price1disc FLOAT, CHANGE COLUMN f_price2disc f_price2disc FLOAT;
ALTER TABLE c_units CHANGE COLUMN f_defaultqty f_defaultqty FLOAT;
ALTER TABLE a_store_reserve CHANGE COLUMN f_qty f_qty FLOAT;
ALTER TABLE o_draft_sale_body CHANGE COLUMN f_qty f_qty FLOAT;
ALTER TABLE a_store_sale CHANGE COLUMN f_qty f_qty FLOAT;

ALTER TABLE o_draft_sale_body CHANGE COLUMN f_qty f_qty FLOAT;
ALTER TABLE a_store_sale CHANGE COLUMN f_qty f_qty FLOAT;
ALTER TABLE c_groups CHANGE f_taxDept f_taxdept INT;
UPDATE o_goods SET f_taxdept='0' WHERE f_taxdept='';
ALTER TABLE o_goods CHANGE column f_taxdept f_taxdept INT;


#03/07/24 09:15
UPDATE s_app SET f_version ='160' WHERE f_app='DB';
ALTER TABLE c_goods MODIFY f_lastinputprice FLOAT,
MODIFY f_price_margin FLOAT,
MODIFY f_price_margin2 FLOAT,
MODIFY f_wholenumber INT,
MODIFY f_enabled INT,
MODIFY f_service INT,
MODIFY f_weight FLOAT,
MODIFY f_complectout FLOAT,
MODIFY f_iscomplect INT,
MODIFY f_base_currency INT,
MODIFY f_lowlevel FLOAT;
ALTER TABLE c_goods_complectation MODIFY f_qty FLOAT, modify f_price FLOAT;
ALTER TABLE mf_process MODIFY f_price FLOAT, MODIFY f_goalprice FLOAT;
ALTER TABLE b_cards_discount MODIFY f_mode INT, MODIFY f_value FLOAT, MODIFY f_active INT;
ALTER TABLE o_draft_sale MODIFY f_amount FLOAT;
ALTER TABLE o_draft_sale_body  modify f_qty FLOAT, MODIFY f_price FLOAT,
MODIFY f_back FLOAT, modify f_special_price INT, modify f_state INT;

#03/07/24 09:15
UPDATE s_app SET f_version ='161' WHERE f_app='DB';
CREATE TABLE sys_mobile (f_id INTEGER PRIMARY KEY AUTO_INCREMENT, f_state INTEGER, f_order JSON);

#09/07/24 09:15
UPDATE s_app SET f_version ='162' WHERE f_app='DB';
ALTER TABLE b_gift_card_history MODIFY f_amount FLOAT;

#12/07/24 23:21
UPDATE s_app SET f_version ='163' WHERE f_app='DB';
ALTER TABLE o_preorder ADD COLUMN f_phone TINYTEXT;
ALTER TABLE o_preorder ADD column f_email TINYTEXT AFTER f_phone, ADD COLUMN f_passport TINYTEXT AFTER f_email;
ALTER TABLE o_header_hotel ADD f_vatmode INTEGER;
CREATE TABLE o_vat_mode (f_id INTEGER primary KEY AUTO_INCREMENT, f_name TINYTEXT);
INSERT INTO o_vat_mode (f_id, f_name) VALUES (1, 'VAT included'),(2, 'No VAT'), (3, 'VAT not included');
UPDATE o_header_hotel SET f_vatmode=1;
ALTER TABLE o_header_hotel MODIFY f_roomrate FLOAT;


#14/07/24 23:21
UPDATE s_app SET f_version ='164' WHERE f_app='DB';
UPDATE o_header SET f_servicefactor=0 WHERE f_servicefactor IS NULL;
UPDATE o_header SET f_discountfactor=0 WHERE f_discountfactor IS NULL;
ALTER TABLE `o_header`	CHANGE COLUMN `f_servicefactor` `f_servicefactor` FLOAT DEFAULT 0 AFTER `f_amountdiscount`;
ALTER TABLE `o_header`	CHANGE COLUMN `f_discountfactor` `f_discountfactor` FLOAT DEFAULT 0;

#15/07/24 23:21
UPDATE s_app SET f_version ='165' WHERE f_app='DB';
ALTER TABLE o_body ADD COLUMN f_working_day DATE;

#17/07/24 23:21
UPDATE s_app SET f_version ='166' WHERE f_app='DB';
ALTER TABLE o_payment MODIFY f_cash FLOAT, modify f_card FLOAT, modify f_prepaid FLOAT;
CREATE TABLE o_prepaid (f_id INTEGER PRIMARY KEY AUTO_INCREMENT, f_header CHAR(36), f_method INT, f_amount FLOAT, f_fiscal INT);
ALTER TABLE h_tables MODIFY f_locksrc TINYTEXT;
ALTER TABLE d_stoplist MODIFY f_qty FLOAT;
UPDATE s_app SET f_version='1.1.9.207' WHERE f_app='WAITER';

#31/07/24 
UPDATE s_app SET f_version='167' WHERE f_app='DB';
ALTER TABLE `o_goods`	CHANGE COLUMN `f_id` `f_id` CHAR(36) NOT NULL COLLATE 'latin1_general_ci' FIRST;
ALTER TABLE `o_goods`	CHANGE COLUMN `f_storerec` `f_storerec` CHAR(36) NULL DEFAULT NULL COLLATE 'latin1_general_ci' AFTER `f_row`;

#15/08/24
UPDATE s_app SET f_version='168' WHERE f_app='DB';
CREATE TABLE c_goods_price_order (f_id INTEGER PRIMARY KEY auto_increment, f_state INTEGER, f_name TINYTEXT, f_body JSON, lu TIMESTAMP DEFAULT CURRENT_TIMESTAMP); 
ALTER TABLE `c_goods_price_order`	CHANGE COLUMN `lu` `lu` TIMESTAMP NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP() AFTER `f_body`;


#21/08/24
UPDATE s_app SET f_version='169' WHERE f_app='DB';
ALTER TABLE b_car MODIFY COLUMN f_id CHAR(36) character set latin1 COLLATE LATIN1_GENERAL_CI;
ALTER TABLE o_body_process ADD f_cookingtime INT AFTER f_id;
CREATE TABLE `o_header_progress` (
	`f_id` CHAR(36) NOT NULL COLLATE 'latin1_general_ci',
	`f_state` INT(11) NULL DEFAULT NULL,
	`f_table` INT(11) NULL DEFAULT NULL,
	`f_startwash` TIMESTAMP NULL DEFAULT NULL,
	`f_washtime` INT(11) NULL DEFAULT NULL,
	`f_startdry` TIMESTAMP NULL DEFAULT NULL,
	`f_drytime` INT(11) NULL DEFAULT NULL,
	`f_parking` TIMESTAMP NULL DEFAULT NULL,
	`f_freeparking` INT(11) NULL DEFAULT NULL,
	PRIMARY KEY (`f_id`) USING BTREE
)
COLLATE='latin1_general_ci'
ENGINE=InnoDB
;


#23/08/24
UPDATE s_app SET f_version='170' WHERE f_app='DB';
ALTER TABLE a_header DROP COLUMN f_sessionid, ADD COLUMN f_working_session INT;
ALTER TABLE s_salary_attendance ADD COLUMN f_shift INT AFTER f_date;
ALTER TABLE s_salary_payment ADD COLUMN f_shift INT AFTER f_date;
ALTER TABLE s_salary_attendance ADD COLUMN f_paid INT ;
ALTER TABLE `s_working_sessions`	CHANGE COLUMN `f_close` `f_close` TIMESTAMP NULL DEFAULT NULL AFTER `f_open`;
ALTER TABLE s_salary_attendance DROP COLUMN f_paid , ADD COLUMN f_paid CHAR(36) character set latin1 COLLATE LATIN1_GENERAL_CI;
ALTER TABLE e_cash MODIFY f_amount FLOAT;
ALTER TABLE e_cash MODIFY f_sign INT;

#02/09/24
UPDATE s_app SET f_version='171' WHERE f_app='DB';
ALTER TABLE a_store MODIFY f_qty FLOAT;
ALTER TABLE a_store_draft MODIFY f_qty FLOAT;
ALTER TABLE o_goods MODIFY f_qty FLOAT;

#05/09/24
UPDATE s_app SET f_version='172' WHERE f_app='DB';
CREATE TABLE `s_config` (
	`f_name` TINYTEXT NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`f_config` LONGTEXT NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci'
);
INSERT INTO `s_config` (`f_name`, `f_config`) VALUES ('Sale', '{\r\n"fiscal_ip":"192.168.16.21",\r\n"fiscal_port":1981,\r\n"fiscal_password":"Qc4HB9WY",\r\n"fiscal_extpos":"false",\r\n"fiscal_opcode":"3",\r\n"fiscal_oppin":"3",\r\n"recipe_font_size":24,\r\n"recipe_paper_width":650,\r\n"recipe_font_family":"Arial LatArm Unicode",\r\n"recipe_printer":"local"\r\n}');


#19/10/24
UPDATE s_app SET f_version='173' WHERE f_app='DB';
UPDATE o_body SET f_emarks=NULL;
ALTER TABLE `o_body`	ADD UNIQUE INDEX `un_emarks` (`f_emarks`);

#20/10/24
UPDATE s_app SET f_version='174' WHERE f_app='DB';
ALTER TABLE c_groups ADD COLUMN f_class CHAR(2);
ALTER TABLE mf_tasks MODIFY  f_qty FLOAT, modify f_ready FLOAT, modify f_out FLOAT;
ALTER TABLE mf_daily_process MODIFY f_price FLOAT;


#12/11/24
UPDATE s_app SET f_version='175' WHERE f_app='DB';
ALTER TABLE `o_goods`	CHANGE COLUMN `f_discountfactor` `f_discountfactor` FLOAT NULL DEFAULT NULL AFTER `f_storerec`;
ALTER TABLE d_recipes MODIFY COLUMN f_qty FLOAT;
ALTER TABLE d_part1 ADD COLUMN f_image CHAR(36);
CREATE TABLE sys_chat(f_id INTEGER PRIMARY KEY AUTO_INCREMENT, f_state INT, f_created TIMESTAMP, f_userfrom INT, f_userto INT, f_body JSON);
ALTER TABLE d_dish MODIFY f_cost FLOAT, MODIFY f_netweight FLOAT, MODIFY f_recipeqty FLOAT;