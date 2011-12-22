package Sort::XS;
use strict;
use warnings;
use base Exporter::;
our @EXPORT = qw(xsort);

our $VERSION = '0.10';
require XSLoader;
XSLoader::load( 'Sort::XS', $VERSION );
use Carp qw/croak/;

use constant ERR_MSG_NOLIST           => 'Need to provide a list';
use constant ERR_MSG_UNKNOWN_ALGO     => 'Unknown algorithm : ';
use constant ERR_MSG_NUMBER_ARGUMENTS => 'Bad number of arguments';

my $_mapping = {
    'quick'     => \&Sort::XS::quick_sort,
    'heap'      => \&Sort::XS::heap_sort,
    'merge'     => \&Sort::XS::merge_sort,
    'insertion' => \&Sort::XS::insertion_sort,
    'perl'      => \&_perl_sort,
};

# API to call XS subs

sub xsort {
    # shortcut to speedup API usage, we first advantage preferred usage 
    # ( we could avoid it... but we want to provide an api as fast as possible )
    my $argc = scalar @_; 
    if ( $argc == 1) {
        croak ERR_MSG_NOLIST unless ref $_[0] eq ref [];
        return Sort::XS::quick_sort( $_[0] );
    }

    # default parameters
    my %params;
    $params{algorithm} = 'quick';

    # default list
    $params{list} = $_[0];

    croak ERR_MSG_NOLIST unless $params{list};
    my %args;
    unless ( ref $params{list} eq ref [] ) {
        # hash input 
        croak ERR_MSG_NUMBER_ARGUMENTS if $argc % 2;
        (%args) = @_;
        croak ERR_MSG_NOLIST
          unless defined $args{list} && ref $args{list} eq ref [];
        $params{list} = $args{list};
    }
    else {
        # first element was the array, then hash option
        croak ERR_MSG_NUMBER_ARGUMENTS unless scalar @_ % 2;
        my $void;
        ( $void, %args ) = @_;
    }
    map { $params{$_} = $args{$_} || $params{$_}; } qw/algorithm data/;

    my $sub = $_mapping->{ $params{algorithm} };
    croak( ERR_MSG_UNKNOWN_ALGO, $params{algorithm} ) unless defined $sub;

    return $sub->( $params{list} );
}

sub _perl_sort {
    my $list = shift;
    my @sorted = sort { $a <=> $b } @{$list};
    return \@sorted;
}

1;

__END__

=head1 NAME

Sort::XS - a ( very ) fast XS sort alternative for one dimension list

=head1 SYNOPSIS

  use Sort::XS qw/xsort/;

  # use it simply
  my $sorted = xsort([1, 5, 3]);
  $sorted = [ 1, 3, 5 ];
  
  # personalize your xsort with some options
  my $list = [ 1..1000, 200..1100 ]
  my $sorted = xsort( $list )
            or xsort( list => $list )
            or xsort( list => $list, algorithm => 'quick' )
            or xsort( $list, algorithm => 'quick', data => integer )
            or xsort( list => $list, algorithm => 'heap', data => 'integer' ) 
            or xsort( list => $list, algorithm => 'merge', data => 'string' );
   
   # if you [ mainly ] use very small arrays ( ~ 10 rows ) 
   #    prefer using directly one of the XS subroutines
   $sorted = Sort::XS::quick_sort( $list )
        or Sort::XS::heap_sort($list)
        or Sort::XS::merge_sort($list)
        or Sort::XS::insertion_sort($list);
    
=head1 DESCRIPTION

This module provides several common sort algorithms implemented as XS.
Sort can only be used on one dimension list of integers or strings.

It's goal is not to replace the internal sort subroutines, but to provide a better alternative in some specifics cases :

=over 2

=item - no need to specify a comparison operator

=item - sorting a mono dimension list

=back


=head1 ALGORITHMS

I've chosen to use quicksort as the default method ( even if it s not a stable algorithm ), you can also consider to use heapsort which provides a worst case in "n log n".

Chosing the correct algorithm depends on distribution of your values and size of your list.
Quicksort provides an average good solution, even if in some case it will be better to use a different choice.

=head2 quick sort

This is the default algorithm. 
In pratice it provides the best results even if in worst case heap sort will be a better choice.

read http://en.wikipedia.org/wiki/Quicksort for more informations

=head2 heap sort

A little slower in practice than quicksort but provide a better worst case runtime.

read http://en.wikipedia.org/wiki/Heapsort for more informations

=head2 merge sort

Stable sort algorithm, that means that in any case the time to compute the result will be similar.
It's still a better choice than the internal perl sort.

read http://en.wikipedia.org/wiki/Mergesort for more informations

=head2 insertion sort

