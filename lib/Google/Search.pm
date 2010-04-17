package Google::Search;

use warnings;
use strict;

=head1 NAME

Google::Search - Interface to the Google AJAX Search API

=head1 VERSION

Version 0.023

=cut

our $VERSION = '0.023';


=head1 SYNOPSIS

    my $key = ... # This should be a valid API key, gotten from:
                  # http://code.google.com/apis/ajaxsearch/signup.html

    my $referer = "http://www.mysite.com/index.html" # This should be a valid referer for the above key

    my $search = Google::Search->Web(q => "rock", key => $key, referer => $referer);
    my $result = $search->first;
    while ($result) {
        print $result->number, " ", $result->uri, "\n";
        $result = $result->next;
    }

    $search = Google::Search->Local( ..., q => "rock" );

    $search = Google::Search->Video( ..., q => "rock" );

    $search = Google::Search->Blog( ..., q => "rock" );

    $search = Google::Search->News( ..., q => "rock" );

    $search = Google::Search->Book( ..., q => "rock" );

    $search = Google::Search->Image( ..., q => "rock" );

    # You can also take advantage of each service's specialized interface
    # The search below specifies the latitude and longitude:
    $search = Google::Search->Local( ..., q => { q => "rock", sll => "33.823230,-116.512110" }, ... );
    
=head1 DESCRIPTION

