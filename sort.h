#ifndef _SORT_H
#define _SORT_H

typedef int ElementType;

void Swap( ElementType *Lhs, ElementType *Rhs );
void InsertionSort( ElementType A[ ], int N );
void ShellSort(ElementType A[], int N);
void HeapSort(ElementType A[], int N);
void MergeSort(ElementType A[], int N);
void QuickSort(ElementType A[], int N);

/* used to benchmark memory usage */
void VoidSort(ElementType A[], int N);

#endif
