
#!/bin/bash

set -euo pipefail


# Enable command echoing for debugging purposes
# set -x

# Check if enough arguments are passed
if [ "$#" -ne 2 ]; then
  echo "Usage: ./filter_ecDNA_calls.sh <input_file> <gene_list_file>"
  exit 1
fi

# Step 1: Get the input files from the command-line arguments
input_file="$1"  # First argument: input TSV file (e.g., P-0109064-T01-IM7.ecs_results.tsv)
gene_list_file="$2"  # Second argument: gene list file (e.g., geneList_IM7_505.txt)

# Step 2: Derive the sample ID and directory of the input file
sample_id=$(basename "$input_file" .ecs_results.tsv)
input_dir=$(dirname "$input_file")

# Define the output file names with sample_id as prefix and placed in the same directory as the input file
formatted_file="${input_dir}/${sample_id}_formatted.tsv"
no_cn_file="${input_dir}/${sample_id}_noCN.tsv"  # New file without the CN column
filtered_file="${input_dir}/${sample_id}_filtered_p_ecDNA.tsv"

# Remove the .tsv extension from the filtered file for file3 and file4
filtered_file_base="${filtered_file%.tsv}"

# Define output for matched and unmatched genes with the sample_id prefix in the same directory
file3="${filtered_file_base}_filtered_impactGeneList.tsv"  # Output for matched genes
file4="${filtered_file_base}_unfiltered_impactGeneList.tsv"  # Output for unmatched genes

# Step 3: Call the Python script (convert_ecDNA_format.py) to format and filter the input file
python3 convert_ecDNA_format.py "$input_file" "$formatted_file"

# Step 4: Generate a new file without the CN column
cut --complement -f4 "$formatted_file" > "$no_cn_file"

# Step 5: Filter the noCN file based on p_ecDNA >= 0.4
awk 'NR==1 || $4 >= 0.4' "$no_cn_file" > "$filtered_file"

# Step 6: Use the filtered file for further processing (comparing it with the gene list)
awk 'NR==FNR {genes[$1]; next} FNR==1 || ($2 in genes)' "$gene_list_file" "$filtered_file" > "$file3"
awk 'NR==FNR {genes[$1]; next} FNR==1 || !($2 in genes)' "$gene_list_file" "$filtered_file" > "$file4"

echo "Pipeline completed."
echo "File without CN: $no_cn_file"
echo "Filtered file: $filtered_file"
echo "Filtered matched rows saved to: $file3"
echo "Filtered unmatched rows saved to: $file4"

# Disable command echoing after script execution
# set +x
