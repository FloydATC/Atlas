
DROP TRIGGER IF EXISTS after_hostgroup_update;

DELIMITER //

CREATE TRIGGER after_hostgroup_update AFTER UPDATE ON hostgroups
  FOR EACH ROW
  BEGIN
    IF (STATE(OLD.up) != STATE(NEW.up)) 
    THEN
      INSERT INTO statechanges (object_type, object_id, from_state, to_state) 
      VALUES ('hostgroup', NEW.id, STATE(OLD.up), STATE(NEW.up));
    END IF;
  END;
//

DELIMITER ;

