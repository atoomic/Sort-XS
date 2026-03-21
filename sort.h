#ifndef _SORT_H
#define _SORT_H

/* Portable inline hint for internal hot functions */
#if defined(__GNUC__) || defined(__clang__)
#define SORT_INLINE inline __attribute__((always_inline))
#elif defined(_MSC_VER)
#define SORT_INLINE __forceinline
#else
#define SORT_INLINE inline
#endif

/* typedef used */
typedef union {
	double f;
        IV     i;
	char  *s;
} ElementType;

typedef int (CmpFunction)(const ElementType *a, const ElementType *b);

/* prototype of functions */

int compare_int(const ElementType *a, const ElementType *b);
int compare_str(const ElementType *a, const ElementType *b);

void InsertionSort(ElementType A[], int N, CmpFunction *cmp);
void ShellSort(ElementType A[], int N, CmpFunction *cmp);
void HeapSort(ElementType A[], int N, CmpFunction *cmp);
void MergeSort(ElementType A[], int N, CmpFunction *cmp);
void QuickSort(ElementType A[], int N, CmpFunction *cmp);

/* used to benchmark memory usage */
void VoidSort(ElementType A[], int N, CmpFunction *cmp);

#endif
