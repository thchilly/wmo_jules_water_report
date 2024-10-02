#!/bin/bash

# Script to calculate tasrange (tasmax - tasmin) and update the metadata for the JULES model.
# Usage: ./processTasRange.sh /path/to/input_data /path/to/output_data

# Check if the user has provided the input and output directories as arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: No input and/or output directory provided."
    echo "Usage: ./processTasRange.sh /path/to/input_data /path/to/output_data"
    exit 1
fi

# Input and output directory
input_dir=$1
output_dir=$2

# Ensure the output directory exists
mkdir -p "$output_dir"

# Loop through all tasmax files in the input directory
for tasmax in "$input_dir"/*_tasmax_*.nc; do
    # Define tasmin and tasrange files based on tasmax file name
    tasmin="${tasmax/tasmax/tasmin}"   # Replace 'tasmax' with 'tasmin' in the file name
    tasrange="$output_dir/$(basename "${tasmax/tasmax/tasrange}")"  # Replace 'tasmax' with 'tasrange' and set output path

    # Check if the corresponding tasmin file exists
    if [ ! -f "$tasmin" ]; then
        echo "Error: Corresponding tasmin file not found for $tasmax"
        continue
    fi

    # Step 1: Perform the calculation of tasrange = tasmax - tasmin (without compression for faster processing)
    echo "Calculating tasrange for $tasmax and $tasmin..."
    cdo -f nc4 sub "$tasmax" "$tasmin" "$tasrange.tmp.nc"

    # Check if the calculation was successful
    if [ $? -eq 0 ]; then
        echo "Successfully created $tasrange.tmp.nc"
    else
        echo "Error: Failed to create $tasrange"
        continue
    fi

    # Step 2: Convert to NetCDF3 format for renaming operations
    echo "Converting $tasrange.tmp.nc to NetCDF3 format..."
    ncks -3 "$tasrange.tmp.nc" "$tasrange.tmp3.nc"

    # Step 3: Rename the 'tasmax' variable to 'tasrange' and update metadata in the NetCDF3 file
    echo "Renaming variable and updating attributes for $tasrange.tmp3.nc..."

    # Rename the variable 'tasmax' to 'tasrange' using ncrename
    ncrename -v tasmax,tasrange "$tasrange.tmp3.nc"

    # Update the 'long_name' attribute to reflect the tasrange meaning using ncatted
    ncatted -O -a long_name,tasrange,o,c,"Range between Daily Maximum and Minimum Near-Surface Air Temperature" "$tasrange.tmp3.nc"

    # Add a global attribute comment to the file using ncatted
    ncatted -O -a comment,global,o,c,"This tasrange data has been produced as input meteorological forcing data for the JULES model." "$tasrange.tmp3.nc"

    # Step 4: Convert back to NetCDF4 classic format with level 6 compression
    echo "Converting back to NetCDF4 classic format with compression..."
    ncks -4 -L 6 "$tasrange.tmp3.nc" "$tasrange"

    # Step 5: Cleanup intermediate files
    rm "$tasrange.tmp.nc" "$tasrange.tmp3.nc"

    # Check if the final file was created successfully
    if [ $? -eq 0 ]; then
        echo "Successfully processed and compressed $tasrange"
    else
        echo "Error processing $tasrange"
    fi
done

echo "tasrange calculation and metadata update complete."
