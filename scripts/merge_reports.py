import pandas as pd
import sys

# Take file paths as command-line arguments
ecDNA_report_path = sys.argv[1]
facets_report_path = sys.argv[2]
output_path = sys.argv[3]

# Load the reports
ecDNA_report = pd.read_csv(ecDNA_report_path, sep="\t")
facets_report = pd.read_csv(facets_report_path, sep="\t")

# Merge reports based on 'sample_id' and 'gene' columns, with ecDNA columns first
merged_report = pd.merge(ecDNA_report, facets_report, on=["sample_id", "gene"], how="inner")

# Reorder columns to have ecDNA report columns first, followed by facets report columns
ecDNA_columns = ecDNA_report.columns.tolist()
facets_columns = [col for col in facets_report.columns if col not in ["sample_id", "gene"]]
desired_columns = ecDNA_columns + facets_columns

# Apply column order to the merged report
merged_report = merged_report[desired_columns]

# Format columns in facets report that should be integers
# Replace 'column_name' with actual column names from the facets report that should be integers
integer_columns = ['gene_start', 'gene_end', 'seg_start', 'seg_end', 'seg_length', 'tcn', 'lcn', 'seg', 'segclust', 'mcn', 'gene_snps', 'gene_het_snps', 'genes_on_seg']
for col in integer_columns:
    if col in merged_report.columns:
        # Convert to integer where possible, else replace NaN with empty string
        merged_report[col] = merged_report[col].apply(lambda x: int(x) if pd.notnull(x) else "")

# Save the merged result
merged_report.to_csv(output_path, sep="\t", index=False, na_rep='')
print(f"Merge complete. Output saved to {output_path}.")
