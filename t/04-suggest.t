#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
plan 'no_plan';

use Google::Search;

SKIP: {
    skip 'Do TEST_RELEASE=1 to go out to Google and run some tests' unless $ENV{TEST_RELEASE};

    my( $data, $result );

    $data = Google::Search->suggest( 'monkey' );
    explain $data;
    is( ref $data, 'ARRAY' );
    is( +@$data, 10 );
    for (@$data ) {
        like( $_->[0], qr/monkey/i );
        like( $_->[1], qr/^[\d,]+ results$/ );
        like( $_->[2], qr/^\d+$/ );
    }

    $data = Google::Search->suggest( 'monkey', [ hl => 'de' ] );
    explain $data;
    is( ref $data, 'ARRAY' );
    is( +@$data, 10 );
    for (@$data ) {
        like( $_->[0], qr/monkey/i );
        like( $_->[1], qr/^[\d\.]+ Ergebnisse$/ );
        like( $_->[2], qr/^\d+$/ );
    }
}
__END__


