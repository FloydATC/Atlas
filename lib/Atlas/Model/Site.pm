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
    AND hostgroups.id IS NOT NULL
    GROUP BY hostgroups.id
    HAVING members > 0
    ORDER BY hostgroups.id
  ";
}

sub query_lanlinks {
  return "
    SELECT
      h1.id AS h1_id,
      h1.x AS h1_x,
      h1.y AS h1_y,
      h2.id AS h2_id,
      h2.x AS h2_x,
      h2.y AS h2_y,
      commlinks.*
    FROM commlinks
    LEFT JOIN hosts AS h1 ON (h1.id = commlinks.host1)
    LEFT JOIN hosts AS h2 ON (h2.id = commlinks.host2)
    WHERE (h1.site = ? AND h2.site = ?)
    ORDER BY commlinks.id
  ";
}

sub query_wanlinks {
  return "
    SELECT
      h1.id AS h1_id,
      h1.x AS h1_x,
      h1.y AS h1_y,
      h2.id AS h2_id,
      h2.x AS h2_x,
      h2.y AS h2_y,
      s1.id AS s1_id,
      s1.x AS s1_x,
      s1.y AS s1_y,
      s2.id AS s2_id,
      s2.x AS s2_x,
      s2.y AS s2_y,
      commlinks.*
    FROM commlinks
    LEFT JOIN hosts AS h1 ON (h1.id = commlinks.host1)
    LEFT JOIN hosts AS h2 ON (h2.id = commlinks.host2)
    LEFT JOIN sites AS s1 ON (s1.id = h1.site)
    LEFT JOIN sites AS s2 ON (s2.id = h2.site)
    WHERE (h1.site = ? OR h2.site = ?)
    AND h1.site != h2.site
    ORDER BY commlinks.id
  ";
}

sub query_insert {
  return "
    INSERT INTO sites (name, x, y) 
    VALUES (?, ?, ?)
  ";
}


sub query_memberof {
  # Select all Sitegroups this Site is member of
  return "
    SELECT sitegroups.*
    FROM sitegroups
    WHERE sitegroups.id IN (
      SELECT sitegroup 
      FROM sitegroupmembers
      WHERE site = ? 
    )
    ORDER BY sitegroups.name, sitegroups.id
  ";
}


sub query_notmemberof {
  # Select all Sitegroups this Site is NOT member of
  return "
    SELECT sitegroups.*
    FROM sitegroups
    WHERE sitegroups.id NOT IN (
      SELECT sitegroup 
      FROM sitegroupmembers
      WHERE site = ? 
    )
    ORDER BY sitegroups.name, sitegroups.id
  ";
}


return 1;

