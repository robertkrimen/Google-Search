package Google::Search::Page;

use Moose;
use Google::Search::Carp;

has search => qw/is ro required 1 isa Google::Search weak_ref 1/;
has number => qw/is ro required 1 isa Int/;
has response => qw/is ro required 1 lazy 1/, default => sub {
    my $self = shift;
    return $self->search->request(start => $self->start);
};
has start => qw/is ro required 1 isa Int/, default => sub {
    my $self = shift;
    return $self->number * $self->search->rsz_number;
};
has results => qw/is ro required 1 lazy 1/, default => sub {
    my $self = shift;
    return $self->response->results;
};
has error => qw/is ro lazy 1/, default => sub {
    return shift->response->error;
};

sub result {
    my $self = shift;
    my $number = shift;

    return if $self->error;

    return unless $self->results;

    return $self->results->[$number];
}

1;
