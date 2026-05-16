#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Test::LeakTrace };
    if ($@) {
        plan skip_all => 'Test::LeakTrace required for leak tests';
    }
    Test::LeakTrace->import('no_leaks_ok');
}

use Sort::XS ();

# Test data
my @int_data  = (5, 3, 1, 4, 2, 8, 7, 6, 10, 9);
my @str_data  = qw(kiwi banana apple cherry date elderberry fig grape);

# ── Integer sort leak tests ─────────────────────────────────────────────

{
    no strict 'refs';
    for my $algo (qw(quick heap merge shell insertion)) {
        my $sort_func = \&{"Sort::XS::${algo}_sort"};
        no_leaks_ok { $sort_func->(\@int_data) } "${algo}_sort: no leak";
    }
}

# ── String sort leak tests ──────────────────────────────────────────────

{
    no strict 'refs';
    for my $algo (qw(quick heap merge shell insertion)) {
        my $sort_func = \&{"Sort::XS::${algo}_sort_str"};
        no_leaks_ok { $sort_func->(\@str_data) } "${algo}_sort_str: no leak";
    }
}

# ── API wrapper leak tests ──────────────────────────────────────────────

no_leaks_ok { Sort::XS::xsort(\@int_data) }
    'xsort(arrayref): no leak';

no_leaks_ok { Sort::XS::xsort(\@int_data, algorithm => 'heap') }
    'xsort(arrayref, algorithm): no leak';

no_leaks_ok { Sort::XS::xsort(list => \@int_data, algorithm => 'merge', type => 'integer') }
    'xsort(hash args): no leak';

no_leaks_ok { Sort::XS::sxsort(\@str_data) }
    'sxsort: no leak';

no_leaks_ok { Sort::XS::ixsort(\@int_data) }
    'ixsort: no leak';

# ── QuickSelect leak tests ─────────────────────────────────────────────

no_leaks_ok { Sort::XS::quick_select(\@int_data, 3) }
    'quick_select: no leak';

no_leaks_ok { Sort::XS::quick_select_str(\@str_data, 2) }
    'quick_select_str: no leak';

no_leaks_ok { Sort::XS::qselect(\@int_data, k => 5) }
    'qselect(int): no leak';

no_leaks_ok { Sort::XS::qselect(\@str_data, k => 3, type => 'string') }
    'qselect(str): no leak';

# ── Edge cases ──────────────────────────────────────────────────────────

no_leaks_ok { Sort::XS::quick_sort([]) }
    'empty array: no leak';

no_leaks_ok { Sort::XS::quick_sort([42]) }
    'single element: no leak';

no_leaks_ok { Sort::XS::quick_sort(undef) }
    'undef input: no leak';

no_leaks_ok { Sort::XS::quick_sort_str([]) }
    'empty string array: no leak';

# ── Error paths (croak) leak tests ──────────────────────────────────────
# When croak() is called, any SVs allocated before the longjmp must not leak.

no_leaks_ok {
    eval { Sort::XS::quick_select(\@int_data, 0) };    # k out of range
} 'quick_select croak (k=0): no leak';

no_leaks_ok {
    eval { Sort::XS::quick_select(\@int_data, 999) };  # k out of range
} 'quick_select croak (k=999): no leak';

no_leaks_ok {
    eval { Sort::XS::quick_select("not a ref", 1) };   # bad input
} 'quick_select croak (bad input): no leak';

no_leaks_ok {
    eval { Sort::XS::quick_select_str(\@str_data, 0) };
} 'quick_select_str croak (k=0): no leak';

done_testing;
