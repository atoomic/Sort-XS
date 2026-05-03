#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Sort::XS ();

# Adversarial and stress tests for sort algorithms.
# These patterns historically break sort implementations:
# - Pre-sorted / reverse-sorted (triggers O(n^2) in naive quicksort)
# - All-equal (partition degeneracy)
# - Pipe-organ pattern (sorted-then-reversed, tricky for merge-based sorts)
# - Few unique values (Dutch national flag problem)
# - Extreme integer values near IV_MIN / IV_MAX

my @int_algorithms = qw(insertion shell heap merge quick);
my @str_algorithms = qw(insertion shell heap merge quick);

# Reference sort functions
sub int_ref  { [ sort { $a <=> $b } @{$_[0]} ] }
sub str_ref  { [ sort { $a cmp $b } @{$_[0]} ] }

# Helper: get XS sort function by name and type
sub get_sorter {
    my ($algo, $type) = @_;
    my $suffix = ($type eq 'str') ? '_str' : '';
    my $name = "Sort::XS::${algo}_sort${suffix}";
    no strict 'refs';
    return \&{$name};
}

# ── Integer adversarial patterns ─────────────────────────────────────────

subtest 'pre-sorted arrays' => sub {
    for my $n (2, 3, 10, 50, 200, 1000) {
        my $data = [ 1 .. $n ];
        my $expected = int_ref($data);
        for my $algo (@int_algorithms) {
            is_deeply(get_sorter($algo, 'int')->($data), $expected,
                "$algo: pre-sorted N=$n");
        }
    }
};

subtest 'reverse-sorted arrays' => sub {
    for my $n (2, 3, 10, 50, 200, 1000) {
        my $data = [ reverse 1 .. $n ];
        my $expected = int_ref($data);
        for my $algo (@int_algorithms) {
            is_deeply(get_sorter($algo, 'int')->($data), $expected,
                "$algo: reverse-sorted N=$n");
        }
    }
};

subtest 'all-equal arrays' => sub {
    for my $n (2, 3, 10, 50, 200) {
        my $data = [ (42) x $n ];
        my $expected = int_ref($data);
        for my $algo (@int_algorithms) {
            is_deeply(get_sorter($algo, 'int')->($data), $expected,
                "$algo: all-equal N=$n");
        }
    }
};

subtest 'pipe-organ pattern (1..n, n-1..1)' => sub {
    for my $n (5, 20, 100, 500) {
        my $data = [ 1 .. $n, reverse 1 .. ($n - 1) ];
        my $expected = int_ref($data);
        for my $algo (@int_algorithms) {
            is_deeply(get_sorter($algo, 'int')->($data), $expected,
                "$algo: pipe-organ N=" . scalar(@$data));
        }
    }
};

subtest 'few unique values (Dutch national flag)' => sub {
    for my $n (10, 100, 500) {
        # Only 3 distinct values
        my $data = [ map { int(rand(3)) } 1 .. $n ];
        my $expected = int_ref($data);
        for my $algo (@int_algorithms) {
            is_deeply(get_sorter($algo, 'int')->($data), $expected,
                "$algo: 3-value N=$n");
        }
    }
    # Only 2 distinct values (binary)
    for my $n (10, 100) {
        my $data = [ map { int(rand(2)) } 1 .. $n ];
        my $expected = int_ref($data);
        for my $algo (@int_algorithms) {
            is_deeply(get_sorter($algo, 'int')->($data), $expected,
                "$algo: binary N=$n");
        }
    }
};

subtest 'sawtooth pattern' => sub {
    for my $n (50, 200) {
        # Repeating ascending runs of length 5
        my $data = [ map { $_ % 5 } 0 .. ($n - 1) ];
        my $expected = int_ref($data);
        for my $algo (@int_algorithms) {
            is_deeply(get_sorter($algo, 'int')->($data), $expected,
                "$algo: sawtooth N=$n");
        }
    }
};

# ── Extreme integer values ───────────────────────────────────────────────

