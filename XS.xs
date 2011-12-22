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

typedef void (*sort_function_t)(ElementType A[ ], int N);

/* The enum and map are in the same order for easy lookup */
typedef enum { VOID, INSERTION, SHELL, HEAP, MERGE, QUICK } SortType;

sort_function_t sort_function_map[] = {
		VoidSort
		,InsertionSort	
		,ShellSort
		,HeapSort
		,MergeSort
		,QuickSort
};

/*
map_function_t functions_map[] = {
    add,
    multiply
};
*/
/* This function performs all cleanup of input and calls the correct C crypt function */
/*
SV* _jump_to(add_scheme_t scheme, SV *n1, SV *n2) {
    / * char *cryptpw_cstr = NULL; * /
    int n1_cint = 0;
    int n2_cint = 0;
    / * SV* RETVAL = &PL_sv_undef; * /
    int RETVAL = 0;
    / * parse inputs * /
    if (SvPOK(n1)) {
        n1_cint = SvIV(n1);
    }
    if (SvPOK(n2)) {
        n2_cint = SvIV(n2);
    }
    result_cint = functions_map[scheme]( pw_cstr, salt_cstr );
    if (cryptpw_cint != NULL) {
        RETVAL = newSViv(cryptpw_cstr,0);
    	RETVAL = result_cint;
    }
    return RETVAL;
}
*/

/*

	if (SvROK (sv)) {
		AV * av;
		int n;

		if (SvTYPE (SvRV (sv)) != SVt_PVAV)
			croak ("expecting a reference to an array of strings for Glib::Strv");
		av = (AV*) SvRV (sv);
		n = av_len (av) + 1;
		if (n > 0) {
			int i;
			strv = gperl_alloc_temp ((n + 1) * sizeof (gchar *));
			for (i = 0 ; i < n ; i++)
				strv[i] = SvGChar (*av_fetch (av, i, FALSE));
			strv[n] = NULL;
		}
		
	}
 
 
 */

SV* hash_from_string(SV *str) {
	SV* RETVAL;
	HV* rh;
	STRLEN len;
	char * ptr;
	
	/* check input value */
	if (!str || !SvOK (str))
		return NULL; 
	/* we should return an empty hash -> attempt to free unreferenced scalar */	
	rh = newHV();
	/* convert the SV into a char* */
	ptr = SvPV(str, len);
	
	/* store the parameter as a value */
	hv_store(rh, "the key was", 11, str, 0);
	/* use the parameter as a key */
	hv_store(rh, ptr, len, newSViv(1234), 0);
	
	RETVAL = newRV((SV *)rh);
	return RETVAL;
}

SV* hash_from_array(SV *array) {
	SV* RETVAL;
	HV* rh;
	AV* av;
	SV* str;
	STRLEN len;
	char * ptr;
	int n, i;
	
	/* check input value */
	if (!array || !SvOK (array) || !SvROK (array))
		return NULL; 
	/* we should return an empty hash -> attempt to free unreferenced scalar */	
	rh = newHV();
	/* convert sv into an array */
	av = (AV*) SvRV (array);
	/* check that we have an array of strings */
	if (SvTYPE (av) != SVt_PVAV)
		croak ("expecting a reference to an array of strings for Glib::Strv");
	n = av_len (av) + 1;
	for ( i = 0; i < n; ++i) {
		str = *av_fetch(av, i, FALSE);
		ptr = SvPV(str, len);
		hv_store(rh, ptr, len, newSViv(1), 0);
	}
	
	RETVAL = newRV((SV *)rh);
	return RETVAL;
}

/*
I32    hv_iterinit(HV*);
            * Prepares starting point to traverse hash table *
    HE*    hv_iternext(HV*);
            * Get the next entry, and return a pointer to a
               structure that has both the key and value *
    char*  hv_iterkey(HE* entry, I32* retlen);
            * Get the key from an HE structure and also return
               the length of the key string *
    SV*    hv_iterval(HV*, HE* entry);
            * Return an SV pointer to the value of the HE
               structure *
    SV*    hv_iternextsv(HV*, char** key, I32* retlen);
            * This convenience routine combines hv_iternext,
               hv_iterkey, and hv_iterval.  The key and retlen
               arguments are return values for the key and its
               length.  The value is returned in the SV* argument *
*/

