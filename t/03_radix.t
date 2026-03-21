#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Sort::XS ();

# Basic radix sort tests
subtest 'radix_sort basic' => sub {
    is_deeply(
        Sort::XS::radix_sort([8, 5, 1, 7]),
        [1, 5, 7, 8],
        'simple integers'
    );

    is_deeply(
        Sort::XS::radix_sort([18, 11, 1, 151, 12]),
        [1, 11, 12, 18, 151],
        'mixed integers'
    );

    is_deeply(
        Sort::XS::radix_sort([1..100, 24..42]),
        [sort { $a <=> $b } (1..100, 24..42)],
        'large array with duplicates'
    );
};

# Negative numbers
subtest 'radix_sort negatives' => sub {
    is_deeply(
        Sort::XS::radix_sort([-5, 3, -1, 7, 0, -3]),
        [-5, -3, -1, 0, 3, 7],
        'mixed positive and negative'
    );

    is_deeply(
        Sort::XS::radix_sort([-100, -50, -200, -1]),
        [-200, -100, -50, -1],
        'all negative'
    );
};

# Edge cases
subtest 'radix_sort edge cases' => sub {
    is_deeply(
        Sort::XS::radix_sort([42]),
        [42],
        'single element'
    );

    is_deeply(
        Sort::XS::radix_sort([]),
        [],
        'empty array'
    );

    is_deeply(
        Sort::XS::radix_sort([5, 5, 5, 5]),
        [5, 5, 5, 5],
        'all same'
    );

    is_deeply(
        Sort::XS::radix_sort([1, 2, 3, 4, 5]),
        [1, 2, 3, 4, 5],
        'already sorted'
    );

    is_deeply(
        Sort::XS::radix_sort([5, 4, 3, 2, 1]),
        [1, 2, 3, 4, 5],
        'reverse sorted'
    );
};

# Large values (IV range)
subtest 'radix_sort large values' => sub {
    my $max = (~0 >> 1);
    my $min = -$max - 1;

    is_deeply(
        Sort::XS::radix_sort([$max, 0, $min, 1, -1]),
        [$min, -1, 0, 1, $max],
        'extreme IV range'
    );
};

# Corner cases from 02_corners.t adapted for radix
subtest 'radix_sort corners' => sub {
    my $max = (~0 >> 1);
    my $min = -$max - 1;

    for my $n (5, 10, 20) {
        my @data;
        for (0 .. $n) {
            my $d = int rand 300;
            if ($d < 100) {
                $d += $min;
            } elsif ($d < 200) {
                $d -= 150;
            } else {
                $d += ($max - 300);
            }
            push @data, $d;
        }
        my @sorted_data = sort { int($a) <=> int($b) } @data;
        is_deeply(
            Sort::XS::radix_sort(\@data),
            \@sorted_data,
            "radix sort $n random integers with extreme values"
        );
    }
};

# Consistency with quick_sort
subtest 'radix vs quick consistency' => sub {
    for my $size (100, 1000) {
        my @data = map { int(rand(2000000)) - 1000000 } 1..$size;
        my $radix_result = Sort::XS::radix_sort(\@data);
        my $quick_result = Sort::XS::quick_sort(\@data);
        is_deeply($radix_result, $quick_result,
            "radix and quick produce same result for $size elements");
    }
};

done_testing;
