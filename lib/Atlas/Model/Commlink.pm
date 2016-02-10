package Atlas::Model::Commlink;

sub query_insert {
  return "
    INSERT INTO commlinks (host1, host2, name)
    VALUES (?, ?, ?)
  ";
}


return 1;

