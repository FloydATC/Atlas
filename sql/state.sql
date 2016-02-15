

DROP FUNCTION IF EXISTS state;

DELIMITER //

CREATE FUNCTION state(n DECIMAL(5,4))
RETURNS VARCHAR(8)
BEGIN
  DECLARE str VARCHAR(8);

  IF n = 0 THEN SET str = 'dead';
  ELSEIF n = 1 THEN SET str = 'alive';
  ELSE SET str = 'warning';
  END IF;

  RETURN str;
END //

DELIMITER ;
