#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Sort::XS ();

use Data::Dumper qw/Dumper/;

my @tests = (
    [ 8, 5, 1, 7 ],
    [ 18,       11, 1, 151, 12 ],
    [ 1 .. 100, 50 .. 120 ]

);

foreach my $m (qw/fast insertion shell heap merge quick/) {
    subtest "sort with $m" => sub {
        foreach my $t (@tests) {
            my @sorted = sort { $a <=> $b } @$t;

            my $result = eval "Sort::XS::${m}_sort(\$t)";
            is_deeply( $result, \@sorted, "sort using $m" )
              or do { warn "\n- method $m : \n", Dumper($result); die; };
        }
    };

}

is_deeply(
    Sort::XS::void_sort( [ 1, 5, 3 ] ),
    [ 1, 5, 3 ],
    'void sort is dummy and do nothing'
);

done_testing;
