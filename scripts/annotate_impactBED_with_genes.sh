


# awk 'BEGIN{OFS="\t"} {print $3, $5, $6, $1}' refFlat_withoutPrefix.txt > /juno/cmo/bergerlab/sumans/Project_ecDNA/Production/references/beds/beds_with_genes/refFlat_withoutPrefix.bed

# awk 'BEGIN{OFS="\t"} !/^@/ {print $1, $2-1, $3, $5}' cv5_picard_baits_withoutHeaders.interval_list  > /juno/cmo/bergerlab/sumans/Project_ecDNA/Production/references/beds/beds_with_genes/cv5_picard_baits_withoutHeaders.bed

#!/bin/bash

# Path to the directory containing the interval files
INTERVAL_DIR="/juno/cmo/bergerlab/sumans/Project_ecDNA/Production/references/beds/original_beds"
REF_FLAT_FILE="/juno/cmo/bergerlab/sumans/Project_ecDNA/Production/references/refFlat_withoutPrefix.txt"
OUTPUT_DIR="/juno/cmo/bergerlab/sumans/Project_ecDNA/Production/references/beds/beds_with_genes"
FINAL_DIR="/juno/cmo/bergerlab/sumans/Project_ecDNA/Production/references/beds/final_beds"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# List of interval files (each file should be relative to INTERVAL_DIR)
interval_files_list=("cv3_hg19_picard_baits_withoutHeaders.interval_list" "cv5_picard_baits_withoutHeaders.interval_list" "IMPACT468_picard_baits.interval_list" "IMPACT505_picard_baits-1.interval_list")  # Replace with your list of files

# Loop through each file in the list
for interval_file in "${interval_files_list[@]}"; do
    # Full path to the interval file
    full_interval_file="$INTERVAL_DIR/$interval_file"

    # Extract the file name without the path and extension
    file_prefix=$(basename "$full_interval_file" .interval_list)

    echo "Processing file: $file_prefix"

    # Step 1: Convert interval_list to BED format and save in the output directory
    awk 'BEGIN{OFS="\t"} {print $1, $2-1, $3, $5}' "$full_interval_file" > "$OUTPUT_DIR/${file_prefix}_bed.bed"

    #Use this command instaed of above one if the interval file contains a header line
    # awk 'BEGIN{OFS="\t"} !/^@/ {print $1, $2-1, $3, $5}' "$full_interval_file" > "$OUTPUT_DIR/${file_prefix}_bed.bed"

    # Step 2: Convert refFlat file to BED format (you only need to do this once if refFlat is the same for all)
    awk 'BEGIN{OFS="\t"} {print $3, $5, $6, $1}' "$REF_FLAT_FILE" > "$OUTPUT_DIR/refFlat_bed.bed"

    # Step 3: Sort the BED files and save in the output directory
    sort -k1,1 -k2,2n "$OUTPUT_DIR/${file_prefix}_bed.bed" > "$OUTPUT_DIR/${file_prefix}_sorted_bed.bed"
    sort -k1,1 -k2,2n "$OUTPUT_DIR/refFlat_bed.bed" > "$OUTPUT_DIR/refFlat_sorted_bed.bed"

    # Step 4: Annotate the sorted BED file with gene names from the sorted refFlat and save in the output directory
    # bedtools intersect -a "$OUTPUT_DIR/${file_prefix}_sorted_bed.bed" -b "$OUTPUT_DIR/refFlat_sorted_bed.bed" -wa -wb -c > "$OUTPUT_DIR/${file_prefix}_counts_bed.bed"

    #  bedtools intersect -a "$OUTPUT_DIR/${file_prefix}_sorted_bed.bed" -b "$OUTPUT_DIR/refFlat_sorted_bed.bed" -wa -wb | awk '!seen[$1,$2,$3]++' > "$OUTPUT_DIR/${file_prefix}_annotated_unique_bed.bed"

       bedtools intersect -a "$OUTPUT_DIR/${file_prefix}_sorted_bed.bed" -b "$OUTPUT_DIR/refFlat_sorted_bed.bed" -wa -wb -loj > "$OUTPUT_DIR/${file_prefix}_annotated_bed.bed"
    # bedtools closest -a "$OUTPUT_DIR/${file_prefix}_sorted_bed.bed" -b "$OUTPUT_DIR/refFlat_sorted_bed.bed" -d > "$OUTPUT_DIR/${file_prefix}_sorted_closest_bed.bed"

     # Step 5: Use awk to ensure only one row per interval (even if multiple overlaps)
    awk '!seen[$1,$2,$3]++' "$OUTPUT_DIR/${file_prefix}_annotated_bed.bed" > "$OUTPUT_DIR/${file_prefix}_annotated_unique_bed.bed"

    # Step 6: Clean up the annotated file to keep only the desired columns (optional) and save in the output directory
    # awk 'BEGIN{OFS="\t"} {print $1, $2, $3, $8, $4}' "$OUTPUT_DIR/${file_prefix}_annotated_unique_bed.bed" > "$OUTPUT_DIR/${file_prefix}_final_bed.bed"
    awk 'BEGIN{OFS="\t"} {print $1, $2, $3, ($8 == "." ? "NA" : $8), $4}' "$OUTPUT_DIR/${file_prefix}_annotated_unique_bed.bed" > "$OUTPUT_DIR/${file_prefix}_final_bed.bed"

    # Step 7: Copying the final BED to its final destination directory
    cp "$OUTPUT_DIR/${file_prefix}_final_bed.bed" "$FINAL_DIR/${file_prefix}_final_bed.bed"

    echo "Finished processing file: $file_prefix"

    # exit
done

echo "All files processed."

