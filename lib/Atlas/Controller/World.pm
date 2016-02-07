package Atlas::Controller::World;
use Mojo::Base 'Mojolicious::Controller';



# Action
sub welcome {
  my $self = shift;

  # Render response
  $self->render( text => 'Hello there.' );
}

sub map {
  my $self = shift;

  # Render response
  $self->render( template => 'world_map' );
}


sub svg {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $id = $self->param('id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::World->query_wanlinks, $delay->begin);
      $db->query(Atlas::Model::World->query_sitegroups, $delay->begin);
      $db->query(Atlas::Model::World->query_sites, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( wanlinks => $res->hashes->to_array );
      };
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( sitegroups => $res->hashes->to_array );
      };
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( sites => $res->hashes->to_array );
      };

      # Render response
      $self->render( template => 'world_svg', type => 'svg', format => 'svg' );
    }
  )->wait;

}


sub menu {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;  
  my $id = $self->param('id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::World->query_sites, $delay->begin);
    },   
    sub {
      my $delay = shift;
      {
        my $err = shift; 
        my $res = shift; 
        die $err if $err;
        $self->stash( sites => $res->hashes->to_array );
      };
      
      # Render response
      $self->render( template => 'world_menu', type => 'html', format => 'html' );
    }
  )->wait;
} 



1;
