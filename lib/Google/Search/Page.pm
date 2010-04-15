package Google::Search::Page;

use Any::Moose;
use Google::Search::Carp;

has search => qw/ is ro required 1 isa Google::Search weak_ref 1 /;
has number => qw/ is ro required 1 isa Int /;

has response => qw/ is ro lazy_build 1 /;
sub _build_response {
    my $self = shift;
    return $self->search->request(start => $self->start);
}

has http_response => qw/is ro isa HTTP::Response lazy_build 1/;
sub _build_http_response {
    my $self = shift;
    return $self->response->http_response;
}

has start => qw/ is ro lazy_build 1 isa Int /;
sub _build_start {
    my $self = shift;
    return $self->number * $self->search->rsz_number;
}

has results => qw/ is ro lazy_build 1 /;
sub _build_results {
    my $self = shift;
    return $self->response->results;
}

has error => qw/ is ro lazy_build 1 /;
sub _build_error {
    return shift->response->error;
}

sub result {
    my $self = shift;
    my $number = shift;

    return if $self->error;

    return unless $self->results;

    return $self->results->[$number];
}

1;
