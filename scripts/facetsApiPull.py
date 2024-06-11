import sys
import os

#change this to wherever the facetsAPI is stored
# sys.path.insert(1, '/juno/work/ccs/pricea2/pipelines/facetsAPI')
from facetsAPI import *

def get_selected_genes(useSingleRun, allowDefaults):
    clinical_sample_file="/home/sumans/Projects/Project_BoundlessBio/data/input/data_clinical_sample.oncokb.txt"
    facets_dir="/work/ccs/shared/resources/impact/facets/all/"
    prepared_metadata = FacetsMeta(clinical_sample_file, facets_dir, "purity")
    prepared_metadata.setSingleRunPerSample(useSingleRun,allowDefaults)
    #This file should look something like:
    #Sample ID
    #P-0000120-T01-IM3
    #P-0000120-T02-IM6
    #P-0000220-T01-IM3
    #P-0000220-T02-IM6
    #P-0000274-T01-IM3
    prepared_metadata.selectSamplesFromFile("/home/sumans/Projects/Project_BoundlessBio/data/facetsAPI_testing/sampleList.txt")
    prepared_metadata.buildFacetsMeta()
    target_dataset = FacetsDataset(prepared_metadata)
    target_dataset.buildFacetsDataset()
    #Here are some specific genes we want data for.
    target_gene_list = ["CARD11", "RAC1", "CDKN2A", "CDKN2B"]
    found_runs = []
    for facets_run in target_dataset.runList:
        found_runs.append(facets_run.id)
    for target_sample in prepared_metadata.samples_from_file:
        if target_sample not in found_runs:
            print("Missing: " + target_sample)
    #Loop over our gene objects and print out what we want.
    with open("/home/sumans/Projects/Project_BoundlessBio/data/facetsAPI_testing/gene_report.txt", 'w') as outfile:
        outfile.write("sample\tgene\tgene_start\tgene_end\tseg_start\tseg_end\tseg_length\tcf\ttcn\tlcn\tcn_state\tfilter\ttsg\tseg\tmedian_cnlr_seg\tsegclust\tmcn\tgenes_on_seg\tgene_snps\tgene_het_snps\tspans_segs" + "\n")
        for cur_run in target_dataset.runList:
            #print(cur_run.id)
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
if __name__ == '__main__':
    get_selected_genes(True, True)