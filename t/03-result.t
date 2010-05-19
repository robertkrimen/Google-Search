use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Google::Search;

my $result;
sub result (@) {
    my $service = shift;
    my $search = Google::Search->new( service => $service, query => 'rock', @_ );
    my $result = $search->first;
    die "Error searching in $service: ", $search->error->message unless $result;
    return $result;
}

sub ok_diag ($) {
    local $Test::Builder::Level += 1;
    my $value = shift;
    diag( $value );
    ok( $value );
}

sub ok_attr (@) {
    local $Test::Builder::Level += 1;
    my $result = shift;
    for ( @_ ) {
        diag ( $result->$_ );
        ok( $result->$_, "Missing $_ for " . $result->search->service );
    }
}

SKIP: {
    skip 'Do TEST_RELEASE=1 to go out to Google and run some tests' unless $ENV{TEST_RELEASE};

    for ( qw/ web local video blog blogs
            news book books image images patent patents / ) {
        ok_diag( result( $_ )->title );
    }

    ok_attr( result( 'local' ), qw/ lat lng streetAddress / );
    ok_attr( result( 'video' ), qw/ published publisher / );
    ok_attr( result( 'blog' ), qw/ blogUrl author / );
    ok_attr( result( 'news' ), qw/ publisher publishedDate / );
    ok_attr( result( 'book' ), qw/ publishedYear authors / );
    ok_attr( result( 'image' ), qw/ width height / );
    ok_attr( result( 'patent' ), qw/ assignee applicationDate patentNumber patentStatus / );
}

1;

