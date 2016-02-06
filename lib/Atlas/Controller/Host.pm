package Atlas::Controller::Host;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# Action
sub welcome {
  my $self = shift;

  # Render response
  $self->render( text => 'Hello there.' );
}

sub move {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $relx = $self->param('relx');
  my $rely = $self->param('rely');
  my $id = $self->param('id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Host->query_move, $relx, $rely, $id, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
      };

      # Render response
      $self->render( text => 'OK' );
    }
  )->wait;
}

sub popup {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $id = $self->param('id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Host->query_get, $id, $delay->begin);
      $db->query(Atlas::Model::Host->query_peers, $id, $id, $id, $delay->begin); # Note! 3 equal placeholders
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( host => $res->hashes->first );
      };
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( peers => $res->hashes->to_array );
      };

      # Render response
      $self->render( template => 'host_popup', type => 'html', format => 'html' );
    }
  )->wait;
}



1;
