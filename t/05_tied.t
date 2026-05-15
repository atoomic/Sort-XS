#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Sort::XS ();

# Tied arrays are unsafe with Sort::XS because AvARRAY() bypasses
# Perl's magic layer.  av_len() respects tied FETCHSIZE but AvARRAY()
# returns the raw (possibly empty) internal buffer — size/buffer
# mismatch causes a buffer overread or segfault.
#
# The module must croak with a clear message instead of crashing.

# Minimal tied array class (Tie::StdArray is core)
{
    package TiedTestArray;
    use Tie::Array;
    our @ISA = ('Tie::StdArray');
}

my @tied;
tie @tied, 'TiedTestArray';
@tied = (5, 3, 1, 4, 2);

# ── Sort functions reject tied arrays ───────────────────────────────

for my $algo (qw(quick heap merge insertion shell)) {
    my $sort_fn = "Sort::XS::${algo}_sort";
    no strict 'refs';
    eval { $sort_fn->(\@tied) };
    like($@, qr/tied/, "$sort_fn rejects tied array");

    my $sort_str_fn = "Sort::XS::${algo}_sort_str";
    eval { $sort_str_fn->(\@tied) };
    like($@, qr/tied/, "$sort_str_fn rejects tied array");
}

# ── qselect rejects tied arrays ─────────────────────────────────────

eval { Sort::XS::quick_select(\@tied, 1) };
like($@, qr/tied/, "quick_select rejects tied array");

eval { Sort::XS::quick_select_str(\@tied, 1) };
like($@, qr/tied/, "quick_select_str rejects tied array");

# ── Perl API wrappers also reject tied arrays ───────────────────────

eval { Sort::XS::xsort(\@tied) };
like($@, qr/tied/, "xsort rejects tied array");

eval { Sort::XS::sxsort(\@tied) };
like($@, qr/tied/, "sxsort rejects tied array");

# ── Non-tied arrays still work fine ─────────────────────────────────

my $plain = [5, 3, 1, 4, 2];
is_deeply(Sort::XS::quick_sort($plain), [1, 2, 3, 4, 5],
    "plain array still sorts correctly");

done_testing;
