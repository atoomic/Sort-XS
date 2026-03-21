#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Sort::XS ();

my @chars = map chr $_, 0x20..0x30, 0xc0..0xdf;

for my $size (10, 100, 1000, 10000, 10000) {
    my @data = map join('', map $chars[rand @chars], 1..5), 0..$size;

    rand > .5 and utf8::upgrade($_) for @data;
    my @copy = @data;
    my @sorted_data = sort @copy;

    for my $algorithm (qw(insertion shell heap merge)) {
        my $sorter = do { no strict 'refs'; \&{"Sort::XS::${algorithm}_sort_str"} };
        is_deeply($sorter->(\@data),
                  \@sorted_data,
                  "sorting strings using $algorithm algorithm");
    }
}

done_testing;
