bench_dir=/bench
echo "Start running benches under $bench_dir"
cd $bench_dir
for b in `ls *.tar`;
do
	echo "--------------------------------------"
	bench_name=`echo $b | sed -E 's/.tar//'`
	echo "Run bench $bench_name..."
	tar xf $b
	cd $bench_name
	cat ./run.sh
	chmod a+x ./run.sh
	sh ./run.sh
	cd $bench_dir
done
echo "End of run benches"
