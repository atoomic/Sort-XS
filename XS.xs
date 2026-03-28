/*-
 * Copyright (c) 2011 cPanel, Inc.
 * All rights reserved.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself, either Perl version 5.10.1 or,
 * at your option, any later version of Perl 5 you may have available.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "sort.h"
#include <string.h>

typedef void (*sort_function_t)(ElementType A[ ], int N, CmpFunction *cmp);

/* The enum and map are in the same order for easy lookup */
/* Prefixed to avoid conflicts with Windows macros (VOID, INT) from winnt.h */
typedef enum { SORT_VOID, SORT_INSERTION, SORT_SHELL, SORT_HEAP, SORT_MERGE, SORT_QUICK } SortAlgo;
typedef enum { SORT_INT, SORT_STR } SortType;

sort_function_t sort_function_map[] = {
		VoidSort
		,InsertionSort	
		,ShellSort
		,HeapSort
		,MergeSort
		,QuickSort
};
/* typedef int (CmpFunction)(const ElementType *a, const ElementType *b); */

CmpFunction *cmp_functionmap[] = {
		compare_int,
		compare_str
};


SV* _jump_to_sort(const SortAlgo method, const SortType type, SV* array) {
	AV* av;
	AV* input;
	SV* reply;
	SV** svp;
	ElementType *elements;

	av = newAV();
	reply = newRV_noinc((SV *) av);

	/* not defined or not a reference */
	if (!array || !SvOK(array) || !SvROK(array) )
		return reply;

	input = (AV*) SvRV(array);
	/* should reference an array */
	if (SvTYPE (input) != SVt_PVAV)
		croak ("expecting a reference to an array");

	int size = av_len(input);
	int count = size + 1;

	/* empty array — nothing to sort */
	if (count <= 0)
		return reply;

	Newx(elements, count, ElementType);

	/* Direct access to AV's internal SV** array — avoids per-element
	   bounds checking and magic handling from av_fetch() */
	svp = AvARRAY(input);

	int i;
	/* Hoisted type check: separate loops eliminate per-element branch */
	if ( type == SORT_INT ) {
		for ( i = 0; i < count; ++i)
			elements[i].i = SvIV(svp[i]);
	} else {
		for ( i = 0; i < count; ++i)
			elements[i].s = SvPV_nolen(svp[i]);
	}

	/* map to the c method */
	sort_function_map[method]( elements, count, cmp_functionmap[type]);

	/* pre-extend the output AV to avoid incremental reallocation */
	av_extend(av, size);

	/* convert into perl types — hoisted type check */
	if ( type == SORT_INT ) {
		for ( i = 0; i < count; ++i)
			av_push(av, newSViv(elements[i].i));
	} else {
		for ( i = 0; i < count; ++i)
			av_push(av, newSVpv(elements[i].s, 0));
	}

	Safefree(elements);

	return reply;
}

/* 
 * read perlguts : http://search.cpan.org/~flora/perl-5.14.2/pod/perlguts.pod 
 * 
 * */


MODULE = Sort::XS PACKAGE = Sort::XS

PROTOTYPES: ENABLE

SV* insertion_sort(array)
		SV* array
		CODE:
			RETVAL = _jump_to_sort(SORT_INSERTION, SORT_INT, array);
		OUTPUT:
			RETVAL

SV* insertion_sort_str(array)
		SV* array
		CODE:
			RETVAL = _jump_to_sort(SORT_INSERTION, SORT_STR, array);
		OUTPUT:
			RETVAL
			
SV* shell_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(SORT_SHELL, SORT_INT, array);
	OUTPUT:
		RETVAL

SV* shell_sort_str(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(SORT_SHELL, SORT_STR, array);
	OUTPUT:
		RETVAL

SV* heap_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(SORT_HEAP, SORT_INT, array);
	OUTPUT:
		RETVAL

SV* heap_sort_str(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(SORT_HEAP, SORT_STR, array);
	OUTPUT:
		RETVAL

SV* merge_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(SORT_MERGE, SORT_INT, array);
	OUTPUT:
		RETVAL

SV* merge_sort_str(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(SORT_MERGE, SORT_STR, array);
	OUTPUT:
		RETVAL

SV* quick_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(SORT_QUICK, SORT_INT, array);
	OUTPUT:
		RETVAL

SV* quick_sort_str(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(SORT_QUICK, SORT_STR, array);
	OUTPUT:
		RETVAL

SV* void_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(SORT_VOID, SORT_INT, array);
	OUTPUT:
		RETVAL
