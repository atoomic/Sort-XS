#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Sort::XS qw(xsort ixsort sxsort);

# --- Integer descending sort ---

my @algorithms = qw(quick heap merge insertion shell perl);

for my $algo (@algorithms) {
    my $list = [5, 3, 8, 1, 9, 2, 7, 4, 6];
    my $expected = [9, 8, 7, 6, 5, 4, 3, 2, 1];

    my $sorted = xsort($list, algorithm => $algo, order => 'desc');
    is_deeply($sorted, $expected, "integer descending sort with $algo");
}

# --- String descending sort ---

for my $algo (@algorithms) {
    my $list = ['cherry', 'apple', 'banana', 'date', 'elderberry'];
    my $expected = ['elderberry', 'date', 'cherry', 'banana', 'apple'];

    my $sorted = xsort($list, algorithm => $algo, type => 'string', order => 'desc');
    is_deeply($sorted, $expected, "string descending sort with $algo");
}

# --- Default algorithm (quick) descending ---

{
    my $list = [10, 20, 30, 40, 50];
    my $sorted = xsort($list, order => 'desc');
    is_deeply($sorted, [50, 40, 30, 20, 10], "default algorithm descending");
}

# --- sxsort with descending ---

{
    my $list = ['zebra', 'ant', 'monkey'];
    my $sorted = sxsort($list, order => 'desc');
    is_deeply($sorted, ['zebra', 'monkey', 'ant'], "sxsort with descending");
}

# --- Edge cases ---

{
    my $sorted = xsort([42], order => 'desc');
    is_deeply($sorted, [42], "single element descending");
}

{
    my $sorted = xsort([], order => 'desc');
    is_deeply($sorted, [], "empty array descending");
}

{
    my $list = [5, 5, 3, 3, 1, 1];
    my $sorted = xsort($list, order => 'desc');
    is_deeply($sorted, [5, 5, 3, 3, 1, 1], "duplicates descending");
}

{
    my $list = [5, 4, 3, 2, 1];
    my $sorted = xsort($list, order => 'desc');
    is_deeply($sorted, [5, 4, 3, 2, 1], "already descending");
}

{
    my $list = [1, 2, 3, 4, 5];
    my $sorted = xsort($list, order => 'desc');
    is_deeply($sorted, [5, 4, 3, 2, 1], "ascending to descending");
}

# --- Negative numbers ---

{
    my $list = [-3, 5, -1, 0, 2, -7];
    my $sorted = xsort($list, order => 'desc');
    is_deeply($sorted, [5, 2, 0, -1, -3, -7], "negative numbers descending");
}

# --- Ascending (default) still works ---

{
    my $list = [5, 3, 1, 4, 2];
    my $sorted_asc = xsort($list);
    is_deeply($sorted_asc, [1, 2, 3, 4, 5], "ascending still works without order param");

    my $sorted_asc2 = xsort($list, order => 'asc');
    is_deeply($sorted_asc2, [1, 2, 3, 4, 5], "explicit order => 'asc' works");
}

# --- Large array descending ---

{
    my @data = map { int(rand(10000)) } 1..1000;
    my @expected = sort { $b <=> $a } @data;
    my $sorted = xsort(\@data, order => 'desc');
    is_deeply($sorted, \@expected, "large array (1000 elements) descending");
}

{
    my @data = map { chr(65 + rand(26)) x int(1 + rand(5)) } 1..500;
    my @expected = sort { $b cmp $a } @data;
    my $sorted = xsort(\@data, type => 'string', order => 'desc');
    is_deeply($sorted, \@expected, "large string array (500 elements) descending");
}

done_testing;
