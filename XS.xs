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
typedef enum { VOID, INSERTION, SHELL, HEAP, MERGE, QUICK } SortAlgo;
typedef enum { INT, STR } SortType;

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
	SV** svp;
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

	/* Direct access to AV's internal SV** array — avoids per-element
	   bounds checking and magic handling from av_fetch() */
	svp = AvARRAY(input);

	int i;
	/* Hoisted type check: separate loops eliminate per-element branch */
	if ( type == INT ) {
		for ( i = 0; i < count; ++i) {
			SORT_PREFETCH(&svp[i + 8]);
			elements[i].i = SvIV(svp[i]);
		}
	} else {
		for ( i = 0; i < count; ++i) {
			SORT_PREFETCH(&svp[i + 8]);
			elements[i].s = SvPV_nolen(svp[i]);
		}
	}

	/* map to the c method */
	sort_function_map[method]( elements, count, cmp_functionmap[type]);

	/* pre-extend the output AV to avoid incremental reallocation */
	av_extend(av, size);

	/* convert into perl types — hoisted type check */
	if ( type == INT ) {
		for ( i = 0; i < count; ++i)
			av_push(av, newSViv(elements[i].i));
	} else {
		for ( i = 0; i < count; ++i)
			av_push(av, newSVpv(elements[i].s, 0));
	}

	if (needs_free)
		free(elements);
	else
		Safefree(elements);

	return reply;
}

/* In-place sort: modifies the original AV instead of creating a new one.
   Eliminates the output allocation and SV creation overhead — the biggest
   bottleneck for large arrays.

   For integers: extract values, sort, write back with sv_setiv().
   For strings: we sort an index array and then permute the SV* pointers
   directly in the AV. This avoids the use-after-free that would occur
   if we wrote sorted string pointers back with sv_setpv() (overwriting
   an SV's buffer invalidates other elements pointing to it). */

/* Index-based element for string in-place sort */
typedef struct {
	char *s;
	int   orig_idx;
} IndexedStr;

static int compare_indexed_str(const void *a, const void *b) {
	return strcmp(((const IndexedStr *)a)->s, ((const IndexedStr *)b)->s);
}

void _sort_inplace(const SortAlgo method, const SortType type, SV* array) {
	AV* input;
	SV** svp;
	int i;

	if (!array || !SvOK(array) || !SvROK(array))
		croak("expecting a reference to an array");

	input = (AV*) SvRV(array);
	if (SvTYPE(input) != SVt_PVAV)
		croak("expecting a reference to an array");

	int size = av_len(input);
	int count = size + 1;
	if (count <= 1) return;

	svp = AvARRAY(input);

	if (type == INT) {
		/* Integer path: extract, sort, write back */
		ElementType *elements;
		int needs_free = 0;

		if (count <= STACK_ALLOC_THRESHOLD) {
			Newx(elements, count, ElementType);
		} else {
			elements = (ElementType *)malloc(count * sizeof(ElementType));
			if (!elements)
				croak("Sort::XS: out of memory allocating %d elements", count);
			needs_free = 1;
		}

		for (i = 0; i < count; ++i) {
			SORT_PREFETCH(&svp[i + 8]);
			elements[i].i = SvIV(svp[i]);
		}

		sort_function_map[method](elements, count, cmp_functionmap[type]);

		for (i = 0; i < count; ++i)
			sv_setiv(svp[i], elements[i].i);

		if (needs_free)
			free(elements);
		else
			Safefree(elements);
	} else {
		/* String path: sort indices, then permute SV pointers in-place.
		   This is safe because we never modify any SV's string buffer —
		   we just rearrange which SV sits at which position in the AV. */
		IndexedStr *indexed;
		SV **sv_copy;

		Newx(indexed, count, IndexedStr);
		Newx(sv_copy, count, SV*);

		for (i = 0; i < count; ++i) {
			SORT_PREFETCH(&svp[i + 8]);
			indexed[i].s = SvPV_nolen(svp[i]);
			indexed[i].orig_idx = i;
		}

		/* Use qsort on the indexed array — we can't easily use the
		   Sort-XS sort functions here since IndexedStr != ElementType */
		qsort(indexed, count, sizeof(IndexedStr), compare_indexed_str);

		/* Build sorted SV* array */
		for (i = 0; i < count; ++i)
			sv_copy[i] = svp[indexed[i].orig_idx];

		/* Copy sorted pointers back into the AV */
		memcpy(svp, sv_copy, count * sizeof(SV*));

		Safefree(indexed);
		Safefree(sv_copy);
	}
}

/* Radix sort wrapper for XS — uses O(n) radix sort for integers,
   bypassing the comparison-based sort entirely. */

