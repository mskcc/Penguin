#!/bin/bash

# Define the path to the file containing the sample IDs
sample_id_file="./sampleList.txt"

# Define source folders
folder1="/juno/cmo/bergerlab/sumans/Project_ecDNA/Production/penguin/data/projects/ECS_Integration_Tests/output/echoCalls"
folder2="/juno/cmo/bergerlab/yuk3/Project_ecDNA/penguin/data/output/output_BREAST_V1_FACETS/echoCalls"

# Define destination root folder
destination_root="/juno/cmo/bergerlab/sumans/Project_ecDNA/Production/data_for_review/MB_data"

# Loop through each sample ID from the file
while IFS= read -r sample_id; do
    # Skip empty lines
    [[ -z "$sample_id" ]] && continue

    # Create the destination directory named after the sample ID
    destination_dir="${destination_root}/${sample_id}"
    mkdir -p "$destination_dir"

    # Check and copy files from folder1
    echo "Processing $sample_id in folder1..."
    echoCaller_folder1=$(find "$folder1" -type d -name "${sample_id}*" -exec find {} -type d -name "echoCaller" \;)
    if [[ -d "$echoCaller_folder1" ]]; then
        cp "$echoCaller_folder1/${sample_id}.ecs_results.tsv" \
           "$echoCaller_folder1/${sample_id}_filtered_p_ecDNA.tsv" \
           "$echoCaller_folder1/${sample_id}_formatted.tsv" \
           "$echoCaller_folder1/${sample_id}_filtered_p_ecDNA_filtered_impactGeneList.tsv" \
           "$destination_dir" 2>/dev/null || echo "Some files may be missing for $sample_id in folder1"
    else
        echo "Directory for $sample_id not found in folder1"
    fi

    # Check and copy files from folder2
    echo "Processing $sample_id in folder2..."
    echoCaller_folder2=$(find "$folder2" -type d -name "${sample_id}*" -exec find {} -type d -name "echoCaller" \;)
    if [[ -d "$echoCaller_folder2" ]]; then
        eval cp "$echoCaller_folder2/${sample_id}*.ECHO_results.csv" "$destination_dir" 2>/dev/null || echo "File missing for $sample_id in folder2"
    else
        echo "Directory for $sample_id not found in folder2"
    fi
done < "$sample_id_file"

echo "Copying completed."
