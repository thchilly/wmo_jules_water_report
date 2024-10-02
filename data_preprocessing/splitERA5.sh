#!/bin/bash

# Input directory with the raw ERA5 files
input_dir="/Data/thanasis/WMO/ERA5/raw"

# Output directories for 2022 and 2023
output_dir_2022="/Data/thanasis/WMO/ERA5/raw/2022"
output_dir_2023="/Data/thanasis/WMO/ERA5/raw/2023"
output_dir_test="/Data/thanasis/WMO/ERA5/raw/test"

# Ensure the output directories exist
mkdir -p $output_dir_2022
mkdir -p $output_dir_2023
mkdir -p $output_dir_test


# Define index ranges for each year
year_2022_range="1/8760"     # 8760 hours in 2022
year_2023_range="8761/17520" # 8760 hours in 2023

# List of files to process
files=("10m_u_component_of_wind_hourly_2022_2024.nc" 
       "10m_v_component_of_wind_hourly_2022_2024.nc"
       "2m_dewpoint_temperature_hourly_2022_2024.nc"
       "2m_temperature_hourly_2022_2024.nc"
       "maximum_2m_temperature_since_previous_post_processing_hourly_2022_2024.nc"
       "minimum_2m_temperature_since_previous_post_processing_hourly_2022_2024.nc"
       "surface_pressure_hourly_2022_2024.nc"
       "surface_solar_radiation_downwards_hourly_2022_2024.nc"
       "surface_thermal_radiation_downwards_hourly_2022_2024.nc"
       "total_precipitation_hourly_2022_2024.nc")

# Loop through each file and split it into 2022 and 2023
for file in "${files[@]}"; do
    input_file="${input_dir}/${file}"

    # Split and compress the 2022 data
    output_file_2022="${output_dir_2022}/${file%.nc}_2022.nc"
    echo "Extracting and compressing 2022 data from $file..."
    cdo -f nc4 -z zip_5 seltimestep,$year_2022_range "$input_file" "$output_file_2022"

    # Split and compress the 2023 data
    output_file_2023="${output_dir_2023}/${file%.nc}_2023.nc"
    echo "Extracting and compressing 2023 data from $file..."
    cdo -f nc4 -z zip_5 seltimestep,$year_2023_range "$input_file" "$output_file_2023"
    
    # Using split year 
    output_file_test="${output_dir_test}/${file%.nc}_test.nc"
    cdo -f nc4 -z zip_5 splityear, "$input_file" "$output_file"

done

echo "Data successfully split and compressed for 2022 and 2023!"