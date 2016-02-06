package Atlas::Model::Commlink;

sub get {
  my $class = shift;
  my $c = shift;
  my $dbh = shift;
  my $id = shift;
  #print "$class get c=$c dbh=$dbh id=$id\n";
  my $sth = $dbh->prepare("
    SELECT * 
    FROM commlinks
    WHERE id = ?
    ORDER BY id
    LIMIT 1
  ");
  $sth->execute($id);
  if (my $commlink = $sth->fetchrow_hashref) {
    return $commlink;
  }
  return {};
}

sub link {
  my $class = shift;
  my $c = shift;
  my $dbh = shift;
  my $id = shift;
 
  my $commlink = get($class, $c, $dbh, $id);          
  return "<A href=\"/commlink/details?id=".$commlink->{'id'}."\">".$commlink->{'name'}."</A>";
}



return 1;

