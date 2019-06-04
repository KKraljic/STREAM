#!/bin/bash

#SBATCH -o ./flops-out.txt
#SBATCH -D .

#SBATCH -J LIKWID-K
#SBATCH --get-user-env
#SBATCH --clusters=mpp2
#SBATCH --export=NONE
#SBATCH --time=04:30:00

# LOAD MODULE
module load mpi.intel
module load likwid/4.3
AMOUNT_THREADS=28
export OMP_NUM_THREADS=$AMOUNT_THREADS

N_TIMES=2000
RESULTS=results
mkdir $RESULTS
likwid-perfctr -g FLOPS_AVX -execpid -C 0-27 -O -m icc/stream_c.exe -n $N_TIMES > results/icc_flops.out


