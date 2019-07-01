#!/bin/bash
#ICC
module load mpi.intel
#module load likwid/4.3

./compile.sh -c icc
mkdir -p icc/
mv add.exe icc/
mv scale.exe icc/
mv copy.exe icc/
mv triad.exe icc/

#GCC
module unload mpi.intel
module load gcc
#module load likwid/4.3
module list

./compile.sh -c gcc
mkdir -p gcc/
mv add.exe gcc/
mv scale.exe gcc/
mv copy.exe gcc/
mv triad.exe gcc/