Google::Search is an interface to the Google AJAX Search API (L<http://code.google.com/apis/ajaxsearch/>). 

Currently, their API looks like it will fetch you the top 64 results for your search query.

According to the Terms of Service, you need to sign up for an API key here: L<http://code.google.com/apis/ajaxsearch/signup.html>

=cut

use Any::Moose;
use Google::Search::Carp;

use Google::Search::Response;
use Google::Search::Page;
use Google::Search::Result;
use Google::Search::Error;
use LWP::UserAgent;

BEGIN {
    use vars qw/ $BASE %SERVICE2URI /;
    $BASE = 'http://ajax.googleapis.com/ajax/services/search';
    %SERVICE2URI = (
        map { $_ => "$BASE/$_" } qw/ web local video blogs news books images patent /,
        blog => "$BASE/blogs",
        book => "$BASE/books",
        image => "$BASE/images",
    );
}

=head1 METHODS

=head2 Google::Search->Web(...)

Create a new web search. See C<new> for more information.

=head2 Google::Search->Local(...)

Create a new local search. See C<new> for more information.

=head2 Google::Search->Video(...)

Create a new video search. See C<new> for more information.

=head2 Google::Search->Blog(...)

=head2 Google::Search->Blogs(...)

Create a new blog search. See C<new> for more information.

=head2 Google::Search->News(...)

Create a new news search. See C<new> for more information.

=head2 Google::Search->Book(...)

=head2 Google::Search->Books(...)

Create a new book search. See C<new> for more information.

=head2 Google::Search->Image(...)

=head2 Google::Search->Images(...)

Create a new book search. See C<new> for more information.

=head2 Google::Search->new(...) 

Create and return a new Google::Search object

You can configure the search by passing the following to C<new>:

    q               The search phrase to submit to Google
                    Optionally, this can also be a hash of parameters to submit. You can
                    use the hash form to take advantage of each service's varying interface.
                    Make sure to at least include a C<q> parameter with your search.

    key             Your Google AJAX Search API key (see Description)

    referer         A referer that is valid for the above key

    service         The service to search under. This can be any of: web,
                    local, video, blog, news, book, or image.

=cut

sub service2uri {
    my $class = shift;
    my $service = shift;
    croak "Missing service" unless $service;
    $service = lc $service;
    return unless my $uri = $SERVICE2URI{$service};
    return $uri;
}

sub uri_for_service {
    return shift->service2uri( @_ );
}

sub BUILDARGS {
    my $class = shift;
    
    my $given;
    if ( 1 == @_ && ref $_[0] eq 'HASH' ) {
        $given = $_[0];
    }
    elsif ( 0 == @_ % 2 ) {
        $given = { @_ };
    }
    else {
        croak "Odd number of arguments: @_";
    }

    $given->{query} = $given->{q} if defined $given->{q} && ! defined $given->{query};
    $given->{version} = $given->{v} if defined $given->{v} && ! defined $given->{version};
    $given->{referer} = $given->{referrer}
        if defined $given->{referrer} && ! defined $given->{referer};

    return $given;
}

for my $service ( keys %SERVICE2URI ) {
    no strict 'refs';
    my $method = ucfirst $service;
    *$method = sub {
        my $class = shift;
        return $class->new( service => $service, @_ );
    };
}

has agent => qw/ is ro lazy_build 1 isa LWP::UserAgent /;
sub _build_agent {
    my $self = shift;
    my $agent = LWP::UserAgent->new;
    $agent->env_proxy;
    return $agent;
}

has service => qw/ is ro lazy_build 1 /;
sub _build_service { 'web' }

has uri => qw/ is ro lazy_build 1 isa URI /;
sub _build_uri {
    my $self = shift;
    my $service = $self->service;
    my $uri = $self->service2uri( $service );
    croak "Invalid service ($service)" unless $uri;
    return URI->new( $uri );
}

has query => qw/ is ro required 1 /;
sub q { return shift->query( @_ ) }

has version => qw/ is ro lazy_build 1 isa Str /;
sub _build_version { '1.0' }
sub v { return shift->version( @_ ) }

has referer => qw/ is ro isa Str /;
sub referrer { return shift->referer( @_ ) }

has key => qw/ is ro isa Str /;

has rsz => qw/ is ro lazy_build 1 isa Str /;
sub _build_rsz { 'large' }
has rsz_number => qw/ is ro lazy_build 1 isa Int /;
sub _build_rsz_number {
    my $self = shift;
    my $rsz = $self->rsz;
    return 4 if $rsz eq "small";
    return 8 if $rsz eq "large";
    croak "Don't understand rsz ($rsz)";
}

has _page => qw/ is ro required 1 /, default => sub { [] };
has _result => qw/ is ro required 1 /, default => sub { [] };
has current => qw/ is ro lazy_build 1 /;
sub _build_current {
    return shift->first;
}
has error => qw/ is rw /;

sub request {
    my $self = shift;

    my @parameters;
    my @headers;

    my $referer = $self->referer;
    my $key = $self->key;

    push @headers, Referer => $referer if $referer;
    push @parameters, key => $key if $key;

    my $query = $self->query;
    if (ref $query eq "HASH") {
        # TODO Check for query instead of q?
        push @parameters, %$query;
    }
    else {
        push @parameters, q => $query;
    }

    my $uri = $self->uri->clone;
    $uri->query_form({ v => $self->version, rsz => $self->rsz, @parameters, @_ });

    return unless my $http_response = $self->agent->get( $uri, @headers );

    return Google::Search::Response->new( http_response => $http_response );
}

sub page {
    my $self = shift;
    my $number = shift;

    $self->error(undef);

    my $page = $self->_page->[$number] ||=
            Google::Search::Page->new(search => $self, number => $number);

    $self->error( $page->error ) if $page->error;

    return $page;
}

=head2 $search->first 

Returns a L<Google::Search::Result> representing the first result in the search, if any.

Returns undef if nothing was found

=cut

sub first {
    my $self = shift;
    return $self->result(0);
}

=head2 $search->next 

An iterator for $search. Will the return the next result each time it is called, and undef when
there are no more results.

Returns a L<Google::Search::Result>

Returns undef if nothing was found

=cut

sub next {
    my $self = shift;
    return $self->current unless $self->{current};
    return $self->{current} = $self->current->next;
}

=head2 $search->result( <rank> )

Returns a L<Google::Search::Result> corresponding to the result at <rank>

These are equivalent:

    $search->result(0)

    $search->first

=cut

sub result {
    my $self = shift;
    my $number = shift;

    $self->error(undef);

    return $self->_result->[$number] if $self->_result->[$number];
    my $result = do {
        my $result_number = $number % $self->rsz_number;
        my $page_number = int($number / $self->rsz_number);
        my $page = $self->page($page_number);
        my $content = $page->result($result_number);
        if ($content) {
            Google::Search::Result->parse($content, page => $page, search => $self, number => $number);
        }
        else {
            undef;
        }
    };
    return undef unless $result;
    return $self->_result->[$number] = $result;
}

=head2 $search->all

Returns L<Google::Search::Result> list which includes every result Google has returned for the query

In scalar context an array reference is returned, a list otherwise

An empty list is returned if nothing was found

=cut

sub all {
    my $self = shift;

    my $result = $self->first;
    1 while $result && ($result = $result->next); # Fetch everything
    if ($self->error) {
        die $self->error->reason unless $self->error->message eq "out of range start";
    }

    my @results = @{ $self->_result };
    return wantarray ? @results : \@results;
}

=head2 $search->match( <code> )

Returns a L<Google::Search::Result> list

This method will iterate through each result in the search, passing the result to <code> as the first argument.
If <code> returns true, then the result will be included in the returned list

In scalar context this method returns the number of matches

=cut

sub match {
    my $self = shift;
    my $matcher = shift;

    my @matched;
    my $result = $self->first;
    while ($result) {
        push @matched, $result if $matcher->($result);
        $result = $result->next;
    }
    if ($self->error) {
        die $self->error->reason unless $self->error->message eq "out of range start";
    }
    return @matched;
}

=head2 $search->first_match( <code> )

Returns a L<Google::Search::Result> that is the first to match <code>

This method will iterate through each result in the search, passing the result to <code> as the first argument.
If <code> returns true, then the result will be returned and iteration will stop.

=cut

sub first_match {
    my $self = shift;
    my $matcher = shift;

    my $result = $self->first;
    while ($result) {
        return $result if $matcher->($result);
        $result = $result->next;
    }
    if ($self->error) {
        die $self->error->reason unless $self->error->message eq "out of range start";
    }
    return undef;
}

$_->meta->make_immutable for qw/
    Google::Search
    Google::Search::Response
    Google::Search::Page
    Google::Search::Result
    Google::Search::Error
/;

=head2 $search->error

Returns a L<Google::Search::Error> if there was an error with the last search

If you receive undef from a result access then you can use this routine to see if there was a problem

    warn $search->error->reason;

    warn $search->error->http_response->as_string;

    # Etc, etc.

This will return undef if no error was encountered

=cut


=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 SEE ALSO

L<REST::Google::Search>

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
