package Google::Search::Error;

use Moose;
use Google::Search::Carp;

use overload
    "" => \&reason,
    fallback => 1,
;

has code => qw/is ro isa Int/;
has message => qw/is ro isa Str/, default => "";
has reason => qw/is ro isa Str required 1 lazy 1/, default => sub {
    my $self = shift;
    return $self->message unless defined $self->code;
    return join " ", $self->code, $self->message;

};

1;
