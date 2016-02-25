package Atlas::Controller::Commlink;
use Mojo::Base 'Mojolicious::Controller';

use Text::CSV_XS;
use Data::Dumper;
use Encode;

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
  my $commlink_id = $self->param('commlink_id');
  unless ($commlink_id) { $self->res->code(400); $self->render( text => 'Required parameter missing' ); return; }

  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $db->query(Atlas::Model::Commlink->query_get, $commlink_id, $delay->begin);
    },
    sub {
      my $delay = shift;
      {
        my $err = shift;
        my $res = shift;
        die $err if $err;
        $self->stash( commlink => $res->hashes->first );
      };

      # Render response
      $self->render( template => 'commlink_details', type => 'html', format => 'html' );
    }
  )->wait;
 
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
      $self->redirect_to("/site/map?site_id=".$site_id);
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
    [ 'commlinks.node'  => 'link node (unique, required)'   ],
    [ 'commlinks.type'  => 'link type (optional)'           ],
    [ 'commlinks.speed' => 'link speed (optional)'          ],
    [ 'host1.node'      => 'host 1 node (unique, required)' ],
    [ 'host1.name'      => 'host 1 name (unique, required)' ],
    [ 'host2.node'      => 'host 2 node (unique, required)' ],
    [ 'host2.name'      => 'host 2 name (unique, required)' ]
  );

  # Did we actually receive a file?
  if ($file) {
    my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1, sep_char => $separator });
    my @lines = map { decode("UTF-8", $_) } split(/[\r\n]+/, $file->slurp);
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
  #$db->query("SET character_set_client = utf8");
  
  # Find commlink columns (if any)
  my $commlink = undef;
  foreach my $col (1 .. scalar @columns) {
    if ($self->param('c'.$col) =~ /^commlinks\.(.+)$/) {
      my $key = $1;
      $key =~ s/\W+//g; # Sanitize key
      my $value = $db->quote($columns[$col-1]); # Sanitize value
      $commlink->{$key} = $value;
    }
  } 
  unless ($commlink) { 
    $self->write_chunk('<DIV class="error">Nothing to import, please check your field selections.</DIV>');
    $self->finish(); # Final chunk
    return;
  }
  
  # Find host1 and host2 columns (if any)
  my $host1 = undef;
  my $host2 = undef;
  foreach my $col (1 .. scalar @columns) {
    if ($self->param('c'.$col) =~ /^host1\.(.+)$/) {
      my $key = $1;
      $key =~ s/\W+//g; # Sanitize key
      my $value = $db->quote($columns[$col-1]); # Sanitize value
      $host1->{$key} = $value;
    }
    if ($self->param('c'.$col) =~ /^host2\.(.+)$/) {
      my $key = $1;
      $key =~ s/\W+//g; # Sanitize key
      my $value = $db->quote($columns[$col-1]); # Sanitize value
      $host2->{$key} = $value;
    }
  }  
  unless ($host1 && $host2) { 
    $self->write_chunk('<DIV class="error">Importing commlinks requires host 1 and host 2 information, please check your field selections.</DIV>');
    $self->finish(); # Final chunk
    return;
  }
     
  # DEBUG
  $self->write_chunk('commlink: '.Dumper($commlink)."<BR>\n") if $debug >= 3;
  $self->write_chunk('host1: '.Dumper($host1)."<BR>\n") if $debug >= 3;
  $self->write_chunk('host2: '.Dumper($host2)."<BR>\n") if $debug >= 3;

  my $commlink_id = undef;
  my $host1_id = undef;
  my $host2_id = undef;
  
  # Choose unique identifier for commlinks (prefer 'node', fall back to 'name')
  my $commlink_key_field = undef;
  my $commlink_key_value = undef;
  if ($commlink) {
    if (defined $commlink->{'node'}) {
      $commlink_key_field = 'node';
      $commlink_key_value = $commlink->{$commlink_key_field};
      delete $commlink->{'node'};
    } elsif (defined $commlink->{'name'}) {
      $commlink_key_field = 'name';
      $commlink_key_value = $commlink->{$commlink_key_field};
      delete $commlink->{'name'};
    }
  
    if (!defined $commlink_key_field && !defined $commlink_key_value) {
      $self->write_chunk('<DIV class="error">You have selected to import commlinks but a required identifier is missing.</DIV>');
      $self->finish(); # Final chunk
      return;
    }
  }  

  # Choose unique identifier for host1 (prefer 'node', fall back to 'name')
  my $host1_key_field = undef;
  my $host1_key_value = undef;
  if ($host1) {
    if (defined $host1->{'node'}) {
      $host1_key_field = 'node';
      $host1_key_value = $host1->{$host1_key_field};
      delete $host1->{'node'};
    } elsif (defined $host1->{'name'}) {
      $host1_key_field = 'name';
      $host1_key_value = $host1->{$host1_key_field};
      delete $host1->{'name'};
    }
  
    if (!defined $host1_key_field && !defined $host1_key_value) {
      $self->write_chunk('<DIV class="error">A required identifier for host 1 is missing.</DIV>');
      $self->finish(); # Final chunk
      return;
    }
  }  

  # Choose unique identifier for host2 (prefer 'node', fall back to 'name')
  my $host2_key_field = undef;
  my $host2_key_value = undef;
  if ($host2) {
    if (defined $host2->{'node'}) {
      $host2_key_field = 'node';
      $host2_key_value = $host2->{$host2_key_field};
      delete $host2->{'node'};
    } elsif (defined $host2->{'name'}) {
      $host2_key_field = 'name';
      $host2_key_value = $host2->{$host2_key_field};
      delete $host2->{'name'};
    }
  
    if (!defined $host2_key_field && !defined $host2_key_value) {
      $self->write_chunk('<DIV class="error">A required identifier for host 2 is missing.</DIV>');
      $self->finish(); # Final chunk
      return;
    }
  }  
  
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      
      {
        # Look up ID for host 1
        my $statement = "SELECT id FROM hosts WHERE $host1_key_field = $host1_key_value"; # These variables are safe
        $self->write_chunk(encode("UTF-8", 'sql: '.$statement."<BR>\n")) if $debug >= 2;
        $db->query($statement, $delay->begin);
      };

      {
        # Look up ID for host 2
        my $statement = "SELECT id FROM hosts WHERE $host2_key_field = $host2_key_value"; # These variables are safe
        $self->write_chunk(encode("UTF-8", 'sql: '.$statement."<BR>\n")) if $debug >= 2;
        $db->query($statement, $delay->begin);
      };
      
    }, 
    sub {
      my $delay = shift;

      {
        # Get ID for host 1
        my $err = shift;
        my $res = shift;
        if ($err) {
          $self->write_chunk(encode("UTF-8", '<DIV class="error">(Host 1) '.$err.'</DIV>')) if $debug >= 1;
          $errors++;
        }
        my $host1_hashref = $res->hashes->first;
        if ($host1_hashref && $host1_hashref->{'id'}) {
          $host1_id = $host1_hashref->{'id'};
        } else {
          $self->write_chunk(encode("UTF-8", '<DIV class="error">Host 1 lookup failed, '.$host1_key_field.' '.$host1_key_value.' not found.</DIV>')) if $debug >= 1;
          $errors++;
        }
      };

      {
        # Get ID for host 2
        my $err = shift;
        my $res = shift;
        if ($err) {
          $self->write_chunk(encode("UTF-8", '<DIV class="error">(Host 2) '.$err.'</DIV>')) if $debug >= 1;
          $errors++;
        }
        my $host2_hashref = $res->hashes->first;
        if ($host2_hashref && $host2_hashref->{'id'}) {
          $host2_id = $host2_hashref->{'id'};
        } else {
          $self->write_chunk(encode("UTF-8", '<DIV class="error">Host 2 lookup failed, '.$host2_key_field.' '.$host2_key_value.' not found.</DIV>')) if $debug >= 1;
          $errors++;
        }
      };
      
      # Update $commlink hash with ID for host1 and host2
      # Note: undefined -> 'NULL' will cause query to fail, this is just to handle failed lookups with grace
      $commlink->{'host1'} = $host1_id || 'NULL';
      $commlink->{'host2'} = $host2_id || 'NULL';
      
      {
        # Try a simple INSERT - will fail if any unique key conflicts with an existing record
        my @fields = sort keys %{$commlink};
        my @values = @{$commlink}{@fields};
        my $statement = "
          INSERT INTO commlinks (".join(',',@fields,$commlink_key_field).") 
          VALUES (".join(',',@values,$commlink_key_value).")
        ";
        $self->write_chunk(encode("UTF-8", 'sql: '.$statement."<BR>\n")) if $debug >= 2;
        #$db->query(utf8::upgrade($statement), $delay->begin);
        $db->query($statement, $delay->begin);
      };
      
    },
    sub {
      my $delay = shift;
      my $can_pass = 1; # Set to 0 if we need to do a follow-up query

      # Check if insert worked
      {
        my $err = shift;
        my $res = shift;
        if ($err) {
          if ($err =~ /Duplicate entry/) {
            $self->write_chunk('Insert failed') if $debug >= 3;
          } else {
            $self->write_chunk(encode("UTF-8", '<DIV class="error">(Commlink) '.$err.'</DIV>')) if $debug >= 1;
            $errors++;
          }
        } else {
          $commlink_id = $res->last_insert_id;
          $self->write_chunk('Insert successful, ID=$commlink_id') if $debug >= 3;
        }
      }
      
      # No? Look up existing commlink then
      if ($commlink && !$commlink_id) {
        # Insert failed. Find the conflicting record.
        $self->write_chunk("Update existing commlink instead<BR>\n") if $debug >= 3;
        $can_pass = 0;
        my $statement = "SELECT id FROM commlinks WHERE $commlink_key_field = $commlink_key_value"; # These variables are safe
        $self->write_chunk(encode("UTF-8", 'sql: '.$statement."<BR>\n")) if $debug >= 2;
        $db->query($statement, $delay->begin);
      }
      
      $delay->pass if $can_pass; # Will wait for $delay->begin callbacks if not
    },
    sub {
      my $delay = shift;
      my $can_pass = 1; # Set to 0 if we need to do a follow-up query 
      
      # Lookup successful?
      my $commlink_hashref = undef;
      if ($commlink && !$commlink_id) { 
        my $err = shift;
        my $res = shift;
        if ($err) {
          $self->write_chunk(encode("UTF-8", '<DIV class="error">(Commlink) '.$err.'</DIV>')) if $debug >= 1;
          $errors++;
        }
        my $commlink_hashref = $res->hashes->first;
        if ($commlink_hashref && $commlink_hashref->{'id'}) {
          $commlink_hashref = $commlink_hashref;
        } else {
          $self->write_chunk(encode("UTF-8", '<DIV class="error">Commlink lookup failed, '.$commlink_key_field.' '.$commlink_key_value.' not found.</DIV>')) if $debug >= 1;
          $errors++;
        }
      }
      
      # Update existing commlink
      if (keys %{$commlink} && !$commlink_id) {
        # We are here because insert failed and we need to update an existing record. Do so now.
        $can_pass = 0;
        my @fields = sort keys %{$commlink};
        #my @values = @{$commlink}{@fields};
        my $statement = "
          UPDATE commlinks
          SET ".join(',',map { $_.'='.$commlink->{$_} } @fields)."
          WHERE id = ".int($commlink_hashref->{'id'} || 0)."
        ";
        $self->write_chunk(encode("UTF-8", 'sql: '.$statement."<BR>\n")) if $debug >= 2;
#        $db->query(utf8::upgrade($statement), $delay->begin);
        $db->query($statement, $delay->begin);
      }
      
      $delay->pass if $can_pass; # Will wait for $delay->begin callbacks if not
    },
    sub {
      my $delay = shift;

      # Loop. Looks recursive but does not stack because we are inside a Mojo::IOLoop
      $self->write_chunk("<HR>\n") if $debug >= 2;
      $self->write_chunk("|\n") if $debug < 2;
      $self->write_chunk(encode("UTF-8", "<!-- Processed line: $line  -->\n"));
      $self->stash( 'errors' => $errors );
      $self->import_loop(); 
    }
  ); 
     
}


1;

