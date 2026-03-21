#ifndef _SORT_H
#define _SORT_H

/* Portable inline hint for internal hot functions */
#if defined(__GNUC__) || defined(__clang__)
#define SORT_INLINE inline __attribute__((always_inline))
#define SORT_HOT __attribute__((hot))
#define SORT_LIKELY(x)   __builtin_expect(!!(x), 1)
#define SORT_UNLIKELY(x) __builtin_expect(!!(x), 0)
#define SORT_PREFETCH(addr) __builtin_prefetch(addr, 0, 0)
#elif defined(_MSC_VER)
#define SORT_INLINE __forceinline
#define SORT_HOT
#define SORT_LIKELY(x)   (x)
#define SORT_UNLIKELY(x) (x)
#define SORT_PREFETCH(addr) ((void)0)
#else
#define SORT_INLINE inline
#define SORT_HOT
#define SORT_LIKELY(x)   (x)
#define SORT_UNLIKELY(x) (x)
#define SORT_PREFETCH(addr) ((void)0)
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
void RadixSort(ElementType A[], int N);

/* used to benchmark memory usage */
void VoidSort(ElementType A[], int N, CmpFunction *cmp);

#endif
