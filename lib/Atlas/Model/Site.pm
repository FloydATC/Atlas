package Atlas::Model::Site;


sub query_move {
  return "
    UPDATE sites 
    SET x = x + ?, y = y + ?
    WHERE id = ?
  ";
}


sub query_get {
  return "
    SELECT *
    FROM sites
    WHERE id = ?
  ";
}


sub query_hosts {
  return "
    SELECT * 
    FROM hosts
    WHERE site = ?
    ORDER BY name, id
  ";
}


sub query_hostgroups {
  return "
    SELECT 
      hostgroups.id,
      hostgroups.name,
      MIN(hosts.x) AS x,
      MIN(hosts.y) AS y,
      MAX(hosts.x)-MIN(hosts.x) AS width,
      MAX(hosts.y)-MIN(hosts.y) AS height,
      COUNT(hosts.id) AS members
    FROM hosts
    LEFT JOIN hostgroupmembers ON (hostgroupmembers.host = hosts.id)
    LEFT JOIN hostgroups ON (hostgroups.id = hostgroupmembers.hostgroup)
    WHERE hosts.site = ?
    GROUP BY hostgroups.id
    HAVING members > 0
    ORDER BY hostgroups.id
  ";
}

return 1;

