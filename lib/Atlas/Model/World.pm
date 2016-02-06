package Atlas::Model::World;

sub sites {
  my $class = shift;
  my $c = shift;
  my $dbh = shift;

  #print "$class sites c=$c dbh=$dbh\n";
  my $sth = $dbh->prepare("
    SELECT * 
    FROM sites
    ORDER BY sites.id   
  ");
  $sth->execute();
  my @sites = ();
  while (my $site = $sth->fetchrow_hashref) {
    push @sites, $site;
  }
  $sth->finish;
  return @sites;
}

sub sitegroups {
  my $class = shift;
  my $c = shift;
  my $dbh = shift;

  #print "$class sitegroups c=$c dbh=$dbh\n";
  my $sth = $dbh->prepare("
    SELECT 
      sitegroups.id,
      sitegroups.name,
      MIN(sites.x) AS x,
      MIN(sites.y) AS y,
      MAX(sites.x)-MIN(sites.x) AS width,
      MAX(sites.y)-MIN(sites.y) AS height,
      COUNT(sites.id) AS members
    FROM sites
    LEFT JOIN sitegroupmembers ON (sitegroupmembers.site = sites.id)
    LEFT JOIN sitegroups ON (sitegroups.id = sitegroupmembers.sitegroup)
    GROUP BY sitegroups.id
    HAVING members > 0
    ORDER BY sitegroups.id
  ");
  $sth->execute();
  my @sitegroups = ();
  while (my $sitegroup = $sth->fetchrow_hashref) {
    push @sitegroups, $sitegroup;
  }
  #print "found ".scalar(@sitegroups)."\n";
  return @sitegroups;
}



return 1;

