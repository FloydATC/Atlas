
DROP TRIGGER IF EXISTS before_site_insert;

DELIMITER //

CREATE TRIGGER before_site_insert BEFORE INSERT ON sites
  FOR EACH ROW
  BEGIN
    IF (NEW.x IS NULL AND NEW.y IS NULL) 
    THEN
      SET NEW.x = 100 + RAND()*200;
      SET NEW.y = 100 + RAND()*200;
    END IF;
  END;
//

DELIMITER ;

