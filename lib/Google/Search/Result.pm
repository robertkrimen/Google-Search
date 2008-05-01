package Google::Search::Result;

=head1 NAME

Google::Search::Result 

=head1 DESCRIPTION

An object represting a result from a Google search (via L<Google::Search>)

=head1 METHODS

There are a variety of accessors available for each result depending which
service you are searching under

For more information, see L<http://code.google.com/apis/ajaxsearch/documentation/reference.html#_intro_GResult>

=head2 $result->uri

A L<URI> object best representing the location of the result

=head2 $result->title

=head2 $result->titleNoFormatting

=head2 $result->number

The position of the result in the search (starting from 0)

=head2 $result->previous

The previous result before $result or undef if beyond the first

=head2 $result->next

The next result after $result or undef if after the last

=head2 $result->GsearchResultClass

The result class, as given by Google

=cut

#package Google::Search::Result::Web;

#use Moose;
#use Google::Search::Carp;
#extends qw/Google::Search::Result/;

#__PACKAGE__->has_field($_) for qw/title titleNoFormatting visibleUrl content/;
#__PACKAGE__->has_uri_field($_) for qw/unescapedUrl cacheUrl/;
#sub uri { return shift->unescapedUrl(@_) }

#package Google::Search::Result::Local;

#use Moose;
#use Google::Search::Carp;
#extends qw/Google::Search::Result/;

#__PACKAGE__->has_field($_) for qw/title titleNoFormatting lat lng streetAddress city region country/;
#__PACKAGE__->has_uri_field($_) for qw/url ddUrl ddUrlToHere ddUrlFromHere staticMapUrl/;
#sub uri { return shift->url(@_) }

#package Google::Search::Result::Video;

#use Moose;
#use Google::Search::Carp;
#extends qw/Google::Search::Result/;

#__PACKAGE__->has_field($_) for qw/title titleNoFormatting content published publisher duration tbWidth tbHeight/;
#__PACKAGE__->has_uri_field($_) for qw/url tbUrl playUrl/;
#sub uri { return shift->url(@_) }

#package Google::Search::Result::Blog;

#use Moose;
#use Google::Search::Carp;
#extends qw/Google::Search::Result/;

#__PACKAGE__->has_field($_) for qw/title titleNoFormatting content publishedDate author/;
#__PACKAGE__->has_uri_field($_) for qw/blogUrl postUrl/;
#sub uri { return shift->postUrl(@_) }

#package Google::Search::Result::News;

#use Moose;
#use Google::Search::Carp;
#extends qw/Google::Search::Result/;

#__PACKAGE__->has_field($_) for qw/title titleNoFormatting content url publisher location publishedDate/;
#__PACKAGE__->has_uri_field($_) for qw/unescapedUrl clusterUrl/;
#sub uri { return shift->unescapedUrl(@_) }

#package Google::Search::Result::Book;

#use Moose;
#use Google::Search::Carp;
#extends qw/Google::Search::Result/;

#__PACKAGE__->has_field($_) for qw/title titleNoFormatting content url authors publishedYear bookId pageCount/;
#__PACKAGE__->has_uri_field($_) for qw/unescapedUrl/;
#sub uri { return shift->unescapedUrl(@_) }

#package Google::Search::Result::Image;

#use Moose;
#use Google::Search::Carp;
#extends qw/Google::Search::Result/;

#__PACKAGE__->has_field($_) for qw/title titleNoFormatting content contentNoFormatting url visibleUrl width height tbWidth tbHeight/;
#__PACKAGE__->has_uri_field($_) for qw/unescapedUrl originalContextUrl tbUrl/;

#sub uri { return shift->unescapedUrl(@_) }

use Moose;
use Google::Search::Carp;

use URI;

has page => qw/is ro required 1 isa Google::Search::Page weak_ref 1/;
has http_response => qw/is ro isa HTTP::Response required 1 lazy 1/, default => sub {
    my $self = shift;
    return $self->page->http_response;
};
has search => qw/is ro required 1 isa Google::Search weak_ref 1/;
has number => is => "ro", isa => "Int", required => 1;
has _content => is => "ro", required => 1;
__PACKAGE__->has_field($_) for qw/GsearchResultClass/;

