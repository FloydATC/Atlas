use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Atlas');

# SVG/XML
$t->get_ok('/world/svg')->status_is(200)->text_is('svg#worldmap' => '');



done_testing();
