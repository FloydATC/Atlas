use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Atlas');

# HTML
$t->get_ok('/world/map')->status_is(200)->text_is('object#svg' => '');



done_testing();
