# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Correios-CEP.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
use Data::Dumper;
BEGIN { use_ok('WWW::Correios::CEP') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $cepper = new WWW::Correios::CEP();
=pod
	_tests => [
		{ street => 'Rua Realidade dos Nordestinos', neighborhood => 'Cidade Nova Heliópolis',
			location => 'São Paulo'     , uf => 'SP', cep => '04236-000' , status => ''},
		{ street => 'Rua Rio Piracicaba'           , neighborhood => 'I.A.P.I.'              ,
			location => 'Osasco'        , uf => 'SP', cep => '06236-040' , status => ''},
		{ street => 'Rua Hugo Baldessarini'        , neighborhood => 'Vista Alegre'          ,
			location => 'Rio de Janeiro', uf => 'RJ', cep => '21236-040' , status => ''},
		{ street => 'Avenida Urucará'              , neighborhood => 'Cachoeirinha'          ,
			location => 'Manaus'        , uf => 'AM', cep => '69065-180' , status => ''}
	],
=cut
is(ref $cepper, 'WWW::Correios::CEP', 'WWW::Correios::CEP class ok');
print STDERR "download...\n";
# i changed to Dumper to easy read erros
my $got  = Dumper $cepper->find( '03640-000' );
my $expt = Dumper { street => 'Rua Cupá', neighborhood => 'Vila Carlos de Campos', location => 'São Paulo', uf => 'SP', cep => '03640-000', status => '' };

print STDERR "got $got exp $expt\n";
is_deeply( $got, $expt, 'testing address for 03640-000');

