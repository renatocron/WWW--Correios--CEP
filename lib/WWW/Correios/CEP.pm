package WWW::Correios::CEP;

use strict;
# use warnings; 

use HTML::TreeBuilder::XPath;

use Encode;

our $VERSION = '0.20';

#-------------------------------------------------------------------------------
# Seta configuracao DEFAULT
#-------------------------------------------------------------------------------
sub new {
	my $class	= shift;
	my $args	= shift;
	my $atts	= {
		timeout			=> $args->{timeout}		|| 30,
		user_agent		=> $args->{user_agent}	|| 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
		crawler			=> $args->{crawler}		|| 'WWW::Correios::CEP::LWP',
		crawler_instance=> undef,

		post_url		=> $args->{post_url}	|| 'http://www.buscacep.correios.com.br/servicos/dnec/consultaLogradouroAction.do',
		post_content	=> $args->{post_content}||'StartRow=1&EndRow=10&TipoConsulta=relaxation&Metodo=listaLogradouro&relaxation=',

		_tree_builder	=> undef
	};

	return bless $atts, $class;
}

sub find {
	my ($self, $cep) = @_;

	$self->{_tree_builder} = HTML::TreeBuilder::XPath->new unless defined $self->{_tree_builder};

	my @list_address = $self->_extract_address($cep);
	$list_address[0]{address_count} = @list_address unless wantarray;

	return wantarray ? @list_address : $list_address[0];
}

sub _extract_address {
	my ($self, $cep) = @_;

	my @result = ();

	$cep =~ s/[^\d]//go;
	$cep = sprintf('%08d', $cep);
	
	if ($cep =~ /^00/o || $cep =~ /(\d)\1{7}/){
		$result[0]->{status} = "Error: Invalid CEP number ($cep)";
	}else{
	
		unless (defined $self->{crawler_instance}){
			eval("use $self->{crawler}");

			my $ua = $self->{crawler}->new( $self );

			$ua->timeout($self->{timeout});

			$ua->agent($self->{user_agent});

			$self->{crawler_instance} = $ua;

		}
		my $ua = $self->{crawler_instance};

		my $html = eval{$ua->process({
			post_url		=> $self->{post_url},
			post_content	=> $self->{post_content},
			cep 			=> $cep
		})};

		# Check the outcome of the response
		if (!defined $html) {
			$result[0]->{status} = "Error: " . $ua->error;

			$result[0]->{status} .= " $@" if ($@);
		} else {
			$self->_parse_html(\@result, $html);
		}

	}
	
	return wantarray ? @result : $result[0];
}


sub _parse_html {
	my ($self, $address_ref, $html) = @_;

	my $tree = $self->{_tree_builder};

	$html = decode("iso-8859-1", $html) if ($html =~ /iso-8859-1/io);

	$tree->parse_content( $html );

	# thx to gabiru!
	my $ref = $tree->findnodes('//tr[@onclick=~/detalharCep/]');
	
	while (my $p = shift(@$ref)){
		my $address = {};

		$address->{street}       = encode('utf-8', $p->findvalue('./td[1]'));
		$address->{neighborhood} = encode('utf-8', $p->findvalue('./td[2]'));
		$address->{location}     = encode('utf-8', $p->findvalue('./td[3]'));
		$address->{uf}           = encode('utf-8', $p->findvalue('./td[4]'));
		$address->{cep}          = encode('utf-8', $p->findvalue('./td[5]'));

		if ($address->{cep} =~ /^\d{5}\-\d{3}$/){
			$address->{status}       = '';
		}else{
			$address->{status}       = 'Error: Address not found, something is wrong...';
		}

		push (@$address_ref, $address);
	}

	$address_ref->[0]->{status} = 'Error: Address not found' if (!@$address_ref);

	return 1;
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



=head1 DESCRIPTION

This is the documentation for WWW::Correios::CEP


=head1 METHODS

List of methods

=head2 new

Create an instance of WWW::Correios::CEP and configures it
	
Parameters:

	timeout		|| 30,
	user_agent	|| 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
	crawler		|| 'WWW::Correios::CEP::LWP',

	post_url	 || 'http://www.buscacep.correios.com.br/servicos/dnec/consultaLogradouroAction.do',
	post_content ||'StartRow=1&EndRow=10&TipoConsulta=relaxation&Metodo=listaLogradouro&relaxation=',




=head2 find( $cep )

Recive and CEP and try to get it address returning an hash ref with street, neighborhood, location, uf, cep and status.

If you call this method on an array scope, it returns an array with each address, if not, address_count key is added to the hash.


=head1 Full Sample

	my $cepper = new WWW::Correios::CEP(


		timeout		=>  30,
		user_agent	=> 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
		crawler		=> 'WWW::Correios::CEP::LWP',

		# if you want to change POST url
		post_url	 => 'http://www.buscacep.correios.com.br/servicos/dnec/consultaLogradouroAction.do',

		# if you want to change post content, remenber that "cep number" will be concat on end of this string
		post_content =>'StartRow=1&EndRow=10&TipoConsulta=relaxation&Metodo=listaLogradouro&relaxation=',

	);


	my $address = $cepper->find( $cep );

	# returns hashref like { street => '', neighborhood => '', location => '', uf => 'SP', cep => '', status => '', address_count => 0 }

	# you can also call find like it:
	my @address = $cepper->find( $cep );


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
