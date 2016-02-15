
/*
 * WARNING! Truncates all tables 
 */

DROP PROCEDURE IF EXISTS truncate_all;

DELIMITER //

CREATE PROCEDURE truncate_all()
BEGIN
  TRUNCATE commlinks;
  TRUNCATE hostgroupmembers;
  TRUNCATE hostgroups;
  TRUNCATE hosts;
  TRUNCATE sitegroupmembers;
  TRUNCATE sitegroups;
  TRUNCATE sites;
  TRUNCATE statechanges;
END //

DELIMITER ;
