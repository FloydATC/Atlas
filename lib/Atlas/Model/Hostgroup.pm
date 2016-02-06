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



return 1;

