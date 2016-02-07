package Atlas::Controller::Sitegroup;
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
      $db->query(Atlas::Model::Sitegroup->query_move, $relx, $rely, $id, $delay->begin);
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


sub addmember {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $id = $self->param('id'); # Sitegroup ID
  my $site = $self->param('site'); # Site ID
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Sitegroup->query_addmember, $id, $site, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
      };

      # Render response
      $self->flash(message => 'Site added to group');
      $self->redirect_to("/world/map");
    }
  )->wait;
}


sub removemember {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $id = $self->param('id'); # Sitegroup ID
  my $site = $self->param('site'); # Site ID
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Sitegroup->query_removemember, $id, $site, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
      };

      # Render response
      $self->flash(message => 'Site removed from group');
      $self->redirect_to("/world/map");
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
      $db->query(Atlas::Model::Sitegroup->query_get, $id, $delay->begin);  
      $db->query(Atlas::Model::Sitegroup->query_sites, $id, $delay->begin);
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
        $self->stash( sites => $res->hashes->to_array );
      };
      
      # Render response
      $self->render( template => 'sitegroup_popup', type => 'html', format => 'html' );
    }
  )->wait;
} 
 

sub popup_addmember {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;  
  my $id = $self->param('id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Sitegroup->query_get, $id, $delay->begin);  
      $db->query(Atlas::Model::Sitegroup->query_nonmembers, $id, $delay->begin);
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
        $self->stash( sites => $res->hashes->to_array );
      };
      
      # Render response
      $self->render( template => 'sitegroup_popup_addmember', type => 'html', format => 'html' );
    }
  )->wait;
} 
 

sub popup_removemember {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;  
  my $id = $self->param('id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Sitegroup->query_get, $id, $delay->begin);  
      $db->query(Atlas::Model::Sitegroup->query_members, $id, $delay->begin);
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
        $self->stash( sites => $res->hashes->to_array );
      };
      
      # Render response
      $self->render( template => 'sitegroup_popup_removemember', type => 'html', format => 'html' );
    }
  )->wait;
} 
 

1;
