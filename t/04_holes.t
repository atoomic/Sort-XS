#!/usr/bin/env perl

use strict;
use warnings;
use Sort::XS ();

use Test::More tests => 8;


my @data;
rand > .3 and $data[$_] = int rand 100 for 0..20;

my @copy = @data;

no warnings;
my @sorted_data_int = sort { int($a) <=> int($b) } @copy;
my @sorted_data_str = sort { $a cmp $b } @copy;

use warnings;
for my $algorithm (qw(insertion shell heap merge)) {
    my $sorter = do { no strict 'refs'; \&{"Sort::XS::${algorithm}_sort"} };
    is_deeply($sorter->(\@data),
              \@sorted_data_int,
              "sorting integers using $algorithm algorithm");

    $sorter = do { no strict 'refs'; \&{"Sort::XS::${algorithm}_sort_str"} };
    is_deeply($sorter->(\@data),
              \@sorted_data_str,
              "sorting strings using $algorithm algorithm");
}

