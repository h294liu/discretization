#!/bin/bash
set -e 

# ========== User settings ==================================
# model inputs
root_dir=/glade/u/home/hongli/scratch/2020_06_02HRUcomplexity/model
basin=06279940
seg_id=11       #index of seg_id=74016593. Index starts from one. 
model_dir=$root_dir/$basin # model directory

# hru inputs
level_num=3                  # total number of discretization complexities
label_basename=hru_lev       # label basename for spatial discretization

# plot inputs
python=/glade/u/home/hongli/tools/miniconda3/bin/python
python_ncar=/glade/u/apps/ch/opt/python/2.7.16/gnu/8.3.0/pkg-library/20190627/bin/python
code_dir=/glade/u/home/hongli/github/2020_06_02HRUcomplexity/3_model_calib/scripts
plot_code=$code_dir/plot_simobs_flow.py
plot_config_tpl=$code_dir/plot_simobs_flow.cfg
plotStart=2000-10-01
plotEnd=2017-09-30

out_dir=$root_dir/$basin/analysis/4_plot_simobs_flow   # plot output dir
if [ ! -d $out_dir ]; then mkdir -p $out_dir; fi

# ========== end User settings ==================================

for level_id in $(seq 0 ${level_num}); do
    label=${label_basename}${level_id}
    echo $label

    # === PART 1. define complexity level-based file ===
    plot_config=$out_dir/simobs_flow_plot.${label}.cfg
    cp -rP ${plot_config_tpl} ${plot_config}

    # === PART 2. update plot_config ===
    obsFile=$root_dir/obs/obs_flow.${basin}.cfs.csv
    simFile=$model_dir/route_output/sflow.${label}.h.1970-03-02-00000.nc
    sed -i "s~OBSFILE~${obsFile}~g" $plot_config
    sed -i "s~SIMFILE~${simFile}~g" $plot_config
    sed -i "s~OUTDIR~${out_dir}~g" $plot_config
    sed -i "s~BASIN~${basin}~g" $plot_config
    sed -i "s~LABEL~${label}~g" $plot_config
    sed -i "s~SEGINDEX~${seg_id}~g" $plot_config
    sed -i "s~PLOTSTARTDATE~${plotStart}~g" $plot_config
    sed -i "s~PLOTENDDATE~${plotEnd}~g" $plot_config

    # === PART 3. plot ===
    $python_ncar $plot_code $plot_config
done