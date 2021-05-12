# Combine split domain state files (with 2 dimensions, hru and gru)
# A. Wood 2020
# use built-in env containing xarray, pandas, dask (optional)
# eg on cheyenne: module load python/3.6.8; ncar_pylib
#     or source /glade/u/apps/opt/ncar_pylib/ncar_pylib.csh (alt to ncar_pylib)
# -----------------------------------------------

import sys, glob

# --------- arguments -----------
print("found %d args" % len(sys.argv))
if len(sys.argv) == 5:
    stateFileRoot = sys.argv[1]     # eg './hstate/wbout_restart_'
    startDate     = sys.argv[2]     # eg '19910301'
    endDate       = sys.argv[3]     # eg '19920301'
    Freq          = sys.argv[4]     # D (daily) or MS (monthly)
else:
    print("USAGE: %s input_filepath/root startdate(YYYYMMDD) enddate frequency_of_states(D or MS)" % sys.argv[0])
    sys.exit(0)

# now import slower-loading packages if args were ok
import pandas as pd
import xarray as xr
#import dask     # use if not on a shared compute resource
#from dask.distributed import Client  (only if using parallellism)

# --------- code -----------
# set templates for filename creation & globbing (can be args too)
outFnameTemplate = stateFileRoot+'{0!s}00.nc'

# the next line enables parallel reads, but it's fast without them
# client = Client() # this registers some stuff behind the scenes.  
                    # print it (`print(client)`) to see what comp. resources are available. 

# create state date vector and loop over it to merge files
stateDates = (pd.date_range(start=startDate,end=endDate,freq=Freq)).strftime('%Y%m%d')

for sd in stateDates:
    print("working on state date " + sd)

    output_file_list = glob.glob(stateFileRoot+sd+'00_G*.nc')
    output_file_list.sort()
    if len(output_file_list) == 0:
        print('No files found matching pattern: '+stateFileRoot+sd+'00_G*.nc')
        exit(0)

    out_ds   = [xr.open_dataset(f) for f in output_file_list]
    hru_vars = [] # variables that have hru dimension
    gru_vars = [] # variables that have gru dimension

    for name, var in out_ds[0].variables.items():
        if 'hru' in var.dims:
            hru_vars.append(name)
        elif 'gru' in var.dims:
            gru_vars.append(name)

    hru_ds = [ds[hru_vars] for ds in out_ds]
    gru_ds = [ds[gru_vars] for ds in out_ds]
    hru_merged = xr.concat(hru_ds, dim='hru')
    gru_merged = xr.concat(gru_ds, dim='gru')
    merged_ds  = xr.merge([hru_merged, gru_merged])
    
    merged_ds.load().to_netcdf(outFnameTemplate.format(sd))
    
print("DONE:  Last wrote %s" % outFnameTemplate.format(sd))



