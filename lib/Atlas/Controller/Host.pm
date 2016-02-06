package Atlas::Controller::Host;
use Mojo::Base 'Mojolicious::Controller';



# Action
sub welcome {
  my $self = shift;

  # Render response
  $self->render( text => 'Hello there.' );
}

sub move {
  my $self = shift;

  # Render response
  $self->render( template => 'host_move', type => 'text', format => 'text' );
}

sub popup {
  my $self = shift;
  
  $self->render( template => 'host_popup', type => 'html', format => 'html' );
}



1;
