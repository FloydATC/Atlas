package Atlas::Model::Hostgroup;

sub get {
  my $class = shift;
  my $c = shift;
  my $dbh = shift;
  my $id = shift;
  #print "$class get c=$c dbh=$dbh id=$id\n";
  my $sth = $dbh->prepare("
    SELECT * 
    FROM hostgroups
    WHERE id = ?
    ORDER BY name, id
    LIMIT 1
  ");
  $sth->execute($id);
  if (my $hostgroup = $sth->fetchrow_hashref) {
    return $hostgroup;
  }
  return {};
}

sub hosts {
  my $class = shift;
  my $c = shift;
  my $dbh = shift;
  my $id = shift;

  #print "$class hosts c=$c dbh=$dbh id=$id\n";
  my $sth = $dbh->prepare("
    SELECT hosts.*
    FROM hosts
    LEFT JOIN hostgroupmembers ON (hostgroupmembers.host = hosts.id)
    LEFT JOIN hostgroups ON (hostgroups.id = hostgroupmembers.hostgroup)
    WHERE hostgroups.id = ?
    ORDER BY hosts.name, hosts.id
  ");
  $sth->execute($id);
  my @hosts = ();
  while (my $host = $sth->fetchrow_hashref) {
    push @hosts, $host;
  }
  $sth->finish;
  return @hosts;
}

sub link {
  my $class = shift;
  my $c = shift;  
  my $dbh = shift;
  my $id = shift;
 
  my $hostgroup = get($class, $c, $dbh, $id);          
  return "<A href=\"/hostgroup/details?id=".$hostgroup->{'id'}."\">".$hostgroup->{'name'}."</A>";
}

sub move {
  my $class = shift;
  my $c = shift;  
  my $dbh = shift;
  my $id = shift;
  my $relx = shift;
  my $rely = shift;

  print "$class move c=$c dbh=$dbh id=$id relx=$relx rely=$rely\n";
  my $sth = $dbh->prepare("
    UPDATE hosts    
    LEFT JOIN hostgroupmembers ON (hostgroupmembers.host = hosts.id)
    LEFT JOIN hostgroups ON (hostgroups.id = hostgroupmembers.hostgroup)
    SET hosts.x = hosts.x + ?, hosts.y = hosts.y + ?
    WHERE hostgroups.id = ?
  ");
  $sth->execute($relx, $rely, $id);
  $sth->finish;
  return 1;
}



return 1;

