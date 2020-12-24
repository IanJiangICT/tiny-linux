/*
 * Example of pthread
 *
 * Reference: https://github.com/grossiwm/pthreadHelloWorld/blob/master/main.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <sys/types.h>

#define THREAD_CNT_DEFAULT 4

void generateThreadsIndexArray(int *array, int size);
void *print_thread(void *void_pointer);


int main()
{
    printf(""
        " +-+-+-+-+-+-+-+ +-+-+-+-+-+ +-+-+-+-+-+\n"
        " |p|t|h|r|e|a|d| |H|e|l|l|o| |W|o|r|l|d|\n"
        " +-+-+-+-+-+-+-+ +-+-+-+-+-+ +-+-+-+-+-+"
    "");

    int n = THREAD_CNT_DEFAULT;

    printf("\nYou chose to create% d threads.\n", n);

    pthread_t array_of_threads[n];
    // int id[n]

    int threadsIndexesArray[n];
    generateThreadsIndexArray(threadsIndexesArray, n);

    int i = 0;
    while (i < n) {
        pthread_create(&array_of_threads[i], NULL, print_thread, (void *) &threadsIndexesArray[i]);
        i++;
    }

    i = 0;
    while (i < n) {
        pthread_join(array_of_threads[i], NULL);
        i++;
    }
    return 0;
}

void *print_thread(void *void_pointer) {
    //int_ptr receberá o valor o ponteiro para o valor de i

    pid_t tid;
    tid = syscall(SYS_gettid);

    int *int_ptr = (int *) void_pointer;
    printf("I am Thread %02d and my ID is pthread_self:%u or with gettid:%u.\n", *int_ptr, (uint) pthread_self(), tid);

    return NULL;
}

void generateThreadsIndexArray(int *array, int size) {
    for (int i = 0; i < size; i++) {
      array[i] = i + 1;
    }
}
