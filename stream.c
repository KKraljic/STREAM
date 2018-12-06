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
 *      Version 5.10 increases the default array size from 2 million
 *          elements to 10 million elements in response to the increasing
 *          size of L3 caches.  The new default size is large enough for caches
 *          up to 20 MB. 
 *      Version 5.10 changes the loop index variables from "register int"
 *          to "ssize_t", which allows array indices >2^32 (4 billion)
 *          on properly configured 64-bit systems.  Additional compiler options
 *          (such as "-mcmodel=medium") may be required for large memory runs.
 *
 */

/*  2) STREAM runs each kernel "NTIMES" times and reports the *best* result
 *         for any iteration after the first, therefore the minimum value
 *         for NTIMES is 2.
 *      There are no rules on maximum allowable values for NTIMES, but
 *         values larger than the default are unlikely to noticeably
 *         increase the reported performance.
 *      NTIMES can also be set on the compile line without changing the source
 *         code using, for example, "-DNTIMES=7".
 */
#ifdef NTIMES
	#if NTIMES<=1
	#   define NTIMES	30
	#endif
#endif
#ifndef NTIMES
#   define NTIMES	30
#endif

/*
 *	3) Compile the code with optimization.  Many compilers generate
 *       unreasonably bad code before the optimizer tightens things up.  
 *     If the results are unreasonably good, on the other hand, the
 *       optimizer might be too smart for me!
 *
 *     For a simple single-core version, try compiling with:
 *            cc -O stream.c -o stream
 *     This is known to work on many, many systems....
 *
 *     To use multiple cores, you need to tell the compiler to obey the OpenMP
 *       directives in the code.  This varies by compiler, but a common example is
 *            gcc -O -fopenmp stream.c -o stream_omp
 *       The environment variable OMP_NUM_THREADS allows runtime control of the 
 *         number of threads/cores used when the resulting "stream_omp" program
 *         is executed.
 *
 *     To run with single-precision variables and arithmetic, simply add
 *         -DSTREAM_TYPE=float
 *     to the compile line.
 *     Note that this changes the minimum array sizes required --- see (1) above.
 *
 *     The preprocessor directive "TUNED" does not do much -- it simply causes the 
 *       code to call separate functions to execute each kernel.  Trivial versions
 *       of these functions are provided, but they are *not* tuned -- they just 
 *       provide predefined interfaces to be replaced with tuned code.
 *
 *
 *	4) Optional: Mail the results to mccalpin@cs.virginia.edu
 *	   Be sure to include info that will help me understand:
 *		a) the computer hardware configuration (e.g., processor model, memory type)
 *		b) the compiler name/version and compilation flags
 *      c) any run-time information (such as OMP_NUM_THREADS)
 *		d) all of the output from the test case.
 *
 * Thanks!
 *
 *-----------------------------------------------------------------------*/

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
	int temp, array_power = 18, offset = 0, size_iterator;
	ssize_t max_array_size, stream_array_size;
	
	int checktick(), k;
	ssize_t j;
	STREAM_TYPE scalar;
	double t, times[4][NTIMES];
    	int num_threads = 0;
	char region_tag[80];//80 is an arbitratry number; large enough to keep the tags...
	
	
	while ((temp = getopt (argc, argv, "s:o:")) != -1){
		switch (temp){
		  case 's':
			array_power = atoi(optarg);
			break;
		  case 'o':
			offset = atoi(optarg);
			break;
		  default:
			printf("Invalid arguments. Aborting.");
			exit(1);
		 }
	}
	

	LIKWID_MARKER_INIT;
        #pragma omp parallel
        {
        	LIKWID_MARKER_THREADINIT;
        }


	#pragma omp parallel shared(num_threads)
	{
		#pragma omp atomic 
		num_threads++;
	}
   
	max_array_size = (ssize_t) (pow(2, array_power) + 0.5);
	int count = 1;
	for(stream_array_size=1; stream_array_size<max_array_size; stream_array_size = (ssize_t) (pow(2, count) + 0.5)){
		count++;
		STREAM_TYPE	a[stream_array_size+offset],
				b[stream_array_size+offset],
				c[stream_array_size+offset];
				
		double	bytes[4] = {
			2 * sizeof(STREAM_TYPE) * stream_array_size,
			2 * sizeof(STREAM_TYPE) * stream_array_size,
			3 * sizeof(STREAM_TYPE) * stream_array_size,
			3 * sizeof(STREAM_TYPE) * stream_array_size
		};
		/* Get initial value for system clock. */
		#pragma omp parallel for
		for (j=0; j<stream_array_size; j++) {
			a[j] = 1.0;
			b[j] = 2.0;
			c[j] = 0.0;
		}

		t = mysecond();
		#pragma omp parallel for
		for (j = 0; j < stream_array_size; j++) a[j] = 2.0E0 * a[j];
		t = 1.0E6 * (mysecond() - t);
    
    /*	--- MAIN LOOP --- repeat test cases NTIMES times --- */
		scalar = 3.0;
		//Copy
		sprintf(region_tag, "COPY-%lld", stream_array_size);
		for (k=0; k<NTIMES; k++){
			times[0][k] = mysecond();
			#pragma omp parallel 
			{
				LIKWID_MARKER_START(region_tag);
				#pragma omp for
				for (j=0; j<stream_array_size; j++) c[j] = a[j];
				LIKWID_MARKER_STOP(region_tag);
			}
			times[0][k] = mysecond() - times[0][k];
		}

		//Scale
		sprintf(region_tag, "SCALE-%lld", stream_array_size);
		for (k=0; k<NTIMES; k++){
			times[1][k] = mysecond();
			#pragma omp parallel
			{
				LIKWID_MARKER_START(region_tag);
				#pragma omp for
				for (j=0; j<stream_array_size; j++) b[j] = scalar*c[j];
				LIKWID_MARKER_STOP(region_tag);
			}
			times[1][k] = mysecond() - times[1][k];
		}

		//Add
		sprintf(region_tag, "ADD-%lld", stream_array_size);
		for (k=0; k<NTIMES; k++){
			times[2][k] = mysecond();
			#pragma omp parallel
			{
				LIKWID_MARKER_START(region_tag);
				#pragma omp for
				for (j=0; j<stream_array_size; j++) c[j] = a[j]+b[j];
				LIKWID_MARKER_STOP(region_tag);
			}
			times[2][k] = mysecond() - times[2][k];
		}

		//Triad
		sprintf(region_tag, "TRIAD-%lld", stream_array_size);
		for (k=0; k<NTIMES; k++){
			times[3][k] = mysecond();
			#pragma omp parallel
			{
				LIKWID_MARKER_START(region_tag);
				#pragma omp for
				for (j=0; j<stream_array_size; j++) a[j] = b[j]+scalar*c[j];
				LIKWID_MARKER_STOP(region_tag);
			}
			times[3][k] = mysecond() - times[3][k];
		}
		
		/*	--- SUMMARY --- */
		/* note -- skip first iteration */
		#pragma omp barrier
		for (k=1; k<NTIMES; k++){
			for (j=0; j<4; j++){
				avgtime[j] = avgtime[j] + times[j][k];
				mintime[j] = MIN(mintime[j], times[j][k]);
				maxtime[j] = MAX(maxtime[j], times[j][k]);
			}
		}
		printf("%s %12s %12s %8s %21s %13s %12s %12s\n", "Threads", "Array_Size", "N_Times", "Func", "Bandwidth", "Avg_time", "Min_time", "Max_time");
		for (j=0; j<4; j++) {
			avgtime[j] = avgtime[j]/(double)(NTIMES-1);
			printf("%i %16llu %9d %20s %2.1f  %19.6f  %11.6f  %11.6f\n", num_threads, 
			   stream_array_size, 
			   NTIMES,
			   label[j], 	
			   1.0E-06 * bytes[j]/avgtime[j],
			   avgtime[j],
			   mintime[j],
			   maxtime[j]);
		}
	}
	
    LIKWID_MARKER_CLOSE;
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
        struct timeval tp;
        struct timezone tzp;
        int i;

        i = gettimeofday(&tp,&tzp);
        return ( (double) tp.tv_sec + (double) tp.tv_usec * 1.e-6 );
}

