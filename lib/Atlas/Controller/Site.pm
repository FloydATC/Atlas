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

  $self->render_later;
  my $db = $self->mysql->db;  
  my $id = $self->param('id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Site->query_get, $id, $delay->begin);  
    },   
    sub {
      my $delay = shift;
      {
        my $err = shift; 
        my $res = shift; 
        die $err if $err;
        $self->stash( site => $res->hashes->first );
      };
      
      # Render response
      $self->render( template => 'site_map' );
    }
  )->wait;
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
      $db->query(Atlas::Model::Site->query_move, $relx, $rely, $id, $delay->begin);
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

  # This method is used to insert a single new Site
  # If a Sitegroup name is specified, that sitegroup is created automatically
  # If that Sitegroup name already exists, the existing Sitegroup will be used
  # If a Sitegroup name is specified, the new Site is then added as a member of that Sitegroup
  
  $self->render_later;
  my $db = $self->mysql->db;
  my $name = $self->param('name');
  my $sitegroup = $self->param('sitegroup') || undef; # Treat blank string as NULL
  my $x = $self->param('x');
  my $y = $self->param('y');
  my $site_id = undef;
  my $sitegroup_id = undef;
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Site->query_insert, $name, $x, $y, $delay->begin);
      $db->query(Atlas::Model::Sitegroup->query_insert, $sitegroup, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $site_id = $res->last_insert_id;
      };
      {
        my $err = shift;
        my $res = shift;
        # Will fail if sitegroup already exists or name is NULL, this is harmless
      };
      $db->query(Atlas::Model::Sitegroup->query_find, $sitegroup, $delay->begin);      
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        # Will fail if sitegroup name is NULL, this is harmless
        $sitegroup_id = $res->hashes->first->{'id'} unless $err;
      };
      $db->query(Atlas::Model::Sitegroup->query_addmember, $sitegroup_id, $site_id, $delay->begin);      
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        # Will fail if sitegroup name is NULL, this is harmless
      };

      # Render response
      $self->flash(message => 'Site created');
      $self->redirect_to("/world/map");
    }
  )->wait;
}


sub addgroup {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $id = $self->param('id');
  my $sitegroup = $self->param('sitegroup'); # Note: Sitegroup Name!
  my $sitegroup_id = undef;
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Sitegroup->query_insert, $sitegroup, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        # Will fail if sitegroup already exists or name is NULL, this is harmless
      };
      $db->query(Atlas::Model::Sitegroup->query_find, $sitegroup, $delay->begin);      
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        # Will fail if sitegroup name is NULL, this is harmless
        $sitegroup_id = $res->hashes->first->{'id'} unless $err;
      };
      $db->query(Atlas::Model::Sitegroup->query_addmember, $sitegroup_id, $id, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
      };

      # Render response
      $self->flash(message => 'Sitegroup member added');
      $self->redirect_to("/world/map");
    }
  )->wait;
}


sub removegroup {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $id = $self->param('id');
  my $sitegroup = $self->param('sitegroup'); # Sitegroup ID
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Sitegroup->query_removemember, $sitegroup, $id, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
      };

      # Render response
      $self->flash(message => 'Sitegroup member removed');
      $self->redirect_to("/world/map");
    }
  )->wait;
}


sub svg {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $id = $self->param('id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Site->query_get, $id, $delay->begin);
      $db->query(Atlas::Model::Site->query_hostgroups, $id, $delay->begin);
      $db->query(Atlas::Model::Site->query_hosts, $id, $delay->begin);
      $db->query(Atlas::Model::Site->query_lanlinks, $id, $id, $delay->begin);
      $db->query(Atlas::Model::Site->query_wanlinks, $id, $id, $delay->begin);
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
        $self->stash( hostgroups => $res->hashes->to_array );
      };
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( hosts => $res->hashes->to_array );
      };
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( lanlinks => $res->hashes->to_array );
      };
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( wanlinks => $res->hashes->to_array );
      };
      
      # Render response
      $self->render( template => 'site_svg', type => 'svg', format => 'svg' );
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
      $db->query(Atlas::Model::Site->query_get, $id, $delay->begin);
      $db->query(Atlas::Model::Site->query_hosts, $id, $delay->begin);
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
        $self->stash( hosts => $res->hashes->to_array );
      };
      
      # Render response
      $self->render( template => 'site_popup', type => 'html', format => 'html' );
    }
  )->wait;
}


sub popup_new {
  my $self = shift;

  # Popup dialog to create a new Site

  $self->render_later;
  my $db = $self->mysql->db;
  my $sitegroup_id = $self->param('sitegroup_id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Sitegroup->query_get, $sitegroup_id, $delay->begin);
      $db->query(Atlas::Model::World->query_sitegroups, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( sitegroup => $res->hashes->first );
      };
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( sitegroups => $res->hashes->to_array );
      };
      
      # Render response
      $self->render( template => 'site_popup_new', type => 'html', format => 'html' );
    }
  )->wait;
}


sub popup_addgroup {
  my $self = shift;

  # Popup dialog to add group membership

  $self->render_later;
  my $db = $self->mysql->db;
  my $id = $self->param('id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Site->query_notmemberof, $id, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( sitegroups => $res->hashes->to_array );
      };
      
      # Render response
      $self->render( template => 'site_popup_addgroup', type => 'html', format => 'html' );
    }
  )->wait;
}


sub popup_removegroup {
  my $self = shift;

  # Popup dialog to delete group membership

  $self->render_later;
  my $db = $self->mysql->db;
  my $id = $self->param('id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Site->query_memberof, $id, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( sitegroups => $res->hashes->to_array );
      };
      
      # Render response
      $self->render( template => 'site_popup_removegroup', type => 'html', format => 'html' );
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
      $db->query(Atlas::Model::Site->query_get, $id, $delay->begin);
      $db->query(Atlas::Model::Site->query_hosts, $id, $delay->begin);
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
        $self->stash( hosts => $res->hashes->to_array );
      };
      
      # Render response
      $self->render( template => 'site_menu', type => 'html', format => 'html' );
    }
  )->wait;
}



1;
