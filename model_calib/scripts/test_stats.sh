#!/bin/bash
# A. Wood & H. Liu, 2020
# run interaction of Ostrich:  update params, run and route model, calculate diagnostics
# creates a time tracking log to monitor pace of calibration
# 
# USES: R, python3 - on cheyenne: module load R; module load python/3.6.8; ncar_pylib; module load nco 
#                                      (or source /glade/u/apps/opt/ncar_pylib/ncar_pylib.csh )
#          if on jupyterhub & mizuR. compiled with ifort, need:  module load intel

# ========== User settings ==================================
basinID="clearwater"
segNdx=107                     # segment index in routing file matching obs location (start from 1)
nGRU=69                        # for whole basin, can query with ncinfo -d gru <attributes_file>
statStatDate="2007-10-01"      # dates for calculating statistics
endStatDate="2012-09-30"
homeDir="/glade/u/home/andywood/proj/SHARP/wreg/pnnl/$basinID/calib/"  # calib directory
settingsDir="/glade/u/home/andywood/proj/SHARP/wreg/pnnl/$basinID/calib/model/settings/"
summaOutDir="/glade/work/andywood/wreg/summa_data/pnnl/output/$basinID/calib/"
obsFlow=$homeDir'../../obs/obsflow.dly.DWRI1.cfs.csv'      # observed daily flows (csv)

# --- next settings change less frequently ---
summaExe=/glade/u/home/andywood/proj/SHARP/models/summa/bin/summa.exe
routeExe=/glade/u/home/andywood/proj/SHARP/models/routing/mizuRoute/route/bin/mizuroute.exe
summaRunoffRoot=temp-ost       # fixed filename for summa output
nCoresPerJob=1                 # splits domain into 1 gru per job for now
# ========= end User settings ===============================

# ------------------------------------------------------------------------------
# --- 4.  calculate statistics for Ostrich                                   ---
# ------------------------------------------------------------------------------
echo calculating statistics

$homeDir/scripts/calc_sim_stats.Rscr $homeDir/model/route_out/sflow.h.*.nc 'IRFroutedRunoff' $segNdx $obsFlow cfs $homeDir/test_stats.txt $statStatDate $endStatDate 

