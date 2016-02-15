
/*
 * Recalculate state of commlinks, hostgroups, sites and sitegroups, all based on hosts
 */

DROP PROCEDURE IF EXISTS recalc_states;

DELIMITER //

CREATE PROCEDURE recalc_states()
BEGIN
  /* Hosts we have not heard from > dead */
  UPDATE hosts
  SET up=0, since=NOW()
  WHERE (up != 0 OR up IS NULL) 
  AND TIMESTAMPDIFF(SECOND, checked, NOW()) > 30
  AND (TIMESTAMPDIFF(SECOND, alive, checked) > 30 OR alive IS NULL);

  /* Commlinks: 0+NULL=0, 1+NULL=1, NULL+NULL=NULL, 0+1=0, 1+1=1 */
  UPDATE commlinks 
  SET up = (
    SELECT MIN(hosts.up)
    FROM hosts 
    WHERE (hosts.id = commlinks.host1 OR hosts.id = commlinks.host2)
    AND hosts.up IS NOT NULL
  );

  UPDATE hostgroups 
  SET up = (
    SELECT AVG(hosts.up)
    FROM hosts
    LEFT JOIN hostgroupmembers ON (hostgroupmembers.host = hosts.id)
    WHERE hostgroupmembers.hostgroup = hostgroups.id
    AND hosts.up IS NOT NULL 
  );

  UPDATE sites SET up = (
    SELECT AVG(hosts.up)
    FROM hosts
    WHERE site = sites.id
  );

  UPDATE sitegroups 
  SET up = (
    SELECT AVG(sites.up)
    FROM sites
    LEFT JOIN sitegroupmembers ON (sitegroupmembers.site = sites.id)
    WHERE sitegroupmembers.sitegroup = sitegroups.id
    AND sites.up IS NOT NULL 
  );
END //

DELIMITER ;
