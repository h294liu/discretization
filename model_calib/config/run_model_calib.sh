#!/bin/bash
# A. Wood & H. Liu, 2020
# run interaction of Ostrich:  update params, run and route model, calculate diagnostics
# creates a time tracking log to monitor pace of calibration
# 
# USES: R, python3 - on cheyenne: module load nco; module load R; module load python/3.6.8; ncar_pylib (or source /glade/u/apps/opt/ncar_pylib/ncar_pylib.csh )

module load nco
module load R
module load python
module load ncarenv
ncar_pylib

# ========== User settings ==================================
caseLabel=LABEL       # hru complexity level (eg,hru_lev1)
segNdx=SEG_ID         # segment index in routing file matching obs location (start from 1)
nGRU=NGRU             # for whole basin, can query with ncinfo -d gru <attributes_file>
calibDir=CALIBDIR     # calibration direcoty where Ostrich.exe is located. 
modelDir=MODELDIR     # model directory where settings/run is located.
summaRunoffRoot=SUMMARUNOFFROOT   # fixed filename for summa output
routeStart=SIM_START  # route start date. eg 1991-10-01

obsFlow=OBSFILOW                  # file path of observed daily flows (csv)
startStatDate=STARTSTATDATE       # dates for calculating statistics "2007-10-01" 
endStatDate=ENDSTATDATE           

summa_conf_file=$modelDir/run/fileManager.${caseLabel}.txt
route_conf_file=$modelDir/run/control.${caseLabel}.txt

summaOutDir=$modelDir/output/$caseLabel
routeOutDir=$modelDir/route_output
if [ ! -d $summaOutDir ]; then mkdir -p $summaOutDir; fi
if [ ! -d $routeOutDir ]; then mkdir -p $routeOutDir; fi

summa_ofile=$summaOutDir/${summaRunoffRoot}_day.nc
route_ofile=$routeOutDir/sflow.${caseLabel}.h.${routeStart}-00000.nc #sflow.hru_lev0.h.1970-03-02-00000

# --- next settings change less frequently ---
summaExe=/glade/u/home/andywood/proj/SHARP/models/summa/bin/summa_dev.exe
routeExe=/glade/u/home/andywood/proj/SHARP/models/routing/mizuRoute/route/bin/mizuroute.exe
nCoresPerJob=1              # splits domain into 1 gru per job for now
# ========= end User settings ===============================

echo "===== executing trial ====="
echo " "
date | awk '{printf("%s: ---- executing new trial ----\n",$0)}' >> $calibDir/timetrack.log

# ------------------------------------------------------------------------------
# --- 1.  update params                           ---
# ------------------------------------------------------------------------------

echo "--- updating params ---"
date | awk '{printf("%s: updating params\n",$0)}' >> $calibDir/timetrack.log
python $calibDir/scripts/update_ncdf_trial_params.py $caseLabel $calibDir $modelDir
echo " "

# ------------------------------------------------------------------------------
# --- 2.  run summa                                                          ---
# ------------------------------------------------------------------------------
echo Running and routing 

# --- Run Summa (split domain) and concatenate/adjust output for routing
date | awk '{printf("%s: running summa\n",$0)}' >> $calibDir/timetrack.log
for gru in $(seq 1 $nGRU); do
  echo "running $gru"
  ${summaExe} -g $gru $nCoresPerJob -r never -m $summa_conf_file &  # parallel run
  #${summaExe} -g $gru $nCoresPerJob -r never -m $calibDir/models/settings/fileManager.txt   # seq. run by gru
done
wait

# merge output runoff into one file for routing
echo concatenating output files in $summaOutDir
if [ -f $summa_ofile ]; then rm $summa_ofile; fi
python $calibDir/scripts/concat_split_summa.py $summaOutDir/ $summa_ofile

# shift output time back 1 day for routing model
ncap2 -O -s 'time[time]=time-86400' $summa_ofile $summa_ofile

# ------------------------------------------------------------------------------
# --- 3.  route summa output with mizuRoute                                  ---
# ------------------------------------------------------------------------------
date | awk '{printf("%s: routing summa\n",$0)}' >> $calibDir/timetrack.log

# route, after removing existing output
if [ -f $route_ofile ]; then rm $route_ofile; fi
${routeExe} $route_conf_file

# ------------------------------------------------------------------------------
# --- 4.  calculate statistics for Ostrich                                   ---
# ------------------------------------------------------------------------------
echo calculating statistics
date | awk '{printf("%s: calculating statistics\n",$0)}' >> $calibDir/timetrack.log

# Arguments: simQ_file simQ_varname simQ_index obs_file obs_units(cfs,cms) output_stats_file start_date end_date
$calibDir/scripts/calc_sim_stats.Rscr $route_ofile 'IRFroutedRunoff' $segNdx $obsFlow cfs $calibDir/trial_stats.txt $startStatDate $endStatDate 

date | awk '{printf("%s: done with trial\n",$0)}' >> $calibDir/timetrack.log
wait
exit 0
