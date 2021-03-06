package Atlas::Controller::Site;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Home;

use Text::CSV_XS;
use Data::Dumper;

# Action
sub welcome {
  my $self = shift;

  # Render response
  $self->render( text => 'Hello there.' );
}


sub details {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $site_id = $self->param('site_id');
  unless ($site_id) { $self->res->code(400); $self->render( text => 'Required parameter missing' ); return; }

  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Site->query_get, $site_id, $delay->begin);
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
      $self->render( template => 'site_details', type => 'html', format => 'html' );
    }
  )->wait;

}

sub map {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;  
  my $site_id = $self->param('site_id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Site->query_get, $site_id, $delay->begin);  
      $db->query(Atlas::Model::Site->query_dimensions, $site_id, $delay->begin);  
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
  unless ($id) { $self->res->code(400); $self->render( text => 'Required parameter missing' ); return; }
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
  my $site_name = $self->param('name'); # Required
  unless ($site_name) { $self->res->code(400); $self->render( text => 'Required parameter missing' ); return; }
  my $sitegroup_name = $self->param('sitegroup') || undef; # Treat blank string as NULL
  my $x = $self->param('x');
  my $y = $self->param('y');
  my $site_id = undef;
  my $sitegroup_id = undef;
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Site->query_insert, $site_name, $x, $y, $delay->begin);
      if ($sitegroup_name) {
        $db->query(Atlas::Model::Sitegroup->query_insert, $sitegroup_name, $delay->begin);
      }
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        if ($err && $err =~ /Duplicate entry/) {
          # User error - Render response and exit early
          $self->flash(message => 'Site already exists');
          $self->res->code(303); 
          $self->redirect_to("/world/map");
          return;
        } 
        die $err if $err;

        $site_id = $res->last_insert_id;
      };
      if ($sitegroup_name) {
        my $err = shift;
        my $res = shift;
        if ($err) {
          unless ($err =~ /Duplicate entry/) {
            die $err;
          } 
        }
        $db->query(Atlas::Model::Sitegroup->query_find, $sitegroup_name, $delay->begin);      
      } else {
        $delay->pass; # Skip to next block immediately
      }
    },
    sub {
      my $delay = shift;
      if ($sitegroup_name) {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $sitegroup_id = $res->hashes->first->{'id'};
      };
      
      if ($sitegroup_id) {
        $db->query(Atlas::Model::Sitegroup->query_addmember, $sitegroup_id, $site_id, $delay->begin);      
      } else {
        $delay->pass; # Skip to next block immediately
      }
    },
    sub {
      my $delay = shift;
      if ($sitegroup_id) {
        my $err = shift;
        my $res = shift;
        die $err if $err;
      };

      # Render response
      $self->flash(message => 'Site created');
      $self->res->code(303);
      $self->redirect_to("/world/map");
    }
  )->wait;
}


sub addgroup_byname {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $id = $self->param('id');
  my $sitegroup = $self->param('sitegroup'); # Note: Sitegroup Name!
  unless ($id && $sitegroup) { $self->res->code(400); $self->render( text => 'Required parameter missing' ); return; }
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
      $self->res->code(303);
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
  unless ($id && $sitegroup) { $self->res->code(400); $self->render( text => 'Required parameter missing' ); return; }
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
      $self->res->code(303);
      $self->redirect_to("/world/map");
    }
  )->wait;
}


sub svg {
  my $self = shift;

  $self->render_later;
  my $db = $self->mysql->db;
  my $id = $self->param('id');
  my $icons = Mojo::Home->new()->rel_dir('public/icons');
  print "I think the icons are in $icons\n";
  $self->stash( 'icons' => $icons );
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
  my $site_id = $self->param('id');
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Site->query_get, $site_id, $delay->begin);
      $db->query(Atlas::Model::Site->query_hostgroups, $site_id, $delay->begin);
      $db->query(Atlas::Model::Site->query_hosts, $site_id, $delay->begin);
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


