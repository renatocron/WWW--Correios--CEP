package WWW::Correios::CEP::LWP;

use strict;
use LWP::UserAgent;

our $VERSION = '0.01';


sub new {
	my $class	= shift;
	my $args	= shift;
	my $atts	= {
		timeout			=> $args->{timeout}		|| 30,
		user_agent		=> $args->{user_agent}	|| 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',

	};

	$atts->{ua} = LWP::UserAgent->new( );

	return bless $atts, $class;

}

sub process {
	my ($self, $args) = @_;

	my $ua = $self->{ua};

	undef($self->{error});

	my $req = HTTP::Request->new(POST => $args->{post_url});
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($args->{post_content} . $args->{cep});

	# Pass request to the user agent and get a response back
	my $res = $ua->request($req);

	# Check the outcome of the response
	if ($res->is_success) {

		return $res->content;

	}
	else {
		$self->{error} = $res->status_line;
	}

	return undef;
}

sub error() {
	my ($self) = @_;
	return $self->{error};
}

sub agent {
	my ($self, $set) = @_;

	$self->{user_agent} = $set if (defined $set);

	$self->{ua}->agent($set);

	return $set;
}

sub timeout {
	my ($self, $set) = @_;

	$self->{timeout} = $set if (defined $set);

	$self->{ua}->timeout($set);

	return $set;
}








1