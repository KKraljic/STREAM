/*-----------------------------------------------------------------------*/
/* Program: STREAM                                                       */
/* Revision: $Id: stream.c,v 5.10 2013/01/17 16:01:06 mccalpin Exp mccalpin $ */
/* Original code developed by John D. McCalpin                           */
/* Programmers: John D. McCalpin                                         */
/*              Joe R. Zagar                                             */
/*                                                                       */
/* This program measures memory transfer rates in MB/s for simple        */
/* computational kernels coded in C.                                     */
/*-----------------------------------------------------------------------*/
/* Copyright 1991-2013: John D. McCalpin                                 */
/*-----------------------------------------------------------------------*/
/* License:                                                              */
/*  1. You are free to use this program and/or to redistribute           */
/*     this program.                                                     */
/*  2. You are free to modify this program for your own use,             */
/*     including commercial use, subject to the publication              */
/*     restrictions in item 3.                                           */
/*  3. You are free to publish results obtained from running this        */
/*     program, or from works that you derive from this program,         */
/*     with the following limitations:                                   */
/*     3a. In order to be referred to as "STREAM benchmark results",     */
/*         published results must be in conformance to the STREAM        */
/*         Run Rules, (briefly reviewed below) published at              */
/*         http://www.cs.virginia.edu/stream/ref.html                    */
/*         and incorporated herein by reference.                         */
/*         As the copyright holder, John McCalpin retains the            */
/*         right to determine conformity with the Run Rules.             */
/*     3b. Results based on modified source code or on runs not in       */
/*         accordance with the STREAM Run Rules must be clearly          */
/*         labelled whenever they are published.  Examples of            */
/*         proper labelling include:                                     */
/*           "tuned STREAM benchmark results"                            */
/*           "based on a variant of the STREAM benchmark code"           */
/*         Other comparable, clear, and reasonable labelling is          */
/*         acceptable.                                                   */
/*     3c. Submission of results to the STREAM benchmark web site        */
/*         is encouraged, but not required.                              */
/*  4. Use of this program or creation of derived works based on this    */
/*     program constitutes acceptance of these licensing restrictions.   */
/*  5. Absolutely no warranty is expressed or implied.                   */
/*-----------------------------------------------------------------------*/
# include <stdio.h>
# include <stdlib.h>
# include <unistd.h>
# include <math.h>
# include <float.h>
# include <limits.h>
#include <likwid.h>
#include <errno.h>
# include <omp.h>
/*-----------------------------------------------------------------------
 * INSTRUCTIONS:
 *
 *	1) STREAM requires different amounts of memory to run on different
 *           systems, depending on both the system cache size(s) and the
 *           granularity of the system timer.
 *     You should adjust the value of 'stream_array_size' (below)
 *           to meet *both* of the following criteria:
 *       (a) Each array must be at least 4 times the size of the
 *           available cache memory. I don't worry about the difference
 *           between 10^6 and 2^20, so in practice the minimum array size
 *           is about 3.8 times the cache size.
 *           Example 1: One Xeon E3 with 8 MB L3 cache
 *               stream_array_size should be >= 4 million, giving
 *               an array size of 30.5 MB and a total memory requirement
 *               of 91.5 MB.  
 *           Example 2: Two Xeon E5's with 20 MB L3 cache each (using OpenMP)
 *               stream_array_size should be >= 20 million, giving
 *               an array size of 153 MB and a total memory requirement
 *               of 458 MB.  
 *       (b) The size should be large enough so that the 'timing calibration'
 *           output by the program is at least 20 clock-ticks.  
 *           Example: most versions of Windows have a 10 millisecond timer
 *               granularity.  20 "ticks" at 10 ms/tic is 200 milliseconds.
 *               If the chip is capable of 10 GB/s, it moves 2 GB in 200 msec.
 *               This means the each array must be at least 1 GB, or 128M elements.
 *
 */

# define HLINE "-------------------------------------------------------------\n"

# ifndef MIN
# define MIN(x,y) ((x)<(y)?(x):(y))
# endif
# ifndef MAX
# define MAX(x,y) ((x)>(y)?(x):(y))
# endif

#ifndef STREAM_TYPE
#define STREAM_TYPE double
#endif

static double	avgtime[4] = {0}, maxtime[4] = {0},
		mintime[4] = {FLT_MAX,FLT_MAX,FLT_MAX,FLT_MAX};

static char	*label[4] = {"Copy       ", "Scale      ",
    "Add        ", "Triad      "};

extern double mysecond();
extern void checkSTREAMresults();
extern int omp_get_num_threads();


