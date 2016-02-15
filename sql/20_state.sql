

DROP FUNCTION IF EXISTS state;

DELIMITER //

CREATE FUNCTION state(n DECIMAL(5,4))
RETURNS VARCHAR(8)
BEGIN
  IF n IS NULL
    THEN RETURN 'unknown';
  END IF;

  IF n = 0 
    THEN RETURN 'dead';
  END IF;
  
  IF n = 1 
    THEN RETURN 'alive';
  END IF;
  
  RETURN 'warning';
END //

DELIMITER ;
