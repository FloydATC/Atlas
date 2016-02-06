package Atlas::Model::Host;

sub get {
  my $class = shift;
  my $c = shift;
  my $dbh = shift;
  my $id = shift;
  #print "$class get c=$c dbh=$dbh id=$id\n";
  my $sth = $dbh->prepare("
    SELECT * 
    FROM hosts
    WHERE id = ?
    ORDER BY id
    LIMIT 1
  ");
  $sth->execute($id);
  if (my $host = $sth->fetchrow_hashref) {
    return $host;
  }
  return {};
}

sub link {
  my $class = shift;
  my $c = shift;
  my $dbh = shift;
  my $id = shift;
 
  my $host = get($class, $c, $dbh, $id);          
  return "<A href=\"/host/details?id=".$host->{'id'}."\">".$host->{'name'}."</A>";
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
    UPDATE hosts    
    SET x = ?, y = ?
    WHERE id = ?
  ");
  $sth->execute($x, $y, $id);
  $sth->finish;
  return 1;
}

sub peers {
  my $class = shift;
  my $c = shift;
  my $dbh = shift;
  my $id = shift;
 
  my $sth = $dbh->prepare("
    SELECT 
      hosts.id AS host_id, 
      commlinks.id AS commlink_id
    FROM hosts, commlinks
    WHERE (commlinks.host1 = hosts.id OR commlinks.host2 = hosts.id)
    AND (commlinks.host1 = ? OR commlinks.host2 = ?)
    AND hosts.id != ?
    ORDER BY hosts.name, hosts.id
  ");
  my @hosts = ();
  $sth->execute($id, $id, $id); 
  while (my $host = $sth->fetchrow_hashref) {
    push @hosts, $host
  }
  $sth->finish;
  return @hosts;
}


return 1;

