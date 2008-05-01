package Google::Search;

use warnings;
use strict;

=head1 NAME

Google::Search - 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

=cut

use Moose;
use Google::Search::Carp;

use Google::Search::Response;
use Google::Search::Page;
use Google::Search::Result;
use LWP::UserAgent;

use constant SERVICE_URI => {
    web => 'http://ajax.googleapis.com/ajax/services/search/web',

    local => 'http://ajax.googleapis.com/ajax/services/search/local',

    video => 'http://ajax.googleapis.com/ajax/services/search/video',

    blog => 'http://ajax.googleapis.com/ajax/services/search/blogs',
    blogs => 'http://ajax.googleapis.com/ajax/services/search/blogs',

    news => 'http://ajax.googleapis.com/ajax/services/search/news',

    book => 'http://ajax.googleapis.com/ajax/services/search/books',
    books => 'http://ajax.googleapis.com/ajax/services/search/books',

    image => 'http://ajax.googleapis.com/ajax/services/search/images',
    images => 'http://ajax.googleapis.com/ajax/services/search/images',
};

has agent => qw/is ro required 1 lazy 1 isa LWP::UserAgent/, default => sub {
    my $self = shift;
    my $agent = LWP::UserAgent->new;
    $agent->env_proxy;
    return $agent;
};
has service => qw/is ro lazy 1/, default => "web";
has uri => qw/is ro required 1 lazy 1 isa URI/, default => sub {
    my $self = shift;
    return URI->new($self->uri_for_service($self->service));
};
has q => qw/is ro required 1 isa Str/;
has v => qw/is ro required 1 isa Str/, default => "1.0";
has rsz => qw/is ro required 1 isa Str default small/;
has rsz_number => qw/is ro required 1 isa Int/, default => sub {
    my $self = shift;
    my $rsz = $self->rsz;
    return 4 if $rsz eq "small";
    return 8 if $rsz eq "large";
    croak "Don't understand rsz ($rsz)";
};
has _page => qw/is ro required 1/, default => sub { [] };
has _result => qw/is ro required 1/, default => sub { [] };
has current => qw/is ro required 1 isa Google::Search::Result lazy 1/, default => sub {
    return shift->first;
};
has error => qw/is rw/;

sub uri_for_service {
    my $self = shift;
    my $service = shift;
    return unless $service;
    $service = lc $service;
    $service =~ s/^\s*//g;
    $service =~ s/\s*$//g;
    return SERVICE_URI->{$service};
}

sub request {
    my $self = shift;

    my $referer = "http://bravo9.com/test/";
    my $key = "ABQIAAAAtDqLrYRkXZ61bOjIaaXZyxRzmYrwLktJSlj4239XJWgXhec7BRTpxY7L0KEkxEgtcpqoMuT-fDwC7A";

    my $uri = $self->uri->clone;
    $uri->query_form({ v => $self->v, key => $key, q => $self->q, rsz => $self->rsz, @_ });

#    warn $uri;

    return unless my $http_response = $self->agent->get($uri, [ Referer => $referer ]);

#    warn $http_response->as_string;

    return Google::Search::Response->new(http_response => $http_response);
}

sub page {
    my $self = shift;
    my $number = shift;

    $self->error(undef);

    my $page = $self->_page->[$number] ||= Google::Search::Page->new(search => $self, number => $number);

    $self->error($page->error) if $page->error;

    return $page;
}

sub first {
    my $self = shift;
    return $self->result(0);
}

sub next {
    my $self = shift;
    return $self->current unless $self->{current};
    return $self->{current} = $self->current->next;
}

sub result {
    my $self = shift;
    my $number = shift;

    $self->error(undef);

    return $self->_result->[$number] ||= do {
        my $result_number = $number % $self->rsz_number;
        my $page_number = int($number / $self->rsz_number);
        my $content = $self->page($page_number)->result($result_number);
        if ($content) {
#            Google::Search::Result->new(search => $self, number => $number, content => $content);
            Google::Search::Result->parse($content, search => $self, number => $number);
        }
        else {
            undef;
        }
    };
}

sub all {
    my $self = shift;

    my $result = $self->first;
    1 while $result && $result->next; # Fetch everything
    die $self->error->reason unless $self->error->message eq "out of range start";

    my @results = @{ $self->_result };
    return wantarray ? @results : \@results;
}

sub match {
    my $self = shift;
    my $matcher = shift;

    my @matched;
    my $result = $self->first;
    while ($result) {
        push @matched, $result if $matcher->($result);
        $result = $result->next;
    }
    die $self->error->reason unless $self->error->message eq "out of range start";
    return @matched;
}

sub match_first {
    my $self = shift;
    my $matcher = shift;

    my $result = $self->first;
    while ($result) {
        return $result if $matcher->($result);
        $result = $result->next;
    }
    die $self->error->reason unless $self->error->message eq "out of range start";
    return undef;
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-google-search at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Google-Search>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Google::Search


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Google-Search>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Google-Search>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Google-Search>

=item * Search CPAN

L<http://search.cpan.org/dist/Google-Search>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Google::Search
