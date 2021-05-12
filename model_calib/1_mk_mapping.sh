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
module load R

# 3. run 
basin=06279940
label_basename=hru_lev    # label basename for spatial discretization
level_num=3               # total number of discretization complexities

root_dir=/glade/u/home/hongli/scratch/2020_06_02HRUcomplexity/model
p2p_dir=${root_dir}/prep/p2p    # p2p directory
python_ncar=/glade/u/apps/ch/opt/python/2.7.16/gnu/8.3.0/pkg-library/20190627/bin/python

if [ ! -d ${p2p_dir}/shapes/$basin ]; then mkdir ${p2p_dir}/shapes/$basin; fi
cd ${p2p_dir}

for i in $(seq 0 ${level_num}); do
# for i in $(seq 0 0); do
    label=${label_basename}${i}
    echo $label

#     # === first create hru.gpkg from hru.shp (if needed)
#     module unload netcdf
#     module load gdal
#     ogr2ogr -f GPKG [gpkg_file].gpkg [shape_file].shp

    # === make the spatial weights file 
    # arguments:  target_polygon_gpkg target_ID source_polygon_gpkg source_ID \
    # [optional arg to output lat/lon & i/j index if present] output_spw_file
    
    target_polygon=./shapes/$basin/${label}_elmn.gpkg
    target_fieldname=hruId
    
    # NLDAS->HRU (for mapping nldas params)
    $python_ncar poly2poly/poly2poly.i_j_version.v4.py $target_polygon $target_fieldname \
    /glade/work/andywood/wreg/gis/grids/nldas_hruId_masked.gpkg hru_id GRIDLL \
    ./maps/spweights.nldas125_to_$label.$basin.nc

    # basin HUC12 -> HRU (alternative for mapping forcings)
    $python_ncar poly2poly/poly2poly.i_j_version.v4.py $target_polygon $target_fieldname \
    /glade/work/andywood/wreg/gis/shapes/bighorn/06279940.huc12.gpkg HUCIDXint \
    ./maps/spweights.hucIDx_to_$label.$basin.nc
    
#     # GMET->HRU (for mapping forcings)
#     $python_ncar poly2poly/poly2poly.i_j_version.v4.py $target_polygon $target_fieldname \
#       /glade/work/andywood/wreg/gis/grids/WEST.elev.125.gpkg id GRID \
#       ./maps/spweights.west_gmet125_to_$label.$basin.nc

#     # Westwide HUC12 -> HRU (alternative for mapping forcings)
#     $python_ncar poly2poly/poly2poly.i_j_version.v4.py $target_polygon $target_fieldname \
#     /glade/work/andywood/wreg/gis/shapes/wUShuc12/wUS_HUC12_ext_v4.simpl-0.002.gpkg HUCIDXint \
#       ./maps/spweights.wUShuc12_to_$label.$basin.nc

    # === Re-order polygid based on hruId in shapefile
    Rscript reorder_sp_weights.Rscr hruIds.lev${i}.srt.txt ./maps/spweights.nldas125_to_$label.$basin.nc ./maps/spweights.nldas125_to_$label.$basin.reorder.nc

    Rscript reorder_sp_weights.Rscr hruIds.lev${i}.srt.txt ./maps/spweights.hucIDx_to_$label.$basin.nc ./maps/spweights.hucIDx_to_$label.$basin.reorder.nc
done

