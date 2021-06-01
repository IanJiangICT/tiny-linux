bench_dir=$1
mp_cnt=`grep processor /proc/cpuinfo | wc -l`

echo "Start running benches under $bench_dir mp_cnt = $mp_cnt"

for_list=`seq 1 $mp_cnt`
for i in $for_list
do
	(sh $bench_dir/bench-auto.sh $bench_dir $i > /bench-auto-$i.log &)
done

while (``);
do
	echo "----"
	cat /proc/sched_debug | grep -e ^cpu\# -e ^\>R -e riscv | cut -b1-40
	ls -l /bench-auto-*.log
	usleep 200000
done
wait