/* SVTYPE possible values
    SVt_IV    Scalar
    SVt_NV    Scalar
    SVt_PV    Scalar
    SVt_RV    Scalar
    SVt_PVAV  Array
    SVt_PVHV  Hash
    SVt_PVCV  Code
    SVt_PVGV  Glob (possible a file handle)
    SVt_PVMG  Blessed or Magical Scalar  
 */

SV* array_from_hash(SV* hash) {
	AV* av;
	HV* hv;
	SV* reply;
	HE* iter;
	
	av = newAV();
	reply = newRV((SV *)av);
	
	/* not defined or not a reference */
	if (!hash || !SvOK(hash) || !SvROK(hash) )
		return reply;
	
	hv = (HV*) SvRV(hash);
	/* should reference a hash */
	if (SvTYPE (hv) != SVt_PVHV)
		croak ("expecting a reference to a hash");	
	
	/* iterate on a hash */
	hv_iterinit(hv);
	while ( iter = hv_iternext(hv) ) {
		char* key;
		I32  len;
		SV*   key_sv;
		key = hv_iterkey(iter, &len);
		/* convert char* to SV */
		key_sv = newSVpv(key, len);
		av_push(av, key_sv);   
		/* add a void element */
		char test[20] = "length is";
		av_push(av, newSVpv(test, 0));
		/* add length to array */
		av_push(av, newSViv(len));
	}
	

	return reply;
}

void compare_bucket(int numberstocheck[], int n)
{
  int i, j, k;
  int thebucket[n];
  for(i = 0; i < n; i++) {
    thebucket[i] = 0;
  }

  for(i = 0; i < n; i++) {
    thebucket[numberstocheck[i]]++;
  }
  for(i = 0, j = 0; i < n; i++) {
    for(k = thebucket[i]; k > 0; k--){
      numberstocheck[j++] = i;
    }
  }
}

SV* _jump_to_sort(SortType method, SV* array) {
	AV* av;
	AV* input;
	SV* reply;
	SV* elt;
		
	av = newAV();
	reply = newRV_noinc((SV *) av);
		
	/* not defined or not a reference */
	if (!array || !SvOK(array) || !SvROK(array) )
		return reply;
	
	input = (AV*) SvRV(array);
	/* should reference a hash */
	if (SvTYPE (input) != SVt_PVAV)
		croak ("expecting a reference to an array");	
		
	int size = av_len(input);
	int numbers[size+1];
	int i;
	for ( i = 0; i <= size; ++i) {
		numbers[i] = SvIV(*av_fetch(input, i, 0));
		/* fprintf(stderr, "number %02d is %d\n", i, numbers[i]); */	
	}
	
	/* map to the c method */
	sort_function_map[method]( numbers, size + 1);
	
	/* convert into perl types */
	for ( i = 0; i <= size; ++i) {
		av_push(av, newSViv(numbers[i]));
	}
	
	
	return reply;
}

/* 
 * read perlguts : http://search.cpan.org/~flora/perl-5.14.2/pod/perlguts.pod 
 * 
 * */


MODULE = Sort::XS PACKAGE = Sort::XS

PROTOTYPES: ENABLE

SV* fast_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(QUICK, array);
	OUTPUT:
		RETVAL

SV* insertion_sort(array)
		SV* array
		CODE:
			RETVAL = _jump_to_sort(INSERTION, array);
		OUTPUT:
			RETVAL

SV* shell_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(SHELL, array);
	OUTPUT:
		RETVAL

SV* heap_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(HEAP, array);
	OUTPUT:
		RETVAL

SV* merge_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(MERGE, array);
	OUTPUT:
		RETVAL

SV* quick_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(QUICK, array);
	OUTPUT:
		RETVAL


SV* void_sort(array)
	SV* array
	CODE:
		RETVAL = _jump_to_sort(VOID, array);
	OUTPUT:
		RETVAL
