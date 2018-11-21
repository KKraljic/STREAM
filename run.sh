#!/bin/bash

#SBATCH -o ./output.txt
#SBATCH -D .

#SBATCH -J LIKWID-K
#SBATCH --get-user-env
#SBATCH --clusters=mpp2
#SBATCH --export=NONE
#SBATCH --time=00:05:00

# LOAD MODULE
module load mpi.intel
module load likwid/4.3

echo '======================================================='
echo '===========Starting ICC Streamer and LIKWID============'
echo '======================================================='
echo ''
echo '-----> Meta information:'
module list
echo ''
echo ''
echo ''
echo '-----> Baseline ICC:'
ARRAY_SIZE=1
while [  $ARRAY_SIZE -lt 67000000 ]; 
do

        ./compile.sh -c icc -a $ARRAY_SIZE -n 10
        ./stream_c.exe
        let ARRAY_SIZE=ARRAY_SIZE+1000000
done
echo '-----> Baseline GCC:'
ARRAY_SIZE=1
while [  $ARRAY_SIZE -lt 67000000 ]; 
do

        ./compile.sh -c gcc -a $ARRAY_SIZE -n 10
        ./stream_c.exe
        let ARRAY_SIZE=ARRAY_SIZE+1000000
done
echo '-----> Benchmark Output:'
ARRAY_SIZE=1
while [  $ARRAY_SIZE -lt 26 ]; 
do
	N_ITERATIONS=4
        while [  $N_ITERATIONS -lt 5 ]; 
        do
                ./compile.sh -c icc -a $((2**$ARRAY_SIZE)) -n $((2**N_ITERATIONS))
                ./stream_c.exe
		likwid-perfctr -g CACHES -g DATA -g ENERGY -g FALSE_SHARE -g FLOPS_AVX -g HA -g L2CACHE -g L3CACHE -g MEM -g NUMA ./stream_c.exe
                let N_ITERATIONS=N_ITERATIONS+1
        done
        let ARRAY_SIZE=ARRAY_SIZE+1
done
echo ''
echo ''
echo '======================================================='
echo '===========Starting GCC Streamer and LIKWID============'
echo '======================================================='
echo ''
echo '-----> Meta information:'
module unload mpi.intel
module load gcc
module list
echo ''
echo ''
echo '-----> Benchmark Output'
ARRAY_SIZE=1
while [  $ARRAY_SIZE -lt 26 ]; 
do
	N_ITERATIONS=4
	while [  $N_ITERATIONS -lt 5 ]; 
	do
		./compile.sh -c gcc -a $((2**$ARRAY_SIZE)) -n $((2**$N_ITERATIONS))
		./stream_c.exe
		likwid-perfctr -g CACHES -g DATA -g ENERGY -g FALSE_SHARE -g FLOPS_AVX -g HA -g L2CACHE -g L3CACHE -g MEM -g NUMA ./stream_c.exe
		let N_ITERATIONS=N_ITERATIONS+1
	done
	let ARRAY_SIZE=ARRAY_SIZE+1
done
echo ''
echo ''

