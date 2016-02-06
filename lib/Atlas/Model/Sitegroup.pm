package Atlas::Model::Sitegroup;

sub get {
  my $class = shift;
  my $c = shift;
  my $dbh = shift;
  my $id = shift;
  #print "$class get c=$c dbh=$dbh id=$id\n";
  my $sth = $dbh->prepare("
    SELECT * 
    FROM sitegroups
    WHERE id = ?
    ORDER BY id
    LIMIT 1
  ");
  $sth->execute($id);
  if (my $sitegroup = $sth->fetchrow_hashref) {
    return $sitegroup;
  }
  return {};
}

sub link {
  my $class = shift;
  my $c = shift;  
  my $dbh = shift;
  my $id = shift;
 
  my $sitegroup = get($class, $c, $dbh, $id);     
  return "<A href=\"/sitegroup/details?id=".$sitegroup->{'id'}."\">".$sitegroup->{'name'}."</A>";
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
    UPDATE sites    
    LEFT JOIN sitegroupmembers ON (sitegroupmembers.site = sites.id)
    LEFT JOIN sitegroups ON (sitegroups.id = sitegroupmembers.sitegroup)
    SET sites.x = sites.x + ?, sites.y = sites.y + ?
    WHERE sitegroups.id = ?
  ");
  $sth->execute($relx, $rely, $id);
  $sth->finish;
  return 1;
}

sub sites {
  my $class = shift;
  my $c = shift;
  my $dbh = shift;
  my $id = shift;

  #print "$class hosts c=$c dbh=$dbh id=$id\n";
  my $sth = $dbh->prepare("
    SELECT sites.*
    FROM sites
    LEFT JOIN sitegroupmembers ON (sitegroupmembers.site = sites.id)
    LEFT JOIN sitegroups ON (sitegroups.id = sitegroupmembers.sitegroup)
    WHERE sitegroups.id = ?
    ORDER BY sites.name, sites.id
  ");
  $sth->execute($id);
  my @sites = ();
  while (my $site = $sth->fetchrow_hashref) {
    push @sites, $site;
  }
  $sth->finish;
  return @sites;
}




return 1;

