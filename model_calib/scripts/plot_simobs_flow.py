#!/usr/bin/env python
# coding: utf-8

# Script to plot timeseries (eg simulated versus obs flow)
# Uses python3:  on cheyenne: module load python/3.6.8
#                             source /glade/u/apps/opt/ncar_pylib/ncar_pylib.csh or ncar_pylib
# source: /glade/u/home/andywood/proj/SHARP/plotting/plot_simobs_flow.py

import matplotlib
matplotlib.use('Agg')

import matplotlib.pyplot as plt
#import xarray as xr
import sys, os
import numpy as np
import pandas as pd
from scipy import stats
from netCDF4 import Dataset, num2date 
from datetime import datetime
import matplotlib.gridspec as gridspec

# --- read config file as argument if present ---
if len(sys.argv) == 2:
     configFile = sys.argv[1]
     exec(open(configFile).read())    # read config file variables
else:
     print("USAGE: %s <config file for plot script>" % sys.argv[0])
     sys.exit(0)

# --- start script --- 
print('plotting: ' + basinName)
    
# --- set dates of plot configuration file
calib_start_time = datetime.strptime(calStartTime, '%Y-%m-%d %H:%M:%S')
calib_end_time   = datetime.strptime(calEndTime, '%Y-%m-%d %H:%M:%S')
plot_start_time  = datetime.strptime(calStartTime, '%Y-%m-%d %H:%M:%S')
plot_end_time    = datetime.strptime(calEndTime, '%Y-%m-%d %H:%M:%S')

# --- read simulated flow from netcdf file (cms)
f        = Dataset(simFile)
sim_irf  = f.variables[simVarName][:,(segIndex-1)]
time_var = f.variables['time']
sim_time = num2date(time_var[:], time_var.units)
df       = pd.DataFrame(data=sim_time, dtype='str', columns=['time'])
df       = df.apply(lambda x: x.str.strip('00:00:00'))['time'].to_list()
f.close() 

# --- read observed flow from CSV file (cfs)
df_obs = pd.read_csv(obsFile, header=0, sep=',', index_col=0, parse_dates=[0],
                     keep_default_na=False, na_values=[obsVoid])
df_obs = df_obs.apply(pd.to_numeric, errors='coerce')   # convert 'str' data column to float
df_obs.rename(columns={df_obs.columns[0]:'Observed'}, inplace=True)
df_obs['Observed'] = df_obs['Observed'].div(35.315)    # convert to m^3/s
df_obs = df_obs[plotStartTime:plotEndTime]

# --- make dataframes ---
df_sim       = pd.DataFrame(data={'Simulated':sim_irf}, index=df)
df_sim.index = pd.to_datetime(df_sim.index, errors='coerce')
df_sim       = df_sim[plotStartTime:plotEndTime]    # subset daily sim to plot window

df_final     = pd.concat([df_sim, df_obs], axis=1)  # combine daily sim & obs timeseries
df_final_calib    = df_final[calStartTime:calEndTime]   # daily, calib. period only, defined in config file

df_final_WY       = df_final.resample('AS-OCT').mean()  # resampled to annual mean starting in October
df_final_calib_WY = df_final_calib.resample('AS-OCT').mean()

df_final_AJ       = df_final[(df_final.index.month>=4) & (df_final.index.month<=7)].resample('AS-OCT').mean()
df_final_calib_AJ = df_final_calib[(df_final_calib.index.month>=4) & (df_final_calib.index.month<=7)].resample('AS-OCT').mean()
df_final_M        = df_final.resample('M').mean()[df_final.resample('M').count()>=28]  # only for months with at least 28 days
df_final_MA       = df_final.groupby(df_final.index.month).mean()                     # monthly avg
df_final_MA.columns   = ['Sim (all yrs)', 'Obs (all yrs)']
df_final_calib_MA = df_final_calib.groupby(df_final_calib.index.month).mean()         # monthly avg, cal period
df_final_calib_MA.columns = ['Sim (calib)','Obs (calib)']

# --- calculate some statistics ---
# calc some statistics
corr_AJ = stats.pearsonr(df_final_AJ.iloc[:,0], df_final_AJ.iloc[:,1]) 
corr_WY = stats.pearsonr(df_final_calib_WY.iloc[:,0], df_final_calib_WY.iloc[:,1]) 
print("correlations (AJ, WY): ", corr_AJ[0], corr_WY[0])
    
