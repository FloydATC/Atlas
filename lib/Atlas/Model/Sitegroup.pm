package Atlas::Model::Sitegroup;


sub query_get {
  return "
    SELECT * 
    FROM sitegroups
    WHERE id = ?
    ORDER BY id
    LIMIT 1
  ";
}


sub query_move {
  return "
    UPDATE sites    
    LEFT JOIN sitegroupmembers ON (sitegroupmembers.site = sites.id)
    LEFT JOIN sitegroups ON (sitegroups.id = sitegroupmembers.sitegroup)
    SET sites.x = sites.x + ?, sites.y = sites.y + ?
    WHERE sitegroups.id = ?
  ";
}


sub query_sites {
  return "
    SELECT sites.*
    FROM sites
    LEFT JOIN sitegroupmembers ON (sitegroupmembers.site = sites.id)
    LEFT JOIN sitegroups ON (sitegroups.id = sitegroupmembers.sitegroup)
    WHERE sitegroups.id = ?
    ORDER BY sites.name, sites.id
  ";
}


return 1;

