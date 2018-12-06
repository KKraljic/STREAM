ifndef A_SIZE
   A_SIZE = 10000000
endif

ifndef N_AMOUNT
   N_AMOUNT = 10
endif

CFLAGS = -O2 -fopenmp -DSTREAM_ARRAY_SIZE=$(A_SIZE) -DNTIMES=$(N_AMOUNT) 
LFLAGS = -DLIKWID_PERFMON -I/lrz/sys/tools/likwid/likwid-4.3.2/include -L/lrz/sys/tools/likwid/likwid-4.3.2/lib -llikwid -lm

all: stream_f.exe stream_c.exe

stream_f.exe: stream.f mysecond.o
	$(CC) $(CFLAGS) -c mysecond.c ${LFLAGS}

stream_c.exe: stream.c
	$(CC) $(CFLAGS) stream.c -o stream_c.exe ${LFLAGS}

clean:
	rm -f stream_f.exe stream_c.exe *.o
