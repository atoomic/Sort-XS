#!/usr/bin/env perl

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        require Test::More;
        Test::More::plan( skip_all =>
'these tests are for release candidate testing ( set RELEASE_TESTING=1 )'
        );
    }
}

use strict;
use warnings;
use v5.10;

use Benchmark qw/timethese cmpthese/;
use Test::More;
use Sort::XS;
use List::Util qw(shuffle);

use Data::Dumper qw/Dumper/;

my @sets = (

    # very small arrays
    { arrays => 1000, rows => [10] },

    # mixed of common usage
    { arrays => 10, rows => [ 10, 100, 1_000 ] },

    { arrays => 100, rows => [100] },
    { arrays => 100, rows => [1_000] },
    { arrays => 100, rows => [10_000] },
    { arrays => 10,  rows => [100_000] },
    { arrays => 1,   rows => [1_000_000] },
);

foreach my $set (@sets) {

    # generate set of arrays to test
    my @tests;
    my $arrays = $set->{arrays} || 1;
    my @rows = @{ $set->{rows} };

    for ( 1 .. $arrays ) {
        for my $nelt (@rows) {
            push @tests, generate_sample($nelt);
        }
    }

    # benchmark the tests
    my $results = benchmark_set( \@tests );

    # display results
    say "### bench $arrays arrays of ", join( ', ', @rows ), " rows";
    map {
        my @a = @{$_};
        say sprintf( "%s -> %0s req/sec", $a[0], $a[1] );
    } @{ cmpthese($results) };
    say "\n";
}

ok(1);
done_testing;

exit;

# helpers

sub perl_sort {
    my $array = shift;

    my @sorted = sort { $a <=> $b } @$array;

    return \@sorted;
}

sub generate_sample {
    my ($elt) = shift;

    return [] unless $elt;

    #
    my @reply;
    my $last;
    for my $n ( 1 .. $elt ) {
        push( @reply, ( $reply[$#reply] || 1 ) + int( rand(10) ) );
    }
    @reply = shuffle @reply;

    return \@reply;
}

sub benchmark_set {
    my ($set) = @_;
    my @tests = @$set;

    my $count = -2;
    return timethese(
        $count,
        {
### correct on memory
            #        'insertion' => sub {
            #            foreach my $t (@tests) {
            #                my @sorted = Sort::XS::insertion_sort($t);
            #            }
            #        },

            'merge' => sub {
                foreach my $t (@tests) {
                    my $sorted = Sort::XS::merge_sort($t);
                }
            },

            'quick' => sub {
                foreach my $t (@tests) {
                    my $sorted = Sort::XS::quick_sort($t);
                }
            },
            'api_quick' => sub {
                foreach my $t (@tests) {
                    my $sorted = xsort($t);
                }
            },
            'api_hash_quick' => sub {
                foreach my $t (@tests) {
                    my $sorted = xsort(
                        list      => $t,
                        algorithm => 'quick',
                        data      => 'integer'
                    );
                }
            },

            'void' => sub {
                foreach my $t (@tests) {
                    my $sorted = Sort::XS::void_sort($t);
                }
            },

            'heap' => sub {
                foreach my $t (@tests) {
                    my $sorted = Sort::XS::heap_sort($t);
                }
            },

            'perl' => sub {
                foreach my $t (@tests) {
                    my $sorted = perl_sort($t);

                }
            },
        }
    );

}

__END__

# Sort::Fast
sort one dimension arrays faster using XS

# 1000 arrays * 10 rows ( integers )
merge -> 557/s req/sec
perl -> 565/s req/sec
heap -> 625/s req/sec
quick -> 637/s req/sec

# 100 arrays * 100 rows ( integers ) 
perl -> 645/s req/sec
merge -> 729/s req/sec
** heap -> 866/s req/sec
*** quick -> 946/s req/sec

# 100 arrays * 1_000 ( integers )
perl -> 50.7/s req/sec
merge -> 69.8/s req/sec
*** heap -> 83.9/s req/sec
*** quick -> 92.7/s req/sec

# 100 arrays * 10_000 ( integer )
perl -> 3.95/s req/sec
merge -> 5.97/s req/sec
** heap -> 7.20/s req/sec
*** quick -> 8.37/s req/sec

# 10 arrays * 100_000 rows ( integers )
perl -> 3.03/s req/sec
merge -> 5.26/s req/sec
** heap -> 6.08/s req/sec
*** quick -> 7.35/s req/sec


# 1 array * 1_000_000 rows ( integers )

perl -> 1.89/s req/sec
** merge -> 4.50/s req/sec
** heap -> 4.74/s req/sec
*** quick -> 6.43/s req/sec
