#!/bin/bash

#SBATCH -o ./flops-out.txt
#SBATCH -D .

#SBATCH -J LIKWID-K
#SBATCH --get-user-env
#SBATCH --clusters=mpp2
#SBATCH --export=NONE
#SBATCH --time=03:00:00

# LOAD MODULE
module load mpi.intel
module load likwid/4.3
AMOUNT_THREADS=28
ARRAY_SIZE=30
N_TIMES=30
export OMP_NUM_THREADS=$AMOUNT_THREADS
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
likwid-perfctr -g FLOPS_AVX -execpid -C 0-27 -O -m icc/stream_c.exe -s $ARRAY_SIZE -n $N_TIMES > results/icc_flops.out
echo ''
module unload mpi.intel
module load gcc
echo ''
echo '-----> Meta information:'
module list
echo ''
echo ''
echo ''
echo '-----> Baseline GCC:'
likwid-perfctr -g FLOPS_AVX -execpid -C 0-27 -O -m gcc/stream_c.exe -s $ARRAY_SIZE -n $N_TIMES > results/gcc_flops.out


