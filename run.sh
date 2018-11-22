#!/bin/bash

#SBATCH -o ./test-likwid.txt
#SBATCH -D .

#SBATCH -J LIKWID-K
#SBATCH --get-user-env
#SBATCH --clusters=mpp2
#SBATCH --export=NONE
#SBATCH --time=00:00:15

# LOAD MODULE
module load mpi.intel
module load likwid/4.3

export OMP_NUM_THREADS=28
likwid-perfctr -g MEM -execpid -C S0:0-13@S1:14-28 ./stream_c.exe
