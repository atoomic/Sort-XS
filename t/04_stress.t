#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Sort::XS ();

# Stress tests for adversarial and degenerate inputs.
# These patterns expose worst-case behavior in sorting algorithms:
# - pre-sorted: QuickSort with naive pivot hits O(n^2)
# - reverse-sorted: same issue, opposite direction
# - all-equal: partitioning degenerates if not handled
# - many duplicates: Dutch national flag problem
# - negative numbers: sign-related comparison bugs

my @algorithms = qw(insertion shell heap merge quick);

sub check_sort {
    my ($algo, $label, $input) = @_;
    my $expected = [ sort { $a <=> $b } @$input ];
    my $sorter = do { no strict 'refs'; \&{"Sort::XS::${algo}_sort"} };
    is_deeply($sorter->($input), $expected, "$algo: $label")
        or diag "first 10 of input: @{$input}[0..9]";
}

sub check_sort_str {
    my ($algo, $label, $input) = @_;
    my $expected = [ sort { $a cmp $b } @$input ];
    my $sorter = do { no strict 'refs'; \&{"Sort::XS::${algo}_sort_str"} };
    is_deeply($sorter->($input), $expected, "$algo: $label (str)")
        or diag "first 10 of input: @{$input}[0..9]";
}

for my $algo (@algorithms) {
    subtest "$algo stress tests" => sub {

        # Pre-sorted (already ascending)
        check_sort($algo, "pre-sorted 1000", [1..1000]);

        # Reverse-sorted
        check_sort($algo, "reverse-sorted 1000", [reverse 1..1000]);

        # All-equal elements
        check_sort($algo, "all-equal 500", [(7) x 500]);

        # Many duplicates (small range, large array)
        my @dupes = map { int(rand(10)) } 1..1000;
        check_sort($algo, "many duplicates 1000", \@dupes);

        # Negative numbers
        check_sort($algo, "negative only", [map { -$_ } 1..200]);

        # Mixed positive and negative
        check_sort($algo, "mixed sign 500", [map { int(rand(2000)) - 1000 } 1..500]);

        # Pipe organ (ascending then descending)
        check_sort($algo, "pipe organ", [1..250, reverse 1..250]);

        # Sawtooth pattern
        my @saw = map { ($_ % 50) } 1..500;
        check_sort($algo, "sawtooth 500", \@saw);

        # Already sorted with one swap
        my @nearly = (1..500);
        @nearly[10, 490] = @nearly[490, 10];
        check_sort($algo, "nearly sorted 500", \@nearly);

        # Large random array
        my @large = map { int(rand(1_000_000)) } 1..5000;
        check_sort($algo, "random 5000", \@large);
    };
}

subtest "string stress tests" => sub {
    for my $algo (@algorithms) {

        # Pre-sorted strings
        check_sort_str($algo, "pre-sorted strings", ['a'..'z']);

        # Reverse-sorted strings
        check_sort_str($algo, "reverse strings", [reverse 'a'..'z']);

        # All-equal strings
        check_sort_str($algo, "all-equal strings", [("foo") x 100]);

        # Many duplicate strings
        my @words = qw(apple banana cherry date elderberry);
        my @str_dupes = map { $words[int(rand(@words))] } 1..500;
        check_sort_str($algo, "many duplicate strings", \@str_dupes);

        # Long strings
        my @long = map { "prefix_" . int(rand(10000)) . "_suffix" } 1..200;
        check_sort_str($algo, "long strings", \@long);
    }
};

done_testing;