sub previous {
    my $self = shift;
    my $number = $self->number;
    return undef unless $number > 0;
    return $self->search->result($number - 1);
}

sub next {
    my $self = shift;
    return $self->search->result($self->number + 1);
}

sub get {
    my $self = shift;
    my $field = shift;

    return unless $field;
    return $self->_content->{$field};
}

sub has_field {
    my $class = shift;
    my $field = shift;
    $class->meta->add_attribute($field => qw/is ro lazy 1/, default => sub {
        return shift->get($field);
    }, @_);
}

sub has_uri_field {
    my $class = shift;
    my $field = shift;
    $class->meta->add_attribute($field => qw/is ro lazy 1/, default => sub {
        my $self = shift;
        return undef unless my $uri = $self->get($field);
        return URI->new($uri);
    }, @_);
}

sub parse {
    my $class = shift;
    my $content = shift;
    my $GsearchResultClass = $content->{GsearchResultClass};
    my $result_class;
    ($result_class) = $GsearchResultClass =~ m/^G(\w+)Search/;
    croak "Don't know how to parse $GsearchResultClass" unless $result_class;
    $result_class = ucfirst $result_class;
    $result_class = "Google::Search::Result::$result_class";
    return $result_class->new(_content => $content, @_);
}


package Google::Search::Result::Web;

use Moose;
use Google::Search::Carp;
extends qw/Google::Search::Result/;

__PACKAGE__->has_field($_) for qw/title titleNoFormatting visibleUrl content/;
__PACKAGE__->has_uri_field($_) for qw/unescapedUrl cacheUrl/;
sub uri { return shift->unescapedUrl(@_) }

package Google::Search::Result::Local;

use Moose;
use Google::Search::Carp;
extends qw/Google::Search::Result/;

__PACKAGE__->has_field($_) for qw/title titleNoFormatting lat lng streetAddress city region country/;
__PACKAGE__->has_uri_field($_) for qw/url ddUrl ddUrlToHere ddUrlFromHere staticMapUrl/;
sub uri { return shift->url(@_) }

package Google::Search::Result::Video;

use Moose;
use Google::Search::Carp;
extends qw/Google::Search::Result/;

__PACKAGE__->has_field($_) for qw/title titleNoFormatting content published publisher duration tbWidth tbHeight/;
__PACKAGE__->has_uri_field($_) for qw/url tbUrl playUrl/;
sub uri { return shift->url(@_) }

package Google::Search::Result::Blog;

use Moose;
use Google::Search::Carp;
extends qw/Google::Search::Result/;

__PACKAGE__->has_field($_) for qw/title titleNoFormatting content publishedDate author/;
__PACKAGE__->has_uri_field($_) for qw/blogUrl postUrl/;
sub uri { return shift->postUrl(@_) }

package Google::Search::Result::News;

use Moose;
use Google::Search::Carp;
extends qw/Google::Search::Result/;

__PACKAGE__->has_field($_) for qw/title titleNoFormatting content url publisher location publishedDate/;
__PACKAGE__->has_uri_field($_) for qw/unescapedUrl clusterUrl/;
sub uri { return shift->unescapedUrl(@_) }

package Google::Search::Result::Book;

use Moose;
use Google::Search::Carp;
extends qw/Google::Search::Result/;

__PACKAGE__->has_field($_) for qw/title titleNoFormatting content url authors publishedYear bookId pageCount/;
__PACKAGE__->has_uri_field($_) for qw/unescapedUrl/;
sub uri { return shift->unescapedUrl(@_) }

package Google::Search::Result::Image;

use Moose;
use Google::Search::Carp;
extends qw/Google::Search::Result/;

__PACKAGE__->has_field($_) for qw/title titleNoFormatting content contentNoFormatting url visibleUrl width height tbWidth tbHeight/;
__PACKAGE__->has_uri_field($_) for qw/unescapedUrl originalContextUrl tbUrl/;

sub uri { return shift->unescapedUrl(@_) }

1;

__END__

for my $field (qw/GsearchResultClass title titleNoFormatting url visibleUrl content/) {
    has $field => is => "ro", lazy => 1, default => sub { 
        return shift->content->{$field};
    };
}
for my $field (qw/unescapedUrl postUrl blogUrl cacheUrl/) {
    has $field => is => "ro", lazy => 1, default => sub { 
    };
}

