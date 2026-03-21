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


/* Stack allocation threshold: arrays up to this size use alloca(),
   larger arrays use malloc(). 4096 elements keeps us well within
   typical stack limits while avoiding malloc overhead for small sorts. */
#define STACK_ALLOC_THRESHOLD 4096

SV* _jump_to_sort(const SortAlgo method, const SortType type, SV* array) {
	AV* av;
	AV* input;
	SV* reply;
	ElementType *elements;
	int needs_free = 0;

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

	/* Use stack for small arrays, heap for large ones */
	if (count <= STACK_ALLOC_THRESHOLD) {
		Newx(elements, count, ElementType);
	} else {
		elements = (ElementType *)malloc(count * sizeof(ElementType));
		if (!elements)
			croak("Sort::XS: out of memory allocating %d elements", count);
		needs_free = 1;
	}

	int i;
	for ( i = 0; i < count; ++i) {
		if ( type == SORT_INT ) {
			elements[i].i = SvIV(*av_fetch(input, i, 0));
		} else {
			elements[i].s = SvPV_nolen(*av_fetch(input, i, 0));
		}
	}

	/* map to the c method */
	sort_function_map[method]( elements, count, cmp_functionmap[type]);

	/* pre-extend the output AV to avoid incremental reallocation */
	av_extend(av, size);

	/* convert into perl types */
	for ( i = 0; i < count; ++i) {
		if ( type == SORT_INT ) {
			av_push(av, newSViv(elements[i].i));
		} else {
			av_push(av, newSVpv(elements[i].s, 0));
		}
	}

	if (needs_free)
		free(elements);
	else
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
