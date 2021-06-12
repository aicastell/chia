#!/bin/bash

NUMBER_OF_THREADS=4

USER=chia
PLOT_K_SIZE=32
PLOT_MB_B=4000
PLOT_CPUS_R=4
PLOT_BUCKETS_U=128
PLOT_CHALLENGE_N=16

i=0

while [ $i -lt $NUMBER_OF_THREADS ]
do
    echo "screen -d -m -S chia${i} bash -c 'cd /home/${USER}/Documentos/chia-blockchain && . ./activate && sleep ${i}h && chia plots create -k ${PLOT_K_SIZE} -b ${PLOT_MB_B} -e -r ${PLOT_CPUS_R} -u ${PLOT_BUCKETS_U} -n ${PLOT_CHALLENGE_N} -t /media/tmp-01 -d /media/hdd-01 | tee /home/${USER}/chialogs/chia${i}_plotter.log'"
    i=$(($i + 1))
done

