package Atlas::Controller::World;
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
  $self->render( template => 'world_map' );
}

sub svg {
  my $self = shift;

  # Render response
  $self->render( template => 'world_svg', type => 'svg', format => 'svg' );
}





1;
