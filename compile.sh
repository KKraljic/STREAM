#/bin/bash
A=0
N=0
C=gcc

while getopts a:n:c: option
do
	case "${option}"
	in
		a) A=${OPTARG};;
		n) N=${OPTARG};;
		c) C=${OPTARG};;
		esac
done

make clean
make CC=$C
