#!/bin/bash
set -e 
# make model directory for calibration use based on the reference model directory

# ========== User settings ==================================
basin=06279940
ref_model_dir=/glade/u/home/hongli/scratch/2020_06_02HRUcomplexity/model/$basin # reference hydro model dir
root_dir=/glade/u/home/hongli/scratch/2020_06_02HRUcomplexity/calib/$basin # calib parent dir
if [ ! -d $root_dir ]; then mkdir -p $root_dir; fi

model_dir=$root_dir/model    # model directory for calib
if [ ! -d $model_dir ]; then mkdir -p $model_dir; fi

level_num=3             # total number of discretization complexities
label_basename=hru_lev  # label basename for spatial discretization
source_dir=/glade/u/home/hongli/github/2020_06_02HRUcomplexity/3_model_calib
ostrichExe=/glade/u/home/andywood/proj/SHARP/calib/Ostrich/OstrichGCC

# ========== end User settings ==================================

##=== PART 1. Create model based on ref_model_dir ====
# (1) link two folders to reference model
for folder in forcings route_input; do
    # test if this link exists
    if [[ -L $model_dir/$folder && -d $model_dir/$folder ]]; then rm $model_dir/$folder; fi
    ln -s -f $ref_model_dir/$folder $model_dir/
done

# (2) copy folders from reference model
for folder in settings run; do
    if [ -d $model_dir/$folder ]; then rm -r $model_dir/$folder; fi
    cp -r -RP $ref_model_dir/$folder $model_dir/
done

# (3) create empty folders
for folder in output route_output; do
    if [ -d $model_dir/$folder ]; then rm -r $model_dir/$folder; fi
    mkdir -p $model_dir/$folder
done
if [ ! -d $model_dir/analysis ]; then mkdir -p $model_dir/analysis; fi

##=== PART 2. Create calib folders ====
for level_id in $(seq 0 ${level_num}); do
    label=${label_basename}${level_id}

    # (1) creat hru level denpendent calibration dir
    calib_dir=$root_dir/$label # loc. of Ostrich.exe
    if [ ! -d $calib_dir ]; then mkdir -p $calib_dir; fi
    
    # (2) link scripts, tpl and config folders
    for folder in scripts tpl config; do
        if [ ! -L $calib_dir/$folder ]; then ln -s $source_dir/$folder $calib_dir/; fi
    done
    
    # (3) link Ostrich executable
    if [ ! -L $calib_dir/Ostrich.exe ]; then ln -s $ostrichExe $calib_dir/Ostrich.exe; fi
    
    # (4) create pattern trialParam file
    # Note: pattern trialParam works as the reference and is used to update trial param.
    cp $model_dir/settings/trialParams.${label}.nc $model_dir/settings/trialParams.${label}.pattern.nc 

    # (5) create link for initial condition file 
    outputPath=$model_dir/output/${label}/
    if [ ! -d $outputPath ]; then mkdir -p $outputPath; fi
    initConditionFile=coldState.3l3h_100cm.${label}.nc
    if [ ! -L $outputPath/$initConditionFile ]; then 
        ln -s $model_dir/settings/$initConditionFile $outputPath/
    fi
done

# (5) remove useless files in run --- 
rm -f $model_dir/run/qsub.*.sh
rm -f $model_dir/run/*.submit*
rm -f $model_dir/run/config
rm -r $model_dir/run/aw_reference
rm -r $model_dir/run/diag
rm -r $model_dir/run/logs

echo Done