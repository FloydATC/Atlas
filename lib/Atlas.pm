package Atlas;
use Mojo::Base 'Mojolicious';

use DBI;
use Atlas::Model::World;
use Atlas::Model::Site;
use Atlas::Model::Sitegroup;
use Atlas::Model::Host;
use Atlas::Model::Hostgroup;
use Atlas::Model::Commlink;

sub startup {
  my $self = shift;

  $self->secrets(['woo']);
  
  $self->helper( dbh => sub {
    my $c = shift;
    my $DBTYPE = 'mysql';
    my $DBHOST = 'zeus';
    my $DBNAME = 'atlas';
    my $DBUSER = 'atlas';
    my $DBPASS = 'atlas';  
    return DBI->connect("dbi:$DBTYPE:$DBNAME:$DBHOST", $DBUSER, $DBPASS);
  });

  $self->helper( atlas_world_sitegroups => sub { return Atlas::Model::World->sitegroups(@_); });
  $self->helper( atlas_world_sites      => sub { return Atlas::Model::World->sites(@_); });
  $self->helper( atlas_site_get         => sub { return Atlas::Model::Site->get(@_); });
  $self->helper( atlas_site_link        => sub { return Atlas::Model::Site->link(@_); });
  $self->helper( atlas_site_move        => sub { return Atlas::Model::Site->move(@_); });
  $self->helper( atlas_site_hostgroups  => sub { return Atlas::Model::Site->hostgroups(@_); });
  $self->helper( atlas_site_hosts       => sub { return Atlas::Model::Site->hosts(@_); });
  $self->helper( atlas_sitegroup_get    => sub { return Atlas::Model::Sitegroup->get(@_); });
  $self->helper( atlas_sitegroup_link   => sub { return Atlas::Model::Sitegroup->link(@_); });
  $self->helper( atlas_sitegroup_move   => sub { return Atlas::Model::Sitegroup->move(@_); });
  $self->helper( atlas_sitegroup_sites  => sub { return Atlas::Model::Sitegroup->sites(@_); });
  $self->helper( atlas_host_get         => sub { return Atlas::Model::Host->get(@_); });
  $self->helper( atlas_host_link        => sub { return Atlas::Model::Host->link(@_); });
  $self->helper( atlas_host_move        => sub { return Atlas::Model::Host->move(@_); });
  $self->helper( atlas_host_peers       => sub { return Atlas::Model::Host->peers(@_); });
  $self->helper( atlas_hostgroup_get    => sub { return Atlas::Model::Hostgroup->get(@_); });
  $self->helper( atlas_hostgroup_hosts  => sub { return Atlas::Model::Hostgroup->hosts(@_); });
  $self->helper( atlas_hostgroup_link   => sub { return Atlas::Model::Hostgroup->link(@_); });
  $self->helper( atlas_hostgroup_move   => sub { return Atlas::Model::Hostgroup->move(@_); });
  $self->helper( atlas_commlink_link    => sub { return Atlas::Model::Commlink->link(@_); });

  my $r = $self->routes;
  $r->get('/world')->to(controller => 'World', action => 'welcome');
  $r->get('/world/map')->to(controller => 'World', action => 'map');
  $r->get('/world/svg')->to(controller => 'World', action => 'svg');
  $r->get('/site')->to(controller => 'Site', action => 'welcome');
  $r->get('/site/map')->to(controller => 'Site', action => 'map');
  $r->post('/site/move')->to(controller => 'Site', action => 'move');
  $r->get('/site/popup')->to(controller => 'Site', action => 'popup');
  $r->get('/site/svg')->to(controller => 'Site', action => 'svg');
  $r->post('/sitegroup/move')->to(controller => 'Sitegroup', action => 'move');
  $r->get('/sitegroup/popup')->to(controller => 'Sitegroup', action => 'popup');
  $r->post('/host/move')->to(controller => 'Host', action => 'move');
  $r->get('/host/popup')->to(controller => 'Host', action => 'popup');
  $r->post('/hostgroup/move')->to(controller => 'Hostgroup', action => 'move');
  $r->get('/hostgroup/popup')->to(controller => 'Hostgroup', action => 'popup');
    
}

return 1;
