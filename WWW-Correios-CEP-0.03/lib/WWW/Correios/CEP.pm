package WWW::Correios::CEP;

use strict;

# use warnings;

use LWP::UserAgent;
use HTML::TreeBuilder::XPath;

use Encode;
use utf8;

our $VERSION = '0.03';

#-------------------------------------------------------------------------------
# Seta configuracao DEFAULT
#-------------------------------------------------------------------------------
sub new {
    my $class  = shift();
    my $params = shift();

    my $this = {
        _tests => [
            {
                street       => 'Rua Realidade dos Nordestinos',
                neighborhood => 'Cidade Nova Heliópolis',
                location     => 'São Paulo',
                uf           => 'SP',
                cep          => '04236-000',
                status       => ''
            },
            {
                street       => 'Rua Rio Piracicaba',
                neighborhood => 'I.A.P.I.',
                location     => 'Osasco',
                uf           => 'SP',
                cep          => '06236-040',
                status       => ''
            },
            {
                street       => 'Rua Hugo Baldessarini',
                neighborhood => 'Vista Alegre',
                location     => 'Rio de Janeiro',
                uf           => 'RJ',
                cep          => '21236-040',
                status       => ''
            },
            {
                street       => 'Avenida Urucará',
                neighborhood => 'Cachoeirinha',
                location     => 'Manaus',
                uf           => 'AM',
                cep          => '69065-180',
                status       => ''
            }
        ],
        _require_tests => 1,
        _tests_status  => undef,
        _user_agent    => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',

        _lwp_ua      => undef,
        _lwp_options => { timeout => 30 },
        _post_url =>
'http://www.buscacep.correios.com.br/servicos/dnec/consultaLogradouroAction.do',
        _post_content =>
'StartRow=1&EndRow=10&TipoConsulta=relaxation&Metodo=listaLogradouro&relaxation=',

        _pass_test => 0
    };
    $this->{_require_tests} = $params->{require_tests}
      if ( defined $params->{require_tests} );
    $this->{_tests} = $params->{with_tests}
      if ( defined $params->{with_tests} );
    $this->{_user_agent} = $params->{user_agent}
      if ( defined $params->{user_agent} );

    $this->{_post_url} = $params->{post_url} if ( defined $params->{post_url} );
    $this->{_post_content} = $params->{post_content}
      if ( defined $params->{post_content} );

    $this->{_lwp_options} = $params->{lwp_options}
      if ( defined $params->{lwp_options} );

    $this->{_lwp_options}{timeout} = $params->{timeout}
      if ( defined $params->{timeout} );

    bless( $this, $class );
    return $this;
}

sub tests {
    my ($this) = @_;

    my $is_ok = 1;
    foreach my $test ( @{ $this->{_tests} } ) {
        my $result = $this->_extractAddress( $test->{cep} );

        my $ok = 1;
        foreach ( keys %$result ) {
            $ok = $result->{$_} eq $test->{$_};
            last unless $ok;
        }

        push( @{ $this->{_tests_status} }, $result );

        $is_ok = $ok ? $is_ok : 0;
    }

    $this->{_pass_test} = $is_ok;
    return $is_ok;
}

sub find {
    my ( $this, $cep ) = @_;

    $this->tests()
      if ( $this->{_require_tests} && !defined $this->{_tests_status} );

    die("Tests FAIL") if ( !$this->{_pass_test} && $this->{_require_tests} );

    my @list_address = $this->_extractAddress($cep);
    $list_address[0]{address_count} = @list_address unless wantarray;

    return wantarray ? @list_address : $list_address[0];
}

sub _extractAddress {
    my ( $this, $cep ) = @_;

    my @result = ();

    $cep =~ s/[^\d]//go;
    $cep = sprintf( '%08d', $cep );

    if ( $cep =~ /^00/o || $cep =~ /(\d)\1{7}/ ) {
        $result[0]->{status} = "Error: Invalid CEP number ($cep)";
    }
    else {

        if ( !defined $this->{_lwp_ua} ) {
            my $ua = LWP::UserAgent->new( %{ $this->{_lwp_options} } );
            $ua->agent( $this->{_user_agent} );
            $this->{_lwp_ua} = $ua;
        }
        my $ua = $this->{_lwp_ua};

        my $req = HTTP::Request->new( POST => $this->{_post_url} );
        $req->content_type('application/x-www-form-urlencoded');
        $req->content( $this->{_post_content} . $cep );

        # Pass request to the user agent and get a response back
        my $res = $ua->request($req);

        # Check the outcome of the response
        if ( $res->is_success ) {

            $this->_parseHTML( \@result, $res->content );

        }
        else {
            $result[0]->{status} = "Error: " . $res->status_line;
        }

    }

    return wantarray ? @result : $result[0];
}

sub _parseHTML {
    my ( $this, $address_ref, $html ) = @_;

    my $tree = HTML::TreeBuilder::XPath->new;

    $html = decode( "iso-8859-1", $html ) if ( $html =~ /iso-8859-1/io );

    $tree->parse_content($html);

    # thx to gabiru!
    my $ref = $tree->findnodes('//tr[@onclick=~/detalharCep/]');

    while ( my $p = shift(@$ref) ) {
        my $address = {};

        $address->{street}       = $p->findvalue('./td[1]');
        $address->{neighborhood} = $p->findvalue('./td[2]');
        $address->{location}     = $p->findvalue('./td[3]');
        $address->{uf}           = $p->findvalue('./td[4]');
        $address->{cep}          = $p->findvalue('./td[5]');

        if ( $address->{cep} ) {
            $address->{status} = '';
        }
        else {
            $address->{status} =
              'Error: Address not found, something is wrong...';
        }

        push( @$address_ref, $address );
    }

    $address_ref->[0]->{status} = 'Error: Address not found'
      if ( !@$address_ref );

    return 1;
}

