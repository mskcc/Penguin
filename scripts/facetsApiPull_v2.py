import sys
import os
import pandas as pd
import numpy as np

from facetsAPI import *

sampleID = sys.argv[1]
gene = sys.argv[2]
dataDir = sys.argv[3]
outFile = sys.argv[4]

def get_selected_genes(useSingleRun, allowDefaults, target_sample_id, target_gene_list, geneReport, dataDir):
    clinical_sample_file= dataDir + "/input/data_clinical_sample.oncokb.txt"
    facets_dir="/work/ccs/shared/resources/impact/facets/all/"

    prepared_metadata = FacetsMeta(clinical_sample_file, facets_dir, "hisens")
    prepared_metadata.setSingleRunPerSample(useSingleRun,allowDefaults)
    prepared_metadata.build_from_file_listing = True
    prepared_metadata.samples_from_file.append(target_sample_id)
    prepared_metadata.buildFacetsMeta()

    target_dataset = FacetsDataset(prepared_metadata)
    target_dataset.buildFacetsDataset()

    found_runs = []
    for facets_run in target_dataset.runList:
        found_runs.append(facets_run.id)

    for target_sample in prepared_metadata.samples_from_file:
        if target_sample not in found_runs:
            print("Missing: " + target_sample)


    #Loop over our gene objects and print out what we want.
    with open(geneReport, 'a') as outfile:
        for cur_run in target_dataset.runList:

            for cur_gene in cur_run.genes:
                if cur_gene.gene in target_gene_list:

                    outfile.write(str(cur_run.id) + "\t")
                    outfile.write(str(cur_gene.gene) + "\t")
                    outfile.write(str(cur_gene.gene_start) + "\t")
                    outfile.write(str(cur_gene.gene_end) + "\t")
                    outfile.write(str(cur_gene.seg_start) + "\t")
                    outfile.write(str(cur_gene.seg_end) + "\t")
                    outfile.write(str(cur_gene.seg_length) + "\t")
                    outfile.write(str(cur_gene.cf) + "\t")
                    outfile.write(str(cur_gene.tcn) + "\t")
                    outfile.write(str(cur_gene.lcn) + "\t")
                    outfile.write(str(cur_gene.cn_state) + "\t")
                    outfile.write(str(cur_gene.filter) + "\t")
                    outfile.write(str(cur_gene.tsg) + "\t")
                    outfile.write(str(cur_gene.seg) + "\t")
                    outfile.write(str(cur_gene.median_cnlr_seg) + "\t")
                    outfile.write(str(cur_gene.segclust) + "\t")
                    outfile.write(str(cur_gene.mcn) + "\t")
                    outfile.write(str(cur_gene.genes_on_seg) + "\t")
                    outfile.write(str(cur_gene.gene_snps) + "\t")
                    outfile.write(str(cur_gene.gene_het_snps) + "\t")
                    outfile.write(str(cur_gene.spans_segs) + "\t")
                    outfile.write("\n")



if gene != "NA" :
    get_selected_genes(True, True, sampleID, [gene], outFile, dataDir)
else :
    with open(outFile, 'a') as outfile:
        outfile.write(sampleID + "\tNo genes above ECHO amplification threshold\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\n")


