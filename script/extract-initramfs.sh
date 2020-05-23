img=$1
start=`grep -a -b -m 1 --only-matching '070701' $img | head -1 | cut -f 1 -d :`
end=`grep -a -b -m 1 --only-matching 'TRAILER!!!' $img | head -1 | cut -f 1 -d :`

# 11 bytes = length of TRAILER!!! zero terminated string, fixes premature end of file warning in CPIO
end=$((end + 11))
count=$((end - start))
echo Start = $start
echo End = $end
echo Count = $count
if (($count < 0)); then
    echo "-E- Couldn't match start/end of the initramfs image."
    exit
fi
dd if=$img bs=1 skip=$start count=$count > initramfs.cpio
