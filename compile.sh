#/bin/bash
A=0
N=0

while getopts a:n: option
do
	case "${option}"
	in
		a) A=${OPTARG};;
		n) N=${OPTARG};;
		esac
done

make clean

if [ $A -gt 0 ];
then 
	if [ $N -gt 0 ];
	then 
		make A_SIZE=$A N_AMOUNT=$N
	else
		make
	fi
else 
	make
fi