int main(int argc, char **argv){
	int checktick();
	int temp, num_threads = 0, n_times = 10000;
	size_t offset = 0;
	size_t max_array_size, array_size, j, k;
	STREAM_TYPE scalar;


#pragma omp parallel shared(num_threads)
    {
        #pragma omp critical
        {
            num_threads++;
        }
    }


	LIKWID_MARKER_INIT;
    #pragma omp parallel
    {
        LIKWID_MARKER_THREADINIT;
    }


	char region_tag[80];//80 is an arbitratry number; large enough to keep the tags...
	
	while ((temp = getopt (argc, argv, "s:o:n:")) != -1){
		switch (temp){
		  case 'n':
			n_times = atoi(optarg);
			break;
		  default:
			printf("Invalid arguments. Aborting.");
			exit(1);
		 }
	}

    //max_array_size = 268435456;
	max_array_size= 2147483648;
    //max_array_size = 128;
	double **times;
	times = malloc(sizeof(double *) * 4);
	for(j=0; j<4; j++){
		times[j] = (double *) malloc(4*n_times*sizeof(double));
	}


	STREAM_TYPE *a = malloc(sizeof(STREAM_TYPE)*(max_array_size+offset));

	STREAM_TYPE *b = malloc(sizeof(STREAM_TYPE)*(max_array_size+offset));

	STREAM_TYPE *c = malloc(sizeof(STREAM_TYPE)*(max_array_size+offset));

	
	for(array_size=1; array_size<max_array_size; array_size=array_size*2){
		double	bytes[4] = {
			2.0 * sizeof(STREAM_TYPE) * array_size,
			2.0 * sizeof(STREAM_TYPE) * array_size,
			3.0 * sizeof(STREAM_TYPE) * array_size,
			3.0 * sizeof(STREAM_TYPE) * array_size
		};
		/* Get initial value for system clock. */
		#pragma omp parallel for schedule(static)
		for (j=0; j<array_size; j++) {
			a[j] = 1.0;
			b[j] = 2.0;
			c[j] = 0.0;
		}

		#pragma omp parallel for schedule(static)
		for (j = 0; j < array_size; j++) a[j] = 2.0E0 * a[j];
    
		/*--- MAIN LOOP --- repeat test cases NTIMES times --- */
		scalar = 3.0;
		//Copy
		sprintf(region_tag, "COPY-%ld", array_size);



		for (k=0; k<n_times; k++){
		    times[0][k] = omp_get_wtime();
            #pragma omp parallel
		    {
		        LIKWID_MARKER_START(region_tag);
				#pragma omp for nowait
				for (j=0; j<array_size; j++) c[j] = a[j];
                LIKWID_MARKER_STOP(region_tag);
			}
			times[0][k] = omp_get_wtime() - times[0][k];
		}

		//Scale
		sprintf(region_tag, "SCALE-%ld", array_size);
        for (k=0; k<n_times; k++){
            times[1][k] = omp_get_wtime();
		    #pragma omp parallel
		    {
			    LIKWID_MARKER_START(region_tag);
				#pragma omp for nowait schedule(static)
				for (j=0; j<array_size; j++) b[j] = scalar*c[j];
                LIKWID_MARKER_STOP(region_tag);
			}
            times[1][k] = omp_get_wtime() - times[1][k];
		}
		//Add
		sprintf(region_tag, "ADD-%ld", array_size);
        for (k=0; k<n_times; k++){
            times[2][k] = omp_get_wtime();
		    #pragma omp parallel
		    {
			    LIKWID_MARKER_START(region_tag);
				#pragma omp for nowait schedule(static)
				for (j=0; j<array_size; j++) c[j] = a[j]+b[j];
                LIKWID_MARKER_STOP(region_tag);
			}
            times[2][k] = omp_get_wtime() - times[2][k];
		}
		//Triad
		sprintf(region_tag, "TRIAD-%ld", array_size);
        for (k=0; k<n_times; k++){
            times[3][k] = omp_get_wtime();
		    #pragma omp parallel
		    {
			    LIKWID_MARKER_START(region_tag);
				#pragma omp for nowait schedule(static)
				for (j=0; j<array_size; j++) a[j] = b[j]+scalar*c[j];
                LIKWID_MARKER_STOP(region_tag);
			}
            times[3][k] = omp_get_wtime() - times[3][k];
		}

		/*	--- SUMMARY --- */
		/* note -- skip first iteration */
		#pragma omp barrier
		for (k=1; k<n_times; k++){
			for (j=0; j<4; j++){
				avgtime[j] = avgtime[j] + times[j][k];
				if(times[j][k]> 0.0)mintime[j] = MIN(mintime[j], times[j][k]);
				maxtime[j] = MAX(maxtime[j], times[j][k]);
			}
		}
		printf("%s,%s,%s,%s,%s,%s,%s,%s\n", "Threads", "Arr_Size", "NTimes", "Func", "Max_BW_[GB/s]", "Avg_time", "Min_time", "Max_time");
		for (j=0; j<4; j++) {
			avgtime[j] = avgtime[j]/(double)(n_times-1);
			printf("%i,%lu,%ld,%s,%.4f,%.6f,%.6f,%.6f\n", num_threads,
			   array_size, 
			   n_times,
			   label[j], 	
			   1.0E-09 * bytes[j]/mintime[j],
			   avgtime[j],
			   mintime[j],
			   maxtime[j]);
		}
	}
	
    LIKWID_MARKER_CLOSE;
    free(a);
    free(b);
    free(c);
    return 0;
}

# define	M	20

int
checktick()
    {
    int		i, minDelta, Delta;
    double	t1, t2, timesfound[M];

/*  Collect a sequence of M unique time values from the system. */

    for (i = 0; i < M; i++) {
	t1 = mysecond();
	while( ((t2=mysecond()) - t1) < 1.0E-6 )
	    ;
	timesfound[i] = t1 = t2;
	}

/*
 * Determine the minimum difference between these M values.
 * This result will be our estimate (in microseconds) for the
 * clock granularity.
 */

    minDelta = 1000000;
    for (i = 1; i < M; i++) {
	Delta = (int)( 1.0E6 * (timesfound[i]-timesfound[i-1]));
	minDelta = MIN(minDelta, MAX(Delta,0));
	}

   return(minDelta);
    }



/* A gettimeofday routine to give access to the wall
   clock timer on most UNIX-like systems.  */

#include <sys/time.h>

double mysecond()
{
	double time = omp_get_wtime();
        return time;
}

