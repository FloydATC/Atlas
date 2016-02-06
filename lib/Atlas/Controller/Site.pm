package Atlas::Controller::Site;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# Action
sub welcome {
  my $self = shift;

  # Render response
  $self->render( text => 'Hello there.' );
}

sub map {
  my $self = shift;

  # Render response
  $self->render( template => 'site_map' );

}

sub move {
  my $self = shift;
  
  # Render response
  $self->render( template => 'site_move', type => 'text', format => 'text' );
}

sub svg {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $id = $self->param('id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Site->query_hostgroups, $id, $delay->begin);
      $db->query(Atlas::Model::Site->query_hosts, $id, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( hostgroups => $res->hashes->to_array );
      };
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( hosts => $res->hashes->to_array );
      };
      
      # Render response
      $self->render( template => 'site_svg', type => 'svg', format => 'svg' );
    }
  )->wait;

}

sub popup {
  my $self = shift;

  # Render response;  
  $self->render( template => 'site_popup', type => 'html', format => 'html' );
}



1;
