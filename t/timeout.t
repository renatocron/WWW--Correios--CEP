#########################
use utf8;

use Test::More tests => 3;
use Data::Dumper;
BEGIN { use_ok('WWW::Correios::CEP') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $cepper = new WWW::Correios::CEP(
    { timeout => 1, post_url => 'http://192.168.0.184/', require_tests => 0 } );

is( ref $cepper, 'WWW::Correios::CEP', 'WWW::Correios::CEP class ok' );

my $got = Dumper $cepper->find('03640-000');

my $expt = Dumper {
    'status' => 'Error: 500 Can\'t connect to 192.168.0.184:80 (timeout)' };

is_deeply( $got, $expt, 'timeout in 1sec is ok!' );
