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

export OMP_NUM_THREADS=2
likwid-perfctr -g MEM -execpid -C 0-27 -m ./stream_c.exe
