bench_dir=$1
#mp_cnt=`grep processor /proc/cpuinfo | wc -l`
mp_cnt=$2

echo "Start running benches under $bench_dir mp_cnt = $mp_cnt"

for i in 1 2 3 4 ;
do
	(sh $bench_dir/bench-auto.sh $bench_dir $i &)
	
done
wait

