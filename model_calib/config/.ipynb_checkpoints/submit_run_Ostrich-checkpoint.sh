#!/bin/bash
#PBS -N JOB_NAME
#PBS -A P48500028
#PBS -q regular
#PBS -l select=1:ncpus=36:mpiprocs=36
#PBS -l walltime=12:00:00
#PBS -o OUT_FILE.out
#PBS -e OUT_FILE.err

# ========= User settings ===============================
caseLabel=LABEL       # hru complexity level (eg,hru_lev1)
calibDir=CALIBDIR     # calibration direcoty where Ostrich.exe is located. 
modelDir=MODELDIR     # model directory where settings/run is located.
MaxIter=MAXITERATIONS # max nunmber of iterations of a calib
# ========= end User settings ===============================

mkdir -p /glade/scratch/hongli/temp
export TMPDIR=/glade/scratch/hongli/temp
export MPI_SHEPHERD=true

module load python
module load ncarenv
ncar_pylib

# define multiplier bounds and run Ostrich
# Arguments:  <case_label> <calib_dir> <settings_dir>
date | awk '{printf("%s: ---- executing define_mtp_bound.py ----\n",$0)}' > ./timetrack.log
python ./scripts/define_mtp_bound.py $caseLabel $calibDir $modelDir

# update iteration number 
sed -i "s~MAXITER~${MaxIter}~g" $calibDir/ostIn.txt

# Run calibration
./Ostrich.exe

# save OstOutput0.txt after calib
ost_output=OstOutput0.txt
output_num=$(ls -l OstOutput* |wc -l)
if [ $output_num -gt 0 ]; then cp ${ost_output} OstOutput${output_num}.txt; fi
