package Atlas::Controller::Host;
use Mojo::Base 'Mojolicious::Controller';

#use Socket;
use Atlas::Net::Ping;
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
  unless ($id) { $self->res->code(400); $self->render( text => 'Required parameter missing' ); return; }
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
  unless ($name) { $self->res->code(400); $self->render( text => 'Required parameter missing' ); return; }
  my $ip = $self->param('ip');
  my $site = $self->param('site'); # Site ID
  my $hostgroup_name = $self->param('hostgroup') || undef; # Note: Treat blank string as NULL
  my $x = $self->param('x');
  my $y = $self->param('y');
  my $host_id = undef;
  my $hostgroup_id = undef;
  
  if ($ip eq '' || $ip eq '0.0.0.0') { $ip = undef; }
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Host->query_insert, $name, $ip, $site, $x, $y, $delay->begin);
      if ($hostgroup_name) {
        $db->query(Atlas::Model::Hostgroup->query_insert, $site, $hostgroup_name, $delay->begin);
      }
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        if ($err && $err =~ /Duplicate entry/) {
          # User error - Render response and exit early
          $self->flash(message => 'Host already exists');
          $self->res->code(303); 
          $self->redirect_to("/site/map?id=".$site);
          return;
        }
        die $err if $err;
        $host_id = $res->last_insert_id;
      };
      if ($hostgroup_name) {
        my $err = shift;
        my $res = shift;
        if ($err) {
          unless ($err =~ /Duplicate entry/) {
            die $err;
          }
        }
        $db->query(Atlas::Model::Hostgroup->query_find, $site, $hostgroup_name, $delay->begin);
      } else {
        $delay->pass;
      }
    },
    sub {
      my $delay = shift;
      if ($hostgroup_name) {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $hostgroup_id = $res->hashes->first->{'id'};
      };
      if ($hostgroup_id) {
        $db->query(Atlas::Model::Hostgroup->query_addmember, $hostgroup_id, $host_id, $delay->begin);
      } else {
        $delay->pass;
      }
    },
    sub {
      my $delay = shift;
      if ($hostgroup_id) {
        my $err = shift;
        my $res = shift;
        # Will fail if hostgroup name is NULL, this is harmless
      };

      # Render response
      $self->flash(message => 'Host created');
      $self->res->code(303); 
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
  unless ($site_id && $host_id && $hostgroup_name) { $self->res->code(400); $self->render( text => 'Required parameter missing' ); return; }
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
      $self->res->code(303);
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
  unless ($site_id && $host_id && $hostgroup_name) { $self->res->code(400); $self->render( text => 'Required parameter missing' ); return; }
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
      $self->res->code(303);
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


sub popup_connecthost {
  my $self = shift;

  # Popup dialog to create a commlink from one host to another

  $self->render_later;
  my $db = $self->mysql->db;
  my $site_id = $self->param('site_id');
  my $host_id = $self->param('host_id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Host->query_get, $host_id, $delay->begin);
      $db->query(Atlas::Model::Host->query_nonpeers, $host_id, $host_id, $host_id, $host_id, $host_id, $delay->begin); # Note: 5 x id (!!)
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
        $self->stash( hosts => $res->hashes->to_array );
      };

      # Render response
      $self->render( template => 'host_popup_connecthost', type => 'html', format => 'html' );
    }
  )->wait;
}


# Loopback request from SEEN thread 
sub seen {
  my $self = shift;

  my %seen = @{$self->req->params}; # ip => timestamp, ip => timestamp, ...

  if (%seen) {
    $self->render_later;
    my $db = $self->mysql->db;

    Mojo::IOLoop->delay(
      sub {
        my $delay = shift;
        # One query per ip/timestamp pair
        foreach my $host_ip (keys %seen) {
          $db->query(Atlas::Model::Host->query_seen_ip, $host_ip, $seen{$host_ip}, $delay->begin);
        }
      },
      sub {
        my $delay = shift;
        # One err/res pair per ip/timestamp pair
        foreach my $host_ip (keys %seen) {
          my $err = shift;
          my $res = shift;
          die $err if $err;
        };

        $db->query(Atlas::Model::World->query_recalc_states, $delay->begin);
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
  } else {
    # Render response
    $self->render( text => 'No updates', status => 500 );
  }

}


sub send_echo_request {
  my $self = shift;
  my $host_id = $self->param('host_id');
  my $host = {};

  $self->render_later;
  my $db = $self->mysql->db;
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Host->query_get, $host_id, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die "send_echo_request()/query_get FAILED\n\t".$err if $err;
        $host = $res->hashes->first;
      };

      # Send out three ICMP echo requests
      # The pcap thread is already listening for ICMP echo replies (and anything else)
      my $packet = Atlas::Net::Ping->new( destination => $host->{'ip'}, id => 1, seq => 1 );
      $packet->send if $packet;
      Mojo::IOLoop->timer(0.200 => sub {
        my $packet = Atlas::Net::Ping->new( destination => $host->{'ip'}, id => 1, seq => 2 );
        $packet->send if $packet;
      });
      Mojo::IOLoop->timer(0.400 => sub {
        my $packet = Atlas::Net::Ping->new( destination => $host->{'ip'}, id => 1, seq => 3 );
        $packet->send if $packet;
      });


      $db->query(Atlas::Model::Host->query_update_checked, $host->{'id'}, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die "send_echo_request()/query_update_checked FAILED\n\t".$err if $err;
      };

      # Render response
      $self->render( text => 'OK' );
    }
  )->wait;

}

1;

