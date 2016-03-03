package WWW::Correios::CEP;
use strict;
use warnings;

use LWP::UserAgent;
use HTML::TreeBuilder::XPath;

use Encode;
use utf8;

sub new {
    my ($class, $params) = @_;

    my $this = {
        _user_agent   => defined $params->{user_agent}
                       ? $params->{user_agent}
                       : 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
        _lwp_ua       => undef,
        _lwp_options  => $params->{lwp_options} || { timeout => 30 },

        _post_url     => defined $params->{post_url}
                       ? $params->{post_url}
                       :
'http://www.buscacep.correios.com.br/sistemas/buscacep/resultadoBuscaCepEndereco.cfm',

        _post_content => defined $params->{post_content}
                       ? $params->{post_content}
                       :
'tipoCEP=LOG&semelhante=N&relaxation='
    };

    $this->{_lwp_options}{timeout} = $params->{timeout}
      if defined $params->{timeout};

    return bless $this, $class;
}

sub find {
    my ($this, $cep) = @_;

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
    $html = decode( 'iso-8859-1', $html );
    $html =~ s/&nbsp;//g; # <-- findvalue is keeping that
    $tree->parse_content($html);

    my $ref = $tree->findnodes('//table[contains(@class,"tmptabela")]/tr[not(th)]');

    while ( my $p = shift(@$ref) ) {
        my $address = {};

        $address->{street}       = $p->findvalue('./td[1]');
        $address->{neighborhood} = $p->findvalue('./td[2]');
        $address->{cep}          = $p->findvalue('./td[4]');

        ($address->{location}, $address->{uf}) =
            split qr{\s*/\s*} => $p->findvalue('./td[3]');

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

1;
__END__

=encoding utf8

=head1 NAME

WWW::Correios::CEP - Perl extension for extract address from CEP (zip code) number

=head1 SYNOPSIS

	use WWW::Correios::CEP;

	my $cepper = WWW::Correios::CEP-new;

	my $address = $cepper->find( $cep );

    print $address->{street}; # neighborhood, location, uf

=head1 DESCRIPTION

This module fetches CEP information (Brazilian ZIP codes) directly from
the Correios website, Brazil's official post office company.


=head1 METHODS

=head2 new

Creates a new instance of WWW::Correios::CEP. Accepts the following arguments:

=over 4

=item * timeout

when to give up connecting to the Correios website. Defaults to 30 seconds.

=item * user_agent

User Agent string. Default to "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)"

=item * post_url

Where to post the query. Defaults to Correios' current location (we hope!)

=item * post_content

What to post in the query. Defaults to Correios' standard options (we hope!)

=item * lwp_options

Extra options to pass to LWP::UserAgent.

=back

=head2 find( $cep )

Recieves the CEP string and tries to get address data. Returns a hashref with the following keys:

=over 4

=item * street

=item * neighborhood

=item * location

=item * uf

=item * status

=back

If there is more than one address, it returns a list of hashrefs in list context, or
just the first hashref in scalar context, together with an "C<address_count>" key with
the total returned addresses.

=head1 SEE ALSO

WWW::Correios::SRO

=head1 BUGS AND LIMITATIONS

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

2011 - Special thanks to Gabriel "gabiru" Andrade for providing a better
solution for finding addresses!

2014 - Thanks to Garu, for removing legacy test code and improving docs!

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2014 by RenatoCRON

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

