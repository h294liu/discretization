#!/bin/bash
set -e 

# ========== User settings ==================================
basin=06279940
root_dir=/glade/u/home/hongli/scratch/2020_06_02HRUcomplexity/model

model_dir=${root_dir}/$basin  # model directory
if [ ! -d $model_dir/run ]; then echo $model_dir does not exist; fi

log_dir=${model_dir}/run/logs
if [ ! -d $log_dir ]; then mkdir -p $log_dir; fi

level_num=3                   # total number of discretization complexities
label_basename=hru_lev        # label basename for spatial discretization

# model run inputs
summaStart="1970-03-01 03:00"  # summa start time 
summaEnd="2019-12-31 24:00"    # summa end time
routeStart="1970-03-02"        # route start time  
routeEnd="2019-12-31"          # route end time
Ngru=18                        # number of GRUs
summaRunoffRoot=wbout          # fixed filename for summa output

# statistics inputs
seg_id=11       # index of seg_id=74016593. Index starts from one. 
obsFlow=/glade/u/home/hongli/scratch/2020_06_02HRUcomplexity/calib/obs/obs_flow.$basin.cfs.csv # observed daily flows
startStatDate="1970-03-02" # start date for calculating statistics "2007-10-01" 
endStatDate="2019-12-31"   # end date for calculating statistics "2019-12-31"

# configration and scripts sources
source_dir=/glade/u/home/hongli/github/2020_06_02HRUcomplexity/3_model_calib  # source code dir
config_dir=$source_dir/config                 # config dir
summa_config_tpl=$config_dir/fileManager.txt  # summa config file
route_config_tpl=$config_dir/control.txt      # route config file
run_model_tpl=$config_dir/run_model.sh        # run_model config file
submit_tpl=$config_dir/submit_run_model.sh    # sumbit job config file

# ========== end User settings ==================================

for level_id in $(seq 0 ${level_num}); do
    label=${label_basename}${level_id}
    echo $label

    # === PART 0.create links
    # (1) link scripts, tpl and config folders
    for folder in scripts config; do
        if [ ! -L $model_dir/$folder ]; then ln -s $source_dir/$folder $model_dir/; fi
    done
    
    # (2) create link for initial condition file 
    outputPath=$model_dir/output/${label}/
    if [ ! -d $outputPath ]; then mkdir -p $outputPath; fi
    initConditionFile=coldState.3l3h_100cm.${label}.nc
    if [ ! -L $outputPath/$initConditionFile ]; then 
        ln -s $model_dir/settings/$initConditionFile $outputPath/
    fi

    # === PART 1. Update model config files ====
    # (1) define summa_config and route_config
    summa_config=$model_dir/run/fileManager.${label}.txt
    route_config=$model_dir/run/control.${label}.txt
    cp -rfp ${summa_config_tpl} ${summa_config}
    cp -rfp ${route_config_tpl} ${route_config}

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
    # (1) define run_model and qsub
    run_model_sh=$model_dir/run/run_model.${label}.sh
    qsub_sh=$model_dir/run/qsub.${label}.sh
    log_ofile_base=$log_dir/${label}
    job_name=${basin}_${level_id}
    
    cp -rfp ${run_model_tpl} ${run_model_sh}
    cp -rfp ${submit_tpl} ${qsub_sh}

    # (2) update run_model.sh
    sed -i "s~LABEL~${label}~g" $run_model_sh
    sed -i "s~SEG_ID~${seg_id}~g" $run_model_sh
    sed -i "s~NGRU~${Ngru}~g" $run_model_sh
    sed -i "s~CALIBDIR~${calib_dir}~g" $run_model_sh
    sed -i "s~MODELDIR~${model_dir}~g" $run_model_sh
    sed -i "s~SUMMARUNOFFROOT~${summaRunoffRoot}~g" $run_model_sh
    sed -i "s~SIM_START~${routeStart}~g" $run_model_sh
    sed -i "s~OBSFILOW~${obsFlow}~g" $run_model_sh
    sed -i "s~STARTSTATDATE~${startStatDate}~g" $run_model_sh
    sed -i "s~ENDSTATDATE~${endStatDate}~g" $run_model_sh
    
    # (3) update submit.sh
    sed -i "s~JOB_NAME~${job_name}~g" $qsub_sh
    sed -i "s~OUT_FILE~${log_ofile_base}~g" $qsub_sh
    sed -i "s~RUN_MODEL_FILE~${run_model_sh}~g" $qsub_sh

     #(4) submit job
    cd $model_dir
    qsub $qsub_sh
    cd $root_dr
done