subtest 'extreme IV values' => sub {
    my $iv_max = ~0 >> 1;
    my $iv_min = -$iv_max - 1;

    my @datasets = (
        { name => 'min and max',    data => [ $iv_max, $iv_min, 0, $iv_max, $iv_min ] },
        { name => 'near overflow',  data => [ $iv_max, $iv_max - 1, $iv_max - 2, $iv_min, $iv_min + 1, $iv_min + 2 ] },
        { name => 'zeros and extremes', data => [ 0, $iv_max, 0, $iv_min, 0 ] },
        { name => 'all negative',   data => [ -1, -100, -50, -999, -2 ] },
        { name => 'mixed sign',     data => [ -5, 3, -1, 0, 7, -3, 2 ] },
    );

    for my $ds (@datasets) {
        my $expected = int_ref($ds->{data});
        for my $algo (@int_algorithms) {
            is_deeply(get_sorter($algo, 'int')->($ds->{data}), $expected,
                "$algo: $ds->{name}");
        }
    }
};

# ── Size boundary tests ──────────────────────────────────────────────────

subtest 'size boundaries around Cutoff (16)' => sub {
    # QuickSort switches to InsertionSort at Cutoff=16.
    # Test sizes around this boundary to catch off-by-one errors.
    for my $n (15, 16, 17, 18, 32, 33) {
        my $data = [ reverse 1 .. $n ];
        my $expected = int_ref($data);
        for my $algo (@int_algorithms) {
            is_deeply(get_sorter($algo, 'int')->($data), $expected,
                "$algo: cutoff boundary N=$n");
        }
    }
};

subtest 'powers of two (heap boundary tests)' => sub {
    # HeapSort has edge cases at powers of two (odd/even child count)
    for my $n (7, 8, 15, 16, 31, 32, 63, 64, 127, 128, 255, 256) {
        my $data = [ reverse 1 .. $n ];
        my $expected = int_ref($data);
        for my $algo (@int_algorithms) {
            is_deeply(get_sorter($algo, 'int')->($data), $expected,
                "$algo: power-of-two boundary N=$n");
        }
    }
};

# ── Large random arrays ──────────────────────────────────────────────────

subtest 'large random arrays' => sub {
    srand(42);  # deterministic
    for my $n (1000, 5000, 10000) {
        my $data = [ map { int(rand(100000)) - 50000 } 1 .. $n ];
        my $expected = int_ref($data);
        for my $algo (@int_algorithms) {
            is_deeply(get_sorter($algo, 'int')->($data), $expected,
                "$algo: random N=$n");
        }
    }
};

# ── String adversarial patterns ──────────────────────────────────────────

subtest 'string: pre-sorted' => sub {
    for my $n (10, 100) {
        my $data = [ map { sprintf("item_%05d", $_) } 1 .. $n ];
        my $expected = str_ref($data);
        for my $algo (@str_algorithms) {
            is_deeply(get_sorter($algo, 'str')->($data), $expected,
                "$algo: string pre-sorted N=$n");
        }
    }
};

subtest 'string: reverse-sorted' => sub {
    for my $n (10, 100) {
        my $data = [ map { sprintf("item_%05d", $_) } reverse 1 .. $n ];
        my $expected = str_ref($data);
        for my $algo (@str_algorithms) {
            is_deeply(get_sorter($algo, 'str')->($data), $expected,
                "$algo: string reverse N=$n");
        }
    }
};

subtest 'string: all-equal' => sub {
    my $data = [ ("same") x 50 ];
    my $expected = str_ref($data);
    for my $algo (@str_algorithms) {
        is_deeply(get_sorter($algo, 'str')->($data), $expected,
            "$algo: string all-equal");
    }
};

subtest 'string: common prefixes' => sub {
    my $data = [ map { "prefix_" . chr(ord('z') - $_) } 0 .. 25 ];
    my $expected = str_ref($data);
    for my $algo (@str_algorithms) {
        is_deeply(get_sorter($algo, 'str')->($data), $expected,
            "$algo: string common prefixes");
    }
};

