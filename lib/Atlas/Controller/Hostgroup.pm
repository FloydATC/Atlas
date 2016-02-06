package Atlas::Controller::Hostgroup;
use Mojo::Base 'Mojolicious::Controller';



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
      $db->query(Atlas::Model::Hostgroup->query_move, $relx, $rely, $id, $delay->begin);
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
      $db->query(Atlas::Model::Hostgroup->query_get, $id, $delay->begin);
      $db->query(Atlas::Model::Hostgroup->query_hosts, $id, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( hostgroup => $res->hashes->first );
      };
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( hosts => $res->hashes->to_array );
      };

      # Render response
      $self->render( template => 'hostgroup_popup', type => 'html', format => 'html' );
    }
  )->wait;
}


1;
