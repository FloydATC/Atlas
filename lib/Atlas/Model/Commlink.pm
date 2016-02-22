package Atlas::Model::Commlink;


sub import_fields {
  return qw(
    node
    name
  );
}


sub query_insert {
  return "
    INSERT INTO commlinks (host1, host2, name)
    VALUES (?, ?, ?)
  ";
}


return 1;

