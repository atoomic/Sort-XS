#!/usr/bin/env perl

# Test that sorting large arrays does not crash (stack overflow).
# Before the fix, _jump_to_sort() used a variable-length array (VLA)
# on the stack: ElementType elements[size+1]. For large inputs this
# exceeded the default stack size and caused a segfault / stack smash.

use strict;
use warnings;
use Test::More;
use Sort::XS ();

# 100_000 elements is well beyond the typical 8 MB stack limit
# (ElementType is a union of double/IV/char* — at least 8 bytes each,
# so 100k elements ≈ 800 KB minimum, but recursion overhead makes it worse).
my $large_size = 100_000;

subtest 'large integer array' => sub {
    my @data = map { int(rand(1_000_000)) } 1 .. $large_size;
    my @expected = sort { $a <=> $b } @data;

    my $result = Sort::XS::quick_sort(\@data);
    is(scalar @$result, $large_size, "result has correct size");
    is_deeply($result, \@expected, "large integer sort is correct");
};

subtest 'large string array' => sub {
    my @data = map { sprintf("str%08d", int(rand(1_000_000))) } 1 .. $large_size;
    my @expected = sort { $a cmp $b } @data;

    my $result = Sort::XS::quick_sort_str(\@data);
    is(scalar @$result, $large_size, "result has correct size");
    is_deeply($result, \@expected, "large string sort is correct");
};

done_testing;
