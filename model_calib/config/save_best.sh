#!/bin/bash
# needs editing to update for current basin and run

# ========== User settings ==================================
run=RUNID                       # calibration run number  
caseLabel=LABEL                 # hru complexity level (eg,hru_lev1)
calibDir=CALIBDIR               # calibration direcoty where Ostrich.exe is located. 
modelDir=MODELDIR               # model directory where settings/run is located.
summaRunoffRoot=SUMMARUNOFFROOT # fixed filename for summa output
# ========= end User settings ===============================

saveDir=$calibDir/out_archive/$run/
mkdir -p $saveDir

summa_ofile=$modelDir/output/$caseLabel/${summaRunoffRoot}_day.nc
route_ofile=$modelDir/route_output/sflow.${caseLabel}.h.*.nc

echo "saving input files for the best solution found in $saveDir ..."
cp $calibDir/nc_multiplier.txt $saveDir/
cp $modelDir/settings/trialParams.${caseLabel}.nc $saveDir/
cp $calibDir/trial_stats.txt $saveDir/
cp $calibDir/Ost*.txt $saveDir/
cp $calibDir/timetrack.log $saveDir/
cp $calibDir/ostIn.txt $saveDir/
# cp $calibDir/ost_* $saveDir/

cp $summa_ofile $saveDir/
cp $route_ofile $saveDir/

exit 0

