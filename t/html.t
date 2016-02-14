use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Atlas');

# HTML
$t->get_ok('/world/map')->status_is(200)->text_is('object#svg' => '');

# Popup
$t->get_ok('/worldmap/popup')->status_is(200)->text_is('div#popup1' => '');
$t->get_ok('/site/popup')->status_is(200)->text_is('div#popup1' => '');
$t->get_ok('/sitemap/popup')->status_is(200)->text_is('div#popup1' => '');
$t->get_ok('/site/popup_new')->status_is(200)->text_is('div#popup1' => '');
$t->get_ok('/site/popup_addgroup')->status_is(200)->text_is('div#popup1' => '');
$t->get_ok('/site/popup_removegroup')->status_is(200)->text_is('div#popup1' => '');
$t->get_ok('/sitegroup/popup')->status_is(200)->text_is('div#popup1' => '');
$t->get_ok('/sitegroup/popup_addmember')->status_is(200)->text_is('div#popup1' => '');
$t->get_ok('/sitegroup/popup_removemember')->status_is(200)->text_is('div#popup1' => '');
$t->get_ok('/host/popup_new')->status_is(200)->text_is('div#popup1' => '');
$t->get_ok('/host/popup_addgroup')->status_is(200)->text_is('div#popup1' => '');
$t->get_ok('/host/popup_removegroup')->status_is(200)->text_is('div#popup1' => '');
$t->get_ok('/hostgroup/popup')->status_is(200)->text_is('div#popup1' => '');
$t->get_ok('/hostgroup/popup_addmember')->status_is(200)->text_is('div#popup1' => '');
$t->get_ok('/hostgroup/popup_removemember')->status_is(200)->text_is('div#popup1' => '');

# Ajax
$t->post_ok('/site/move')->status_is(400);
$t->post_ok('/site/insert')->status_is(400);
$t->post_ok('/site/addgroup')->status_is(400);
$t->post_ok('/site/removegroup')->status_is(400);
$t->post_ok('/sitegroup/move')->status_is(400);
$t->post_ok('/sitegroup/addmember')->status_is(400);
$t->post_ok('/sitegroup/removemember')->status_is(400);
$t->post_ok('/host/move')->status_is(400);
$t->post_ok('/host/insert')->status_is(400);
$t->post_ok('/host/addgroup')->status_is(400);
$t->post_ok('/host/removegroup')->status_is(400);
$t->post_ok('/hostgroup/move')->status_is(400);
$t->post_ok('/hostgroup/addmember')->status_is(400);
$t->post_ok('/hostgroup/removemember')->status_is(400);
$t->post_ok('/commlink/insert')->status_is(400);

done_testing();
