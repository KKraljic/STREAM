#!/bin/bash

#SBATCH -o ./flops-out.txt
#SBATCH -D .

#SBATCH -J LIKWID-K
#SBATCH --get-user-env
#SBATCH --clusters=mpp2
#SBATCH --export=NONE
#SBATCH --time=00:30:00

# LOAD MODULE
module load mpi.intel
module load likwid/4.3
AMOUNT_THREADS=28
export OMP_NUM_THREADS=$AMOUNT_THREADS
ARRAY_SIZE=$((2**23))
N_TIMES=400000
likwid-perfctr -g FLOPS_AVX -execpid -C 0-27 -O -m icc/stream_c.exe -s $ARRAY_SIZE -n $N_TIMES > results/icc_flops.out
module unload mpi.intel
module load gcc
likwid-perfctr -g FLOPS_AVX -execpid -C 0-27 -O -m gcc/stream_c.exe -s $ARRAY_SIZE -n $N_TIMES > results/gcc_flops.out


