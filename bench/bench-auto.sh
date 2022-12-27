bench_dir=$1 # Example: /bench
run_index=$2 # Example: 1
run_dir=/bench-run-$run_index # Example: /bench-run-1

cd $bench_dir
bench_tar_list=`ls *.tar`
echo "======================================"
echo "Start running $run_index of benches under $bench_dir"
echo "$bench_tar_list"
echo "======================================"
mkdir $run_dir
for b in $bench_tar_list;
do
	cd $bench_dir
	bench_name=`echo $b | sed -E 's/\.tar//'`
	echo "--------------------------------------"
	echo "Run bench $run_dir/$bench_name..."
	tar xf $b -C $run_dir
	cd $run_dir/$bench_name
	cat ./run.sh
	chmod a+x ./run.sh
	sh ./run.sh
	cd $run_dir
	rm -rf $bench_name
	echo "End of $run_dir/$bench_name..."
done
echo "End of all"
#echo "Calling poweroff..." 
#poweroff -f
