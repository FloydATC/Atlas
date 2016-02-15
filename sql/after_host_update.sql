
DROP TRIGGER IF EXISTS after_host_update;

DELIMITER //

CREATE TRIGGER after_host_update AFTER UPDATE ON hosts
  FOR EACH ROW
  BEGIN
    IF (STATE(OLD.up) != STATE(NEW.up)) 
    THEN
      INSERT INTO statechanges (object_type, object_id, from_state, to_state) 
      VALUES ('host', NEW.id, STATE(OLD.up), STATE(NEW.up));
    END IF;
  END;
//

DELIMITER ;

