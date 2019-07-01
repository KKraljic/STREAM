# Compiling this modification of STREAM

Clone this repository first. Change the directory into the freshly cloned project. Afterwards, please run the prepare script:

    ./prepare_job.sh

This script loads all required modules and compiles all required binaries.

# Running this modification of STREAM

All run scripts are in the "run-scripts" sub directories. Currently, there are scripts for caches and for flops. In order to run a specific benchmark (sum, scale, triad, copy), please modify the following command as required:

    sbatch <run-script>

After the execution of these scripts, you'll find the output in the freshly created results directory.
