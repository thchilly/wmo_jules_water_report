#!/bin/bash

# Script to rename NetCDF files and variables for a specific year
# Usage: ./ERA5_rename_custom.sh <year>

# Check if the year argument is provided
if [ -z "$1" ]; then
  echo "Error: Year not specified."
  echo "Usage: ./ERA5_rename_custom.sh <year>"
  exit 1
fi

# Define the year
year=$1

# Define input and output directories
input_dir="/Data/thanasis/WMO/ERA5/raw/${year}"
output_dir="/Data/thanasis/WMO/ERA5/derived/${year}"

# Create the output directory if it does not exist
mkdir -p "$output_dir"

# Define the variable list [specific variables used for JULES]
VARIABLE_LIST=(
  "2m_temperature - tas"
  "maximum_2m_temperature_since_previous_post_processing - tasmax"
  "minimum_2m_temperature_since_previous_post_processing - tasmin"
  "total_precipitation - pr"
  "surface_pressure - ps"
  "surface_solar_radiation_downwards - rsds"
  "surface_thermal_radiation_downwards - rlds"
)

# Complete ERA5 - ISIMIP variable list
# VARIABLE_LIST=(
#   "2m_temperature - tas"
#   "maximum_2m_temperature_since_previous_post_processing - tasmax"
#   "minimum_2m_temperature_since_previous_post_processing - tasmin"
#   "total_precipitation - pr"
#   "surface_pressure - ps"
#   "surface_solar_radiation_downwards - rsds"
#   "surface_thermal_radiation_downwards - rlds"
#   "2m_dewpoint_temperature - dewptas"
#   "10m_u_component_of_wind - uas"
#   "10m_v_component_of_wind - vas"
#   "convective_precipitation - prc"
#   "mean_sea_level_pressure - psl"
#   "sea_surface_temperature - sst"
#   "skin_temperature - ts"
#   "snow_depth - snowd"
#   "snowfall - snow"
#   "surface_latent_heat_flux - hfls"
#   "surface_sensible_heat_flux - hfss"
#   "toa_incident_solar_radiation - rsdt"
#   "total_cloud_cover - clt"
#   "convective_rain_rate - rainc"
#   "convective_snowfall - snowc"
#   "high_cloud_cover - clh"
#   "low_cloud_cover - cll"
#   "medium_cloud_cover - clm"
#   "surface_net_thermal_radiation - rlns"
#   "top_net_thermal_radiation - rlnt"
#   "surface_net_solar_radiation - rsns"
#   "top_net_solar_radiation - rsnt"
#   "large_scale_precipitation - prl"
#   "large_scale_rain_rate - rainl"
#   "evaporation - evap"
#   "potential_evaporation - evappot"
#   "snowmelt - snowmlt"
#   "instantaneous_10m_wind_gust - sfcWindgust"
#   "large_scale_snowfall - snowl"
#   "precipitation_type - prtype"
#   "large_scale_snowfall_rate_water_equivalent - snowlw"
#   "downward_uv_radiation_at_the_surface - ruvds"
#   "total_sky_direct_solar_radiation_at_surface - rsdsdir"
#   "snow_evaporation - snowevap"
# )

# Loop over each variable pair in the list
for VAR_PAIR in "${VARIABLE_LIST[@]}"; do
  VARIABLE_IN=$(echo "${VAR_PAIR}" | awk -F- '{print $1}' | sed -e "s# ##g")
  echo "Processing variable: ${VARIABLE_IN}"
  VARIABLE_OUT=$(echo "${VAR_PAIR}" | awk -F- '{print $2}' | sed -e "s# ##g")
  echo "Renaming to: ${VARIABLE_OUT}"

  # Process each file that matches the input variable pattern in the input directory
  for FILE in ${input_dir}/${VARIABLE_IN}_*.nc; do
    echo "Current file: ${FILE}"
    if [ -f "${FILE}" ]; then
      # Get the variable name from the NetCDF file and trim whitespace
      VARIABLE_NETCDF=$(cdo -s showname "${FILE}" | xargs)
      echo "Original variable name in the file: '${VARIABLE_NETCDF}'"
      echo "Expected variable name: '${VARIABLE_OUT}'"

      # Get start and end dates from the file
      DATE_START=$(cdo -s showdate "${FILE}" | awk '{print $1}' | sed "s#-##g")
      DATE_STOP=$(cdo -s showdate "${FILE}" | awk '{print $NF}' | sed "s#-##g")

      # Construct the output filename
      FILE_OUT="${output_dir}/$(basename "${FILE}" | sed -e "s#${VARIABLE_IN}#${VARIABLE_OUT}_1hr_ECMWF-ERA5#g" -e "s#_[0-9][0-9][0-9][0-9]\.#_${DATE_START}-${DATE_STOP}.#g")"

      # Print progress
      echo "Processing ${FILE} to ${FILE_OUT}"

      # Copy the file instead of moving
      cp "${FILE}" "${FILE_OUT}"

      # Rename the internal variable in the NetCDF file
      if [ "${VARIABLE_NETCDF}" == "${VARIABLE_OUT}" ]; then
          echo "Variable already has the correct name. Skipping renaming."
      else
          # Handle possible leading/trailing whitespace
          ncrename -v "$(echo "${VARIABLE_NETCDF}" | xargs),${VARIABLE_OUT}" "${FILE_OUT}"
      fi

    else
      echo "File not found: ${FILE}"
    fi
  done
done

echo "File renaming completed for year ${year}. Output files saved to ${output_dir}."