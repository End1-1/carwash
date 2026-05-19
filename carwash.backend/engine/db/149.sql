#26/05/24
UPDATE s_app SET f_version ='149' WHERE f_app='DB';
ALTER TABLE d_dish_comment ADD COLUMN f_group INT AFTER f_id, ADD COLUMN f_dish int AFTER f_group;