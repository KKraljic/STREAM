#!/bin/bash

#SBATCH -o ./output-with-marker.txt
#SBATCH -D .

#SBATCH -J LIKWID-K
#SBATCH --get-user-env
#SBATCH --clusters=mpp2
#SBATCH --export=NONE
#SBATCH --time=00:30:00

# LOAD MODULE
module load mpi.intel
module load likwid/4.3
DATA_FLAGS1="-g CACHES"
DATA_FLAGS2="-g FALSE_SHARE"
DATA_FLAGS3="-g FLOPS_AVX"
DATA_FLAGS4="-g MEM"
THREAD_PIN="1-28"

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
AMOUNT_THREADS=1
while [  $AMOUNT_THREADS -lt 29 ];
do
	export OMP_NUM_THREADS=$AMOUNT_THREADS
	ARRAY_SIZE=1
	while [  $ARRAY_SIZE -lt 67000000 ]; 
	do
        	~/compilations/icc/$ARRAY_SIZE/10/stream_c.exe
        	let ARRAY_SIZE=ARRAY_SIZE+2000000
	done
	echo '-----> Baseline GCC:'
	ARRAY_SIZE=1
	while [  $ARRAY_SIZE -lt 67000000 ]; 
	do
        	~/compilations/gcc/$ARRAY_SIZE/10/stream_c.exe
	        let ARRAY_SIZE=ARRAY_SIZE+2000000
	done
	let AMOUNT_THREADS=AMOUNT_THREADS+1
done
echo '-----> Benchmark Output:'
AMOUNT_THREADS=1
while [  $AMOUNT_THREADS -lt 29 ];
do
	export OMP_NUM_THREADS=$AMOUNT_THREADS
	ARRAY_SIZE=1
	while [  $ARRAY_SIZE -lt 26 ]; 
	do
		N_ITERATIONS=4
	        while [  $N_ITERATIONS -lt 5 ]; 
	        do
        	        ~/compilations/icc/$((2**$ARRAY_SIZE))/$((2**N_ITERATIONS))/stream_c.exe
			likwid-perfctr ${DATA_FLAGS1} -execpid -C ${THREAD_PIN} ~/compilations/icc/$((2**$ARRAY_SIZE))/$((2**N_ITERATIONS))/stream_c.exe
			likwid-perfctr ${DATA_FLAGS2} -execpid -C ${THREAD_PIN} ~/compilations/icc/$((2**$ARRAY_SIZE))/$((2**N_ITERATIONS))/stream_c.exe
			likwid-perfctr ${DATA_FLAGS3} -execpid -C ${THREAD_PIN} ~/compilations/icc/$((2**$ARRAY_SIZE))/$((2**N_ITERATIONS))/stream_c.exe
			likwid-perfctr ${DATA_FLAGS4} -execpid -C ${THREAD_PIN} ~/compilations/icc/$((2**$ARRAY_SIZE))/$((2**N_ITERATIONS))/stream_c.exe

	                let N_ITERATIONS=N_ITERATIONS+1
        	done
	        let ARRAY_SIZE=ARRAY_SIZE+1
	done
	let AMOUNT_THREADS=AMOUNT_THREADS+1
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
AMOUNT_THREADS=1
while [  $AMOUNT_THREADS -lt 29 ];
do
	export OMP_NUM_THREADS=$AMOUNT_THREADS
	ARRAY_SIZE=1
	while [  $ARRAY_SIZE -lt 26 ]; 
	do
		N_ITERATIONS=4
		while [  $N_ITERATIONS -lt 5 ]; 
		do
			~/compilations/gcc/$((2**$ARRAY_SIZE))/$((2**N_ITERATIONS))/stream_c.exe
			likwid-perfctr ${DATA_FLAGS1} -execpid -C ${THREAD_PIN} ~/compilations/gcc/$((2**$ARRAY_SIZE))/$((2**N_ITERATIONS))/stream_c.exe
			likwid-perfctr ${DATA_FLAGS2} -execpid -C ${THREAD_PIN} ~/compilations/gcc/$((2**$ARRAY_SIZE))/$((2**N_ITERATIONS))/stream_c.exe
                        likwid-perfctr ${DATA_FLAGS3} -execpid -C ${THREAD_PIN} ~/compilations/gcc/$((2**$ARRAY_SIZE))/$((2**N_ITERATIONS))/stream_c.exe
                        likwid-perfctr ${DATA_FLAGS4} -execpid -C ${THREAD_PIN} ~/compilations/gcc/$((2**$ARRAY_SIZE))/$((2**N_ITERATIONS))/stream_c.exe

			let N_ITERATIONS=N_ITERATIONS+1
		done
		let ARRAY_SIZE=ARRAY_SIZE+1
	done
	let AMOUNT_THREADS=AMOUNT_THREADS+1
done

