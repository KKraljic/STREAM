#!/bin/bash

module load mpi.intel
module load likwid/4.3

ARRAY_SIZE=1
while [  $ARRAY_SIZE -lt 67000000 ]; 
do
        ./compile.sh -c icc -a $ARRAY_SIZE -n 10
        let ARRAY_SIZE=ARRAY_SIZE+1000000
done
ARRAY_SIZE=1
while [  $ARRAY_SIZE -lt 67000000 ]; 
do

        ./compile.sh -c gcc -a $ARRAY_SIZE -n 10
        let ARRAY_SIZE=ARRAY_SIZE+1000000
done
ARRAY_SIZE=1
while [  $ARRAY_SIZE -lt 26 ]; 
do
	N_ITERATIONS=4
        while [  $N_ITERATIONS -lt 5 ]; 
        do
                ./compile.sh -c icc -a $((2**$ARRAY_SIZE)) -n $((2**N_ITERATIONS))
                let N_ITERATIONS=N_ITERATIONS+1
        done
        let ARRAY_SIZE=ARRAY_SIZE+1
done
module unload mpi.intel
module load gcc
module list
echo '-----> Benchmark Output'
ARRAY_SIZE=1
while [  $ARRAY_SIZE -lt 26 ]; 
do
	N_ITERATIONS=4
	while [  $N_ITERATIONS -lt 5 ]; 
	do
		./compile.sh -c gcc -a $((2**$ARRAY_SIZE)) -n $((2**$N_ITERATIONS))
		let N_ITERATIONS=N_ITERATIONS+1
	done
	let ARRAY_SIZE=ARRAY_SIZE+1
done

