ifndef A_SIZE
   A_SIZE = 10000000
endif

ifndef N_AMOUNT
   N_AMOUNT = 10
endif


#CC = gcc
#CFLAGS = -O2 -fopenmp -DSTREAM_ARRAY_SIZE=$(A_SIZE) -DNTIMES=$(N_AMOUNT)
CFLAGS = -O2 -fopenmp -DSTREAM_ARRAY_SIZE=$(A_SIZE) -DNTIMES=$(N_AMOUNT) 
LFLAGS = -DLIKWID_PERFMON -I/lrz/sys/tools/likwid/likwid-4.3.2/include -L/lrz/sys/tools/likwid/likwid-4.3.2/lib -llikwid -lm


#FC = gfortran
#FFLAGS = -O2 -fopenmp -DSTREAM_ARRAY_SIZE=$(A_SIZE) -DNTIMES=$(N_AMOUNT)

all: stream_f.exe stream_c.exe

stream_f.exe: stream.f mysecond.o
	$(CC) $(CFLAGS) -c mysecond.c ${LFLAGS}
	#$(FC) $(FFLAGS) -c stream.f
	#$(FC) $(FFLAGS) stream.o mysecond.o -o stream_f.exe

stream_c.exe: stream.c
	$(CC) $(CFLAGS) stream.c -o stream_c.exe ${LFLAGS}

clean:
	rm -f stream_f.exe stream_c.exe *.o

# an example of a more complex build line for the Intel icc compiler
stream.icc: stream.c
	icc -O3 -xCORE-AVX2 -ffreestanding -qopenmp -DSTREAM_ARRAY_SIZE=80000000 -DNTIMES=20 stream.c -o stream.omp.AVX2.80M.20x.icc
