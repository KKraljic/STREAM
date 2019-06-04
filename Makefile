
CFLAGS =  -march=haswell -O3 -qopenmp -Wall -Wconversion
LFLAGS = -DLIKWID_PERFMON -I/lrz/sys/tools/likwid/likwid-4.3.2/include -L/lrz/sys/tools/likwid/likwid-4.3.2/lib -llikwid -lm

all: stream_f.exe stream_c.exe

stream_f.exe: stream.f mysecond.o
	$(CC) $(CFLAGS) -c mysecond.c ${LFLAGS}

stream_c.exe: stream.c
	$(CC) $(CFLAGS) stream.c -o stream_c.exe ${LFLAGS}

clean:
	rm -f stream_f.exe stream_c.exe *.o
