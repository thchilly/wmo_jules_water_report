#!/bin/bash

# Script to upscale daily data from 0.25 to 0.5 degree resolution for all variables for a given year
# Usage: ./get0p5deg_allVars.sh <year>

# Check if the year argument is provided
if [ -z "$1" ]; then
  echo "Error: Year not specified."
  echo "Usage: ./get0p5deg_allVars.sh <year>"
  exit 1
fi

# Define the year
year=$1

# Define the list of variables to process
variables=("tas" "tasmax" "tasmin" "pr" "hurs" "huss" "ps" "rlds" "rsds" "sfcwind")

# Loop through each variable and call the get_0p5deg.sh script
for var in "${variables[@]}"; do
  echo "Upscaling variable: $var for year: $year to 0.5 degree resolution"

  # Call the get_0p5deg.sh script for the current variable and year
  ./home/thanasis/WMO/get0p5deg.sh "$year" "$var"

  # Check if the script executed successfully
  if [ $? -ne 0 ]; then
    echo "Error: Upscaling failed for variable $var. Exiting..."
    exit 1
  fi

  echo "Successfully upscaled variable: $var for year: $year to 0.5 degree resolution"
done

echo "All variables successfully upscaled to 0.5 degree resolution for year: $year."