# --- make plot --- 
# fig, ax = plt.subplots(4, 1)
width  = 6.5  # in inches
height = 9.0
lwd    = 0.8  # line thickness

# plot layout
print("plot layout")
fig = plt.figure()
# ax1 = plt.subplot2grid((4, 2), (0, 0), colspan=2)
# ax2 = plt.subplot2grid((4, 2), (1, 0), colspan=2)
# ax3 = plt.subplot2grid((4, 2), (2, 0), colspan=2)
# ax4 = plt.subplot2grid((4, 2), (3, 0))
# ax5 = plt.subplot2grid((4, 2), (3, 1))
# plt.subplots_adjust(wspace=0, hspace=0)

AX = gridspec.GridSpec(4,2)
AX.update(wspace = 0.5, hspace = 0.3)
ax1  = plt.subplot(AX[0,:])
ax2 = plt.subplot(AX[1,:])
ax3 = plt.subplot(AX[2,:])
ax4 = plt.subplot(AX[3,0])
ax5 = plt.subplot(AX[3,1])

# plot monthly
print("plot monthly")
df_final_M.plot(ax=ax1, figsize=(width,height), color=['red','black'], linewidth=lwd)

# plot daily calibration period
print("plot daily calibration period")
df_final_calib.plot(ax=ax2, figsize=(width,height), color=['red','black'], linewidth=lwd)

# plot monthly long term averages for period
print("plot monthly long term averages")
df_final_calib_MA.plot(ax=ax3, figsize=(width,height), color=['red','black'], linewidth=lwd)
df_final_MA.plot(ax=ax3, figsize=(width,height), color=['red','black'], linewidth=lwd, linestyle=':')

# plot scatter for water year mean flow
print("plot scatter for water year mean flow")
axmax = df_final_WY.max().max()
ax4.scatter(df_final_WY.iloc[:,0], df_final_WY.iloc[:,1], c='black', s=5)
ax4.scatter(df_final_calib_WY.iloc[:,0], df_final_calib_WY.iloc[:,1], c='red', s=10, label='Calib')
ax4.plot((0, axmax), (0, axmax), c='orange', linestyle=':')
ax4.annotate('corr: '+str(round(corr_WY[0], 3)), xy=(axmax*0.97, axmax*0.03), horizontalalignment='right')

# plot scatter for spring runoff period (Apr-Jul)
print("plot scatter for for spring runoff period")
axmax = df_final_AJ.max().max()
ax5.scatter(df_final_AJ.iloc[:,0], df_final_AJ.iloc[:,1],c='black', s=5)
ax5.scatter(df_final_calib_AJ.iloc[:,0], df_final_calib_AJ.iloc[:,1], c='red', s=10, label='Calib')
ax5.plot((0, axmax), (0, axmax), c='orange', linestyle=':')
ax5.annotate('corr: '+str(round(corr_AJ[0], 3)), xy=(axmax*0.97, axmax*0.03), horizontalalignment='right')
    
# other plot details
print("other plot details")
ax1.axvline(x=calib_start_time, color='grey', linewidth=0)
ax1.axvline(x=calib_end_time, color='grey', linewidth=0)
ax1.axvspan(calib_start_time, calib_end_time, color='grey', alpha=0.2, label='Calib Period')
ax1.set_ylabel('Flow, Monthly (cms)')
ax2.set_ylabel('Flow, Daily (cms)')
ax3.set_ylabel('Flow, Monthly (cms)')
ax3.set_xlabel('Calendar Month')
ax4.set_ylabel('WY Obs (cms)')
ax4.set_xlabel('WY Sim (cms)')
ax5.set_ylabel('Apr-Jul Obs (cms)')
ax5.set_xlabel('Apr-Jul Sim (cms)')
ax1.legend(loc='upper right')
ax2.legend().remove()
ax3.legend(loc='upper right')
ax4.legend()
# ax5.legend().remove()
ax1.set_title('Streamflow: ' + basinName + ' ' + ofileBasename, fontsize='medium',weight='semibold')

# --- save plot
print("save plot")
if not os.path.exists(outDir):
    os.makedirs(outDir)
plotFname=os.path.join(outDir, basinName + '_' + ofileBasename + '_hydrograph.png')
plt.savefig(plotFname, dpi=80)
print('Created figure' + plotFname)

