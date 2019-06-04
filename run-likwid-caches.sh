#!/bin/bash

#SBATCH -o ./caches-out.txt
#SBATCH -D .

#SBATCH -J LIKWID-K
#SBATCH --get-user-env
#SBATCH --clusters=mpp2
#SBATCH --export=NONE
#SBATCH --time=04:59:00

# LOAD MODULE
module load mpi.intel
module load likwid/4.3
AMOUNT_THREADS=28
export OMP_NUM_THREADS=$AMOUNT_THREADS

N_TIMES=2000
RESULTS=results
mkdir $RESULTS
likwid-topology > $RESULTS/topology.out
likwid-perfctr -g CACHES -execpid -C 0-27 -O -m icc/stream_c.exe -n $N_TIMES > $RESULTS/icc_caches.out

