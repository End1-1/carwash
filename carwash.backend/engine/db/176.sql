#5/12/24
UPDATE s_app SET f_version='176' WHERE f_app='DB';
CREATE TABLE sys_tasks (f_id INTEGER PRIMARY KEY AUTO_INCREMENT, f_parent INTEGER, f_user INTEGER, f_created TIMESTAMP, f_body TEXT);
ALTER TABLE o_header MODIFY f_amounttelcell FLOAT, MODIFY f_amountdebt FLOAT;
ALTER TABLE h_halls ADD COLUMN f_onlinereport INT DEFAULT 0;
UPDATE s_app SET f_version ='1.1.9.210' WHERE f_app='WAITER';
ALTER TABLE d_dish ADD COLUMN f_addbyqr integer DEFAULT 0;
CREATE TABLE sys_search_cache (f_id INTEGER PRIMARY KEY AUTO_INCREMENT, f_objecttype INTEGER, f_objectid INTEGER, f_text TEXT);
DROP TABLE s_stranslator;
ALTER TABLE h_halls DROP f_booking;
ALTER TABLE `b_history`	CHANGE COLUMN `f_id` `f_id` CHAR(36) NOT NULL COLLATE 'latin1_general_ci' FIRST;
ALTER TABLE `o_header_options`	CHANGE COLUMN `f_id` `f_id` CHAR(36) NOT NULL COLLATE 'latin1_general_ci' FIRST;

