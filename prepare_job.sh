#!/bin/bash
#ICC
module load mpi.intel
#module load likwid/4.3

./compile.sh -c icc
mkdir -p icc/
mv stream_c.exe icc/

#GCC
module unload mpi.intel
module load gcc
#module load likwid/4.3
module list

./compile.sh -c gcc
mkdir -p gcc/
mv stream_c.exe gcc/
