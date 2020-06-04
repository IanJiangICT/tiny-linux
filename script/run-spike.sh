#!/bin/bash

SPIKE=spike
SMP=4
which $SPIKE
if [ $? -eq 0 ]
then
	$SPIKE -p$SMP obj/bbl/bbl
else
	echo "No Spike found"
fi