Provide one implementation of insertion sort, but prefer using either any of the previous algorithm or even the perl internal sort.

read http://en.wikipedia.org/wiki/Mergesort for more informations

=head2 perl

this is not an algorithm by itself, but provides an easy way to disable all XS code by switching back to a regular sort.

Perl 5.6 and earlier used a quicksort algorithm to implement sort. 
That algorithm was not stable, so could go quadratic. (A stable sort preserves the input order of elements that compare equal. 
Although quicksort's run time is O(NlogN) when averaged over all arrays of length N, the time can be O(N**2), 
quadratic behavior, for some inputs.) 

In 5.7, the quicksort implementation was replaced with a stable mergesort algorithm whose worst-case behavior is O(NlogN). 
But benchmarks indicated that for some inputs, on some platforms, the original quicksort was faster. 

5.8 has a sort pragma for limited control of the sort. Its rather blunt control of the underlying algorithm may not persist into future Perls, 
but the ability to characterize the input or output in implementation independent ways quite probably will.

use default perl version

=head1 METHODS

=head2 xsort

API that allow you to use one of the XS subroutines. Prefer using this method. ( view optimization section for tricks )

=over 4

=item list

provide a reference to an array
if only one argument is provided can be ommit

    my $list = [ 1, 3, 2, 5, 4 ];
    xsort( $list ) or xsort( list => $list )

=item algorithm [ optional, default = quick ]

default value is quick
you can use any of the following choices

    quick # quicksort
    heap  # heapsort
    merge
    insertion # not recommended ( slow )
    perl # use standard perl sort method instead of c implementation

=item data [ optional, default = integer ]

You can specify which kind of sort you are expecting ( i.e. '<=>' or 'cmp' ) by setting this attribute to one of these two values

    integer # <=>, is the default operator if not specified
    string  # cmp, do the compare on string

=back

=head2  quick_sort   

XS subroutine to perform the quicksort algorithm. No type checking performed.
Accept only one single argument as input.

    my $list = [1, 6, 4, 2, 3, 5 ]
    Sort::XS::quick_sort($list);
    
=head2  heap_sort

XS subroutine to perform the heapsort algorithm. No type checking performed.
Accept only one single argument as input.    

    my $list = [1, 6, 4, 2, 3, 5 ]
    Sort::XS::heap_sort($list);
    
=head2  merge_sort

XS subroutine to perform the mergesort algorithm. No type checking performed.
Accept only one single argument as input.    
    
    my $list = [1, 6, 4, 2, 3, 5 ]
    Sort::XS::merge_sort($list)
    
=head2  insertion_sort    

XS subroutine to perform the insertionsort algorithm. No type checking performed.
Accept only one single argument as input.    

    my $list = [1, 6, 4, 2, 3, 5 ]
    Sort::XS::insertion_sort($list);

=head1 OPTIMIZATION

xsort provides an api to call xs subroutines to easy change sort preferences and an easy way to use it ( adding data checking )
as it provides an extra layer on the top of xs subroutines it has a cost... and adds a little more slowness...
This extra cost cannot be noticed on large arrays ( > 100 rows ), but for very small arrays ( ~ 10 rows ) it will not a good idea to use the api ( at least at this stage ). 
In this case you will prefer to do a direct call to one of the XS methods to have pure performance.

Note that all the XS subroutines are not exported by default. 

    my $list = [1, 6, 4, 2, 3, 5 ]
    Sort::XS::quick_sort($list);
    Sort::XS::heap_sort($list);
    Sort::XS::merge_sort($list)
    Sort::XS::insertion_sort($list);

Once again, if you use large arrays, it will be better to use :

    xsort([100..1]);

=head1 BENCHMARK

Here is a glance of what you can expect using this module :

These results have been computed on a set of multiple random arrays generated by the benmark test included in the dist testsuite.

# sorting an ( integer ) array of 10 rows
- quicksort is 12 % faster than a regular perl sort

# sorting an ( integer ) array of 100 rows
- quicksort is 46 % faster than a regular perl sort

# sorting an ( integer ) array of 1_000 rows
- quicksort is 82 % faster than a regular perl sort

# sorting an ( integer ) array of 10_000 rows
- quicksort is 2 x times faster than a regular perl sort ( 112 % )

# sorting an ( integer ) array of 100_000 rows
- quicksort is 2.5 x times faster than a regular perl sort

# sorting an ( integer ) array of 1_000_000 rows
- quicksort is 3.4 x times faster than a regular perl sort

=head1 TODO

Implementation of float, string comparison...
At this time only implement sort of integers

Improve API performance for small set of arrays

=head1 AUTHOR

Nicolas R., E<lt>me@eboxr.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by eboxr.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
