
DROP TRIGGER IF EXISTS before_host_update;

DELIMITER //

CREATE TRIGGER before_host_update BEFORE UPDATE ON hosts
  FOR EACH ROW
  BEGIN
    IF (NEW.ip = '' OR NEW.ip = '0.0.0.0') 
    THEN
      SET NEW.ip = NULL;
    END IF;
  END;
//

DELIMITER ;

