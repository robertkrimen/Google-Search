package Google::Search::Error;

use Moose;
use Google::Search::Carp;

use overload
    "" => \&reason,
    fallback => 1,
;

has code => qw/is ro isa Int/;
has message => qw/is ro isa Str/, default => "";
has http_response => qw/is ro isa HTTP::Response/;
has _reason => qw/init_arg reason is ro isa Str required 1 lazy 1/, default => sub {
    my $self = shift;
    return $self->message unless defined $self->code;
    return join " ", $self->code, $self->message;

};

sub reason {
    return shift->_reason( @_ );
}

1;
