
/*
 * WARNING! Truncates all tables 
 */

DROP PROCEDURE IF EXISTS set_hostgroup;

DELIMITER //

CREATE PROCEDURE set_hostgroup(host_id INTEGER, hostgroup_id INTEGER)
BEGIN
  DELETE FROM hostgroupmembers WHERE host = host_id;
  INSERT INTO hostgroupmembers (host, hostgroup) VALUES (host_id, hostgroup_id);
END //

DELIMITER ;
