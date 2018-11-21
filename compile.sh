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

if [ $A -gt 0 ];
then 
	if [ $N -gt 0 ];
	then 
		make CC=$C A_SIZE=$A N_AMOUNT=$N
	else
		make CC=$C
	fi
else 
	make CC=$C
fi
