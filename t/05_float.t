#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Sort::XS qw(xsort fxsort qselect);

# Reference sort for floats
sub float_ref { [ sort { $a <=> $b } @{$_[0]} ] }

# ── Direct XS function calls ────────────────────────────────────────────

my @algorithms = qw(insertion shell heap merge quick);

subtest 'basic float sorting via XS functions' => sub {
    my $data = [ 3.14, 1.41, 2.72, 0.58, 1.73 ];
    my $expected = float_ref($data);

    for my $algo (@algorithms) {
        my $func = "Sort::XS::${algo}_sort_float";
        no strict 'refs';
        is_deeply($func->($data), $expected, "$algo: basic floats");
    }
};

subtest 'negative floats' => sub {
    my $data = [ -1.5, 3.2, -0.1, 0.0, -99.9, 42.0 ];
    my $expected = float_ref($data);

    for my $algo (@algorithms) {
        my $func = "Sort::XS::${algo}_sort_float";
        no strict 'refs';
        is_deeply($func->($data), $expected, "$algo: negative floats");
    }
};

subtest 'very small differences' => sub {
    my $data = [ 1.0000001, 1.0000003, 1.0000002, 1.0000000 ];
    my $expected = float_ref($data);

    for my $algo (@algorithms) {
        my $func = "Sort::XS::${algo}_sort_float";
        no strict 'refs';
        is_deeply($func->($data), $expected, "$algo: small differences");
    }
};

subtest 'all equal floats' => sub {
    my $data = [ (2.5) x 20 ];
    my $expected = float_ref($data);

    for my $algo (@algorithms) {
        my $func = "Sort::XS::${algo}_sort_float";
        no strict 'refs';
        is_deeply($func->($data), $expected, "$algo: all equal");
    }
};

subtest 'single element' => sub {
    my $data = [ 42.5 ];
    for my $algo (@algorithms) {
        my $func = "Sort::XS::${algo}_sort_float";
        no strict 'refs';
        is_deeply($func->($data), [ 42.5 ], "$algo: single element");
    }
};

subtest 'empty array' => sub {
    my $data = [];
    for my $algo (@algorithms) {
        my $func = "Sort::XS::${algo}_sort_float";
        no strict 'refs';
        is_deeply($func->($data), [], "$algo: empty array");
    }
};

subtest 'pre-sorted floats' => sub {
    my $data = [ 0.1, 0.2, 0.3, 0.4, 0.5 ];
    my $expected = float_ref($data);
    for my $algo (@algorithms) {
        my $func = "Sort::XS::${algo}_sort_float";
        no strict 'refs';
        is_deeply($func->($data), $expected, "$algo: pre-sorted");
    }
};

subtest 'reverse-sorted floats' => sub {
    my $data = [ 5.0, 4.0, 3.0, 2.0, 1.0 ];
    my $expected = float_ref($data);
    for my $algo (@algorithms) {
        my $func = "Sort::XS::${algo}_sort_float";
        no strict 'refs';
        is_deeply($func->($data), $expected, "$algo: reverse-sorted");
    }
};

subtest 'large random float array' => sub {
    srand(42);
    my $data = [ map { rand(1000) - 500 } 1 .. 1000 ];
    my $expected = float_ref($data);
    for my $algo (@algorithms) {
        my $func = "Sort::XS::${algo}_sort_float";
        no strict 'refs';
        is_deeply($func->($data), $expected, "$algo: large random N=1000");
    }
};

# ── API calls ────────────────────────────────────────────────────────────

subtest 'fxsort convenience function' => sub {
    my $data = [ 3.14, 1.41, 2.72 ];
    my $expected = float_ref($data);

    is_deeply(fxsort($data), $expected, "fxsort with array ref");
    is_deeply(fxsort(list => $data), $expected, "fxsort with hash args");

    for my $algo (@algorithms, 'perl') {
        is_deeply(fxsort($data, algorithm => $algo), $expected,
            "fxsort algorithm=$algo");
    }
};

subtest 'xsort with type => float' => sub {
    my $data = [ 9.9, 1.1, 5.5 ];
    my $expected = float_ref($data);

    is_deeply(xsort($data, type => 'float'), $expected,
        "xsort type=float");
    is_deeply(xsort(list => $data, type => 'float'), $expected,
        "xsort list+type=float");
    is_deeply(xsort(list => $data, algorithm => 'merge', type => 'float'),
        $expected, "xsort merge+float");
};

subtest 'fxsort type not overwritten by caller' => sub {
    my $data = [ 3.14, 1.41, 2.72 ];
    my $expected = float_ref($data);

    # Passing type => 'integer' should be overridden by fxsort
    is_deeply(fxsort(list => $data, type => 'integer'), $expected,
        "fxsort type not overwritten");
};

# ── qselect with float ──────────────────────────────────────────────────

subtest 'qselect float' => sub {
    my $data = [ 5.5, 3.3, 1.1, 4.4, 2.2 ];

    is(qselect($data, k => 1, type => 'float'), 1.1, "qselect float k=1 (min)");
    is(qselect($data, k => 3, type => 'float'), 3.3, "qselect float k=3 (median)");
    is(qselect($data, k => 5, type => 'float'), 5.5, "qselect float k=5 (max)");

    # Direct XS call
    is(Sort::XS::quick_select_float($data, 2), 2.2,
        "quick_select_float direct call");
};

subtest 'qselect float edge cases' => sub {
    is(qselect([42.5], k => 1, type => 'float'), 42.5,
        "qselect float single element");

    eval { qselect([1.0, 2.0], k => 0, type => 'float') };
    like($@, qr/out of range/, "qselect float k=0 croaks");

    eval { qselect([1.0, 2.0], k => 3, type => 'float') };
    like($@, qr/out of range/, "qselect float k>N croaks");
};

done_testing;
