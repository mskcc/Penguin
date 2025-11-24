#!/bin/bash

# Ensure the script is called with a config file
if [ $# -ne 1 ]; then
    echo "Usage: $0 <path_to_config_file>"
    exit 1
fi

# Load the config file passed as an argument
config_file="$1"
source "$config_file"

# Define variables from the config file
flag_folder="$echoFlagDirectory"
manifest_folder="$manifestDirectory"
output_folder="$mergedOutputDirectory"

# Define the exclusion file and other files dynamically
exclusion_file="$exclusionFile_cbioportal"
sample_file="${sampleFull}"
results_file="${output_folder}/merged_ecDNA_results_${suffix_ecDNA_file2}"
facets_file="${output_folder}/facets_cbioportal_merged_full.tsv"

# Call the Python script with the required arguments
python3 ./final_report.py \
    --flag_folder "$flag_folder" \
    --manifest_folder "$manifest_folder" \
    --output_folder "$output_folder" \
    --exclusion_file "$exclusion_file" \
    --sample_file "$sample_file" \
    --results_file "$results_file" \
    --facets_file "$facets_file"