#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <sys/types.h>

int main(int argc, char **argv)
{
    unsigned cpu, node;
    pid_t tid;
    tid = syscall(SYS_gettid);
    syscall(SYS_getcpu, &cpu, &node, NULL);
    printf("%s tid %u cpu %u node %u\n", argv[0], tid, cpu, node);
    return 0;
}
