#!/bin/bash
# submit with qsub [job.lsf]

#PBS -N JOB_NAME
#PBS -A P48500028
#PBS -q regular
#PBS -l select=1:ncpus=36:mpiprocs=36
#PBS -l walltime=04:00:00
#PBS -o OUT_FILE.out
#PBS -e OUT_FILE.err

mkdir -p /glade/scratch/hongli/temp
export TMPDIR=/glade/scratch/hongli/temp
export MPI_SHEPHERD=true

### Run the executable
RUN_MODEL_FILE