SV* _radix_sort(SV* array) {
	AV* av;
	AV* input;
	SV* reply;
	SV** svp;
	ElementType *elements;
	int needs_free = 0;

	av = newAV();
	reply = newRV_noinc((SV *) av);

	if (!array || !SvOK(array) || !SvROK(array))
		return reply;

	input = (AV*) SvRV(array);
	if (SvTYPE(input) != SVt_PVAV)
		croak("expecting a reference to an array");

	int size = av_len(input);
	int count = size + 1;

	if (count <= STACK_ALLOC_THRESHOLD) {
		Newx(elements, count, ElementType);
	} else {
		elements = (ElementType *)malloc(count * sizeof(ElementType));
		if (!elements)
			croak("Sort::XS: out of memory allocating %d elements", count);
		needs_free = 1;
	}

	svp = AvARRAY(input);

	int i;
	for (i = 0; i < count; ++i) {
		SORT_PREFETCH(&svp[i + 8]);
		elements[i].i = SvIV(svp[i]);
	}

	RadixSort(elements, count);

	av_extend(av, size);
	for (i = 0; i < count; ++i)
		av_push(av, newSViv(elements[i].i));

	if (needs_free)
		free(elements);
	else
		Safefree(elements);

	return reply;
}

/* In-place radix sort */

void _radix_sort_inplace(SV* array) {
	AV* input;
	SV** svp;
	ElementType *elements;
	int needs_free = 0;

	if (!array || !SvOK(array) || !SvROK(array))
		croak("expecting a reference to an array");

	input = (AV*) SvRV(array);
	if (SvTYPE(input) != SVt_PVAV)
		croak("expecting a reference to an array");

	int size = av_len(input);
	int count = size + 1;
	if (count <= 1) return;

	if (count <= STACK_ALLOC_THRESHOLD) {
		Newx(elements, count, ElementType);
	} else {
		elements = (ElementType *)malloc(count * sizeof(ElementType));
		if (!elements)
			croak("Sort::XS: out of memory allocating %d elements", count);
		needs_free = 1;
	}

	svp = AvARRAY(input);

	int i;
	for (i = 0; i < count; ++i) {
		SORT_PREFETCH(&svp[i + 8]);
		elements[i].i = SvIV(svp[i]);
	}

	RadixSort(elements, count);

	for (i = 0; i < count; ++i)
		sv_setiv(svp[i], elements[i].i);

	if (needs_free)
		free(elements);
	else
		Safefree(elements);
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
			RETVAL = _jump_to_sort(INSERTION, INT, array);
		OUTPUT:
			RETVAL

SV* insertion_sort_str(array)
		SV* array
		CODE:
			RETVAL = _jump_to_sort(INSERTION, STR, array);
		OUTPUT:
			RETVAL

SV* shell_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(SHELL, INT, array);
	OUTPUT:
		RETVAL

SV* shell_sort_str(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(SHELL, STR, array);
	OUTPUT:
		RETVAL

SV* heap_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(HEAP, INT, array);
	OUTPUT:
		RETVAL

SV* heap_sort_str(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(HEAP, STR, array);
	OUTPUT:
		RETVAL

SV* merge_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(MERGE, INT, array);
	OUTPUT:
		RETVAL

SV* merge_sort_str(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(MERGE, STR, array);
	OUTPUT:
		RETVAL

SV* quick_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(QUICK, INT, array);
	OUTPUT:
		RETVAL

SV* quick_sort_str(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(QUICK, STR, array);
	OUTPUT:
		RETVAL

SV* void_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(VOID, INT, array);
	OUTPUT:
		RETVAL

SV* radix_sort(array)
	SV* array
	CODE:
		RETVAL = _radix_sort(array);
	OUTPUT:
		RETVAL

void quick_sort_inplace(array)
	SV* array
	CODE:
		_sort_inplace(QUICK, INT, array);

void quick_sort_str_inplace(array)
	SV* array
	CODE:
		_sort_inplace(QUICK, STR, array);

void heap_sort_inplace(array)
	SV* array
	CODE:
		_sort_inplace(HEAP, INT, array);

void heap_sort_str_inplace(array)
	SV* array
	CODE:
		_sort_inplace(HEAP, STR, array);

void merge_sort_inplace(array)
	SV* array
	CODE:
		_sort_inplace(MERGE, INT, array);

void merge_sort_str_inplace(array)
	SV* array
	CODE:
		_sort_inplace(MERGE, STR, array);

void radix_sort_inplace(array)
	SV* array
	CODE:
		_radix_sort_inplace(array);
