bench_dir=/bench
#mp_cnt=`grep processor /proc/cpuinfo | wc -l`
j_start=$1
j_end=$2
echo "Start benches under $bench_dir: $j_start...$j_end"
for_list=`seq $j_start $j_end`
for i in $for_list
do
	echo "start bench [$i]"
	(sh $bench_dir/bench-auto.sh $bench_dir $i > /bench-auto-$i.log &)
done

while (``)
do
	echo "----"
	date
	ls -l /bench-auto*log
	tail -n 1 /bench-auto*log
	usleep 20000
	#usleep 1980000
done
wait