sub import {
  my $self = shift;
  
  # Key parameters
  my $file = $self->req->upload('file');
  my $separator = $self->param('separator');
  my $skip = $self->param('skip');
  my $null = $self->param('null');
  my $into = $self->param('into');

  my @fields = (
    [ 'sites.name'      => 'site name (unique, required)' ],
    [ 'sites.node'      => 'site node (unique)'           ],
    [ 'sites.x'         => 'site x-coordinate (optional)' ],
    [ 'sites.y'         => 'site y-coordinate (optional)' ],
    [ 'sitegroups.name' => 'sitegroup name (optional)'    ],
    [ 'sitegroups.node' => 'sitegroup node (optional)'    ]
  );

  # Did we actually receive a file?
  if ($file) {
    my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1, sep_char => $separator });
    my @lines = split(/[\r\n]+/, $file->slurp);
    if ($self->param('execute')) {
      # Execute import
      while ($skip) { shift @lines; $skip--; }   
      $self->stash( lines => \@lines );
      $self->stash( csv => $csv );
      $self->stash( errors => 0 );

      # Enter non-blocking import loop
      $self->write_chunk("<P><B>Importing, please wait...</B></P>");
      $self->import_loop();
      return;
    } else {
      # Preview import
      my @skip_rows = ();
      my @rows = ();
      my $error = undef;
      my $cols = 0; 
      my @col_width = ();
      my $count = $skip;
      # Skip rows? (headers etc.)
      while ($count && @lines) {
        push @skip_rows, shift @lines;
        $count--; 
      }
      $count = 10 - $skip;      
      # Preview rows
      while ($count && @lines) {
        my $line = shift @lines;
        my $status = $csv->parse($line);
        unless ($status) {
          $error = $csv->error_diag."\n".$csv->error_input;
          last;
        }
        my @fields = map { ($_ eq $null ? undef : $_) } $csv->fields(); # Null character? -> undef
        push @rows, [ @fields ];
        if (scalar @fields > $cols) { $cols = scalar @fields; }
        foreach my $col (1 .. scalar @fields) {
          my $len = length($fields[$col-1]) || 0;
          if (!defined $col_width[$col-1] || $len/1.5 > $col_width[$col-1]) { 
            $col_width[$col-1] = $len/1.5; 
          }
        }
        $count--;      
      }

      # Finalize for presentation
      $self->stash( skip_rows => \@skip_rows );
      $self->stash( rows => \@rows );
      $self->stash( cols => $cols );
      $self->stash( fields => \@fields );
      $self->stash( col_width => \@col_width );
      $self->stash( error => $error );

      # Render response
      $self->render( template => 'import_preview' );
      return;
    }

  }
  
}


