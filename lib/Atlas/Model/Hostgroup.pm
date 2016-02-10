package Atlas::Model::Hostgroup;

sub query_get {
  return "
    SELECT * 
    FROM hostgroups
    WHERE id = ?
    ORDER BY name, id
    LIMIT 1
  ";
}

sub query_hosts {
  return "
    SELECT hosts.*
    FROM hosts
    LEFT JOIN hostgroupmembers ON (hostgroupmembers.host = hosts.id)
    LEFT JOIN hostgroups ON (hostgroups.id = hostgroupmembers.hostgroup)
    WHERE hostgroups.id = ?
    ORDER BY hosts.name, hosts.id
  ";
}

sub query_move {
  return "
    UPDATE hosts    
    LEFT JOIN hostgroupmembers ON (hostgroupmembers.host = hosts.id)
    LEFT JOIN hostgroups ON (hostgroups.id = hostgroupmembers.hostgroup)
    SET hosts.x = hosts.x + ?, hosts.y = hosts.y + ?
    WHERE hostgroups.id = ?
  ";
}

sub query_insert {
  return "
    INSERT INTO hostgroups (site, name)
    VALUES (?, ?)
  ";
}


sub query_find {
  return "
    SELECT * FROM hostgroups
    WHERE site = ? AND name LIKE ?
    ORDER BY name, id
    LIMIT 1
  ";
}


sub query_addmember {
  return "
    INSERT INTO hostgroupmembers (hostgroup, host)
    VALUES (?, ?)
  ";
}


sub query_removemember {
  return "
    DELETE FROM hostgroupmembers
    WHERE hostgroup = ?
    AND host = ?
  ";
}


sub query_members {
  return "
    SELECT hosts.* 
    FROM hosts
    WHERE id IN (
      SELECT hostgroupmembers.host
      FROM hostgroupmembers
      WHERE hostgroupmembers.hostgroup = ?
    )
  ";
}

sub query_nonmembers {
  return "
    SELECT hosts.* 
    FROM hosts
    WHERE hosts.site = ?
    AND id NOT IN (
      SELECT hostgroupmembers.host
      FROM hostgroupmembers
      WHERE hostgroupmembers.hostgroup = ?
    )
  ";
}

return 1;

