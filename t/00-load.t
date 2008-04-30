#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Google::Search' );
}

diag( "Testing Google::Search $Google::Search::VERSION, Perl $], $^X" );
