
ifeq ($(CC), icc)
    CFLAGS =  -march=haswell -O3 -qopenmp -Wall -Wconversion
else
    CFLAGS =  -march=haswell -O3 -fopenmp -Wall -Wconversion
endif

LFLAGS = -DLIKWID_PERFMON -I/lrz/sys/tools/likwid/likwid-4.3.2/include -L/lrz/sys/tools/likwid/likwid-4.3.2/lib -llikwid -lm

all: stream_f.exe stream_c.exe

stream_f.exe: stream.f mysecond.o
	$(CC) $(CFLAGS) -c mysecond.c ${LFLAGS}

stream_c.exe: 
	$(CC) $(CFLAGS) add.c -o add.exe ${LFLAGS}
	$(CC) $(CFLAGS) copy.c -o copy.exe ${LFLAGS}
	$(CC) $(CFLAGS) triad.c -o triad.exe ${LFLAGS}
	$(CC) $(CFLAGS) scale.c -o scale.exe ${LFLAGS}

clean:
	rm -f stream_f.exe stream_c.exe *.o
