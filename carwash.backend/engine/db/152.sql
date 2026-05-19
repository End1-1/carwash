#04/06/24
UPDATE s_app SET f_version ='152' WHERE f_app='DB';
ALTER TABLE o_header_hotel ADD f_mealplan INTEGER;
CREATE TABLE o_meal_plan (f_id INTEGER PRIMARY KEY AUTO_INCREMENT, f_name TINYTEXT);
INSERT INTO o_meal_plan (f_id, f_name) VALUES (1, 'B/O'), (2, 'B/B'), (3, 'H/B'), (4, 'F/B');
ALTER TABLE o_header_hotel ADD COLUMN f_nights INTEGER;
ALTER TABLE o_header_hotel ADD COLUMN f_remarks TEXT;