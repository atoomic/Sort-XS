#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Sort::XS qw(xsort_inplace);

# In-place integer sorting
subtest 'quick_sort_inplace' => sub {
    my $arr = [8, 5, 1, 7];
    Sort::XS::quick_sort_inplace($arr);
    is_deeply($arr, [1, 5, 7, 8], 'simple integers');

    $arr = [1..100, 24..42];
    my @expected = sort { $a <=> $b } @$arr;
    Sort::XS::quick_sort_inplace($arr);
    is_deeply($arr, \@expected, 'large array with duplicates');
};

# In-place string sorting
subtest 'quick_sort_str_inplace' => sub {
    my $arr = ['kiwi', 'banana', 'apple', 'cherry'];
    Sort::XS::quick_sort_str_inplace($arr);
    is_deeply($arr, ['apple', 'banana', 'cherry', 'kiwi'], 'strings');

    $arr = [reverse 'a'..'z'];
    Sort::XS::quick_sort_str_inplace($arr);
    is_deeply($arr, ['a'..'z'], 'reverse alphabet');
};

# In-place heap sort
subtest 'heap_sort_inplace' => sub {
    my $arr = [18, 11, 1, 151, 12];
    Sort::XS::heap_sort_inplace($arr);
    is_deeply($arr, [1, 11, 12, 18, 151], 'integers');

    $arr = ['cherry', 'apple', 'banana'];
    Sort::XS::heap_sort_str_inplace($arr);
    is_deeply($arr, ['apple', 'banana', 'cherry'], 'strings');
};

# In-place merge sort
subtest 'merge_sort_inplace' => sub {
    my $arr = [42..24];
    my @expected = sort { $a <=> $b } @$arr;
    Sort::XS::merge_sort_inplace($arr);
    is_deeply($arr, \@expected, 'reverse range');

    $arr = [reverse 'aa'..'cc'];
    my @expected_str = sort { $a cmp $b } @$arr;
    Sort::XS::merge_sort_str_inplace($arr);
    is_deeply($arr, \@expected_str, 'strings');
};

# In-place radix sort
subtest 'radix_sort_inplace' => sub {
    my $arr = [-5, 3, -1, 7, 0, -3];
    Sort::XS::radix_sort_inplace($arr);
    is_deeply($arr, [-5, -3, -1, 0, 3, 7], 'mixed positive and negative');

    $arr = [1..1000];
    my @shuffled = sort { rand() <=> rand() } @$arr;
    $arr = [@shuffled];
    Sort::XS::radix_sort_inplace($arr);
    is_deeply($arr, [1..1000], '1000 shuffled elements');
};

# Edge cases for in-place
subtest 'inplace edge cases' => sub {
    my $arr = [42];
    Sort::XS::quick_sort_inplace($arr);
    is_deeply($arr, [42], 'single element');

    $arr = [];
    Sort::XS::quick_sort_inplace($arr);
    is_deeply($arr, [], 'empty array');

    $arr = [1, 2, 3];
    Sort::XS::quick_sort_inplace($arr);
    is_deeply($arr, [1, 2, 3], 'already sorted');
};

# xsort_inplace API
subtest 'xsort_inplace API' => sub {
    my $arr = [5, 3, 1, 4, 2];
    xsort_inplace($arr);
    is_deeply($arr, [1, 2, 3, 4, 5], 'default (quick)');

    $arr = [5, 3, 1, 4, 2];
    xsort_inplace($arr, algorithm => 'heap');
    is_deeply($arr, [1, 2, 3, 4, 5], 'heap via API');

    $arr = [5, 3, 1, 4, 2];
    xsort_inplace($arr, algorithm => 'merge');
    is_deeply($arr, [1, 2, 3, 4, 5], 'merge via API');

    $arr = [5, 3, 1, 4, 2];
    xsort_inplace($arr, algorithm => 'radix');
    is_deeply($arr, [1, 2, 3, 4, 5], 'radix via API');

    $arr = ['cherry', 'apple', 'banana'];
    xsort_inplace($arr, type => 'string');
    is_deeply($arr, ['apple', 'banana', 'cherry'], 'string via API');
};

# Verify in-place actually modifies original
subtest 'inplace modifies original' => sub {
    my @original = (5, 3, 1, 4, 2);
    my $ref = \@original;
    Sort::XS::quick_sort_inplace($ref);
    is_deeply(\@original, [1, 2, 3, 4, 5],
        'original array is modified, not a copy');
};

done_testing;
