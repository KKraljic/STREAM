#!/bin/bash

#SBATCH -o ./baseline-28-threads.txt
#SBATCH -D .

#SBATCH -J LIKWID-K
#SBATCH --get-user-env
#SBATCH --clusters=mpp2
#SBATCH --export=NONE
#SBATCH --time=01:59:00

# LOAD MODULE
module load mpi.intel
module load likwid/4.3

echo '======================================================='
echo '===========Starting Baselines=========================='
echo '======================================================='
echo ''
echo '-----> Meta information:'
module list
echo ''
echo ''
echo ''
echo '-----> Baseline ICC:'
AMOUNT_THREADS=28
export OMP_NUM_THREADS=$AMOUNT_THREADS
ARRAY_SIZE=1
while [  $ARRAY_SIZE -lt 67000000 ]; 
do
  	likwid-perfctr -g CACHES -execpid -C 0-27 ~/compilations/icc/$ARRAY_SIZE/10/stream_c.exe
       	let ARRAY_SIZE=ARRAY_SIZE+20000
done

module unload mpi.intel
module load gcc
echo ''
echo '-----> Meta information:'
module list
echo ''
echo ''
echo ''
echo '-----> Baseline GCC:'
export OMP_NUM_THREADS=$AMOUNT_THREADS
ARRAY_SIZE=1
while [  $ARRAY_SIZE -lt 67000000 ]; 
do
	likwid-perfctr -g CACHES -execpid -C 0-27 ~/compilations/gcc/$ARRAY_SIZE/10/stream_c.exe
        let ARRAY_SIZE=ARRAY_SIZE+20000
done

