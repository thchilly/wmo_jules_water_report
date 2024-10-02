#!/bin/bash

# Script to process daily data for all specified variables for a given year using get_daily_custom.sh
# Usage: ./getDaily_allVars.sh <year>

# Check if the year argument is provided
if [ -z "$1" ]; then
  echo "Error: Year not specified."
  echo "Usage: ./getDaily_allVars.sh <year>"
  exit 1
fi

# Define the year
year=$1

# Define the list of variables to process
variables=("tas" "tasmax" "tasmin" "pr" "hurs" "huss" "ps" "rlds" "rsds" "sfcwind")

# Loop through each variable and call the get_daily_custom.sh script
for var in "${variables[@]}"; do
  echo "Processing variable: $var for year: $year"
  
  # Call the get getDailyERA5.sh script for the current variable and year
  ./getDailyERA5.sh "$year" "$var"
  
  # Check if the script executed successfully
  if [ $? -ne 0 ]; then
    echo "Error: Processing failed for variable $var. Exiting..."
    exit 1
  fi

  echo "Successfully processed variable: $var for year: $year"
done

echo "All variables processed successfully for year: $year."
