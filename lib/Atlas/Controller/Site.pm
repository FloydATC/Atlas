package Atlas::Controller::Site;
use Mojo::Base 'Mojolicious::Controller';



# Action
sub welcome {
  my $self = shift;

  # Render response
  $self->render( text => 'Hello there.' );
}

sub map {
  my $self = shift;

  # Render response
  $self->render( template => 'site_map' );
}

sub move {
  my $self = shift;
  
  # Render response
  $self->render( template => 'site_move', type => 'text', format => 'text' );
}

sub svg {
  my $self = shift;

  # Render response
  $self->render( template => 'site_svg', type => 'svg', format => 'svg' );
}

sub popup {
  my $self = shift;
  
  $self->render( template => 'site_popup', type => 'html', format => 'html' );
}



1;
