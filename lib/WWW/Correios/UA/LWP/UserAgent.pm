package WWW::Correios::UA::LWP::UserAgent;

use strict;
use warnings;

use LWP::UserAgent;


sub new {
    my $class   = shift;
    my $args    = shift;
    my $atts    = {
        ua  => LWP::UserAgent->new(
            timeout => $args->{timeout}     || 5,
            agent   => $args->{user_agent}  || q{
                Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)
            },
            cookie_jar => {},
        ),
    };
    
    return bless $atts, $class;
}


sub post {
    my ( $self, $url, $data ) = @_;
    
    $self->{response} = $self->{ua}->post( $url, $data );
}


sub content {
    my $self = shift;
    
    return $self->{response}->content;
}


return 42;
