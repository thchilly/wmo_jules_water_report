#!/bin/bash

# Script to calculate specific humidity (huss) and relative humidity (hurs)
# from temperature, dew point temperature, and surface pressure
# using Buck (1981) methodology as described by PIK.
#
# Buck (1981) Journal of Applied Meteorology 20, 1527-1532,
# doi:10.1175/1520-0450(1981)020<1527:NEFCVP>2.0.CO;2 as described in
# Buck Research CR-1A User's Manual, Appendix 1
# url:www.hygrometers.com/wp-content/uploads/CR-1A-users-manual-2009-12.pdf
#
# Usage: ./calculate_huss_hurs.sh YEAR
# Example: ./calculate_huss_hurs.sh 2022
#
# Input files are located in:
#   \\sokratis\Data\thanasis\WMO\ERA5\raw\{YEAR}
# Output files will be written to:
#   \\sokratis\Data\thanasis\WMO\ERA5\derived\{YEAR}

# Ensure the year is passed as an argument
if [ -z "$1" ]; then
    echo "Error: No year provided."
    echo "Usage: ./calculate_huss_hurs.sh YEAR"
    exit 1
fi

# Variables
year=$1
input_dir="/Data/thanasis/WMO/ERA5/raw/$year"
output_dir="/Data/thanasis/WMO/ERA5/derived/$year"
mkdir -p "$output_dir"

# Define file paths
PFILE="${input_dir}/surface_pressure_hourly_${year}.nc"
DFILE="${input_dir}/2m_dewpoint_temperature_hourly_${year}.nc"
TFILE="${input_dir}/2m_temperature_hourly_${year}.nc"
SFILE="${output_dir}/huss_hourly_${year}.nc"
RFILE="${output_dir}/hurs_hourly_${year}.nc"

# Define the function to calculate specific and relative humidity
function get_cdoexpr_huss_and_hurs_from_temp_dewp_pres {
  # Constants from Buck (1981)
  local shum=$1
  local rhum=$2
  local temp=$3
  local dewp=$4
  local pres=$5

  local RdoRv=0.62198
  local aw=6.1121
  local ai=6.1115
  local bw=18.729
  local bi=23.036
  local cw=257.87
  local ci=279.82
  local dw=227.3
  local di=333.7
  local xw=7.2e-4
  local xi=2.2e-4
  local yw=3.20e-6
  local yi=3.83e-6
  local zw=5.9e-10
  local zi=6.4e-10

  local a="(($temp>0)?$aw:$ai)"
  local b="(($temp>0)?$bw:$bi)"
  local c="(($temp>0)?$cw:$ci)"
  local d="(($temp>0)?$dw:$di)"
  local x="(($temp>0)?$xw:$xi)"
  local y="(($temp>0)?$yw:$yi)"
  local z="(($temp>0)?$zw:$zi)"

  local saturationpurewatervaporpressure="$a*exp(($b-$temp/$d)*$temp/($temp+$c))"
  local purewatervaporpressure="$a*exp(($b-$dewp/$d)*$dewp/($dewp+$c))"
  local enhancementfactor="1.0+$x+$pres*($y+$z*$temp^2)"
  local watervaporpressure="($purewatervaporpressure)*($enhancementfactor)"
  local saturationwatervaporpressure="($saturationpurewatervaporpressure)*($enhancementfactor)"

  local mixingratio_inverse="($pres/($watervaporpressure)-1.0)/$RdoRv"
  echo "$shum=1.0/($mixingratio_inverse+1.0); $rhum=100.0*($pres/($saturationwatervaporpressure)+$RdoRv-1.0)*$shum/$RdoRv;"
}

# Get CDO expressions for huss and hurs
cdoexpr=$(get_cdoexpr_huss_and_hurs_from_temp_dewp_pres huss hurs "(t2m-273.15)" "(d2m-273.15)" "(sp*0.01)")
cdoexprhuss=$(cut -d ' ' -f 1 <<< "$cdoexpr")
cdoexprhurs=$(cut -d ' ' -f 2 <<< "$cdoexpr")

echo "Calculating huss and hurs for year $year..."

# Step 1: Merge input files (surface pressure, dew point temperature, and temperature)
cdo -L -O merge "$PFILE" "$DFILE" "$TFILE" "${output_dir}/temp_merged_${year}.nc"

# Step 2: Calculate specific and relative humidity for each month and hour
for hour in $(seq -w 0 23); do
  for month in $(seq -w 1 12); do
    echo "Processing hour $hour, month $month"
    sfx="${month}${hour}"
    cdo -L -b f32 aexpr,"$cdoexprhuss" -selmon,$month -selhour,$hour "${output_dir}/temp_merged_${year}.nc" "${SFILE}$sfx"
    cdo -L expr,"$cdoexprhurs" "${SFILE}$sfx" "${RFILE}$sfx"
    cdo -L selname,huss "${SFILE}$sfx" "${SFILE}$sfx.huss"
    mv "${SFILE}$sfx.huss" "${SFILE}$sfx"
  done
done

# Step 3: Merge all monthly/hourly results with compression
cdo -L -f nc4 -z zip_5 -O mergetime "${SFILE}"???? "${SFILE}_compressed.nc"
cdo -L -f nc4 -z zip_5 -O mergetime "${RFILE}"???? "${RFILE}_compressed.nc"

# Step 4: Remove temporary files
rm "${SFILE}"???? "${RFILE}"????

# Step 5: Adjust attributes for specific and relative humidity
ncatted -h \
-a standard_name,huss,o,c,"specific_humidity" \
-a long_name,huss,o,c,"Near-Surface Specific Humidity" \
-a units,huss,o,c,"kg kg-1" \
"${SFILE}_compressed.nc"

ncatted -h \
-a standard_name,hurs,o,c,"relative_humidity" \
-a long_name,hurs,o,c,"Near-Surface Relative Humidity" \
-a units,hurs,o,c,"%" \
"${RFILE}_compressed.nc"

echo "Calculation of huss and hurs complete for year $year."
