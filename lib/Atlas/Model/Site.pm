package Atlas::Model::Site;

sub get {
  my $class = shift;
  my $c = shift;
  my $dbh = shift;
  my $id = shift;
  #print "$class get c=$c dbh=$dbh id=$id\n";
  my $sth = $dbh->prepare("
    SELECT * 
    FROM sites
    WHERE id = ?
    ORDER BY id
    LIMIT 1
  ");
  $sth->execute($id);
  if (my $site = $sth->fetchrow_hashref) {
    return $site;
  }
  return {};
}

sub link {
  my $class = shift;
  my $c = shift;
  my $dbh = shift;
  my $id = shift;
  
  my $site = get($class, $c, $dbh, $id);
  return "<A href=\"/site/map?id=".$site->{'id'}."\">".$site->{'name'}."</A>";
}

sub hosts {
  my $class = shift;
  my $c = shift;
  my $dbh = shift;
  my $id = shift;

  #print "$class hosts c=$c dbh=$dbh id=$id\n";
  my $sth = $dbh->prepare("
    SELECT * 
    FROM hosts
    WHERE hosts.site = ?
    ORDER BY hosts.id   
  ");
  $sth->execute($id);
  my @hosts = ();
  while (my $host = $sth->fetchrow_hashref) {
    push @hosts, $host;
  }
  $sth->finish;
  return @hosts;
}

sub move {
  my $class = shift;
  my $c = shift;
  my $dbh = shift;
  my $id = shift;
  my $x = shift;
  my $y = shift;

  print "$class move c=$c dbh=$dbh id=$id x=$x y=$y\n";
  my $sth = $dbh->prepare("
    UPDATE sites 
    SET x = ?, y = ?
    WHERE id = ?
  ");
  $sth->execute($x, $y, $id);
  $sth->finish;
  return 1;
}

sub hostgroups {
  my $class = shift;
  my $c = shift;
  my $dbh = shift;
  my $id = shift;

  #print "$class hostgroups c=$c dbh=$dbh id=$id\n";
  my $sth = $dbh->prepare("
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
  ");
  $sth->execute($id);
  my @hostgroups = ();
  while (my $hostgroup = $sth->fetchrow_hashref) {
    push @hostgroups, $hostgroup;
  }
  #print "found ".scalar(@hostgroups)."\n";
  return @hostgroups;
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

