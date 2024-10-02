#!/bin/bash

# Script to convert hourly ERA5 data to daily data with appropriate aggregation based on variable
# Usage: ./get_daily_custom.sh <year> <variable>

# Check if year and variable arguments are provided
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Error: Year and/or variable not specified."
  echo "Usage: ./get_daily_custom.sh <year> <variable>"
  exit 1
fi

# Define year and variable
year=$1
var=$2

# Determine aggregation method and metadata based on the variable
case $var in
hurs)
  var_era5_name=$var
  var_standard_name="relative_humidity"
  var_long_name="Near-Surface Relative Humidity"
  var_units="%"
  cdodaywhat="-setrtoc,-inf,0,0 -daymean"
  start_time=00
  interpolate_time=""
  echo "Variable: $var";;
huss)
  var_era5_name=$var
  var_standard_name="specific_humidity"
  var_long_name="Near-Surface Specific Humidity"
  var_units="kg kg-1"
  cdodaywhat="-setrtoc,-inf,0,0 -daymean"
  start_time=00
  interpolate_time=""
  echo "Variable: $var";;
pr)
  var_era5_name=$var
  var_standard_name="precipitation_flux"
  var_long_name="Precipitation"
  var_units="kg m-2 s-1"
  cdodaywhat="-setrtoc,-inf,0,0 -divc,86.4 -daysum"
  start_time=00
  interpolate_time=""
  echo "Variable: $var";;
ps)
  var_era5_name=$var
  var_standard_name="surface_air_pressure"
  var_long_name="Surface Air Pressure"
  var_units="Pa"
  cdodaywhat="-setrtoc,-inf,0,0 -daymean"
  start_time=00
  interpolate_time=""
  echo "Variable: $var";;
rlds)
  var_era5_name=$var
  var_standard_name="surface_downwelling_longwave_flux_in_air"
  var_long_name="Surface Downwelling Longwave Radiation"
  var_units="W m-2"
  cdodaywhat="-setrtoc,-inf,0,0 -divc,3600. -daymean"
  start_time=00
  interpolate_time=""
  echo "Variable: $var";;
rsds)
  var_era5_name=$var
  var_standard_name="surface_downwelling_shortwave_flux_in_air"
  var_long_name="Surface Downwelling Shortwave Radiation"
  var_units="W m-2"
  cdodaywhat="-setrtoc,-inf,0,0 -divc,3600. -daymean"
  start_time=00
  interpolate_time=""
  echo "Variable: $var";;
sfcwind)
  var_era5_name=$var
  var_standard_name="wind_speed"
  var_long_name="Near-Surface Wind Speed"
  var_units="m s-1"
  cdodaywhat="-setrtoc,-inf,0,0 -daymean"
  start_time=00
  interpolate_time=""
  echo "Variable: $var";;
tas)
  var_era5_name=$var
  var_standard_name="air_temperature"
  var_long_name="Near-Surface Air Temperature"
  var_units="K"
  cdodaywhat="-daymean"
  start_time=00
  interpolate_time=""
  echo "Variable: $var";;
tasmax)
  var_era5_name=$var
  var_standard_name="air_temperature"
  var_long_name="Daily Maximum Near-Surface Air Temperature"
  var_units="K"
  cdodaywhat="-daymax"
  start_time=00
  interpolate_time=""
  echo "Variable: $var";;
tasmin)
  var_era5_name=$var
  var_standard_name="air_temperature"
  var_long_name="Daily Minimum Near-Surface Air Temperature"
  var_units="K"
  cdodaywhat="-daymin"
  start_time=00
  interpolate_time=""
  echo "Variable: $var";;
*)
  echo "Variable $var not supported. Exiting..."
  exit 1;;
esac

# Define input and output paths
idir="/Data/thanasis/WMO/ERA5/derived/$year"
odir="/Data/thanasis/WMO/ERA5/derived/$year/daily"
[ ! -d $odir ] && mkdir -p $odir
ifile="${var_era5_name}_1hr_ECMWF-ERA5_hourly_${year}0101-${year}1231.nc"
ofile="${var}_day_ERA5_${year}0101-${year}1231.nc"
ipath="${idir}/${ifile}"

# Check if the input file exists
if [ ! -f "$ipath" ]; then
  echo "Input file $ipath not found. Exiting..."
  exit 1
fi

