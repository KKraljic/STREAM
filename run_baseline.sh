#!/bin/bash

#SBATCH -o ./baseline.txt
#SBATCH -D .

#SBATCH -J LIKWID-K
#SBATCH --get-user-env
#SBATCH --clusters=mpp2
#SBATCH --export=NONE
#SBATCH --time=00:30:00

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
AMOUNT_THREADS=1
while [  $AMOUNT_THREADS -lt 29 ];
do
	export OMP_NUM_THREADS=$AMOUNT_THREADS
	ARRAY_SIZE=1
	while [  $ARRAY_SIZE -lt 67000000 ]; 
	do
        	~/compilations/icc/$ARRAY_SIZE/10/stream_c.exe
        	let ARRAY_SIZE=ARRAY_SIZE+1000000
	done
	let AMOUNT_THREADS=AMOUNT_THREADS+1
done
echo '-----> Baseline GCC:'
AMOUNT_THREADS=1
while [  $AMOUNT_THREADS -lt 29 ];
do
        export OMP_NUM_THREADS=$AMOUNT_THREADS
	ARRAY_SIZE=1
        while [  $ARRAY_SIZE -lt 67000000 ]; 
        do
                ~/compilations/gcc/$ARRAY_SIZE/10/stream_c.exe
                let ARRAY_SIZE=ARRAY_SIZE+1000000
        done
        let AMOUNT_THREADS=AMOUNT_THREADS+1
done