sub import_loop {
  my $self = shift;

  my $csv = $self->stash('csv');
  my $null = $self->param('null');
  my $debug = $self->param('debug');
  my $errors = $self->stash('errors');
  
  # Get the first line
  my $line = shift @{$self->stash('lines')};
  
  # Are we done?
  unless ($line) {
    $self->write_chunk("<P><B>Import completed with $errors error".($errors == 1 ? '' : 's')."</B></P>");
    $self->finish(); # Final chunk
    return;
  }
   
  # Parse line
  my $status = $csv->parse($line);
  last unless $status; # Needs logging and reporting, the user must know what happened. FIXME!
  my @columns = map { ($_ eq $null ? undef : $_) } $csv->fields(); # Null character? -> undef

  my $db = $self->mysql->db;
  
  # Find site columns (if any)
  my $site = undef;
  foreach my $col (1 .. scalar @columns) {
    if ($self->param('c'.$col) =~ /^sites\.(.+)$/) {
      my $key = $1;
      $key =~ s/\W+//g; # Sanitize key
      my $value = $db->quote($columns[$col-1]); # Sanitize value
      $site->{$key} = $value;
    }
  } 
  unless ($site) { 
    $self->write_chunk('<DIV class="error">Nothing to import, please check your field selections.</DIV>');
    $self->finish(); # Final chunk
    return;
  }
  
  # Find sitegroup columns (if any)
  my $sitegroup = undef;
  foreach my $col (1 .. scalar @columns) {
    if ($self->param('c'.$col) =~ /^sitegroups\.(.+)$/) {
      my $key = $1;
      $key =~ s/\W+//g; # Sanitize key
      my $value = $db->quote($columns[$col-1]); # Sanitize value
      $sitegroup->{$key} = $value;
    }
  }  
     
  # DEBUG
  $self->write_chunk('site: '.Dumper($site)."<BR>\n") if $debug >= 3;
  $self->write_chunk('sitegroup: '.Dumper($sitegroup)."<BR>\n") if $debug >= 3;

  my $sitegroup_id = undef;
  my $site_id = undef;
  
  # Choose unique identifier for sites (prefer 'node', fall back to 'name')
  my $site_key_field = undef;
  my $site_key_value = undef;
  if ($site) {
    if (defined $site->{'node'}) {
      $site_key_field = 'node';
      $site_key_value = $site->{$site_key_field};
      delete $site->{'node'};
    } elsif (defined $site->{'name'}) {
      $site_key_field = 'name';
      $site_key_value = $site->{$site_key_field};
      delete $site->{'name'};
    }
  
    if (!defined $site_key_field && !defined $site_key_value) {
      $self->write_chunk('<DIV class="error">You have selected to import sites but a required identifier is missing.</DIV>');
      $self->finish(); # Final chunk
      return;
    }
  }  

  # Choose unique identifier for sitegroups (prefer 'node', fall back to 'name')
  my $sitegroup_key_field = undef;
  my $sitegroup_key_value = undef;
  if ($sitegroup) {
    if (defined $sitegroup->{'node'}) {
      $sitegroup_key_field = 'node';
      $sitegroup_key_value = $sitegroup->{$sitegroup_key_field};
      delete $sitegroup->{'node'};
    } elsif (defined $sitegroup->{'name'}) {
      $sitegroup_key_field = 'name';
      $sitegroup_key_value = $sitegroup->{$sitegroup_key_field};
      delete $sitegroup->{'name'};
    }
  
    if (!defined $sitegroup_key_field && !defined $sitegroup_key_value) {
      $self->write_chunk('<DIV class="error">You have selected to import sitegroups but a required identifier is missing.</DIV>');
      $self->finish(); # Final chunk
      return;
    }
  }  
  
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      
      if ($site) {
        # Try a simple INSERT - will fail if any unique key conflicts with an existing record
        my @fields = sort keys %{$site};
        my @values = @{$site}{@fields};
        my $statement = "
          INSERT INTO sites (".join(',',@fields,$site_key_field).") 
          VALUES (".join(',',@values,$site_key_value).")
        ";
        $self->write_chunk('sql: '.$statement."<BR>\n") if $debug >= 2;
        $db->query($statement, $delay->begin);
      }

      if ($sitegroup) {
        # Try a simple INSERT - will fail if any unique key conflicts with an existing record
        my @fields = sort keys %{$sitegroup};
        my @values = @{$sitegroup}{@fields};
        my $statement = "
          INSERT INTO sitegroups (".join(',',@fields,$sitegroup_key_field).") 
          VALUES (".join(',',@values,$sitegroup_key_value).")
        ";
        $self->write_chunk('sql: '.$statement."<BR>\n") if $debug >= 2;
        $db->query($statement, $delay->begin);
      }
      
    }, 
    sub {
      my $delay = shift;
      my $can_pass = 1; # Set to 0 if we need to do a follow-up query

      if ($site) {
        my $err = shift;
        my $res = shift;
        if ($err) {
          if ($err =~ /Duplicate entry/) {
            $self->write_chunk("Site already exists<BR>\n") if $debug >= 3;
          } else {
            $self->write_chunk('<DIV class="error">(Site) '.$err.'</DIV>') if $debug >= 1;
            $errors++;
          }
        }
        if ($res->last_insert_id) {
          $site_id = $res->last_insert_id;
          $self->write_chunk('Successfully inserted site with id: '.$site_id."<BR>\n") if $debug >= 3;
        }
      }

      if ($sitegroup) {
        my $err = shift;
        my $res = shift;
        if ($err) {
          if ($err =~ /Duplicate entry/) {
            $self->write_chunk("Sitegroup already exists<BR>\n") if $debug >= 3;
          } else {
            $self->write_chunk('<DIV class="error">(Sitegroup) '.$err.'</DIV>') if $debug >= 1;
            $errors++;
          }
        }
        if ($res->last_insert_id) {
          $sitegroup_id = $res->last_insert_id;
          $self->write_chunk('Successfully inserted sitegroup with id: '.$sitegroup_id."<BR>\n") if $debug >= 3;
        }
      }
      
      if ($site && !$site_id) {
        # Insert failed. Find the conflicting record.
        $self->write_chunk("Update existing site instead<BR>\n") if $debug >= 3;
        $can_pass = 0;
        my $statement = "SELECT id FROM sites WHERE $site_key_field = $site_key_value"; # These variables are safe
        $self->write_chunk('sql: '.$statement."<BR>\n") if $debug >= 2;
        $db->query($statement, $delay->begin);
      }

      if ($sitegroup && !$sitegroup_id) {
        # Insert failed. Find the conflicting record.
        $self->write_chunk("Update existing sitegroup instead<BR>\n") if $debug >= 3;
        $can_pass = 0;
        my $statement = "SELECT id FROM sitegroups WHERE $sitegroup_key_field = $sitegroup_key_value"; # These variables are safe
        $self->write_chunk('sql: '.$statement."<BR>\n") if $debug >= 2;
        $db->query($statement, $delay->begin);
      }
      $delay->pass if $can_pass; # Will wait for $delay->begin callbacks if not
    },
    sub {
      my $delay = shift;
      my $can_pass = 1; # Set to 0 if we need to do a follow-up query

      my $site_hashref = undef;
      if ($site && !$site_id) {
        my $err = shift;
        my $res = shift;
        if ($err) {
          $self->write_chunk('<DIV class="error">(Site) '.$err.'</DIV>') if $debug >= 1;
          $errors++;
        }
        $site_hashref = $res->hashes->first;
      }
 
      my $sitegroup_hashref = undef;
      if ($sitegroup && !$sitegroup_id) {
        my $err = shift;
        my $res = shift;
        if ($err) {
          $self->write_chunk('<DIV class="error">(Sitegroup) '.$err.'</DIV>') if $debug >= 1;
          $errors++;
        }
        $sitegroup_hashref = $res->hashes->first;
      }

      if (keys %{$site} && !$site_id) {
        # We are here because insert failed and we need to update an existing record. Do so now.
        $can_pass = 0;
        my @fields = sort keys %{$site};
        #my @values = @{$site}{@fields};
        my $statement = "
          UPDATE sites
          SET ".join(',',map { $_.'='.$site->{$_} } @fields)."
          WHERE id = ".int($site_hashref->{'id'} || 0)."
        ";
        $self->write_chunk('sql: '.$statement."<BR>\n") if $debug >= 2;
        $db->query($statement, $delay->begin);
      }
 
      if (keys %{$sitegroup} && !$sitegroup_id) {
        # We are here because insert failed and we need to update an existing record. Do so now.
        $can_pass = 0;
        my @fields = sort keys %{$sitegroup};
        #my @values = @{$sitegroup}{@fields};
        my $statement = "
          UPDATE sitegroups
          SET ".join(',',map { $_.'='.$sitegroup->{$_} } @fields)."
          WHERE id = ".int($sitegroup_hashref->{'id'} || 0)."
        ";
        $self->write_chunk('sql: '.$statement."<BR>\n") if $debug >= 2;
        $db->query($statement, $delay->begin);
      }
      
      # Corner case: We may have looked up records but not performed any updates on them
      if ($site_hashref->{'id'} && !$site_id) { $site_id = $site_hashref->{'id'}; }
      if ($sitegroup_hashref->{'id'} && !$sitegroup_id) { $sitegroup_id = $sitegroup_hashref->{'id'}; }

      $delay->pass if $can_pass; # Will wait for $delay->begin callbacks if not
    },
    sub {
      my $delay = shift;
      my $can_pass = 1; # Set to 0 if we need to do a follow-up query

      # If we have both a $site_id and a $sitegroup_id at this point, join them together
      if ($site_id && $sitegroup_id) {
        $can_pass = 0;
        my $statement = Atlas::Model::Site->query_set_sitegroup();
        $self->write_chunk('sql: '.$statement." (with parameters $site_id, $sitegroup_id)<BR>\n") if $debug >= 2;
        $db->query($statement, $site_id, $sitegroup_id, $delay->begin);
      }
       
      $delay->pass if $can_pass; # Will wait for $delay->begin callbacks if not
    },
    sub {
      my $delay = shift;

      # Loop. Looks recursive but does not stack because we are inside a Mojo::IOLoop
      $self->write_chunk("<HR>\n") if $debug >= 2;
      $self->write_chunk("|\n") if $debug < 2;
      $self->write_chunk("<!-- Processed line: $line  -->\n");
      $self->stash( 'errors' => $errors );
      $self->import_loop(); 
    }
  ); 
     
}

1;
