
DROP TRIGGER IF EXISTS after_sitegroup_update;

DELIMITER //

CREATE TRIGGER after_sitegroup_update AFTER UPDATE ON sitegroups
  FOR EACH ROW
  BEGIN
    IF (STATE(OLD.up) != STATE(NEW.up)) 
    THEN
      INSERT INTO statechanges (object_type, object_id, from_state, to_state) 
      VALUES ('sitegroup', NEW.id, STATE(OLD.up), STATE(NEW.up));
    END IF;
  END;
//

DELIMITER ;

