#!/bin/bash
set -e

# Commands to create spatial weights file
# A. Wood, H. Liu, 2021
# Cannot be run on the master node because it's a parallel process (will take all cores)
# Typical run is to either to start an interactive node with 36 processors, or 
#   start a terminal in a Jupyterhub session (with 36 processors, 48gb memory)

# # 1. start interactive job
# qsub -X -I -l select=1:ncpus=36:mpiprocs=36 -l walltime=02:00:00 -q regular -A P48500028

# # 2. set up environment
module load python/2.7.16
module load ncarenv
ncar_pylib
module load nco  

# 3. run 
basin=06279940
label_basename=hru_lev    # label basename for spatial discretization
level_num=3               # total number of discretization complexities

root_dir=/glade/u/home/hongli/scratch/2020_06_02HRUcomplexity/model
p2p_dir=${root_dir}/prep/p2p    # p2p directory
model_dir=${root_dir}/$basin    # model directory. existing GRU=HRU run directory (contains settings/)
python_ncar=/glade/u/apps/ch/opt/python/2.7.16/gnu/8.3.0/pkg-library/20190627/bin/python

cd ${p2p_dir}
for i in $(seq 0 ${level_num}); do
# for i in $(seq 0 0); do
    label=${label_basename}${i}
    echo $label
    
    sp_weights=./maps/spweights.nldas125_to_$label.$basin.reorder.nc
    attribFile=$model_dir/settings/attributes.$label.nc
    shapeFile=./shapes/$basin/${label}_elmn.gpkg   
    origParamFile=$model_dir/settings/trialParams.ost.nc
    
    inForcDir=/glade/work/andywood/wreg/summa_data/bighorn/forcings2/$basin/
    outForcDir=$model_dir/forcings/summa_3hr_$label/
    spwFile2=./maps/spweights.hucIDx_to_$label.$basin.reorder.nc
    idMapFile=./apply_scr/idMap.hruId_to_dataNdx.$basin.txt
    
    ## --- PART 1. make the spatial weights file ---  
    # see instructions in 1_mk_mapping.sh

    # set number of HRUs in spatial weights (for scripts below)
    # ncks $sp_weights: print out the full content of $sp_weights
    # $1: the contents of the first column of the ncks output
    # if($1~"polyid"): find the line whose first column content partially matches the pattern or includes the word "polyid"
    # print $3-1: print the number of polyid after minus one since variable starts from zero in bash
    nHru=$(ncks $sp_weights | awk '{if($1~"polyid"){print $3-1;exit}}')

    # clean up (after checking)
    rm ./tmp/*

    ## --- PART 2. attributes --- 
    $python_ncar ./apply_scr/poly2poly.map_vector_attributes.py $sp_weights \
      /glade/u/home/andywood/proj/aist/nldas/summa/settings.LIS_NLDAS_v2/attributes.nc ./tmp/tmpatt.nc int \
      ./apply_scr/IDMap.hruId_2_ncIndex.nldas.swne.txt 0 $nHru

    # update hru2gruId in attributes and add gruId
    $python_ncar ./apply_scr/update_attrib_file.py ./tmp/tmpatt.nc ./tmp/tmpatt2.nc
    ncatted -O -h -a long_name,gruId,c,c,"ID for grouped response unit (GRU)" ./tmp/tmpatt2.nc
    ncatted -O -h -a long_name,hru2gruId,c,c,"ID of GRU to which HRU belongs" ./tmp/tmpatt2.nc
    
    # create or update default 'aspect' attribute
    ncap2 -O -h -s 'aspect=latitude*0-1.0' ./tmp/tmpatt2.nc $attribFile
    ncatted -O -h -a long_name,aspect,o,c,'Mean azimuth of HRU in degrees E of N' $attribFile
    ncatted -O -h -a units,aspect,o,c,degrees $attribFile

    # now update attributes with shapefile values (writes in settings dir)
    attribFileShort="${attribFile/.nc/}"
    $python_ncar ./apply_scr/insert_shapefile_attributes.py $shapeFile $attribFile $attribFileShort.updated.nc

    # --- PART 3. trialparams (hru_only) --- 
    # makes an individual file for each parameter (can be a split run across 1000s of params)
    $python_ncar ./apply_scr/poly2poly.map_vector_trialparams_SG.py $sp_weights \
      /glade/u/home/andywood/proj/aist/nldas/summa/settings.LIS_NLDAS_v2/trialParams.nc  \
      ./tmp/trialParams.$label.nc int ./apply_scr/IDMap.hruId_2_ncIndex.nldas.swne.txt 0 $nHru \
      ./apply_scr/trialParamList.hru_only.txt

    # combine separate hru param files into one
    lastParam=$(ls ./tmp/trialParams.*.nc.* | tail -n 1)   
    lastParamShort="${lastParam%.*}" # strip extension to get target file
    cp $lastParam $lastParamShort   
    for F in ./tmp/trialParams.*.nc.*; do
      echo appending $F
      ncks -A -h $F $lastParamShort   # append all indiv param files into last one
    done
    #cp -f $lastParamShort ./tmp/trialParams.$label.nc

    # trialparams (copy gru variables from original trialparam file)
    ncks -h -O -v routingGammaScale,routingGammaShape $origParamFile ./tmp/gruParams.nc
    # append gru params to hru params
    ncks -A -h ./tmp/gruParams.nc ./tmp/trialParams.$label.nc   
    # copy updated param and attribute files to settings dir
    cp ./tmp/trialParams.$label.nc  $model_dir/settings/

    ## --- PART 4. make cold state
    $python_ncar gen_coldstate.py $model_dir/settings/attributes.$label.nc \
      $model_dir/settings/coldState.3l3h_100cm.$label.nc int64 

    ## --- PART 5. forcings --- 
    # Usage: apply_scr/p2p.map_vector_ts.nldas.py -[h] <weight_netCDF> <input_netCDF> <output_netCDF>
    #               <hru_type (int or str)> <id_mapping_file.txt>

    mkdir -p $outForcDir
    for Yr in $(seq 1970 2019); do
        echo " "; echo "---------"; echo "mapping "$Yr
        inForcFile=$inForcDir/ens_forc.$basin.huc12.$Yr.001.nc
        outForcFile=$outForcDir/ens_forc.$basin.huc12.$Yr.001.nc
        $python_ncar apply_scr/p2p.map_vector_ts.summa.py $spwFile2 $inForcFile $outForcFile int64 $idMapFile 0 $nHru
    done
done