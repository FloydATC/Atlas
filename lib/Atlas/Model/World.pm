package Atlas::Model::World;


sub query_sites {
  return "
    SELECT 
      *,
      STATE(up) AS state 
    FROM sites
    ORDER BY name, id   
  ";
}


sub query_sitegroups {
  return "
    SELECT 
      sitegroups.id,
      sitegroups.name,
      STATE(sitegroups.up) AS state,
      MIN(sites.x) AS x,
      MIN(sites.y) AS y,
      MAX(sites.x)-MIN(sites.x) AS width,
      MAX(sites.y)-MIN(sites.y) AS height,
      COUNT(sites.id) AS members
    FROM sites
    LEFT JOIN sitegroupmembers ON (sitegroupmembers.site = sites.id)
    LEFT JOIN sitegroups ON (sitegroups.id = sitegroupmembers.sitegroup)
    WHERE sitegroups.id IS NOT NULL
    GROUP BY sitegroups.id
    HAVING members > 0
    ORDER BY sitegroups.id
  ";
}

sub query_wanlinks {
  return "
    SELECT
      h1.id AS h1_id,
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
    WHERE h1.site != h2.site
    ORDER BY commlinks.id
  ";
}

sub query_recalc_states {
  return "
    CALL recalc_states()
  ";
}

return 1;

