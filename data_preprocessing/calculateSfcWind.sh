#!/bin/bash

# Surface Wind Calculation Script using CDO
# This script calculates the surface wind (sfcWind) from 10m_u_component_of_wind (uas)
# and 10m_v_component_of_wind (vas) variables using the formula:
# sfcWind = sqrt(uas*uas + vas*vas)

# Usage: ./calculateSfcWind.sh <year>

# Check if the year argument is provided
if [ -z "$1" ]; then
  echo "Error: Year not specified."
  echo "Usage: ./calculateSfcWind.sh <year>"
  exit 1
fi

# Variables
year=$1    # The year to process

# Input and output directories
input_dir="/Data/thanasis/WMO/ERA5/raw/$year"      # Directory containing the wind component files
output_dir="/Data/thanasis/WMO/ERA5/derived/$year" # Directory where output wind speed files will be saved

# Ensure output directory exists
mkdir -p "$output_dir"

# Input file names for uas [u10] and vas [v10] (10m wind components)
uas_file="${input_dir}/10m_u_component_of_wind_hourly_${year}.nc"
vas_file="${input_dir}/10m_v_component_of_wind_hourly_${year}.nc"

# Output file name for surface wind speed
output_file="${output_dir}/sfcwind_hourly_${year}.nc"

# Check if input files exist
if [ ! -f "$uas_file" ] || [ ! -f "$vas_file" ]; then
    echo "Error: One or both input files not found:"
    echo "  $uas_file"
    echo "  $vas_file"
    exit 1
fi

# Perform the calculation using CDO with the same method as PIK
echo "Calculating surface wind (sfcWind) for $year..."

# Step 1: Merge the uas and vas files into a temporary merged file
merged_temp="${output_dir}/temp_merged_wind_${year}.nc"
cdo -s -L -f nc4 -z zip_5 -O merge "$uas_file" "$vas_file" "$merged_temp"

# Step 2: Calculate wind speed and save to the final output file
cdo -s -L -f nc4 -z zip_5 -O -expr,"sfcwind=sqrt(u10*u10 + v10*v10)" "$merged_temp" "$output_file"

# Check if the calculation was successful
if [ $? -eq 0 ]; then
    echo "Surface wind (sfcWind) calculation successful!"
    echo "Adjusting attributes for $output_file..."

    # Adjusting the attributes to match PIK's output
    ncatted -h -O \
        -a standard_name,sfcwind,a,c,"wind_speed" \
        -a long_name,sfcwind,a,c,"Near-Surface Wind Speed" \
        -a units,sfcwind,a,c,"m s-1" \
        -a coordinates,sfcwind,a,c,"lon lat" \
        "$output_file"

    # Remove the temporary merged file
    rm "$merged_temp"

    echo "Attributes adjusted and output saved to: $output_file"
else
    echo "Error: Surface wind calculation failed."
    exit 1
fi
