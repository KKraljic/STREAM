#!/bin/bash

#SBATCH -o ./caches-out.txt
#SBATCH -D .

#SBATCH -J LIKWID-K
#SBATCH --get-user-env
#SBATCH --clusters=mpp2
#SBATCH --export=NONE
#SBATCH --time=00:05:00

# LOAD MODULE
module load mpi.intel
module load likwid/4.3
AMOUNT_THREADS=28
export OMP_NUM_THREADS=$AMOUNT_THREADS

ARRAY_SIZE=$((2**23))
N_TIMES=400000
RESULTS=results
mkdir $RESULTS
likwid-perfctr -g CACHES -execpid -C 0-27 -O -m icc/stream_c.exe -s $ARRAY_SIZE -n $N_TIMES > $RESULTS/icc_caches.out
module unload mpi.intel
module load gcc
likwid-perfctr -g CACHES -execpid -C 0-27 -O -m gcc/stream_c.exe -s $ARRAY_SIZE -n $N_TIMES > $RESULTS/gcc_caches.out


