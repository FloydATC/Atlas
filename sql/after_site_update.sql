
DROP TRIGGER IF EXISTS after_site_update;

DELIMITER //

CREATE TRIGGER after_site_update AFTER UPDATE ON sites
  FOR EACH ROW
  BEGIN
    IF (STATE(OLD.up) != STATE(NEW.up)) 
    THEN
      INSERT INTO statechanges (object_type, object_id, from_state, to_state) 
      VALUES ('site', NEW.id, STATE(OLD.up), STATE(NEW.up));
    END IF;
  END;
//

DELIMITER ;