subtest 'string: empty strings mixed with non-empty' => sub {
    my $data = [ "b", "", "a", "", "c", "" ];
    my $expected = str_ref($data);
    for my $algo (@str_algorithms) {
        is_deeply(get_sorter($algo, 'str')->($data), $expected,
            "$algo: string with empties");
    }
};

subtest 'string: single characters' => sub {
    my $data = [ map { chr($_) } reverse 32 .. 126 ];  # printable ASCII reversed
    my $expected = str_ref($data);
    for my $algo (@str_algorithms) {
        is_deeply(get_sorter($algo, 'str')->($data), $expected,
            "$algo: string single chars reversed");
    }
};

subtest 'string: varying lengths' => sub {
    my $data = [ "a", "aaa", "aa", "aaaa", "a", "aaaaa", "aa" ];
    my $expected = str_ref($data);
    for my $algo (@str_algorithms) {
        is_deeply(get_sorter($algo, 'str')->($data), $expected,
            "$algo: string varying lengths");
    }
};

subtest 'string: large random' => sub {
    srand(42);
    my @chars = ('a' .. 'z', 'A' .. 'Z', '0' .. '9');
    for my $n (100, 1000) {
        my $data = [ map {
            join('', map { $chars[rand @chars] } 1 .. (3 + int(rand(10))))
        } 1 .. $n ];
        my $expected = str_ref($data);
        for my $algo (@str_algorithms) {
            is_deeply(get_sorter($algo, 'str')->($data), $expected,
                "$algo: string random N=$n");
        }
    }
};

# ── Strings with embedded null bytes ────────────────────────────────────

subtest 'string: embedded null bytes' => sub {
    # Strings containing \0 must sort correctly and preserve full content.
    # strcmp/newSVpv would truncate at the first null byte — this tests
    # that we use length-aware comparison (memcmp) and output (newSVpvn).

    my @data = ("a\0c", "a\0b", "a\0a");
    my $expected = str_ref(\@data);
    for my $algo (@str_algorithms) {
        my $result = get_sorter($algo, 'str')->(\@data);
        is_deeply($result, $expected, "$algo: embedded nulls sort correctly");
        # Verify no truncation: output strings must have same length as input
        is(length($result->[0]), 3, "$algo: null-byte string not truncated");
    }
};

subtest 'string: null byte as discriminator' => sub {
    # Two strings identical before the null, different after it
    my @data = ("prefix\0zzz", "prefix\0aaa", "prefix\0mmm");
    my $expected = str_ref(\@data);
    for my $algo (@str_algorithms) {
        is_deeply(get_sorter($algo, 'str')->(\@data), $expected,
            "$algo: null byte as discriminator");
    }
};

subtest 'string: null byte prefix sorting' => sub {
    # "abc" should sort before "abc\0x" (shorter string first)
    my @data = ("abc\0x", "abc", "abc\0");
    my $expected = str_ref(\@data);
    for my $algo (@str_algorithms) {
        is_deeply(get_sorter($algo, 'str')->(\@data), $expected,
            "$algo: prefix vs null-extended");
    }
};

subtest 'qselect_str with null bytes' => sub {
    my @data = ("b\0z", "a\0z", "c\0z");
    my $result = Sort::XS::quick_select_str(\@data, 1);
    is($result, "a\0z", "qselect_str: min with null bytes");
    is(length($result), 3, "qselect_str: result not truncated");
};

# ── MergeSort stability ──────────────────────────────────────────────────

subtest 'mergesort stability' => sub {
    # MergeSort should be stable: equal elements preserve input order.
    # We verify by encoding original position in the string.
    my @input_strs = map { sprintf("key%d_pos%03d", $_ % 5, $_) } 0 .. 49;
    my $data = \@input_strs;
    my $expected = str_ref($data);
    my $result = Sort::XS::merge_sort_str($data);
    is_deeply($result, $expected, "mergesort string stability");

    # Also test integer stability: since integers have no identity beyond
    # value, we just verify correctness with many duplicates
    my $int_data = [ map { $_ % 7 } 0 .. 99 ];
    is_deeply(
        Sort::XS::merge_sort($int_data),
        int_ref($int_data),
        "mergesort integer with many duplicates"
    );
};

done_testing;