sub setTests {
    die("Tests must be an array ref")
      unless ref $_[1] eq 'ARRAY' && ref $_[1][0] eq 'HASH';
    $_[0]->{_tests} = $_[1];
}

sub getTests() {
    shift()->{_tests};
}

sub dump_tests {
    my ($this) = @_;

    print("No tests found!") unless defined $this->{_tests_status};

    foreach ( @{ $this->{_tests_status} } ) {
        if ( $_->{error} ) {
            print
"$_->{cep}: ERROR $_->{error} - street: $_->{street}, neighborhood: $_->{neighborhood}, location: $_->{location}, uf: $_->{uf}\n";
        }
        else {
            print
"$_->{cep}: $_->{street}, $_->{neighborhood} - $_->{location} - $_->{uf}\n";
        }
    }
}

1;
__END__

=encoding utf8

=head1 NAME

WWW::Correios::CEP - Perl extension for extract address from CEP (zip code) number

=head1 SYNOPSIS

	use WWW::Correios::CEP;

	my $cepper = new WWW::Correios::CEP();

	my $address = $cepper->find( $cep );
	# returns hashref like { street => '', neighborhood => '', location => '', uf => 'SP', cep => '', status => '' }


note: if you call "find" before "test" and require_tests is true, tests will be called

=head1 DESCRIPTION

This is the documentation for WWW::Correios::CEP


=head1 METHODS

List of methods

=head2 new

Create an instance of WWW::Correios::CEP and configures it
	
Parameters:
	timeout
	require_tests 
	with_tests
	user_agent
	post_url
	post_content
	lwp_options
	

You can see details on "Full Sample" below


=head2 find( $cep )

Recive and CEP and try to get it address returning an hash ref with street, neighborhood, location, uf, cep and status.

If you call this method on an array scope, it returns an array with each address, if not, address_count key is added to the hash.

=head2 tests( )

This method make tests on some address for test if WWW::Correios::CEP still ok,
you may want keep this, these tests use some time, but it depends on your connection speed/correios site speed.

Retuns 1 if all tests are ok, if false, you may want to call dump_tests to see the changes

=head2 dump_tests( )

prints on STDOUT results of each test

=head2 $cepper->setTests( $array_ref_of_hash )

You can change tests after new too, but you need to call $cepper->tests() if it already called.

$array_ref_of_hash should be an array ref with hashs like "with_tests" bellow

=head2 getTests( )

return current tests array


=head1 Full Sample

	my $cepper = new WWW::Correios::CEP(
		# this is default, you can disable it with a explicit false value,
		require_tests => 1,
		
		lwp_options  => {timeout => 10},
		timeout      => 30, # 30 sec override 10 sec above, same as user_agent
		# if you want to change user agent, that defaults to Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)
		user_agent => 'IECA',
		
		# theses tests may fail if the Correios page have changed.
		# Nevertheless, to not break this class when address/cep changes, you can set a your tests here
		with_tests => [
			{ street => 'Rua Realidade dos Nordestinos', neighborhood => 'Cidade Nova Heliópolis',
				location => 'São Paulo'     , uf => 'SP', cep => '04236000' },
			{ street => 'Rua Rio Piracicaba'           , neighborhood => 'I.A.P.I.'              ,
				location => 'Osasco'        , uf => 'SP', cep => '06236040' },
			{ street => 'Rua Hugo Baldessarini'        , neighborhood => 'Vista Alegre'          ,
				location => 'Rio de Janeiro', uf => 'RJ', cep => '21236040' },
			{ street => 'Avenida Urucará'              , neighborhood => 'Cachoeirinha'          ,
				location => 'Manaus'        , uf => 'AM', cep => '69065180' }
		],

		# if you want to change POST url
		post_url => 'http://www.buscacep.correios.com.br/servicos/dnec/consultaLogradouroAction.do',
		
		# if you want to change post content, remenber that "cep number" will be concat on end of this string
		post_content => 'StartRow=1&EndRow=10&TipoConsulta=relaxation&Metodo=listaLogradouro&relaxation='
	);

	eval{$cepper->tests()};
	if($@){
		# you can use $@ if you want just error message
		$cepper->dump_tests;
	}else{
		my $address = $cepper->find( $cep );

		# returns hashref like { street => '', neighborhood => '', location => '', uf => 'SP', cep => '', status => '', address_count => 0 }

		# you can also call find like it:
		my @address = $cepper->find( $cep );

	}

=head1 SEE ALSO

WWW::Correios::SRO

=head1 BUGS AND LIMITATIONS

No bugs have been reported by users yet since 0.03.


You may reports on github:

L<https://github.com/renatocron/WWW--Correios--CEP/issues>

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

	perldoc WWW\:\:Correios\:\:CEP

=head2 Github

If you want to contribute with the code, you can fork this module on github:

L<https://github.com/renatocron/WWW--Correios--CEP>

=head1 AUTHOR

Renato CRON, E<lt>rentocron@cpan.orgE<gt>

=head1 ACKNOWLEDGEMENTS

Special thanks to Gabriel Andrade, E<gabiru>.

By a better soluction to found table with address!

L<scheme:http://search.cpan.org/~gabiru/>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Renato

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.


=cut
