#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Sort::XS ();

use Data::Dumper qw/Dumper/;

my @tests = (
    { type => 'integer', array => [ 8,  5,  1, 7 ] },
    { type => 'integer', array => [ 18, 11, 1, 151, 12 ] },
    { type => 'integer', array => [ 24 .. 42 ] },
    { type => 'integer', array => [ 42 .. 24 ] },
    { type => 'integer', array => [ 1 .. 100, 24 .. 42 ] },

    { type => 'str', array => [ 'kiwi', 'banana',    'apple', 'cherry' ] },
    { type => 'str', array => [ 'z' .. 'a' ] },
    { type => 'str', array => [ 'a' .. 'z' ] },
    { type => 'str', array => [ 'cc' .. 'aa', 'bb' .. 'ba' ] },

    { type => 'float', array => [ 3.14, 1.41, 2.72, 0.58 ] },
    { type => 'float', array => [ -1.5, 0.0, 2.3, -0.7, 1.1 ] },
    { type => 'float', array => [ 1.0, 1.0, 2.0, 0.5 ] },

);

foreach my $m (qw/insertion shell heap merge quick/) {

#next unless $m eq 'insertion' || $m eq 'shell' || $m eq 'heap' || $m eq 'merge';
    subtest "sort with $m" => sub {
        foreach my $set (@tests) {
            my @sorted;
            my $t = $set->{array};
            @sorted = sort { $a <=> $b } @$t if ( $set->{type} eq 'integer' );
            @sorted = sort { $a cmp $b } @$t if ( $set->{type} eq 'str' );
            @sorted = sort { $a <=> $b } @$t if ( $set->{type} eq 'float' );

            my $suffix = '';
            $suffix = '_str'   if $set->{type} eq 'str';
            $suffix = '_float' if $set->{type} eq 'float';

            my $result = eval "Sort::XS::${m}_sort${suffix}(\$t)";
            is_deeply( $result, \@sorted, "sort using $m on $set->{type}" )
              or do { warn "\n- method $m : \n", Dumper($result); die; };
        }
    };

}

is_deeply(
    Sort::XS::void_sort( [ 1, 5, 3 ] ),
    [ 1, 5, 3 ],
    'void sort is dummy and do nothing'
);

done_testing;
