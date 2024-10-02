#!/bin/bash

# Script to rename the 'tasmax' variable to 'tasrange' and update the 'long_name' attribute in NetCDF files.
# Additionally, adds a global attribute that indicates the tasrange data was produced for the JULES model.
# 
# Usage:
#   ./renameTasrange.sh /path/to/files

# Check if the user has provided the input directory as an argument
if [ -z "$1" ]; then
    echo "Error: No directory provided."
    echo "Usage: ./renameTasrange.sh /path/to/files"
    exit 1
fi

# Directory containing the files
data_dir=$1

# Loop through all tasrange files in the input directory
for file in "$data_dir"/*_tasrange_*.nc; do
    echo "Processing $file..."

    # Rename the variable 'tasmax' to 'tasrange' using ncrename
    ncrename -v tasmax,tasrange "$file"

    # Update the 'long_name' attribute to reflect the tasrange meaning using ncatted
    ncatted -O -a long_name,tasrange,o,c,"Range between Daily Maximum and Minimum Near-Surface Air Temperature" "$file"

    # Add a global attribute comment to the file using ncatted
    ncatted -O -a comment,global,o,c,"This tasrange data has been produced as input meteorological forcing data for the JULES model." "$file"

    # Re-compress the file using level 6 compression
    ncks -4 -L 6 "$file" "$file.tmp" && mv "$file.tmp" "$file"

    # Check if the operations were successful
    if [ $? -eq 0 ]; then
        echo "Successfully renamed variable, updated attributes, added global comment, and compressed $file"
    else
        echo "Error processing $file"
    fi
done

echo "Variable renaming, attribute update, global comment addition, and compression complete."
