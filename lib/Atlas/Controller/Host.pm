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


sub insert {
  my $self = shift;

  # This method is used to insert a single new Host

  $self->render_later;
  my $db = $self->mysql->db;
  my $name = $self->param('name');
  my $ip = $self->param('ip');
  my $site = $self->param('site'); # Site ID
  my $hostgroup = $self->param('hostgroup') || undef; # Note: Hostgroup name. Treat blank string as NULL
  my $x = $self->param('x');
  my $y = $self->param('y');
  my $host_id = undef;
  my $hostgroup_id = undef;
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Host->query_insert, $name, $ip, $site, $x, $y, $delay->begin);
      $db->query(Atlas::Model::Hostgroup->query_insert, $site, $hostgroup, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $host_id = $res->last_insert_id;
      };
      {
        my $err = shift;
        my $res = shift;
        # Will fail if hostgroup already exists or name is NULL, this is harmless
      };
      $db->query(Atlas::Model::Hostgroup->query_find, $site, $hostgroup, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        # Will fail if hostgroup name is NULL, this is harmless
        $hostgroup_id = $res->hashes->first->{'id'} unless $err;
      };
      $db->query(Atlas::Model::Hostgroup->query_addmember, $hostgroup_id, $host_id, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        # Will fail if hostgroup name is NULL, this is harmless
      };

      # Render response
      $self->flash(message => 'Host created');
      $self->redirect_to("/site/map?id=".$site);
    }
  )->wait;
}


sub addgroup_byname {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $site_id = $self->param('site_id');
  my $host_id = $self->param('host_id');
  my $hostgroup_name = $self->param('hostgroup');
  my $hostgroup_id = undef;
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Hostgroup->query_insert, $site_id, $hostgroup_name, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        # Will fail if hostgroup already exists or name is NULL, this is harmless
      };
      $db->query(Atlas::Model::Hostgroup->query_find, $site_id, $hostgroup_name, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        # Will fail if hostgroup name is NULL, this is harmless
        $hostgroup_id = $res->hashes->first->{'id'} unless $err;
      };
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
      $self->flash(message => 'Hostgroup member added');
      $self->redirect_to("/site/map?id=".$site_id);
    }
  )->wait;
}
 

sub removegroup {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $site_id = $self->param('site_id');
  my $host_id = $self->param('host_id'); # Host ID
  my $hostgroup_name = $self->param('hostgroup'); # Hostgroup ID
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Hostgroup->query_removemember, $hostgroup_name, $host_id, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
      };

      # Render response
      $self->flash(message => 'Hostgroup member removed');
      $self->redirect_to("/site/map?id=".$site_id);
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


sub popup_new {
  my $self = shift;

  # Popup dialog to create a new Host

  $self->render_later;
  my $db = $self->mysql->db;
  my $site_id = $self->param('site_id');
  my $hostgroup_id = $self->param('hostgroup_id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Site->query_get, $site_id, $delay->begin);
      $db->query(Atlas::Model::Hostgroup->query_get, $hostgroup_id, $delay->begin);
      $db->query(Atlas::Model::Site->query_hostgroups, $site_id, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( site => $res->hashes->first );
      };
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
        $self->stash( hostgroups => $res->hashes->to_array );
      };
        
      # Render response
      $self->render( template => 'host_popup_new', type => 'html', format => 'html' );
    }
  )->wait;
}


sub popup_addgroup {
  my $self = shift;

  # Popup dialog to add group membership

  $self->render_later;
  my $db = $self->mysql->db;
  my $site_id = $self->param('site_id');
  my $host_id = $self->param('host_id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Host->query_notmemberof, $site_id, $host_id, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( hostgroups => $res->hashes->to_array );
      };

      # Render response
      $self->render( template => 'host_popup_addgroup', type => 'html', format => 'html' );
    }
  )->wait;
}


sub popup_removegroup {
  my $self = shift;

  # Popup dialog to delete group membership

  $self->render_later;
  my $db = $self->mysql->db;
  my $site_id = $self->param('site_id');
  my $host_id = $self->param('host_id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Host->query_memberof, $site_id, $host_id, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( hostgroups => $res->hashes->to_array );
      };

      # Render response
      $self->render( template => 'host_popup_removegroup', type => 'html', format => 'html' );
    }
  )->wait;
}



1;
