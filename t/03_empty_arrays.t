#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Sort::XS ();

# Test that all algorithms handle empty and single-element arrays safely.
# HeapSort and VoidSort previously read A[0] on empty arrays (undefined behavior).

my @int_algorithms = qw(insertion shell heap merge quick void);
my @str_algorithms = qw(insertion shell heap merge quick);

subtest 'empty integer arrays' => sub {
    for my $algo (@int_algorithms) {
        my $sorter = do { no strict 'refs'; \&{"Sort::XS::${algo}_sort"} };
        is_deeply($sorter->([]), [], "empty array with $algo");
    }
};

subtest 'empty string arrays' => sub {
    for my $algo (@str_algorithms) {
        my $sorter = do { no strict 'refs'; \&{"Sort::XS::${algo}_sort_str"} };
        is_deeply($sorter->([]), [], "empty string array with $algo");
    }
};

subtest 'single-element integer arrays' => sub {
    for my $algo (@int_algorithms) {
        my $sorter = do { no strict 'refs'; \&{"Sort::XS::${algo}_sort"} };
        my $result = $sorter->([42]);
        if ($algo eq 'void') {
            is_deeply($result, [42], "single element with $algo (no-op)");
        } else {
            is_deeply($result, [42], "single element with $algo");
        }
    }
};

subtest 'single-element string arrays' => sub {
    for my $algo (@str_algorithms) {
        my $sorter = do { no strict 'refs'; \&{"Sort::XS::${algo}_sort_str"} };
        is_deeply($sorter->(['hello']), ['hello'], "single string element with $algo");
    }
};

subtest 'two-element arrays' => sub {
    for my $algo (qw(insertion shell heap merge quick)) {
        my $sorter = do { no strict 'refs'; \&{"Sort::XS::${algo}_sort"} };
        is_deeply($sorter->([2, 1]), [1, 2], "two elements (reversed) with $algo");
        is_deeply($sorter->([1, 2]), [1, 2], "two elements (sorted) with $algo");
        is_deeply($sorter->([5, 5]), [5, 5], "two equal elements with $algo");
    }
};

subtest 'duplicate elements' => sub {
    for my $algo (qw(insertion shell heap merge quick)) {
        my $sorter = do { no strict 'refs'; \&{"Sort::XS::${algo}_sort"} };
        is_deeply($sorter->([3, 3, 3, 3]), [3, 3, 3, 3], "all duplicates with $algo");
        is_deeply($sorter->([1, 3, 3, 1]), [1, 1, 3, 3], "some duplicates with $algo");
    }
};

subtest 'undef and non-ref inputs' => sub {
    is_deeply(Sort::XS::quick_sort(undef), [], "undef returns empty array");
    is_deeply(Sort::XS::quick_sort("not a ref"), [], "non-ref returns empty array");
};

subtest 'non-array reference croaks' => sub {
    for my $algo (qw(insertion shell heap merge quick)) {
        my $sorter = do { no strict 'refs'; \&{"Sort::XS::${algo}_sort"} };
        eval { $sorter->({}) };
        like($@, qr/expecting a reference to an array/,
             "hashref croaks with $algo");
    }
};

subtest 'xsort API with empty arrays' => sub {
    is_deeply(Sort::XS::xsort([]), [], "xsort on empty array");
    is_deeply(Sort::XS::ixsort([]), [], "ixsort on empty array");
    is_deeply(Sort::XS::sxsort([]), [], "sxsort on empty array");
};

done_testing;
