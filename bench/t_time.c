#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(int argc, char **argv)
{
	long long int value;
	long long int i;
	long long int loop_cnt;
	clock_t ts0;
	clock_t ts1;
	clock_t ts2;
	clock_t ts3;
	clock_t ts4;

	ts0 = clock();
	loop_cnt = 10000*10;
	printf("loop count = %lld\n", loop_cnt);
	value = 0;
	for (i = 0; i < loop_cnt; i++) {
		value += i;
	}

	ts1 = clock();
	loop_cnt *= 10;
	printf("loop count = %lld\n", loop_cnt);
	value = 0;
	for (i = 0; i < loop_cnt; i++) {
		value += i;
	}

	ts2 = clock();
	loop_cnt *= 10;
	printf("loop count = %lld\n", loop_cnt);
	value = 0;
	for (i = 0; i < loop_cnt; i++) {
		value += i;
	}

	ts3 = clock();
	loop_cnt *= 10;
	printf("loop count = %lld\n", loop_cnt);
	value = 0;
	for (i = 0; i < loop_cnt; i++) {
		value += i;
	}

	ts4 = clock();
	printf("ts0 = %ld\n", ts0);
	printf("ts1 = %ld\n", ts1);
	printf("ts2 = %ld\n", ts2);
	printf("ts3 = %ld\n", ts3);
	printf("ts4 = %ld\n", ts4);
	return 0;
}
