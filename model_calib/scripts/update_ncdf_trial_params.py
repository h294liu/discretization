# -*- coding: utf-8 -*-
"""  @author(s): hongli liu, andy wood, may 2020 
     update netcdf trialparameter values using ostrich estimates
     has some built in assumptions about file/dir conventions
"""
# need python3 - on cheyenne: : module load python/3.6.8; ncar_pylib

import numpy as np
from netCDF4 import Dataset
from shutil import copyfile
import os,sys

# ---- USER setting (could make arg as csvlist) ----
direct_param_list = ['']       # not calib by multiplier

# ---- check args first ----
if len(sys.argv) != 4:
    print("Usage: %s <case_label> <calib_dir> <model_dir>" % sys.argv[0])
    sys.exit(0)
# otherwise continue
case_label = sys.argv[1]    # label that will be used to keep multiple basins separate in some cases
calib_dir  = sys.argv[2]    # directory where Ostrich exe and associated files sit (must have "/")
model_dir  = sys.argv[3]    # calibration directory where trial params sit (must have "/")

# ---- assumed file path settings ----
param_txtfile_tpl    = os.path.join(calib_dir,'tpl','nc_multiplier.2.tpl')  # input static template
param_txtfile_ost    = os.path.join(calib_dir,'nc_multiplier.txt')          # input updated by ostrich
param_pattern_ncfile = os.path.join(model_dir,'settings','trialParams.'+case_label+'.pattern.nc')  # input a priori params
param_trial_ncfile   = os.path.join(model_dir,'settings','trialParams.'+case_label+'.nc') # output test params

print("\nUpdating parameters in %s\n" % param_trial_ncfile)

# read param names in string format
var_names   = []
param_names = []
with open (param_txtfile_tpl, 'r') as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('!') and not line.startswith("'"):
            splits = line.split('|')
            if isinstance(splits[1].strip(), str):
                var_names.append(splits[0].strip())
                param_names.append(splits[1].strip())
                
# read new param multiplier values in float format
param_values=[]
with open (param_txtfile_ost, 'r') as f:
    for line in f:
        line=line.strip()
        if line and not line.startswith('!') and not line.startswith("'"):
            splits=line.split('|')
            if splits[0].strip() in var_names:
                param_values.append(float(splits[1].strip()))

# apply multipliers to existing HRU values
copyfile(param_pattern_ncfile, param_trial_ncfile)

dataset_pattern = Dataset(param_pattern_ncfile,'r+')    # open original params
dataset         = Dataset(param_trial_ncfile,'r+')      # open output params

for i in range(len(var_names)):
    var_name = var_names[i]
    
    if var_name in dataset.variables.keys():                  # new_value = multipler * default_value
        if not var_name in direct_param_list:
            marr      = dataset.variables[var_name][:]
            arr_value = marr.data * param_values[i]
            dataset.variables[var_name][:] = np.ma.array(arr_value, mask=np.ma.getmask(marr), fill_value=marr.get_fill_value())
        elif var_name in direct_param_list:                   # new_value = Ostrich value
            marr      = dataset.variables[var_name][:]
            arr_value = np.ones_like(marr.data) * param_values[i]
            dataset.variables[var_name][:] = np.ma.array(arr_value, mask=np.ma.getmask(marr), fill_value=marr.get_fill_value())
        
    # if one of the calibration variables is 'thickness', use it to calculate TopCanopyHeight
    if var_name == 'thickness':
        tied_var_name   = 'heightCanopyBottom'
        target_var_name = 'heightCanopyTop'

        # update TopCanopyHeight
        TH_marr_pattern = dataset_pattern.variables[target_var_name][:]         # default TopCanopyHeight mask array # Hongli CHANGE
        BH_marr_pattern = dataset_pattern.variables[tied_var_name][:]           # default BottomCanopyHeight mask array # Hongli CHANGE
        BH_marr         = dataset.variables[tied_var_name][:]                           # updated BottomCanopyHeight mask array
        arr_value       = BH_marr.data + (TH_marr_pattern.data-BH_marr_pattern.data)*param_values[i]    # updated TopCanopyHeight values
        dataset.variables[target_var_name][:] = np.ma.array(arr_value, mask=np.ma.getmask(TH_marr_pattern), fill_value=TH_marr_pattern.get_fill_value())
                
dataset.close() 
dataset_pattern.close()
