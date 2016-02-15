
DROP TRIGGER IF EXISTS after_commlink_update;

DELIMITER //

CREATE TRIGGER after_commlink_update AFTER UPDATE ON commlinks
  FOR EACH ROW
  BEGIN
    IF (STATE(OLD.up) != STATE(NEW.up)) 
    THEN
      INSERT INTO statechanges (object_type, object_id, from_state, to_state) 
      VALUES ('commlink', NEW.id, STATE(OLD.up), STATE(NEW.up));
    END IF;
  END;
//

DELIMITER ;

