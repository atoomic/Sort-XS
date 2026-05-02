#include <stdlib.h>
#include <string.h>

#include "EXTERN.h"
#include "perl.h"

#include "sort.h"

/* basic comparison operators */
SORT_INLINE int compare_int(const ElementType *a, const ElementType *b) {
        return (a->i > b->i) - (a->i < b->i);
}

SORT_INLINE int compare_str(const ElementType *a, const ElementType *b) {
	return strcmp(a->s, b->s);
}

/*
  A > B
  cmp(A, B) > 0
*/

/* sorting methods */
SORT_INLINE void Swap(ElementType *Lhs, ElementType *Rhs) {
	ElementType Tmp = *Lhs;
	*Lhs = *Rhs;
	*Rhs = Tmp;
}

void InsertionSort(ElementType A[], int N, CmpFunction *cmp) {
	int j, P;
	ElementType Tmp;

	for (P = 1; P < N; P++) {
		Tmp = A[P];
		for (j = P; j > 0 && (*cmp)(&A[j - 1], &Tmp) > 0; j--)
			A[j] = A[j - 1];
		A[j] = Tmp;
	}
}

void ShellSort(ElementType A[], int N, CmpFunction *cmp) {
	int i, j, Increment, gi;
	ElementType Tmp;

	/* Ciura's gap sequence — empirically optimal for modern CPUs.
	   Extended beyond 701 by multiplying by 2.25 (Ciura's suggested ratio). */
	static const int ciura_gaps[] = {
		1, 4, 10, 23, 57, 132, 301, 701,
		1577, 3548, 7983, 17961, 40412, 90927, 204585, 460316
	};
	static const int n_gaps = sizeof(ciura_gaps) / sizeof(ciura_gaps[0]);

	/* Find starting gap */
	for (gi = n_gaps - 1; gi >= 0; gi--)
		if (ciura_gaps[gi] < N)
			break;

	for (; gi >= 0; gi--) {
		Increment = ciura_gaps[gi];
		for (i = Increment; i < N; i++) {
			Tmp = A[i];
			for (j = i; j >= Increment; j -= Increment)
				if ((*cmp)(&A[j - Increment], &Tmp) >= 0)
					A[j] = A[j - Increment];
				else
					break;
			A[j] = Tmp;
		}
	}
}

/* Heap — Floyd's bottom-up sift optimization.
   Standard sift-down does 2 comparisons per level (child vs child, then winner
   vs parent). Floyd's variant first sifts the hole all the way down (1 cmp/level),
   then bubbles back up. This cuts comparisons by ~50% for large heaps because
   most elements end up near the bottom anyway. */

#define LeftChild( i )  ( 2 * ( i ) + 1 )

void PercDown(ElementType A[], int i, int N, CmpFunction *cmp) {
	int Child;
	ElementType Tmp = A[i];
	int hole = i;

	/* Phase 1: sift the hole down to a leaf, always following the larger child.
	   Only 1 comparison per level (child vs child). */
	while ((Child = LeftChild(hole)) < N - 1) {
		if ((*cmp)(&A[Child + 1], &A[Child]) > 0)
			Child++;
		A[hole] = A[Child];
		hole = Child;
	}
	/* Handle odd-sized heap: if only a left child exists */
	if (Child == N - 1) {
		A[hole] = A[Child];
		hole = Child;
	}

	/* Phase 2: bubble the saved element back up from the leaf.
	   Usually only 0-2 levels since most elements belong near the bottom. */
	while (hole > i) {
		int parent = (hole - 1) / 2;
		if ((*cmp)(&Tmp, &A[parent]) > 0) {
			A[hole] = A[parent];
			hole = parent;
		} else
			break;
	}
	A[hole] = Tmp;
}

void VoidSort(ElementType A[], int N, CmpFunction *cmp) {
	if (N > 0) {
		ElementType i;
		i = A[0];
	}
}

void HeapSort(ElementType A[], int N, CmpFunction *cmp) {
	int i;

	if (N <= 1) return;

	for (i = N / 2; i >= 0; i--) /* BuildHeap */
		PercDown(A, i, N, cmp);
	for (i = N - 1; i > 0; i--) {
		Swap(&A[0], &A[i]); /* DeleteMax */
		PercDown(A, 0, i, cmp);
	}
}

/* Merge */

void Merge(ElementType A[], ElementType TmpArray[], int Lpos, int Rpos,
		int RightEnd, CmpFunction *cmp) {
	int LeftEnd, NumElements, TmpPos;
	int StartPos = Lpos;

	LeftEnd = Rpos - 1;
	TmpPos = Lpos;
	NumElements = RightEnd - Lpos + 1;

	/* main loop */
	while (Lpos <= LeftEnd && Rpos <= RightEnd)
		if ((*cmp)(&A[Rpos], &A[Lpos]) >= 0)
			TmpArray[TmpPos++] = A[Lpos++];
		else
			TmpArray[TmpPos++] = A[Rpos++];

	while (Lpos <= LeftEnd) /* Copy rest of first half */
		TmpArray[TmpPos++] = A[Lpos++];
	while (Rpos <= RightEnd) /* Copy rest of second half */
		TmpArray[TmpPos++] = A[Rpos++];

	/* Copy TmpArray back — memcpy is SIMD-accelerated on modern CPUs,
	   much faster than the per-element reverse-copy loop it replaces */
	memcpy(&A[StartPos], &TmpArray[StartPos], NumElements * sizeof(ElementType));
}

