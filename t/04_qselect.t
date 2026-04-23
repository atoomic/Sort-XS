#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Sort::XS qw(qselect);

# --- XS-level tests ---

subtest 'quick_select integers' => sub {
    is(Sort::XS::quick_select([5, 3, 1, 4, 2], 1), 1, 'k=1 is minimum');
    is(Sort::XS::quick_select([5, 3, 1, 4, 2], 5), 5, 'k=N is maximum');
    is(Sort::XS::quick_select([5, 3, 1, 4, 2], 3), 3, 'k=3 is median');
    is(Sort::XS::quick_select([42], 1), 42, 'single element');
    is(Sort::XS::quick_select([7, 7, 7, 7], 2), 7, 'all duplicates');
    is(Sort::XS::quick_select([1, 1, 2, 2, 3], 4), 2, 'duplicates with k in dup range');
};

subtest 'quick_select_str' => sub {
    my @fruits = ('kiwi', 'banana', 'apple', 'cherry');
    is(Sort::XS::quick_select_str(\@fruits, 1), 'apple', 'k=1 is lexical min');
    is(Sort::XS::quick_select_str(\@fruits, 4), 'kiwi', 'k=N is lexical max');
    is(Sort::XS::quick_select_str(\@fruits, 2), 'banana', 'k=2');
    is(Sort::XS::quick_select_str(['z'], 1), 'z', 'single string element');
};

subtest 'quick_select boundary errors' => sub {
    eval { Sort::XS::quick_select([1, 2, 3], 0) };
    like($@, qr/out of range/, 'k=0 croaks');

    eval { Sort::XS::quick_select([1, 2, 3], 4) };
    like($@, qr/out of range/, 'k>N croaks');

    eval { Sort::XS::quick_select([1, 2, 3], -1) };
    like($@, qr/out of range/, 'k<0 croaks');

    eval { Sort::XS::quick_select(undef, 1) };
    like($@, qr/expecting a reference/, 'undef input croaks');

    eval { Sort::XS::quick_select("not a ref", 1) };
    like($@, qr/expecting a reference/, 'non-ref input croaks');

    eval { Sort::XS::quick_select([], 1) };
    like($@, qr/out of range/, 'empty array croaks');
};

# --- Perl API tests ---

subtest 'qselect API integers' => sub {
    is(qselect([5, 3, 1, 4, 2], k => 1), 1, 'qselect k=1');
    is(qselect([5, 3, 1, 4, 2], k => 3), 3, 'qselect k=3');
    is(qselect([10, 20, 5, 15], k => 4), 20, 'qselect k=N');
};

subtest 'qselect API strings' => sub {
    is(qselect(['kiwi', 'banana', 'apple'], k => 1, type => 'string'), 'apple', 'qselect string k=1');
    is(qselect(['kiwi', 'banana', 'apple'], k => 3, type => 'string'), 'kiwi', 'qselect string k=N');
};

subtest 'qselect API errors' => sub {
    eval { qselect("not an array", k => 1) };
    like($@, qr/Need to provide a list/, 'non-array croaks');

    eval { qselect([1, 2, 3]) };
    like($@, qr/k parameter is required/, 'missing k croaks');
};

# --- Correctness against full sort ---

subtest 'qselect matches sorted output' => sub {
    srand(42);
    for my $size (10, 50, 100, 500) {
        my @data = map { int(rand(10000)) - 5000 } 1 .. $size;
        my @sorted = sort { $a <=> $b } @data;
        for my $k (1, int($size / 4), int($size / 2), int(3 * $size / 4), $size) {
            is(Sort::XS::quick_select(\@data, $k), $sorted[$k - 1],
                "size=$size k=$k matches sorted[$k-1]");
        }
    }
};

subtest 'qselect_str matches sorted output' => sub {
    my @words = ('echo', 'alpha', 'delta', 'bravo', 'charlie', 'foxtrot',
                 'golf', 'hotel', 'india', 'juliet');
    my @sorted = sort @words;
    for my $k (1 .. scalar @words) {
        is(Sort::XS::quick_select_str(\@words, $k), $sorted[$k - 1],
            "string k=$k matches sorted[$k-1]");
    }
};

done_testing;
