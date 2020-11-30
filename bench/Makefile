CROSS_COMPILE=riscv64-linux-gnu-

bench=
bench+=hello
bench+=linpackc
bench+=stream
bench+=t_time

all: ${bench}

clean:
	rm -rf ${bench}

hello: hello.c
	${CROSS_COMPILE}gcc -static -o hello hello.c

linpackc: linpackc.c
	${CROSS_COMPILE}gcc -static -O4 -DDP -DROLL -o linpackc linpackc.c -lm

stream: stream.c
	${CROSS_COMPILE}gcc -static -O4 -o stream -DSTREAM_ARRAY_SIZE=1000000 stream.c

t_time: t_time.c
	${CROSS_COMPILE}gcc -static -o t_time t_time.c