void MSort(ElementType A[], ElementType TmpArray[], int Left, int Right, CmpFunction *cmp) {
	int Center;

	if (Left < Right) {
		Center = Left + (Right - Left) / 2;
		MSort(A, TmpArray, Left, Center, cmp);
		MSort(A, TmpArray, Center + 1, Right, cmp);
		Merge(A, TmpArray, Left, Center + 1, Right, cmp);
	}
}

void MergeSort(ElementType A[], int N, CmpFunction *cmp) {
	ElementType *TmpArray;

	Newx(TmpArray, N, ElementType);
	MSort(A, TmpArray, 0, N - 1, cmp);
	Safefree(TmpArray);
}

/* Quick Sort */
/* Return median of Left, Center, and Right */
/* Order these and hide the pivot */

ElementType Median3(ElementType A[], int Left, int Right, CmpFunction *cmp) {
	int Center = Left + (Right - Left) / 2;

	if ((*cmp)(&A[Left], &A[Center]) > 0)
		Swap(&A[Left], &A[Center]);
	if ((*cmp)(&A[Left], &A[Right]) > 0)
		Swap(&A[Left], &A[Right]);
	if ((*cmp)(&A[Center], &A[Right]) > 0)
		Swap(&A[Center], &A[Right]);

	/* Invariant: A[ Left ] <= A[ Center ] <= A[ Right ] */

	Swap(&A[Center], &A[Right - 1]); /* Hide pivot */
	return A[Right - 1]; /* Return pivot */
}

/* Cutoff for switching to insertion sort.
   16 is well-tuned for modern CPUs: small enough to benefit from
   O(n^2) on tiny inputs, large enough to reduce recursion overhead
   and exploit cache-line-sized working sets. */
#define Cutoff ( 16 )

void Qsort(ElementType A[], int Left, int Right, CmpFunction *cmp) {
	int i, j;
	ElementType Pivot;

	/* Tail-call optimization: loop on the larger partition,
	   recurse on the smaller one. Guarantees O(log n) stack depth. */
	while (Left + Cutoff <= Right) {
		Pivot = Median3(A, Left, Right, cmp);
		i = Left;
		j = Right - 1;
		for (;;) {
			while ((*cmp)(&Pivot, &A[++i]) > 0) {}
			while ((*cmp)(&A[--j], &Pivot) > 0) {}
			if (i < j)
				Swap(&A[i], &A[j]);
			else
				break;
		}
		Swap(&A[i], &A[Right - 1]); /* Restore pivot */

		/* Recurse on smaller partition, loop on larger */
		if (i - Left < Right - i) {
			Qsort(A, Left, i - 1, cmp);
			Left = i + 1;
		} else {
			Qsort(A, i + 1, Right, cmp);
			Right = i - 1;
		}
	}

	/* Insertion sort on small remaining subarray */
	if (Left < Right)
		InsertionSort(A + Left, Right - Left + 1, cmp);
}

void QuickSort(ElementType A[], int N, CmpFunction *cmp) {
	Qsort(A, 0, N - 1, cmp);
}

/* Places the kth smallest element in the kth position */
/* Because arrays start at 0, this will be index k-1 */
void Qselect(ElementType A[], int k, int Left, int Right, CmpFunction *cmp) {
	int i, j;
	ElementType Pivot;

	if (Left + Cutoff <= Right) {
		Pivot = Median3(A, Left, Right, cmp);
		i = Left;
		j = Right - 1;
		for (;;) {
			while ((*cmp)(&Pivot, &A[++i]) > 0) {}
			while ((*cmp)(&A[--j], &Pivot) > 0) {}
			if (i < j)
				Swap(&A[i], &A[j]);
			else
				break;
		}
		Swap(&A[i], &A[Right - 1]); /* Restore pivot */

		if (k <= i)
			Qselect(A, k, Left, i - 1, cmp);
		else if (k > i + 1)
			Qselect(A, k, i + 1, Right, cmp);
	} else
		InsertionSort(A + Left, Right - Left + 1, cmp);
}

/* Partial Sort: places the k smallest elements in sorted order at A[0..k-1].
   Strategy: partition around position k via Qselect, then sort A[0..k-1].
   Complexity: O(n + k log k) — much faster than full O(n log n) sort when k << n. */
void PartialSort(ElementType A[], int N, int k, CmpFunction *cmp) {
	if (k <= 0 || N <= 0)
		return;
	if (k >= N) {
		/* k covers the whole array — just do a full sort */
		QuickSort(A, N, cmp);
		return;
	}

	/* Partition so that A[k-1] holds the kth smallest element,
	   and all elements in A[0..k-1] are <= A[k-1] (unordered) */
	Qselect(A, k, 0, N - 1, cmp);

	/* Now sort just the first k elements */
	QuickSort(A, k, cmp);
}

