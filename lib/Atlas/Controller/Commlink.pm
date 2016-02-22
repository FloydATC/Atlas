package Atlas::Controller::Commlink;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# Action
sub welcome {
  my $self = shift;

  # Render response
  $self->render( text => 'Hello there.' );
}


sub insert {
  my $self = shift;

  # This method is used to insert a single new Commlink

  $self->render_later;
  my $db = $self->mysql->db;
  my $host1 = $self->param('host1');
  my $host2 = $self->param('host2');
  my $name = ($self->param('type') || 'generic_link').' '.($self->param('speed') || 'unknown_speed');
  my $site_id = $self->param('site_id'); # Site ID
  unless ($host1 && $host2) { $self->res->code(400); $self->render( text => 'Required parameter missing' ); return; }
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Commlink->query_insert, $host1, $host2, $name, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err
      };

      # Render response
      $self->flash(message => 'Commlink created');
      $self->redirect_to("/site/map?id=".$site_id);
    }
  )->wait;
}


sub import {
  my $self = shift;

  # Key parameters
  my $file = $self->req->upload('file');
  my $separator = $self->param('separator');
  my $skip = $self->param('skip');
  my $into = $self->param('into');

  $self->render( text => "commlink imports not yet implemented, sorry" );
}


1;
