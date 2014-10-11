use utf8;

use Test::More tests => 3;
use Data::Dumper;
BEGIN { use_ok('WWW::Correios::CEP') }

my $cepper = WWW::Correios::CEP->new(
    { timeout => 1, post_url => 'http://192.168.0.184/', require_tests => 0 }
);

is( ref $cepper, 'WWW::Correios::CEP', 'WWW::Correios::CEP class ok' );

my $got = $cepper->find('03640-000');

ok( eval{$got->{status}} =~ /^Error: 500 Can't connect/, 'timeout in 1sec is ok!' );
