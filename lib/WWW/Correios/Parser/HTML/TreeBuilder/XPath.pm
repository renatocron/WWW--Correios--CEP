package WWW::Correios::Parser::HTML::TreeBuilder::XPath;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;


sub new {
    my $class   = shift;
    my $args    = shift;
    my $atts    = {
        parser  => HTML::TreeBuilder::XPath->new,
    };
    
    return bless $atts, $class;
}


sub parse {
    my $self = shift;
    my $html = shift;
    
    my $data;
    
    my $parser = $self->{parser};
    
    $parser->parse_content( $html );
    
    my $cels
        = $parser->findnodes('//div[@class="ctrlcontent"]/table[2]/tr/td');
    
    $data->{street}         = $cels->[1]->as_text;
    $data->{neighborhood}   = $cels->[3]->as_text;
    $data->{cep}            = $cels->[7]->as_text;
    
    if( $cels->[5]->as_text =~ m#(.*?)\/(.*)# ) {
        $data->{city}   = $1;
        $data->{state}  = $2;
    }
    else {
        $data->{city} = $data->{state} = '';
    }
    
    return $data;
}


return 42;
