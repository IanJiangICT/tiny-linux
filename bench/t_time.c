#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <sys/time.h>

int main(int argc, char **argv)
{
	long long int value;
	long long int i;
	long long int loop_cnt;
	clock_t clk0;
	clock_t clk1;
	clock_t clk2;
	clock_t clk3;
	clock_t clk4;
	struct timeval tv0;
	struct timeval tv1;
	struct timeval tv2;
	struct timeval tv3;
	struct timeval tv4;

	clk0 = clock();
	gettimeofday(&tv0, NULL);
	loop_cnt = 10000*10;
	printf("loop count = %lld\n", loop_cnt);
	value = 0;
	for (i = 0; i < loop_cnt; i++) {
		value += i;
	}

	clk1 = clock();
	gettimeofday(&tv1, NULL);
	loop_cnt *= 10;
	printf("loop count = %lld\n", loop_cnt);
	value = 0;
	for (i = 0; i < loop_cnt; i++) {
		value += i;
	}

	clk2 = clock();
	gettimeofday(&tv2, NULL);
	loop_cnt *= 10;
	printf("loop count = %lld\n", loop_cnt);
	value = 0;
	for (i = 0; i < loop_cnt; i++) {
		value += i;
	}

	clk3 = clock();
	gettimeofday(&tv3, NULL);
	loop_cnt *= 10;
	printf("loop count = %lld\n", loop_cnt);
	value = 0;
	for (i = 0; i < loop_cnt; i++) {
		value += i;
	}

	clk4 = clock();
	gettimeofday(&tv4, NULL);

	printf("clk = %ld, tv = %ld %ld\n", clk0, tv0.tv_sec, tv0.tv_usec);
	printf("clk = %ld, tv = %ld %ld\n", clk1, tv1.tv_sec, tv1.tv_usec);
	printf("clk = %ld, tv = %ld %ld\n", clk2, tv2.tv_sec, tv2.tv_usec);
	printf("clk = %ld, tv = %ld %ld\n", clk3, tv3.tv_sec, tv3.tv_usec);
	printf("clk = %ld, tv = %ld %ld\n", clk4, tv4.tv_sec, tv4.tv_usec);
	return 0;
}
