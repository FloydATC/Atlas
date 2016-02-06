package Atlas::Model::World;


sub query_sites {
  return "
    SELECT * 
    FROM sites
    ORDER BY name, id   
  ";
}


sub query_sitegroups {
  return "
    SELECT 
      sitegroups.id,
      sitegroups.name,
      MIN(sites.x) AS x,
      MIN(sites.y) AS y,
      MAX(sites.x)-MIN(sites.x) AS width,
      MAX(sites.y)-MIN(sites.y) AS height,
      COUNT(sites.id) AS members
    FROM sites
    LEFT JOIN sitegroupmembers ON (sitegroupmembers.site = sites.id)
    LEFT JOIN sitegroups ON (sitegroups.id = sitegroupmembers.sitegroup)
    GROUP BY sitegroups.id
    HAVING members > 0
    ORDER BY sitegroups.id
  ";
}

return 1;

