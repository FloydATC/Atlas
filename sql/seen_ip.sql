

/* 
 * Referenced by Atlas::Model::Host.pm
 * Called when SEEN thread posts IP addresses to URI /loopback/seen
 * If host was down, set up=1 and since=seen_datetime
 * Either way, set checked=seen_datetime
 */

DROP PROCEDURE IF EXISTS seen_ip;

DELIMITER //

CREATE PROCEDURE seen_ip(host_ip VARCHAR(16), seen_datetime DATETIME)
BEGIN
  UPDATE hosts SET up=1, since=seen_datetime WHERE ip=host_ip AND up=0;
  UPDATE hosts SET alive=seen_datetime, checked=seen_datetime WHERE ip=host_ip;
END //

DELIMITER ;

