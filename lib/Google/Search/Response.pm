package Google::Search::Response;

use Any::Moose;
use Google::Search::Carp;

use Google::Search::Error;
use JSON;

has http_response => qw/is ro required 1 isa HTTP::Response/;
has content => qw/is ro required 1 lazy 1/, default => sub {
    my $self = shift;
    $self->parse;
    return $self->{content};
};
has error => qw/is ro required 1 lazy 1/, default => sub {
    my $self = shift;
    $self->parse;
    return $self->{error};
};
has responseData => qw/is ro required 1 lazy 1/, default => sub { return shift->content->{responseData} };
has results => qw/is ro required 1 lazy 1/, default => sub { return shift->responseData->{results} };

sub is_success {
    my $self = shift;
    return $self->error ? 0 : 1;
}

sub parse {
    my $self = shift;

    return 1 if $self->{results};

    return undef if $self->{error};

    my $response = $self->http_response;

    return $self->_error(http_response => $response, code => $response->code, message => $response->message) unless $response->is_success;

    my $content = $response->content;
    eval {
        $content = $self->{content} = decode_json $content;
    };
    return $self->_error(http_response => $response, code => -1, message => "Unable to JSON parse content") if $@;

    return $self->_error(http_response => $response, code => -1, message => "Unable to JSON parse content") unless $content;

    return $self->_error(http_response => $response, code => $content->{responseStatus}, message => $content->{responseDetails}) unless $content->{responseStatus} eq 200;

    return $self->_error(http_response => $response, code => -1, message => "responseData is null") unless $self->responseData;

    return $self->_error(http_response => $response, code => -1, message => "responseData.results is null") unless $self->results;

    return 1;

}

sub _error {
    my $self = shift;
    my %error = @_;
    $self->{error} = Google::Search::Error->new(%error);
    $self->{content} = { responseData => { results => undef } };
    return undef;
}

1;
