package Atlas;
use Mojo::Base 'Mojolicious';
use Mojo::mysql;

use Atlas::Model::World;
use Atlas::Model::Site;
use Atlas::Model::Sitegroup;
use Atlas::Model::Host;
use Atlas::Model::Hostgroup;
use Atlas::Model::Commlink;
use Data::Dumper;


sub startup {
  my $self = shift;

  my $config = $self->plugin('Config');
  $self->secrets($config->{'secrets'});
  
  $self->helper( mysql => sub {
    my $c = shift;
    my $DBHOST = $config->{'database'}->{'host'};
    my $DBNAME = $config->{'database'}->{'name'};
    my $DBUSER = $config->{'database'}->{'user'};
    my $DBPASS = $config->{'database'}->{'pass'};  
    state $handle = Mojo::mysql->new("mysql://$DBUSER:$DBPASS\@$DBHOST/$DBNAME");
    $handle->max_connections(25);
  });
  
  $self->helper( config => sub { $config } );

  my $r = $self->routes;
  $r->get('/world')->to(controller => 'World', action => 'welcome');
  $r->get('/world/map')->to(controller => 'World', action => 'map');
  $r->get('/world/import_begin')->to(controller => 'World', action => 'import_begin');
  $r->post('/world/import_preview')->to(controller => 'World', action => 'import_preview');
  $r->get('/world/svg')->to(controller => 'World', action => 'svg');
  $r->get('/worldmap/popup')->to(controller => 'World', action => 'menu');
  $r->get('/site')->to(controller => 'Site', action => 'welcome');
  $r->get('/site/map')->to(controller => 'Site', action => 'map');
  $r->post('/site/move')->to(controller => 'Site', action => 'move'); # Ajax
  $r->post('/site/insert')->to(controller => 'Site', action => 'insert'); # Ajax
  $r->post('/site/addgroup')->to(controller => 'Site', action => 'addgroup_byname'); # Ajax
  $r->post('/site/removegroup')->to(controller => 'Site', action => 'removegroup'); # Ajax 
  $r->get('/site/popup')->to(controller => 'Site', action => 'popup');
  $r->get('/sitemap/popup')->to(controller => 'Site', action => 'menu'); # Clicked on site icon
  $r->get('/site/popup_new')->to(controller => 'Site', action => 'popup_new'); # Create new site
  $r->get('/site/popup_addgroup')->to(controller => 'Site', action => 'popup_addgroup'); # Add sitegroup membership
  $r->get('/site/popup_removegroup')->to(controller => 'Site', action => 'popup_removegroup'); # Remove sitegroup membership
  $r->get('/site/svg')->to(controller => 'Site', action => 'svg');
  $r->post('/sitegroup/move')->to(controller => 'Sitegroup', action => 'move');
  $r->post('/sitegroup/addmember')->to(controller => 'Sitegroup', action => 'addmember');
  $r->post('/sitegroup/removemember')->to(controller => 'Sitegroup', action => 'removemember');
  $r->get('/sitegroup/popup')->to(controller => 'Sitegroup', action => 'popup');
  $r->get('/sitegroup/popup_addmember')->to(controller => 'Sitegroup', action => 'popup_addmember');
  $r->get('/sitegroup/popup_removemember')->to(controller => 'Sitegroup', action => 'popup_removemember');
  $r->post('/host/move')->to(controller => 'Host', action => 'move');
  $r->get('/host/popup')->to(controller => 'Host', action => 'popup'); # Clicked on host icon
  $r->get('/host/popup_new')->to(controller => 'Host', action => 'popup_new'); # Create new host
  $r->post('/host/insert')->to(controller => 'Host', action => 'insert'); # Ajax
  $r->post('/host/addgroup')->to(controller => 'Host', action => 'addgroup_byname'); # Ajax
  $r->post('/host/removegroup')->to(controller => 'Host', action => 'removegroup'); # Ajax 
  $r->get('/host/popup_addgroup')->to(controller => 'Host', action => 'popup_addgroup'); # Add hostgroup membership
  $r->get('/host/popup_removegroup')->to(controller => 'Host', action => 'popup_removegroup'); # Remove hostgroup membership
  $r->get('/host/popup_connecthost')->to(controller => 'Host', action => 'popup_connecthost'); # Create new commlink
  $r->post('/hostgroup/move')->to(controller => 'Hostgroup', action => 'move'); # Ajax
  $r->post('/hostgroup/addmember')->to(controller => 'Hostgroup', action => 'addmember'); # Ajax
  $r->post('/hostgroup/removemember')->to(controller => 'Hostgroup', action => 'removemember'); # Ajax
  $r->get('/hostgroup/popup_addmember')->to(controller => 'Hostgroup', action => 'popup_addmember');
  $r->get('/hostgroup/popup_removemember')->to(controller => 'Hostgroup', action => 'popup_removemember');
  $r->get('/hostgroup/popup')->to(controller => 'Hostgroup', action => 'popup');
  $r->post('/commlink/insert')->to(controller => 'Commlink', action => 'insert'); # Ajax
  $r->post('/loopback/seen')->to(controller => 'Host', action => 'seen'); # SEEN thread
  $r->post('/loopback/beam')->to(controller => 'World', action => 'beam'); # BEAM thread
  $r->post('/host/send_echo_request')->to(controller => 'Host', action => 'send_echo_request'); # Initiated by BEAM
    
}

return 1;
