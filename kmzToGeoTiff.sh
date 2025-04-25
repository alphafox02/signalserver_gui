#!/bin/bash

# Inputs
#    - Input KMZ
#    - Output tiff filename

kmz=$1
output=$2

# Validate KMZ
if [ -z "${kmz}" ];
then
    echo "Error: no input file specified"
    exit 1
fi

echo "Processing file $kmz"

# Function to clean up tmp directory
cleanup() {
    echo "Cleaning up temporary files..."
    rm -r tmp/
}

# Ensure cleanup happens when script exits (on normal exit or error)
trap cleanup EXIT

# Unzip to tmp directory
mkdir tmp
unzip $kmz -d tmp/

# Extract coordinates from kml
north=$(grep -oPm1 "(?<=<north>)[^<]+" tmp/doc.kml)
south=$(grep -oPm1 "(?<=<south>)[^<]+" tmp/doc.kml)
east=$(grep -oPm1 "(?<=<east>)[^<]+" tmp/doc.kml)
west=$(grep -oPm1 "(?<=<west>)[^<]+" tmp/doc.kml)

# Get image filename from kml
inFile=$(grep -oPm1 "(?<=<href>files/)[^<]+" tmp/doc.kml)

# Get output filename from input filename
outFile="${inFile%.*}.tiff"

# Get file path
outPath=$(dirname "$kmz")

echo "Image boundaries: [${north},${west}] (top left), [${south},${east}] (bottom right)"
echo "Processing image ${inFile} and saving to ${outFile}"

# Convert to GeoTiff
gdal_translate -a_srs EPSG:4326 -a_ullr $west $north $east $south tmp/files/$inFile $outFile

# Generate the scaled single TIFF version
single_tiff="single_${outFile}"
gdal_translate -of GTiff -scale $outFile $single_tiff

# Move the GeoTIFFs to original location
mv $outFile $outPath
mv $single_tiff $outPath

# End of script
echo "Processing complete. Files saved to ${outPath}"
