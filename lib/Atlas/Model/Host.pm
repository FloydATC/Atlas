package Atlas::Model::Host;


sub query_get {
  return "
    SELECT * 
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
      commlinks.id AS commlinks_id,
      commlinks.name AS commlinks_name
    FROM hosts, commlinks
    WHERE (commlinks.host1 = hosts.id OR commlinks.host2 = hosts.id)
    AND (commlinks.host1 = ? OR commlinks.host2 = ?)
    AND hosts.id != ?
    ORDER BY hosts.name, hosts.id
  ";
}


sub query_insert {
  return "
    INSERT INTO hosts (name, ip, site, x, y)
    VALUES (?, ?, ?, ?, ?)
  ";
}


return 1;

