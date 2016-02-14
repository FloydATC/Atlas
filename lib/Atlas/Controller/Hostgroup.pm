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
  unless ($id) { $self->res->code(400); $self->render( text => 'Required parameter missing' ); return; }
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


sub addmember {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $site_id = $self->param('site_id');
  my $host_id = $self->param('host_id');
  my $hostgroup_id = $self->param('hostgroup_id');
  unless ($site_id && $host_id && $hostgroup_id) { $self->res->code(400); $self->render( text => 'Required parameter missing' ); return; }
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Hostgroup->query_addmember, $hostgroup_id, $host_id, $delay->begin);
    },   
    sub {
      my $delay = shift;
      {
        my $err = shift; 
        my $res = shift; 
        die $err if $err;
      };

      # Render response
      $self->flash(message => 'Host added to group');
      $self->redirect_to("/site/map?id=$site_id");
    }
  )->wait;
}


sub removemember { 
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $site_id = $self->param('site_id');
  my $host_id = $self->param('host_id');
  my $hostgroup_id = $self->param('hostgroup_id');
  unless ($site_id && $host_id && $hostgroup_id) { $self->res->code(400); $self->render( text => 'Required parameter missing' ); return; }
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Hostgroup->query_removemember, $hostgroup_id, $host_id, $delay->begin);
    },   
    sub {
      my $delay = shift;
      {
        my $err = shift; 
        my $res = shift; 
        die $err if $err;
      };

      # Render response
      $self->flash(message => 'Host removed from group');
      $self->redirect_to("/site/map?id=$site_id");
    }
  )->wait;
}


sub popup_addmember {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $site_id = $self->param('site_id');
  my $hostgroup_id = $self->param('hostgroup_id');
  my $id = $self->param('id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Hostgroup->query_get, $hostgroup_id, $delay->begin);
      $db->query(Atlas::Model::Hostgroup->query_nonmembers, $site_id, $hostgroup_id, $delay->begin);
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
      $self->render( template => 'hostgroup_popup_addmember', type => 'html', format => 'html' );
    }
  )->wait;
}


sub popup_removemember {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $site_id = $self->param('site_id');
  my $hostgroup_id = $self->param('hostgroup_id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Hostgroup->query_get, $hostgroup_id, $delay->begin);
      $db->query(Atlas::Model::Hostgroup->query_members, $hostgroup_id, $delay->begin);
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
      $self->render( template => 'hostgroup_popup_removemember', type => 'html', format => 'html' );
    }
  )->wait;
}



1;
