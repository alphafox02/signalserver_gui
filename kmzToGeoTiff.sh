#!/bin/bash

# Inputs
#    - Input KMZ
#    - Output tiff filename

kmz=$1
output=$2

# Validate KMZ
if [ -z "${kmz}" ]; then
    echo "Error: no input file specified"
    exit 1
fi

echo "Processing file $kmz"

# Create a tmp directory and set up a cleanup function
tmp_dir="tmp"
mkdir -p $tmp_dir

# Ensure that tmp files are cleaned up when the script exits
cleanup() {
    echo "Cleaning up temporary files..."
    # Remove only the specific files/folders you need to clean up
    rm -rf $tmp_dir
}
trap cleanup EXIT

# Unzip KMZ to tmp directory
unzip $kmz -d $tmp_dir/

# Extract coordinates from kml
north=$(grep -oPm1 "(?<=<north>)[^<]+" $tmp_dir/doc.kml)
south=$(grep -oPm1 "(?<=<south>)[^<]+" $tmp_dir/doc.kml)
east=$(grep -oPm1 "(?<=<east>)[^<]+" $tmp_dir/doc.kml)
west=$(grep -oPm1 "(?<=<west>)[^<]+" $tmp_dir/doc.kml)

# Get image filename from kml
inFile=$(grep -oPm1 "(?<=<href>files/)[^<]+" $tmp_dir/doc.kml)

# Get output filename from input filename
outFile="${inFile%.*}.tiff"

# Get file path (directory of the original KMZ)
outPath=$(dirname "$kmz")

echo "Image boundaries: [${north},${west}] (top left), [${south},${east}] (bottom right)"
echo "Processing image ${inFile} and saving to ${outFile}"

# Convert to GeoTiff
gdal_translate -a_srs EPSG:4326 -a_ullr $west $north $east $south $tmp_dir/files/$inFile $outFile

# Move the GeoTIFF to the original location
mv $outFile $outPath

# Clean up tmp files (this is handled by the trap function)
