#!/bin/bash

# Script to upscale daily data from 0.25 to 0.5 degree resolution for a given year and variable
# Usage: ./get_0p5deg.sh <year> <variable>

# Check if year and variable arguments are provided
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Error: Year and/or variable not specified."
  echo "Usage: ./get_0p5deg.sh <year> <variable>"
  exit 1
fi

# Define year and variable
year=$1
var=$2

echo "Upscaling variable: $var for year: $year"

# Set paths
idir="/Data/thanasis/WMO/ERA5/derived/$year/daily/"
odir="/Data/thanasis/WMO/ERA5/daily_0p5deg/$year/"
[ ! -d $odir ] && mkdir -p $odir

# Define the grid description and remap weights file paths
griddes="/home/thanasis/WMO/regrid_0p5deg/ERA5-0p5deg.griddes"
remapweights="/home/thanasis/WMO/regrid_0p5deg/remapweights.0p5deg.from.0p25deg.nc4"

# Define input file for the year
ifile="${var}_day_ERA5_${year}0101-${year}1231.nc"

# Generate remap weights if necessary
if [ $idir/$ifile -nt $remapweights ]; then
  echo "Generating remap weights..."
  cdo -f nc4c -z zip gencon,$griddes $idir/$ifile $remapweights
fi

# Create the output file name
ofile="era5_obsclim_${var}_global_daily_${year}_${year}.nc"

# Perform the remapping
echo "Remapping data from 0.25 to 0.5 degree resolution for $year..."
cdo -O -f nc4c -z zip_6 remap,$griddes,$remapweights $idir/$ifile $odir/$ofile

# Check if the remapping process was successful
if [ $? -ne 0 ]; then
  echo "Error: Remapping operation failed for $var in $year. Exiting..."
  exit 1
fi

# Edit attributes to match the new resolution and standards
echo "Editing NetCDF attributes..."
ncatted -h \
-a long_name,lat,o,c,"Latitude" \
-a long_name,lon,o,c,"Longitude" \
-a title,global,o,c,"ERA5 global meteorological forcing data processed based ISIMIP2 standards" \
-a history,global,d,, \
$odir/$ofile

# Final verification of the output file
# echo "Final verification of the upscaled file..."
# ncdump -c $odir/$ofile

echo "Upscaling complete for variable $var for year $year."
