package Atlas::Controller::World;
use Mojo::Base 'Mojolicious::Controller';

use Text::CSV_XS;
use Data::Dumper;


# Action
sub welcome {
  my $self = shift;

  # Render response
  $self->render( template => 'welcome' );
}

sub import_begin {
  my $self = shift;

  # Render response
  $self->render( template => 'import_begin' );
}

sub import {
  my $self = shift;

  # Key parameters
  my $file = $self->req->upload('file');
  my $into = $self->param('into');

  # Redirect to appropriate form fragment
  if ($file && $file->size() > 0 && $into) {
    if ($into eq 'sites') { $self->redirect_to('/site/import'); }     
    if ($into eq 'hosts') { $self->redirect_to('/host/import'); }     
    if ($into eq 'commlinks') { $self->redirect_to('/commlink/import'); }     

    # Unknown 'into' selected. Empty response.
    $self->render( text => "" );  
  } else {
    # No file file uploaded yet, or 'into' not selected. Empty response.
    $self->render( text => "" );
  }

  return;
  
}



sub map {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;

  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::World->query_canvas_size, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        my $canvas = $res->hashes->first;
        my $min_w = 1280; 
        my $min_h = 1024; 
        if (!defined $canvas->{'width'} || $canvas->{'width'} < $min_w) { 
          $canvas->{'width'} = $min_w; 
        }
        if (!defined $canvas->{'height'} || $canvas->{'height'} < $min_w) { 
          $canvas->{'height'} = $min_w; 
        }
        $self->stash( width => $canvas->{'width'} );
        $self->stash( height => $canvas->{'height'} );
      };
      
      # Render response
      $self->render( template => 'world_map' );
    }
  );

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


# LONG running request - pull work from the database, 
# then initiate subrequests to do ICMP echo requests, SNMP scans, backups etc.
sub beam {
  my $self = shift;

  $self->inactivity_timeout(30);

  $self->render_later;
  my $db = $self->mysql->db;
  my $ua = $self->ua;  
  $self->write_chunk("Entering loop\n");
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      
      # Get a list of hosts that need to be pinged
      $db->query(Atlas::Model::Host->query_need_check, $delay->begin);
    },   
    sub {
      my $delay = shift;
      my @hosts = ();

      {
        my $err = shift; 
        my $res = shift; 
        print "need_check: $err\n" if $err;
        die $err if $err;
        @hosts = @{$res->hashes->to_array};
      };
      
      # Proceed to next step if there are no hosts that need checking
      unless (@hosts) {
        $delay->pass;
      }

      # Request that one ICMP echo request message be sent to each host      
      foreach my $host (@hosts) {      
        #print "Checking ".$host->{'ip'}." (last checked ".($host->{'checked'} || 'NEVER').")\n";
        # Use ~50ms interval so we don't completely flood the network
        Mojo::IOLoop->timer(0.050 => sub {
          $self->write_chunk("Checking ".$host->{'ip'}." (last checked ".($host->{'checked'} || 'NEVER').")\n");
          my $url = $self->url_for('/host/send_echo_request');
          my $head = { Accept=>'*/*' };
          my $form = { 'host_id'=>$host->{'id'} };
          $ua->post($url, $head, form => $form, $delay->begin);
        
        });
      }
      
    },
    sub {
      my $delay = shift;

      $self->write_chunk("Exiting\n");
      $self->finish(); # Final chunk
    }

  )->wait;
}

1;

