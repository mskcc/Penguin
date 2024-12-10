# Define the input and output directories
input_dir="/juno/cmo/bergerlab/sumans/Project_ecDNA/Production/penguin/data/projects/ECS_Integration_Tests/output/echoCalls"
output_dir="/juno/cmo/bergerlab/sumans/Project_ecDNA/Production/penguin/data/projects/ECS_Integration_Tests/output/merged"
output_file="${output_dir}/merged_noCN.tsv"

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Add the header from the first file
for i in "$input_dir"/*/echoCaller/*_noCN.tsv; do
    head -n 1 "$i" > "$output_file"
    break
done

# Append contents of each file excluding the header
for i in "$input_dir"/*/echoCaller/*_noCN.tsv; do
    tail -n +2 "$i" >> "$output_file"
done

echo "Merging complete! Output saved to $output_file."
