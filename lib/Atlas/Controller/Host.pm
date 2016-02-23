package Atlas::Controller::Host;
use Mojo::Base 'Mojolicious::Controller';

#use Socket;
use Atlas::Net::Ping;
use Text::CSV_XS;
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


sub import {
  my $self = shift;
  
  # Key parameters
  my $file = $self->req->upload('file');
  my $separator = $self->param('separator');
  my $skip = $self->param('skip');
  my $null = $self->param('null');
  my $into = $self->param('into');

  my @fields = (
    [ 'hosts.name'      => 'host name (unique, required)' ],
    [ 'hosts.node'      => 'host node (unique)'           ],
    [ 'sites.name'      => 'host site name (required)'    ],
    [ 'sites.node'      => 'host site node (required)'    ],
    [ 'hosts.ip'        => 'host IP address (optional)'   ],
    [ 'hosts.x'         => 'host x-coordinate (optional)' ],
    [ 'hosts.y'         => 'host y-coordinate (optional)' ],
    [ 'hostgroups.name' => 'hostgroup name (optional)'    ],
    [ 'hostgroups.node' => 'hostgroup node (optional)'    ]
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

  # Find host columns (if any)
  my $host = undef;
  foreach my $col (1 .. scalar @columns) {
    if ($self->param('c'.$col) =~ /^hosts\.(.+)$/) {
      my $key = $1;
      $key =~ s/\W+//g; # Sanitize key
      my $value = $db->quote($columns[$col-1]); # Sanitize value
      $host->{$key} = $value;
    }
  } 
  unless ($host) { 
    $self->write_chunk('<DIV class="error">Nothing to import, please check your field selections</DIV>');
    $self->finish(); # Final chunk
    return;
  }
  if ($host->{'ip'}) {
    # Pay special attention to the IP address, we want to stop garbage right here.
    my $invalid = 0;
    unless ($host->{'ip'} =~ /^'\d+\.\d+\.\d+\.\d+'$/) { $invalid = 1; }
    my @parts = split(/\./, $host->{'ip'});
    unless (scalar @parts == 4) { $invalid = 1; }
    foreach my $part (@parts) {
      $part =~ s/\D//g; # Remove single quotes 
      if ($part < 0 || $part > 255) { $invalid = 1; }
    }
    if ($invalid) {
      $self->write_chunk('<DIV class="error">Invalid IP address '.$host->{'ip'}.' rejected, replaced with NULL.</DIV>') if $debug >= 1;
      $host->{'ip'} = 'NULL'; # Remember, this is $db->quote()'d
    }
  }
  
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
    $self->write_chunk('<DIV class="error">Unable to look up site id, please check your field selections</DIV>');
    $self->finish(); # Final chunk
    return;
  }
  
  # Find hostgroup columns (if any)
  my $hostgroup = undef;
  foreach my $col (1 .. scalar @columns) {
    if ($self->param('c'.$col) =~ /^hostgroups\.(.+)$/) {
      my $key = $1;
      $key =~ s/\W+//g; # Sanitize key
      my $value = $db->quote($columns[$col-1]); # Sanitize value
      $hostgroup->{$key} = $value;
    }
  }  
  
  # DEBUG
  $self->write_chunk('host: '.Dumper($host)."<BR>\n") if $debug >= 3;
  $self->write_chunk('hostgroup: '.Dumper($hostgroup)."<BR>\n") if $debug >= 3;

  my $hostgroup_id = undef;
  my $host_id = undef;
  my $site_id = undef;
  
  # Choose unique identifier for hosts (prefer 'node', fall back to 'name')
  my $host_key_field = undef;
  my $host_key_value = undef;
  if ($host) {
    if (defined $host->{'node'}) {
      $host_key_field = 'node';
      $host_key_value = $host->{$host_key_field};
      delete $host->{'node'};
    } elsif (defined $host->{'name'}) {
      $host_key_field = 'name';
      $host_key_value = $host->{$host_key_field};
      delete $host->{'name'};
    }
  
    if (!defined $host_key_field && !defined $host_key_value) {
      $self->write_chunk('<DIV class="error">You have selected to import hosts but a required identifier is missing</DIV>');
      $self->finish(); # Final chunk
      return;
    }
  }  

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
      $self->write_chunk('<DIV class="error">You have selected to import hosts but a required identifier for sites is missing</DIV>');
      $self->finish(); # Final chunk
      return;
    }
  }  

  # Choose unique identifier for hostgroups (prefer 'node', fall back to 'name')
  my $hostgroup_key_field = undef;
  my $hostgroup_key_value = undef;
  if ($hostgroup) {
    if (defined $hostgroup->{'node'}) {
      $hostgroup_key_field = 'node';
      $hostgroup_key_value = $hostgroup->{$hostgroup_key_field};
      delete $hostgroup->{'node'};
    } elsif (defined $hostgroup->{'name'}) {
      $hostgroup_key_field = 'name';
      $hostgroup_key_value = $hostgroup->{$hostgroup_key_field};
      delete $hostgroup->{'name'};
    }
  
    if (!defined $hostgroup_key_field && !defined $hostgroup_key_value) {
      $self->write_chunk('<DIV class="error">You have selected to import hostgroups but a required identifier is missing</DIV>');
      $self->finish(); # Final chunk
      return;
    }
  }  

  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      
      # Look up the site ID
      {
        my $statement = "SELECT id FROM sites WHERE $site_key_field = $site_key_value"; # These variables are safe
        $self->write_chunk('sql: '.$statement."<BR>\n") if $debug >= 2;
        $db->query($statement, $delay->begin);
      };
      
    },
    sub {
      my $delay = shift;
      
      # Fetch the site ID
      {
        my $err = shift;
        my $res = shift;
        if ($err) {
          $self->write_chunk('<DIV class="error">(Site) '.$err.'</DIV>') if $debug >= 1;
          $errors++;
        }
        my $site_hashref = $res->hashes->first;
        if ($site_hashref && $site_hashref->{'id'}) {
          $site_id = $site_hashref->{'id'};
        } else {
          $self->write_chunk('<DIV class="error">(Site) Could not find site $site_key_field = $site_key_value</DIV>') if $debug >= 1;
          $errors++;
        }
      
      };
      
      # Inject site ID into $host and $hostgroup hashes
      $host->{'site'} = $site_id if $site_id;
      $hostgroup->{'site'} = $site_id if $site_id && $hostgroup_key_field;
      
      if ($host) {
        # Try a simple INSERT - will fail if any unique key conflicts with an existing record
        my @fields = sort keys %{$host};
        my @values = @{$host}{@fields};
        my $statement = "
          INSERT INTO hosts (".join(',',@fields,$host_key_field).") 
          VALUES (".join(',',@values,$host_key_value).")
        ";
        $self->write_chunk('sql: '.$statement."<BR>\n") if $debug >= 2;
        $db->query($statement, $delay->begin);
      }

      if ($hostgroup) {
        # Try a simple INSERT - will fail if any unique key conflicts with an existing record
        my @fields = sort keys %{$hostgroup};
        my @values = @{$hostgroup}{@fields};
        my $statement = "
          INSERT INTO hostgroups (".join(',',@fields,$hostgroup_key_field).") 
          VALUES (".join(',',@values,$hostgroup_key_value).")
        ";
        $self->write_chunk('sql: '.$statement."<BR>\n") if $debug >= 2;
        $db->query($statement, $delay->begin);
      }
      
    }, 
    sub {
      my $delay = shift;
      my $can_pass = 1; # Set to 0 if we need to do a follow-up query

      if ($host) {
        my $err = shift;
        my $res = shift;
        if ($err) {
          if ($err =~ /Duplicate entry/) {
            $self->write_chunk("Host already exists<BR>\n") if $debug >= 3;
          } else {
            $self->write_chunk('<DIV class="error">(Host) '.$err.'</DIV>') if $debug >= 1;
            $errors++;
          }
        }
        if ($res->last_insert_id) {
          $host_id = $res->last_insert_id;
          $self->write_chunk('Successfully inserted host with id: '.$host_id."<BR>\n") if $debug >= 3;
        }
      }

      if ($hostgroup) {
        my $err = shift;
        my $res = shift;
        if ($err) {
          if ($err =~ /Duplicate entry/) {
            $self->write_chunk("Hostgroup already exists<BR>\n") if $debug >= 3;
          } else {
            $self->write_chunk('<DIV class="error">(Hostgroup) '.$err.'</DIV>') if $debug >= 1;
            $errors++;
          }
        }
        if ($res->last_insert_id) {
          $hostgroup_id = $res->last_insert_id;
          $self->write_chunk('Successfully inserted hostgroup with id: '.$hostgroup_id."<BR>\n") if $debug >= 3;
        }
      }
      
      if ($host && !$host_id) {
        # Insert failed. Find the conflicting record.
        $self->write_chunk("Update existing host instead<BR>\n") if $debug >= 3;
        $can_pass = 0;
        my $statement = "SELECT id FROM hosts WHERE $host_key_field = $host_key_value"; # These variables are safe
        $self->write_chunk('sql: '.$statement."<BR>\n") if $debug >= 2;
        $db->query($statement, $delay->begin);
      }

      if ($hostgroup && !$hostgroup_id) {
        # Insert failed. Find the conflicting record.
        $self->write_chunk("Update existing hostgroup instead<BR>\n") if $debug >= 3;
        $can_pass = 0;
        my $statement = "SELECT id FROM hostgroups WHERE $hostgroup_key_field = $hostgroup_key_value AND site = $site_id"; # These variables are safe
        $self->write_chunk('sql: '.$statement."<BR>\n") if $debug >= 2;
        $db->query($statement, $delay->begin);
      }
      $delay->pass if $can_pass; # Will wait for $delay->begin callbacks if not
    },
    sub {
      my $delay = shift;
      my $can_pass = 1; # Set to 0 if we need to do a follow-up query

      my $host_hashref = undef;
      if ($host && !$host_id) {
        my $err = shift;
        my $res = shift;
        if ($err) {
          $self->write_chunk('<DIV class="error">(Host) '.$err.'</DIV>') if $debug >= 1;
          $errors++;
        }
        $host_hashref = $res->hashes->first;
      }
 
      my $hostgroup_hashref = undef;
      if ($hostgroup && !$hostgroup_id) {
        my $err = shift;
        my $res = shift;
        if ($err) {
          $self->write_chunk('<DIV class="error">(Hostgroup) '.$err.'</DIV>') if $debug >= 1;
          $errors++;
        }
        $hostgroup_hashref = $res->hashes->first;
      }

      if (keys %{$host} && !$host_id) {
        # We are here because insert failed and we need to update an existing record. Do so now.
        $can_pass = 0;
        my @fields = sort keys %{$host};
        #my @values = @{$host}{@fields};
        my $statement = "
          UPDATE hosts
          SET ".join(',',map { $_.'='.$host->{$_} } @fields)."
          WHERE id = ".int($host_hashref->{'id'} || 0)."
        ";
        $self->write_chunk('sql: '.$statement."<BR>\n") if $debug >= 2;
        $db->query($statement, $delay->begin);
      }
 
      if (keys %{$hostgroup} && !$hostgroup_id) {
        # We are here because insert failed and we need to update an existing record. Do so now.
        $can_pass = 0;
        my @fields = sort keys %{$hostgroup};
        #my @values = @{$hostgroup}{@fields};
        my $statement = "
          UPDATE hostgroups
          SET ".join(',',map { $_.'='.$hostgroup->{$_} } @fields)."
          WHERE id = ".int($hostgroup_hashref->{'id'} || 0)."
        ";
        $self->write_chunk('sql: '.$statement."<BR>\n") if $debug >= 2;
        $db->query($statement, $delay->begin);
      }
      
      # Corner case: We may have looked up records but not performed any updates on them
      if ($host_hashref->{'id'} && !$host_id) { $host_id = $host_hashref->{'id'}; }
      if ($hostgroup_hashref->{'id'} && !$hostgroup_id) { $hostgroup_id = $hostgroup_hashref->{'id'}; }

      $delay->pass if $can_pass; # Will wait for $delay->begin callbacks if not
    },
    sub {
      my $delay = shift;
      my $can_pass = 1; # Set to 0 if we need to do a follow-up query

      # If we have both a $host_id and a $hostgroup_id at this point, join them together
      if ($host_id && $hostgroup_id) {
        $can_pass = 0;
        my $statement = Atlas::Model::Host->query_set_hostgroup();
        $self->write_chunk('sql: '.$statement." (with parameters $host_id, $hostgroup_id)<BR>\n") if $debug >= 2;
        $db->query($statement, $host_id, $hostgroup_id, $delay->begin);
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