# Aggregation step
echo "Aggregating data from hourly to daily using 'valid_time'..."
cdo -L -b f32 -f nc4c setmissval,1e20 -setreftime,1900-01-01,00:00:00,day -settime,00:00:00 -setname,$var -setcalendar,proleptic_gregorian $cdodaywhat $ipath $odir/$ofile.temp

# Check if the CDO operation was successful
if [ $? -ne 0 ]; then
  echo "CDO operation failed for $var. Exiting..."
  exit 1
fi

# Convert to NetCDF3 before renaming [ncrename corrupts nc file in NetCDF4 format]
echo "Converting to NetCDF3 format..."
ncks -3 $odir/$ofile.temp $odir/$ofile.temp2

# Rename variables in the output file
echo "Modifying the output file..."
ncrename -O -d valid_time,time -v valid_time,time $odir/$ofile.temp2 $odir/$ofile.temp3
ncrename -O -d latitude,lat -d longitude,lon -v latitude,lat -v longitude,lon $odir/$ofile.temp3 $odir/$ofile.temp4

# Check for errors after renaming
if [ $? -ne 0 ]; then
  echo "ncrename operation failed for $var. Exiting..."
  exit 1
fi

# Remove time bounds
echo "Removing time bounds in the output file..."
ncks -O -C -x -v time_bnds $odir/$ofile.temp4 $odir/$ofile.temp5

# Convert back to NetCDF4 with lvl 5 compression
echo "Converting back to NetCDF4 format with compression..."
ncks -4 -L 5 $odir/$ofile.temp5 $odir/$ofile

# Remove intermediate files
rm $odir/$ofile.temp $odir/$ofile.temp2 $odir/$ofile.temp3 $odir/$ofile.temp4 $odir/$ofile.temp5 $odir/$ofile.temp6

# Edit attributes
# Remove unwanted GRIB attributes and redundant metadata
echo "Removing unwanted metadata..."
ncatted -h \
-a GRIB_paramId,$var,d,, \
-a GRIB_dataType,$var,d,, \
-a GRIB_numberOfPoints,$var,d,, \
-a GRIB_typeOfLevel,$var,d,, \
-a GRIB_stepUnits,$var,d,, \
-a GRIB_stepType,$var,d,, \
-a GRIB_gridType,$var,d,, \
-a GRIB_uvRelativeToGrid,$var,d,, \
-a GRIB_NV,$var,d,, \
-a GRIB_Nx,$var,d,, \
-a GRIB_Ny,$var,d,, \
-a GRIB_cfName,$var,d,, \
-a GRIB_cfVarName,$var,d,, \
-a GRIB_gridDefinitionDescription,$var,d,, \
-a GRIB_iDirectionIncrementInDegrees,$var,d,, \
-a GRIB_iScansNegatively,$var,d,, \
-a GRIB_jDirectionIncrementInDegrees,$var,d,, \
-a GRIB_jPointsAreConsecutive,$var,d,, \
-a GRIB_jScansPositively,$var,d,, \
-a GRIB_latitudeOfFirstGridPointInDegrees,$var,d,, \
-a GRIB_latitudeOfLastGridPointInDegrees,$var,d,, \
-a GRIB_longitudeOfFirstGridPointInDegrees,$var,d,, \
-a GRIB_longitudeOfLastGridPointInDegrees,$var,d,, \
-a GRIB_missingValue,$var,d,, \
-a GRIB_name,$var,d,, \
-a GRIB_shortName,$var,d,, \
-a GRIB_totalNumber,$var,d,, \
-a GRIB_units,$var,d,, \
-a GRIB_surface,$var,d,, \
-a history,global,d,, \
$odir/$ofile

echo "Editing NetCDF attributes..."
ncatted -h \
-a standard_name,$var,o,c,"$var_standard_name" \
-a long_name,$var,o,c,"$var_long_name" \
-a units,$var,o,c,"$var_units" \
-a calendar,time,o,c,"proleptic_gregorian" \
-a long_name,time,o,c,"Time" \
-a long_name,lat,o,c,"Latitude" \
-a long_name,lon,o,c,"Longitude" \
$odir/$ofile

echo "Metadata cleaning complete."

# Final verification
# echo "Verifying final file..."
# ncdump -c $odir/$ofile

echo "Daily aggregation complete for variable $var and year $year."