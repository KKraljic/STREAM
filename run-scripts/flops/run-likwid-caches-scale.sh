#!/bin/bash

#SBATCH -o ./flops-out-scale.txt
#SBATCH -D .

#SBATCH -J LIKWID-K
#SBATCH --get-user-env
#SBATCH --clusters=mpp2
#SBATCH --export=NONE
#SBATCH --time=36:59:00

# LOAD MODULE
module load mpi.intel
module load likwid/4.3
AMOUNT_THREADS=28
export OMP_NUM_THREADS=$AMOUNT_THREADS

cd ../../

N_TIMES=15000
RESULTS=results
mkdir $RESULTS
likwid-topology > $RESULTS/topology.out
likwid-perfctr -g FLOPS_AVX -execpid -C 0-27 -O -m icc/scale.exe -n $N_TIMES > $RESULTS/icc_flops_scale.out
likwid-perfctr -g FLOPS_AVX -execpid -C 0-27 -O -m gcc/scale.exe -n $N_TIMES > $RESULTS/gcc_flops_scale.out

