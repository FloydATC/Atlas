package Atlas;
use Mojo::Base 'Mojolicious';
use Mojo::mysql;

use Atlas::Model::World;
use Atlas::Model::Site;
use Atlas::Model::Sitegroup;
use Atlas::Model::Host;
use Atlas::Model::Hostgroup;
use Atlas::Model::Commlink;


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
  });

  my $r = $self->routes;
  $r->get('/world')->to(controller => 'World', action => 'welcome');
  $r->get('/world/map')->to(controller => 'World', action => 'map');
  $r->get('/world/svg')->to(controller => 'World', action => 'svg');
  $r->get('/worldmap/popup')->to(controller => 'World', action => 'menu');
  $r->get('/site')->to(controller => 'Site', action => 'welcome');
  $r->get('/site/map')->to(controller => 'Site', action => 'map');
  $r->post('/site/move')->to(controller => 'Site', action => 'move');
  $r->get('/site/popup')->to(controller => 'Site', action => 'popup');
  $r->get('/sitemap/popup')->to(controller => 'Site', action => 'menu');
  $r->get('/site/svg')->to(controller => 'Site', action => 'svg');
  $r->post('/sitegroup/move')->to(controller => 'Sitegroup', action => 'move');
  $r->get('/sitegroup/popup')->to(controller => 'Sitegroup', action => 'popup');
  $r->post('/host/move')->to(controller => 'Host', action => 'move');
  $r->get('/host/popup')->to(controller => 'Host', action => 'popup');
  $r->post('/hostgroup/move')->to(controller => 'Hostgroup', action => 'move');
  $r->get('/hostgroup/popup')->to(controller => 'Hostgroup', action => 'popup');
    
}

return 1;
