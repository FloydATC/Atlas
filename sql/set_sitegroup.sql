
/*
 * WARNING! Truncates all tables 
 */

DROP PROCEDURE IF EXISTS set_sitegroup;

DELIMITER //

CREATE PROCEDURE set_sitegroup(site_id INTEGER, sitegroup_id INTEGER)
BEGIN
  DELETE FROM sitegroupmembers WHERE site = site_id;
  INSERT INTO sitegroupmembers (site, sitegroup) VALUES (site_id, sitegroup_id);
END //

DELIMITER ;
