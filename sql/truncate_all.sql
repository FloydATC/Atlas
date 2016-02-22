
/*
 * WARNING! Truncates all tables 
 */

DROP PROCEDURE IF EXISTS truncate_all;

DELIMITER //

CREATE PROCEDURE truncate_all()
BEGIN
  SET FOREIGN_KEY_CHECKS=0;
  TRUNCATE commlinks;
  TRUNCATE hostgroupmembers;
  TRUNCATE hostgroups;
  TRUNCATE hosts;
  TRUNCATE sitegroupmembers;
  TRUNCATE sitegroups;
  TRUNCATE sites;
  TRUNCATE statechanges;
  SET FOREIGN_KEY_CHECKS=1;
END //

DELIMITER ;
