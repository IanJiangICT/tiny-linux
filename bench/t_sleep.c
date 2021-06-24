#include <sys/types.h>
#include <sys/sysinfo.h>
#include <unistd.h>
#define __USE_GNU
#include <sched.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syscall.h>
#include <sys/time.h>
#include <sys/times.h>

void usage(void)
{
	printf("Usage:\n");
	printf("  t_sleep time-in-ms cpu-id\n");
	printf("Example:\n");
	printf("  t_sleep 10 2\n");
	return;
}

int main(int argc, char **argv)
{
	unsigned long cnt = 0;
	int ms_cnt = 0;
	int cpu_id = 0;
	cpu_set_t mask;
	unsigned cpu, node;
	int i;
	int ret;
	struct timeval tv0, tv1;
	struct timezone tz;
	struct tms tms0, tms1;

	if (argc != 3) {
		usage();
		return 0;
	}

	ms_cnt = atoi(argv[1]);
	cpu_id = atoi(argv[2]);

	if (ms_cnt < 0 || ms_cnt > 8000) {
		ms_cnt = 200;
	}
	if (cpu_id < 0 || cpu_id > 32) {
		cpu_id = 0;
	}


	printf("Test sleep for %d ms at CPU %d\n", ms_cnt, cpu_id);

	CPU_ZERO(&mask);
	CPU_SET(cpu_id, &mask);
	ret = sched_setaffinity(0, sizeof(mask), &mask);
	if (ret == -1) {
		printf("Error: Failed to set affinity. ret = %d\n", ret);
		return 0;
	}

	syscall(SYS_getcpu, &cpu, &node, NULL);
	printf("T cpu %u cnt %lu\n", cpu, cnt);
	cnt++;
	for (i = 0; i < 0x1000; i++) {;}
	gettimeofday(&tv0, &tz);
	times(&tms0);
	if (ms_cnt > 0)
		usleep(ms_cnt * 1000);
	gettimeofday(&tv1, &tz);
	times(&tms1);
	printf("timeval %ld %ld -> %ld %ld\n", tv0.tv_sec, tv0.tv_usec, tv1.tv_sec, tv1.tv_usec);
	printf("tims %s -> %s\n", asctime(gmtime(&tms0)), asctime(gmtime(&tms1)));

	return 0;
}
