# concatenate the outputs of a split domain summa run
# written originally by Manab Saharia, updated by Andy Wood and Hongli Liu
#
# on cheyenne, need:  module load python/3.6.8; ncar_pylib (or equivalent env)
# 
# INPUTS:  directory of split output files, and output path/filename

import sys
import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)
import os
from glob import glob
import netCDF4 as nc
import numpy as np

# --- check args
if len(sys.argv) != 3:
    print("Usage: %s <summa_output_dir> <summa_output_file>" % sys.argv[0])
    sys.exit(0)
# otherwise continue
ncdir              = sys.argv[1]  # eg './v1/06280300/'
merged_output_file = sys.argv[2]  # eg 'gage_06280300_day.nc'

# get list of split summa output files (hardwired pattern)
outfilelist = glob((ncdir+'/*_G*_day.nc'))    # assumes daily outputs
outfilelist.sort()   # not needed, perhaps

# count the number of gru and hru
gru_num = 0
hru_num = 0
for file in outfilelist:
    # f = nc.Dataset(os.path.join(ncdir, file))
    f = nc.Dataset(file)
    gru_num = gru_num+len(f.dimensions['gru'])
    hru_num = hru_num+len(f.dimensions['hru'])

# write output    
# with nc.Dataset(os.path.join(ncdir, outfilelist[0])) as src:
with nc.Dataset(outfilelist[0]) as src:
    with nc.Dataset(merged_output_file, "w") as dst:

        # copy dimensions
        for name, dimension in src.dimensions.items():
            if name == 'gru':
                dst.createDimension(name, gru_num)
            elif name == 'hru':
                dst.createDimension(name, hru_num)
            else:
                dst.createDimension(name, (len(dimension) if not dimension.isunlimited() else None))

        # copy variable attributes all at once via dictionary
        gru_vars = [] # variable name, gru axis in variable dimension for concatenation. 
        hru_vars = []
        for name, variable in src.variables.items():
            x = dst.createVariable(name, variable.datatype, variable.dimensions)               
            dst[name].setncatts(src[name].__dict__)
            # Note here the variable dimension name is the same, but size has been updated for gru and hru.
            
            # Assign different values depending on dimension
            dims = variable.dimensions
            if 'gru' in dims:
                gru_vars.append([name,dims.index('gru')])                
            elif 'hru' in dims:
                hru_vars.append([name,dims.index('hru')]) 
            else:
                dst[name][:]=src[name][:]                

        # read values for gru and hru dimensioned variables
        Dict = {} 
        gru_vars_num = len(gru_vars)
        hru_vars_num = len(hru_vars)
        for i,file in enumerate(outfilelist):
            
            print("combining file %d %s" % (i,file))
            # f = nc.Dataset(os.path.join(ncdir, file))
            f = nc.Dataset(file)
            for j in range(gru_vars_num):
                gru_var_name = gru_vars[j][0]
                dim_index = gru_vars[j][1]
                data=f[gru_var_name][:]
                if i == 0:
                    Dict[gru_var_name]=data
                else:
                    Dict[gru_var_name]=np.concatenate((Dict[gru_var_name],data),axis=dim_index)

            for j in range(hru_vars_num):
                hru_var_name = hru_vars[j][0]
                dim_index = hru_vars[j][1]
                data=f[hru_var_name][:]
                if i == 0:
                    Dict[hru_var_name]=data
                else:
                    Dict[hru_var_name]=np.concatenate((Dict[hru_var_name],data),axis=dim_index)
                    
        # assign values for gru and hru dimensioned variables
        for j in range(gru_vars_num):
            dst.variables[gru_vars[j][0]][:] = Dict[gru_vars[j][0]]
        for j in range(hru_vars_num):
            dst.variables[hru_vars[j][0]][:] = Dict[hru_vars[j][0]]
                   
print("wrote output: %s\nDone" % merged_output_file) 
