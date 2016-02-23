package Atlas::Model::Host;


sub query_get {
  return "
    SELECT 
      *,
      STATE(up) AS state 
    FROM hosts
    WHERE id = ?
    ORDER BY id
    LIMIT 1
  ";
}


sub query_move {
  return "
    UPDATE hosts    
    SET x = x + ?, y = y + ?
    WHERE id = ?
  ";  
}


sub query_peers {
  return "
    SELECT 
      hosts.id AS hosts_id,
      hosts.name AS hosts_name,
      STATE(hosts.up) AS hosts_state,
      commlinks.id AS commlinks_id,
      commlinks.name AS commlinks_name
    FROM hosts, commlinks
    WHERE (commlinks.host1 = hosts.id OR commlinks.host2 = hosts.id)
    AND (commlinks.host1 = ? OR commlinks.host2 = ?)
    AND hosts.id != ?
    ORDER BY hosts.name, hosts.id
  ";
}


sub query_nonpeers {
  return "
    SELECT * 
    FROM hosts
    WHERE id != ? 
    AND id NOT IN (
      SELECT commlinks.host1
      FROM commlinks
      WHERE (commlinks.host1 = ? OR commlinks.host2 = ?)
    )
    AND id NOT IN (
      SELECT commlinks.host2
      FROM commlinks
      WHERE (commlinks.host1 = ? OR commlinks.host2 = ?)
    )
    ORDER BY name, id
  ";
}


sub query_insert {
  return "
    INSERT INTO hosts (name, ip, site, x, y)
    VALUES (?, ?, ?, ?, ?)
  ";
}


sub query_memberof {
  return "
    SELECT hostgroups.*
    FROM hostgroups
    WHERE hostgroups.site = ?
    AND hostgroups.id IN (
      SELECT hostgroupmembers.hostgroup
      FROM hostgroupmembers
      WHERE hostgroupmembers.host = ?
    )
  ";
}


#sub query_update_dead {
#  return "
#    UPDATE hosts
#    SET up=0, since=NOW()
#    WHERE (up != 0 OR up IS NULL) 
#    AND TIMESTAMPDIFF(SECOND, checked, NOW()) > 30
#    AND (TIMESTAMPDIFF(SECOND, alive, checked) > 30 OR alive IS NULL) 
#  ";
#}

sub query_notmemberof {
  return "
    SELECT hostgroups.*
    FROM hostgroups
    WHERE hostgroups.site = ?
    AND hostgroups.id NOT IN (
      SELECT hostgroupmembers.hostgroup
      FROM hostgroupmembers
      WHERE hostgroupmembers.host = ?
    )
  ";
}


sub query_seen_ip {
  return "
    CALL seen_ip(?, FROM_UNIXTIME(?))
  ";
}


sub query_update_checked {
  return "
    UPDATE hosts
    SET checked=NOW()
    WHERE id = ?
  ";
}


sub query_need_check {
  # Find hosts that have not been checked in the last 2 minutes
  my $random = 10+int(rand(90));
  return "
    (
      SELECT
        *,
        NULL AS _age
      FROM hosts
      WHERE ip IS NOT NULL
      AND checked IS NULL
      ORDER BY id
    ) UNION (
      SELECT
        *,
        TIMESTAMPDIFF(MINUTE, checked, NOW()) AS _age
      FROM hosts
      WHERE ip IS NOT NULL
      AND checked IS NOT NULL
      HAVING _age >= 2
      ORDER BY _age DESC, id
    ) 
    LIMIT $random
  ";
}   
 

sub query_set_hostgroup {
  # Replace any hostgroup memberships with just one
  return "
    CALL set_hostgroup(?, ?)
  ";
}
                       
return 1;

