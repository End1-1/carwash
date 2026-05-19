#04/06/24
UPDATE s_app SET f_version ='151' WHERE f_app='DB';
ALTER TABLE mf_actions_group ADD COLUMN f_data JSON;