#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Sort::XS;

# The XS layer accepts blessed arrayrefs (checks SVt_PVAV), but the Perl
# API wrapper used 'ref $x eq ref []' which rejects blessed refs.
# These tests verify all API paths work with blessed arrayrefs.

my @int_data = (5, 3, 1, 4, 2);
my @str_data = ('kiwi', 'banana', 'apple', 'cherry');

my $int_expected = [ sort { $a <=> $b } @int_data ];
my $str_expected = [ sort { $a cmp $b } @str_data ];

# -- xsort fast path (single argument) --

subtest 'xsort fast path with blessed arrayref' => sub {
    my $obj = bless [@int_data], 'My::Array';
    is_deeply(xsort($obj), $int_expected, 'xsort($blessed) works');
};

# -- xsort with algorithm option --

subtest 'xsort with options and blessed arrayref' => sub {
    my $obj = bless [@int_data], 'My::Array';
    for my $algo (qw/quick heap merge insertion shell/) {
        is_deeply(
            xsort($obj, algorithm => $algo),
            $int_expected,
            "xsort(\$blessed, algorithm => '$algo')"
        );
    }
};

# -- xsort hash-style: list => $blessed --

subtest 'xsort hash-style with blessed arrayref' => sub {
    my $obj = bless [@int_data], 'My::Array';
    is_deeply(
        xsort(list => $obj),
        $int_expected,
        'xsort(list => $blessed)'
    );
    is_deeply(
        xsort(list => $obj, algorithm => 'merge'),
        $int_expected,
        'xsort(list => $blessed, algorithm => merge)'
    );
};

# -- ixsort --

subtest 'ixsort with blessed arrayref' => sub {
    my $obj = bless [@int_data], 'My::Array';
    is_deeply(ixsort($obj), $int_expected, 'ixsort($blessed)');
};

# -- sxsort --

subtest 'sxsort with blessed arrayref' => sub {
    my $obj = bless [@str_data], 'My::Array';
    is_deeply(sxsort($obj), $str_expected, 'sxsort($blessed)');
    is_deeply(
        sxsort($obj, algorithm => 'heap'),
        $str_expected,
        'sxsort($blessed, algorithm => heap)'
    );
};

# -- qselect --

subtest 'qselect with blessed arrayref' => sub {
    my $obj = bless [@int_data], 'My::Array';
    is(qselect($obj, k => 1), 1, 'qselect($blessed, k=>1) returns min');
    is(qselect($obj, k => 3), 3, 'qselect($blessed, k=>3) returns median');
    is(qselect($obj, k => 5), 5, 'qselect($blessed, k=>5) returns max');

    my $sobj = bless [@str_data], 'My::Array';
    is(qselect($sobj, k => 1, type => 'string'), 'apple',
        'qselect($blessed, string) works');
};

# -- Direct XS functions still work (regression check) --

subtest 'direct XS functions with blessed arrayref' => sub {
    my $obj = bless [@int_data], 'My::Array';
    is_deeply(Sort::XS::quick_sort($obj), $int_expected,
        'quick_sort($blessed)');
    is_deeply(Sort::XS::heap_sort($obj), $int_expected,
        'heap_sort($blessed)');

    my $sobj = bless [@str_data], 'My::Array';
    is_deeply(Sort::XS::quick_sort_str($sobj), $str_expected,
        'quick_sort_str($blessed)');
};

# -- Error cases still work --

subtest 'error cases unchanged' => sub {
    eval { xsort({}) };
    like($@, qr/Need to provide a list/, 'hashref still rejected');

    eval { xsort('not a ref') };
    like($@, qr/\w+/, 'string still rejected');

    eval { xsort(undef) };
    like($@, qr/\w+/, 'undef still rejected');

    eval { xsort(bless {}, 'My::Hash') };
    like($@, qr/\w+/, 'blessed hashref rejected');
};

done_testing;
