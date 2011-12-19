package WWW::Correios::CEP;

use strict;
use warnings;

use Carp qw( carp );
use Try::Tiny;
use Encode;


our $VERSION = '0.04';


sub new {
    my $class   = shift;
    my $args    = shift;
    my $atts    = {
        ua          => $args->{ua},
        parser      => $args->{parser},
        user_agent  => $args->{user_agent},
        timeout     => $args->{timeout},
        
        host        => q{http://www.buscacep.correios.com.br},
        services    => {
            req1    => {
                service => q{servicos/dnec/consultaLogradouroAction.do},
                vars    => {
                    relaxation      => '',
                    TipoCep         => 'LOG',
                    semelhante      => 'N',
                    cfm             => 1,
                    Metodo          => 'listaLogradouro',
                    TipoConsulta    => 'relaxation',
                    StartRow        => 1,
                    EndRow          => 10,
                },
            },
            req2    => {
                service => q{servicos/dnec/detalheCEPAction.do},
                vars    => {
                    CEP     => '',
                    Metodo  => 'detalhe',
                    Posicao => 1,
                    TipoCep => 2,
                },
            },
        },
    };
    
    unless ( defined $atts->{ua} ) {
        require WWW::Correios::UA::LWP::UserAgent;
        
        $atts->{ua} = WWW::Correios::UA::LWP::UserAgent->new({
            timeout => $atts->{timeout},
            agent   => $atts->{user_agent},
        });
    }
    
    unless ( defined $atts->{parser} ) {
        require WWW::Correios::Parser::HTML::TreeBuilder::LibXML;
        
        $atts->{parser}
            = WWW::Correios::Parser::HTML::TreeBuilder::LibXML->new;
    }
    
    return bless $atts, $class;
}


sub find {
    my ( $self, $cep ) = @_;
    
    $cep =~ s/\D//g
        if defined $cep;
    
    return undef unless $cep && length $cep == 8;
    
    my $data;
    
    try {
        my $url;
        
        ## First request
        ## Get paltial data and cookie JSESSIONID
        $url = $self->{host} . '/' . $self->{services}{req1}{service};
        $data = $self->{services}{req1}{vars};
        
        $data->{relaxation} = $cep;
        
        $self->{ua}->post( $url, $data );
        
        
        ## Second request
        ## Get full data but must send cookie JSESSIONID
        $url = $self->{host} . '/' . $self->{services}{req2}{service};
        $data = $self->{services}{req2}{vars};
        
        $self->{ua}->post( $url, $data );
        
        my $html = $self->{ua}->content;
        
        my $charsets = {
            input   => 'iso-8859-1',
            output  => 'utf-8',
        };
        if ( $html =~ /content="text\/html; charset=(.*?)"/i ) {
            $charsets->{input} = lc $1;
            decode $charsets->{input}, $html;
        }
        
        $data = $self->{parser}->parse( $html );
        
        @$data{ keys %$data }
            = map { encode $charsets->{output}, $_ } values %$data;
        
        $data->{charsets} = $charsets;
    }
    catch {
        carp $_;
        $data = undef;
    };
    
    return $data;
}


return 42;


=pod

=head1 NAME

WWW::Correios::CEP

=head1 VERSION

Version 0.04

=head1 SYNOPSIS
    use WWW::Correios::CEP;

    my $agent   = WWW::Correios::CEP->new();

    my $cep = $agent->find( q{22460-070} );


    use WWW::Correios::CEP;
    use WWW::Correios::Parser::HTML::TreeBuilder::LibXML;
    
    my $parser  = WWW::Correios::Parser::HTML::TreeBuilder::LibXML->new;
    my $agent   = WWW::Correios::CEP->new({ parser => $parser });
    
    my $cep = $agent->find( q{22460-070} );
    
    print Dumper $cep;
    
    # $VAR1 = {
    #   'city'          => 'Rio de Janeiro',
    #   'street'        => 'Rua Zara',
    #   'cep'           => '22460-070',
    #   'neighborhood'  => 'Jardim Botânico',
    #   'state'         => 'RJ'
    #   'charsets'      => {
    #       'input'  => 'iso-8859-1',
    #       'output' => 'utf-8',
    #   },
    # };

=cut
