import pandas as pd
import numpy as np
import os
import sys

# Step 1: Load the input file
if len(sys.argv) != 3:
    print("Usage: convert_ecDNA_format.py <input_file> <output_file>")
    sys.exit(1)

input_file = sys.argv[1]  # First argument: input file (e.g., ecs_report.tsv)
output_file = sys.argv[2]  # Second argument: output file (e.g., formatted.tsv)

# Load the input file
df = pd.read_csv(input_file, sep="\t")

# Extract sample_id from the file name (remove .ecs_results.tsv part)
sample_id = os.path.basename(input_file).replace(".ecs_results.tsv", "")

# Copy the gene column as-is
df['gene'] = df['gene']  # Assuming the gene column exists

# Log2 is feature_1 (replace 'feature_1' with the actual column name from your file)
df['log2'] = df['feature_1'].round(3)

# Calculate CN from log2 values
df['cn'] = np.round(2 ** df['log2'])

# ecDNA_prob is p_ecDNA (replace 'p_ecDNA' with the actual column name from your file)
df['ecDNA_prob'] = df['p_ecDNA'].round(3)

# Calculate ecDNA_status based on ecDNA_prob (0.5 threshold)
df['ecDNA_status'] = np.where(df['ecDNA_prob'] >= 0.5, 'ecDNA', 'non-ecDNA')

# Add the sample_id column to the dataframe
df['sample_id'] = sample_id

# Select only the required columns in the final order
output_df = df[['sample_id', 'gene', 'log2', 'cn', 'ecDNA_prob', 'ecDNA_status']]

# Save the transformed data to a new file
output_df.to_csv(output_file, sep="\t",float_format="%.3f", index=False)

print("File formatted and saved as {}".format(output_file))

# print(df.dtypes)
