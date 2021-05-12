#!/bin/bash
set -e 
# make model directory for calibration use based on the reference model directory

# ========== User settings ==================================
basin=06279940
root_dir=/glade/u/home/hongli/scratch/2020_06_02HRUcomplexity/calib/$basin # calib parent dir
if [ ! -d $root_dir ]; then mkdir -p $root_dir; fi

model_dir=$root_dir/model    # model directory for calib
if [ ! -d $model_dir ]; then mkdir -p $model_dir; fi

level_num=3             # total number of discretization complexities
label_basename=hru_lev  # label basename for spatial discretization

# model run inputs
summaStart="2006-10-01 03:00"  # summa start time
summaEnd="2007-10-01 00:00"    # summa end time
routeStart="2006-10-02"        # route start time
routeEnd="2007-09-30"          # route end time
Ngru=18                        # number of GRUs
summaRunoffRoot=wbout          # fixed filename for summa output
restartDateSumma="2007-10-01"  # summa re-start date used in merge_summa_statefiles.new.py

# configration and scripts sources
config_dir=/glade/u/home/hongli/github/2020_06_02HRUcomplexity/3_model_calib/config # config dir
summa_config_tpl=$config_dir/fileManager.txt      # summa config file
route_config_tpl=$config_dir/control_spinup.txt   # route config file
run_model_tpl=$config_dir/run_model_spinup.sh     # run_model config file
submit_tpl=$config_dir/submit_run_model_spinup.sh # sumbit job config file

# ========== end User settings ==================================

for level_id in $(seq 0 ${level_num}); do
    label=${label_basename}${level_id}

    # === PART 1. Update model config files ====
    # (1) define summa_config and route_config
    summa_config=$model_dir/run/fileManager.${label}.txt
    route_config=$model_dir/run/control.${label}.txt    
    cp -rp ${summa_config_tpl} ${summa_config}
    cp -rp ${route_config_tpl} ${route_config}

    # (2) update summa_config
    settingsPath=$model_dir/settings/
    forcingPath=$model_dir/forcings/summa_3hr_${label}/
    outputPath=$model_dir/output/${label}/
    if [ ! -d $outputPath ]; then mkdir -p $outputPath; fi
    initConditionFile=coldState.3l3h_100cm.${label}.nc
    
    sed -i "s~SIMSTARTTIME~${summaStart}~g" $summa_config
    sed -i "s~SIMENDTIME~${summaEnd}~g" $summa_config
    sed -i "s~SETTINGSPATH~${settingsPath}~g" $summa_config
    sed -i "s~FORCINGPATH~${forcingPath}~g" $summa_config
    sed -i "s~OUTPUTPATH~${outputPath}~g" $summa_config
    sed -i "s~LABEL~${label}~g" $summa_config
    sed -i "s~INITCONDITIONFILE~${initConditionFile}~g" $summa_config

    # (3) update route_config
    ancil_dir=$model_dir/route_input/
    input_dir=$model_dir/output/${label}/ 
    output_dir=$model_dir/route_output/
    if [ ! -d $output_dir ]; then mkdir -p $output_dir; fi

    sed -i "s~LABEL~${label}~g" $route_config
    sed -i "s~SIM_START~${routeStart}~g" $route_config
    sed -i "s~SIM_END~${routeEnd}~g" $route_config
    sed -i "s~ANCIL_DIR~${ancil_dir}~g" $route_config
    sed -i "s~INTPUT_DIR~${input_dir}~g" $route_config
    sed -i "s~OUTPUT_DIR~${output_dir}~g" $route_config
    
    # === PART 2. Update model run files ====
    calib_dir=$root_dir/$label # calib parent directory
    if [ ! -d $calib_dir ]; then mkdir -p $calib_dir; fi

    # (1) define summa_config and route_config
    run_model_sh=$calib_dir/run_model_spinup.sh    
    qsub_sh=$calib_dir/submit_run_model_spinup.sh    
    job_name=${basin}_${level_id}
    log_ofile_base=$calib_dir/${label}_spinup

    cp -rf ${run_model_tpl} ${run_model_sh}
    cp -rf ${submit_tpl} ${qsub_sh}

    # (2) update run_model_spinup.sh
    sed -i "s~LABEL~${label}~g" $run_model_sh
    sed -i "s~NGRU~${Ngru}~g" $run_model_sh
    sed -i "s~CALIBDIR~${calib_dir}~g" $run_model_sh
    sed -i "s~MODELDIR~${model_dir}~g" $run_model_sh
    sed -i "s~SUMMARUNOFFROOT~${summaRunoffRoot}~g" $run_model_sh
    sed -i "s~SIM_START~${routeStart}~g" $run_model_sh
    sed -i "s~STATEDATE~${restartDateSumma}~g" $run_model_sh

    # (3) update submit.sh
    sed -i "s~JOB_NAME~${job_name}~g" $qsub_sh
    sed -i "s~OUT_FILE~${log_ofile_base}~g" $qsub_sh
    sed -i "s~RUN_MODEL_FILE~${run_model_sh}~g" $qsub_sh

    # (4) submit job
    cd $calib_dir
    qsub $qsub_sh
    cd $root_dir
done


echo Done