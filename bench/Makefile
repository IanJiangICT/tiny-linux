CROSS_COMPILE=riscv64-linux-gnu-

bench=
bench+=hello
bench+=jpgenc
bench+=linpackc
bench+=stream
bench+=t_time
bench+=t_sleep
bench+=hello_pthread
bench+=hello_pthread_d
bench+=show_context

install_dir=./_install

all: ${bench}

clean:
	rm -rf ${bench}

hello: hello.c
	${CROSS_COMPILE}gcc -static -o hello hello.c

src_jpgenc=jpgenc_buf.c jpgenc_conf.c jpgenc_enc.c jpgenc_huff.c jpgenc_main.c
jpgenc: ${src_jpgenc}
	${CROSS_COMPILE}gcc -static -o jpgenc -I. ${src_jpgenc}

linpackc: linpackc.c
	${CROSS_COMPILE}gcc -static -O4 -DDP -DROLL -o linpackc linpackc.c -lm

stream: stream.c
	${CROSS_COMPILE}gcc -static -O4 -o stream -DSTREAM_ARRAY_SIZE=1000000 stream.c

t_sleep: t_sleep.c
	${CROSS_COMPILE}gcc -static -o t_sleep t_sleep.c

t_time: t_time.c
	${CROSS_COMPILE}gcc -static -o t_time t_time.c

hello_pthread: hello_pthread.c
	${CROSS_COMPILE}gcc -static -o hello_pthread hello_pthread.c -lpthread

hello_pthread_d: hello_pthread.c
	${CROSS_COMPILE}gcc -o hello_pthread_d hello_pthread.c -lpthread

show_context: show_context.c
	${CROSS_COMPILE}gcc -static -o show_context show_context.c -lpthread

install: ${bench}
	rm -rf ${install_dir}
	mkdir ${install_dir}
	for b in ${bench}; do \
		mkdir ${install_dir}/$$b; \
		cp ./$$b ${install_dir}/$$b/; \
	done
	
