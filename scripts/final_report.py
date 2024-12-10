import argparse
import pandas as pd
import os

def process_ecDNA_analysis(flag_folder, manifest_folder, output_folder, exclusion_file, sample_file, results_file, facets_file):
    # Read files
    excluded_samples = pd.read_csv(exclusion_file, sep="\t", names=["sample_id", "reason"], skiprows=1)
    initial_samples = pd.read_csv(sample_file, sep="\t", names=["sample_id"])
    results = pd.read_csv(results_file, sep="\t")
    facets_data = pd.read_csv(facets_file, sep="\t")

    # Rename the ID column in facets data to match sample summary
    facets_data.rename(columns={"ID": "sample_id"}, inplace=True)

    # Initial sample count
    initial_sample_count = len(initial_samples)

    # Process flag folder
    flag_status = {}
    for file_name in os.listdir(flag_folder):
        sample_id = file_name.split(".")[0]
        if file_name.endswith("done"):
            flag_status[sample_id] = "done"
        elif file_name.endswith("fail") or file_name.endswith("running"):
            flag_status[sample_id] = "analysis_failed"

    # Prepare sample-level summary columns
    sample_summary = []

    for sample_id in initial_samples["sample_id"]:
        # Determine analysis status
        if sample_id in flag_status:
            analysis_status = flag_status[sample_id]
        else:
            exclusion_reason = excluded_samples[excluded_samples["sample_id"] == sample_id]["reason"]
            if not exclusion_reason.empty:
                analysis_status = exclusion_reason.iloc[0].replace(" ", "_").lower()
            else:
                analysis_status = "missing_flag"

        # Filter ecDNA+ results for the current sample
        sample_results = results[results["sample_id"] == sample_id]
        ecDNA_genes = sample_results[sample_results["ecDNA_status"] == "ecDNA"]["gene"]
        ecDNA_genes_impact = sample_results[(sample_results["ecDNA_status"] == "ecDNA") & 
                                            (sample_results["gene_included_in_impact"] == "yes")]["gene"]

        # Create summary for the sample
        sample_summary.append({
            "sample_id": sample_id,
            "analysis_status": analysis_status,
            "ecDNA_status": "ecDNA" if not ecDNA_genes.empty else None,
            "ecDNA_genes": ";".join(ecDNA_genes) if not ecDNA_genes.empty else None,
            "ecDNA_genes_impact": ";".join(ecDNA_genes_impact) if not ecDNA_genes_impact.empty else None,
            "n_ecDNA_genes": len(ecDNA_genes),
            "n_ecDNA_genes_impact": len(ecDNA_genes_impact),
        })

    # Convert to DataFrame
    sample_summary_df = pd.DataFrame(sample_summary)

    # Save the original sample summaries
    sample_summary_file = os.path.join(manifest_folder, "sample_summary.tsv")
    sample_summary_df.to_csv(sample_summary_file, sep="\t", index=False, na_rep="None")

    successful_samples_df = sample_summary_df[sample_summary_df["analysis_status"] == "done"]
    successful_summary_file = os.path.join(manifest_folder, "successful_sample_summary.tsv")
    successful_samples_df.to_csv(successful_summary_file, sep="\t", index=False, na_rep="None")

    # Annotate with facets data
    annotated_sample_summary_df = sample_summary_df.merge(facets_data, on="sample_id", how="left")
    annotated_sample_summary_file = os.path.join(manifest_folder, "sample_summary_annotated.tsv")
    annotated_sample_summary_df.to_csv(annotated_sample_summary_file, sep="\t", index=False, na_rep="None")

    annotated_successful_summary_file = os.path.join(manifest_folder, "successful_sample_summary_annotated.tsv")
    annotated_successful_samples_df = annotated_sample_summary_df[annotated_sample_summary_df["analysis_status"] == "done"]
    annotated_successful_samples_df.to_csv(annotated_successful_summary_file, sep="\t", index=False, na_rep="None")

    # Prepare report
    facets_results_file = "combined_ecDNA_facets_filtered_p_ecDNA_impactGene_annotated.tsv"
    final_results_file = os.path.basename(results_file)

    report = (
        f"Project Analysis Summary:\n"
        f"- Initial sample count: {initial_sample_count}\n"
        f"- Samples with missing data (Non-IMPACT, 12-245 non-consent, missing BAM data): {len(sample_summary_df[sample_summary_df['analysis_status'] != 'done'])}\n"
        f"- Samples with raw data available (Successful Samples): {len(successful_samples_df)}\n"
        f"- Total ecDNA+ genes (all): {len(results[results['ecDNA_status'] == 'ecDNA'])}\n"
        f"- Total ecDNA+ genes (IMPACT): {len(results[(results['ecDNA_status'] == 'ecDNA') & (results['gene_included_in_impact'] == 'yes')])}\n"
        f"- Total unique ecDNA+ samples: {results[results['ecDNA_status'] == 'ecDNA']['sample_id'].nunique()}\n"
        "\n"
        "Attachments:\n"
        f"- Sample Summary (Successful Samples, Annotated with FACETS & cBioPortal data): successful_sample_summary_annotated.tsv\n"
        f"- ecDNA+ gene-level results: {final_results_file}\n"
        f"- ecDNA+ results with FACETS annotations: {facets_results_file}\n"
    )

    # Save report to a text file for email content
    email_report_file = os.path.join(manifest_folder, "email_summary.txt")
    with open(email_report_file, "w") as f:
        f.write(report)

    print("Processing complete.")
    print(report)
    print(f"Original sample summary saved to: {sample_summary_file}")
    print(f"Original successful sample summary saved to: {successful_summary_file}")
    print(f"Annotated sample summary saved to: {annotated_sample_summary_file}")
    print(f"Annotated successful sample summary saved to: {annotated_successful_summary_file}")
    print(f"Email summary saved to: {email_report_file}")

# Main function to handle argument parsing
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process ecDNA analysis.")
    parser.add_argument("--flag_folder", required=True, help="Path to the flag folder.")
    parser.add_argument("--manifest_folder", required=True, help="Path to the manifest folder.")
    parser.add_argument("--output_folder", required=True, help="Path to the output folder.")
    parser.add_argument("--exclusion_file", required=True, help="Path to the exclusion file.")
    parser.add_argument("--sample_file", required=True, help="Path to the sample file.")
    parser.add_argument("--results_file", required=True, help="Path to the results file.")
    parser.add_argument("--facets_file", required=True, help="Path to the facets file.")
    args = parser.parse_args()

    # Call the processing function with parsed arguments
    process_ecDNA_analysis(
        args.flag_folder,
        args.manifest_folder,
        args.output_folder,
        args.exclusion_file,
        args.sample_file,
        args.results_file,
        args.facets_file,
    )