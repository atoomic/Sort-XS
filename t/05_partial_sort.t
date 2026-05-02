use strict;
use warnings;
use Test::More;
use Sort::XS qw(partial_sort);

# Basic integer partial sort
{
    my $list = [5, 3, 8, 1, 9, 2, 7, 4, 6];
    my $top3 = partial_sort($list, k => 3);
    is_deeply($top3, [1, 2, 3], 'top 3 from unsorted integers');
}

# k = 1 (minimum)
{
    my $list = [42, 7, 99, 1, 55];
    my $min = partial_sort($list, k => 1);
    is_deeply($min, [1], 'k=1 returns minimum');
}

# k = N (full sort)
{
    my $list = [5, 3, 1, 4, 2];
    my $all = partial_sort($list, k => 5);
    is_deeply($all, [1, 2, 3, 4, 5], 'k=N returns fully sorted array');
}

# String partial sort
{
    my $list = ['kiwi', 'banana', 'apple', 'cherry', 'date'];
    my $top2 = partial_sort($list, k => 2, type => 'string');
    is_deeply($top2, ['apple', 'banana'], 'top 2 strings');
}

# Large array — verify correctness
{
    my @data = map { int(rand(10000)) } 1..1000;
    my $top10 = partial_sort(\@data, k => 10);
    my @sorted = sort { $a <=> $b } @data;
    is_deeply($top10, [@sorted[0..9]], 'top 10 from 1000 random integers');
}

# Duplicates
{
    my $list = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5];
    my $top5 = partial_sort($list, k => 5);
    is_deeply($top5, [1, 1, 2, 3, 3], 'handles duplicates correctly');
}

# Already sorted
{
    my $list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    my $top4 = partial_sort($list, k => 4);
    is_deeply($top4, [1, 2, 3, 4], 'already sorted input');
}

# Reverse sorted
{
    my $list = [reverse 1..20];
    my $top5 = partial_sort($list, k => 5);
    is_deeply($top5, [1, 2, 3, 4, 5], 'reverse sorted input');
}

# Error cases
{
    eval { partial_sort([1, 2, 3], k => 0) };
    like($@, qr/out of range/, 'k=0 croaks');

    eval { partial_sort([1, 2, 3], k => 4) };
    like($@, qr/out of range/, 'k > N croaks');

    eval { partial_sort('not_an_array', k => 1) };
    like($@, qr/Need to provide a list/, 'non-arrayref croaks');

    eval { partial_sort([1, 2], ) };
    like($@, qr/k parameter is required/, 'missing k croaks');
}

# Direct XS function calls
{
    my $list = [10, 4, 7, 1, 3, 9, 2, 8, 5, 6];
    my $result = Sort::XS::_partial_sort($list, 4);
    is_deeply($result, [1, 2, 3, 4], 'direct XS _partial_sort');

    my $str_list = ['zebra', 'apple', 'mango', 'banana', 'cherry'];
    my $str_result = Sort::XS::_partial_sort_str($str_list, 3);
    is_deeply($str_result, ['apple', 'banana', 'cherry'], 'direct XS _partial_sort_str');
}

done_testing();
