use strict;
use warnings;
use Test::More;
use Sort::XS;

can_ok( 'Sort::XS', 'xsort' );

my @tests = ( [ 1, 5, 3 ], [ 1 .. 10, 2 .. 11 ], [ 10 .. 1 ], [ 1 .. 10 ] );

my @algos = qw/quick heap merge insertion perl/;

foreach my $set (@tests) {
    my @sorted = sort { $a <=> $b } @$set;

    is_deeply( xsort($set), \@sorted, "can sort using one argument" );

    is_deeply( xsort( list => $set ),
        \@sorted, "can sort using a hash argument" );

    map {
        is_deeply( xsort( $set, algorithm => $_ ),
            \@sorted, "can sort use algorithm $_" )
    } @algos;

    is_deeply( xsort( $set, algorithm => 'perl', data => 'integer' ),
        \@sorted, "can sort using a hash argument without list attribute" );
    is_deeply( xsort( list => $set, algorithm => 'perl', data => 'integer' ),
        \@sorted, "can sort using a hash argument" );
}

# bad usage
my @bad_usage = (
    [ [ 10 .. 1 ], algorithm => 'unknown' ],
    [ list => [ 10 .. 1 ], algorithm => 'unknown' ],
    [], ['not a list'], [51],
);
foreach my $params (@bad_usage) {

    eval { xsort(@$params); };
    like( $@, '/\w+/', "can detect an error" );
}

done_testing;

