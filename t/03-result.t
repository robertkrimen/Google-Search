#!/usr/bin/perl -w

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
    diag( $result->title );
    return $result;
}

SKIP: {
    skip 'Do TEST_RELEASE=1 to go out to Google and run some tests' unless $ENV{TEST_RELEASE};

    for ( qw/ web local video blog blogs
            news book books image images patent patents / ) {
        diag( $_ );
        ok( result( $_ )->title );
    }
}

1;

