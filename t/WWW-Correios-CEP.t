# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Correios-CEP.t'

#########################
use utf8;

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
use Data::Dumper;
BEGIN { use_ok('WWW::Correios::CEP') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $cepper = new WWW::Correios::CEP();

is(ref $cepper, 'WWW::Correios::CEP', 'WWW::Correios::CEP class ok');

# i changed to Dumper to easy read erros
my $got  = Dumper $cepper->find( '03640-000' );
my $expt = Dumper { street => 'Rua Cupá', neighborhood => 'Vila Carlos de Campos', location => 'São Paulo', uf => 'SP', cep => '03640-000', status => '' };

is_deeply( $got, $expt, 'testing address for 03640-000');

