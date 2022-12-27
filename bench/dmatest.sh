cd /sys/module/dmatest/parameters
echo 2 > iterations
#echo 1024 > transfer_size
#echo 1 > norandom
#echo dma0chan0 > channel
echo "" > channel
echo 1 > run
cd /