ALTER TABLE `o_goods` DROP FOREIGN KEY `fk_oheader_id`;
ALTER TABLE `o_body`	DROP FOREIGN KEY `fk_obody_header`;
ALTER TABLE `o_goods`DROP INDEX `fk_oheader_id_idx`;
ALTER TABLE `o_body`	DROP INDEX `fk_obody_header_idx`;
ALTER TABLE o_body CHANGE COLUMN f_id f_id CHAR(36) NOT NULL COLLATE 'latin1_general_ci';
ALTER TABLE o_goods CHANGE COLUMN f_id f_id CHAR(36) NOT NULL COLLATE 'latin1_general_ci';
ALTER TABLE o_body CHANGE COLUMN f_header f_header CHAR(36) NOT NULL COLLATE 'latin1_general_ci';
ALTER TABLE o_goods CHANGE COLUMN f_header f_header CHAR(36) NOT NULL COLLATE 'latin1_general_ci';
ALTER TABLE `o_header`	CHANGE COLUMN `f_id` `f_id` CHAR(36) NOT NULL COLLATE 'latin1_general_ci' FIRST;
ALTER TABLE o_goods ADD CONSTRAINT fk_oheader_id FOREIGN KEY(f_header) REFERENCES o_header (f_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE o_body ADD CONSTRAINT fk_obody_oheader_id FOREIGN KEY(f_header) REFERENCES o_header (f_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE o_tax_log MODIFY COLUMN f_order CHAR(36) COLLATE 'latin1_general_ci';
UPDATE s_app SET f_version='1.1.9.212' WHERE f_app='WAITER';
ALTER TABLE `c_goods`	CHANGE COLUMN `lu` `lu` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP() AFTER `f_fiscalname`;
ALTER TABLE o_body MODIFY f_timeorder INTEGER;


#13/12/24
UPDATE s_app SET f_version='177' WHERE f_app='DB';
ALTER TABLE sys_chat ADD COLUMN f_readed TIMESTAMP AFTER f_created;
ALTER TABLE d_translator DROP PRIMARY KEY;
CREATE TABLE sys_dayend (f_id INTEGER PRIMARY KEY auto_increment, f_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP, f_date DATE, f_hall INT, f_data JSON);

#24/12/24
UPDATE s_app SET f_version='177' WHERE f_app='DB';
ALTER TABLE o_header MODIFY f_amounttotal FLOAT(10,2), modify f_amountcard FLOAT(10,2), modify f_amountidram FLOAT(10,2), modify f_amountcash FLOAT(10,2);
ALTER TABLE o_header MODIFY f_amountservice FLOAT(10,2), modify f_amountdiscount FLOAT(10,2), modify f_cash FLOAT(10,2), modify f_change FLOAT(10,2);

#02/01/25
UPDATE s_app SET f_version='178' WHERE f_app='DB';
ALTER TABLE o_preorder ADD COLUMN f_address JSON;
CREATE TABLE s_activation (f_id INTEGER PRIMARY KEY AUTO_INCREMENT, f_ip TINYTEXT, f_created TIMESTAMP, f_code CHAR(8), f_phone CHAR(16));
ALTER TABLE s_activation ADD COLUMN f_state integer AFTER f_id; 
ALTER TABLE s_activation ADD COLUMN f_session CHAR(36) AFTER f_state;
CREATE INDEX idx_activation_phone ON s_activation(f_phone, f_state, f_session);
ALTER TABLE s_user CHANGE COLUMN  f_altpassword f_altpassword TINYTEXT;
ALTER TABLE a_header_store ADD COLUMN f_reason INT AFTER f_invoicedate;
UPDATE a_header_store SET f_reason=JSON_VALUE(f_body, '$.header.f_reason');
CREATE TABLE `log` (
	`f_id` INT(11) NOT NULL AUTO_INCREMENT,
	`f_comp` TINYTEXT NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`f_date` DATE NULL DEFAULT NULL,
	`f_time` TIME NULL DEFAULT NULL,
	`f_user` TINYTEXT NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`f_type` INT(11) NULL DEFAULT NULL,
	`f_rec` VARCHAR(36) NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`f_invoice` VARCHAR(36) NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`f_reservation` VARCHAR(36) NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`f_action` VARCHAR(256) NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`f_value1` TEXT NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`f_value2` TEXT NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	PRIMARY KEY (`f_id`) USING BTREE
)
COLLATE='utf8mb3_general_ci'
ENGINE=InnoDB
AUTO_INCREMENT=24619
;
ALTER TABLE `e_cash`	ADD CONSTRAINT `fk_ecash_cashid` FOREIGN KEY (`f_cash`) REFERENCES `e_cash_names` (`f_id`) ON UPDATE NO ACTION ON DELETE NO ACTION;
INSERT INTO c_partners_state (f_id, f_name) VALUES (0, 'Դաթարեցված');


#19/01/25
UPDATE s_app SET f_version='179' WHERE f_app='DB';
ALTER TABLE d_dish ADD COLUMN f_showonline INTEGER;


#01/02/2025
UPDATE s_app SET f_version='180' WHERE f_app='DB';
ALTER TABLE `s_user`	DROP INDEX `fk_user_state_idx`,	DROP FOREIGN KEY `fk_user_state`;
ALTER TABLE `s_user_state` 	CHANGE COLUMN `f_id` `f_id` INT NOT NULL DEFAULT 0 FIRST;
ALTER TABLE s_user MODIFY COLUMN f_state INT;
ALTER TABLE `s_user`	ADD CONSTRAINT `fx_users_state` FOREIGN KEY (`f_state`) REFERENCES `s_user_state` (`f_id`) ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `s_user_access`	CHANGE COLUMN `f_value` `f_value` INT NULL DEFAULT NULL AFTER `f_key`;
ALTER TABLE o_header MODIFY COLUMN f_source INT, modify f_saletype INT ;
ALTER TABLE `a_header` DROP INDEX `fk_state_idx`,	DROP FOREIGN KEY `fk_state`;
ALTER TABLE a_header MODIFY f_state INT;
ALTER TABLE `a_state`	CHANGE COLUMN `f_id` `f_id` INT NOT NULL DEFAULT 0 FIRST;
ALTER TABLE `a_header` ADD CONSTRAINT `fk_aheader_state` FOREIGN KEY (`f_state`) REFERENCES `a_state` (`f_id`) ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE c_storages_state MODIFY f_id INT;
ALTER TABLE o_draft_sale MODIFY f_state INT;
ALTER TABLE d_dish MODIFY f_service INT, MODIFY f_discount INT, MODIFY f_remind INT, MODIFY f_extra INT, MODIFY f_samestore INT;
ALTER TABLE d_menu MODIFY f_state INt, modify f_recent INT;
ALTER TABLE o_state MODIFY f_id INT;
ALTER TABLE c_partners MODIFY f_state INT DEFAULT 1, MODIFY f_category int DEFAULT 1;
ALTER TABLE c_partners_state MODIFY f_id INT DEFAULT 1;
UPDATE c_partners SET f_category=1 WHERE f_category NOT IN (SELECT f_id FROM c_partners_category);
UPDATE c_partners SET f_state=1 WHERE f_state NOT IN (SELECT f_id FROM c_partners_state);
ALTER TABLE `c_partners`	ADD CONSTRAINT `fk_partners_category` FOREIGN KEY (`f_category`) REFERENCES `c_partners_category` (`f_id`) ON UPDATE NO ACTION ON DELETE NO ACTION, ADD CONSTRAINT `fk_partners_state` FOREIGN KEY (`f_state`) REFERENCES `c_partners_state` (`f_id`) ON UPDATE NO ACTION ON DELETE NO ACTION,	ADD CONSTRAINT `fk_partners_group` FOREIGN KEY (`f_group`) REFERENCES `c_partners_group` (`f_id`) ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `c_partners`	ADD CONSTRAINT `fk_partners_manager` FOREIGN KEY (`f_manager`) REFERENCES `s_user` (`f_id`) ON UPDATE NO ACTION ON DELETE NO ACTION;