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


sub query_find {
  return "
    SELECT * 
    FROM sitegroups
    WHERE name LIKE ?
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


sub query_insert {
  return "
    INSERT INTO sitegroups (name) 
    VALUES (?)
  ";
}


sub query_addmember {
  return "
    INSERT INTO sitegroupmembers (sitegroup, site)
    VALUES (?, ?)
  ";
}

sub query_removemember {
  return "
    DELETE FROM sitegroupmembers
    WHERE sitegroup = ?
    AND site = ?
  ";
}

sub query_members {
  return "
    SELECT * FROM sites
    WHERE id IN (
      SELECT site 
      FROM sitegroupmembers
      WHERE sitegroup = ?
    )
    ORDER BY name, id
  ";
}

sub query_nonmembers {
  return "
    SELECT * FROM sites
    WHERE id NOT IN (
      SELECT site 
      FROM sitegroupmembers
      WHERE sitegroup = ?
    )
    ORDER BY name, id
  ";
}

return 1;

