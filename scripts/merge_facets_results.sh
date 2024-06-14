#!/bin/bash

# config file
CONFIG_FILE=$1
source $CONFIG_FILE

dataDir=$dataDirectory
outputDir=${dataDir}/output/${outputDirectoryName}
mergedFile=${outputDir}/merged.FACETS_gene_results.tsv

# Rewrite merged file
rm -rf $mergedFile

count=0

# Start of file
echo -e "sample\tgene\tgene_start\tgene_end\tseg_start\tseg_end\tseg_length\tcf\ttcn\tlcn\tcn_state\tfilter\ttsg\tseg\tmedian_cnlr_seg\tsegclust\tmcn\tgenes_on_seg\tgene_snps\tgene_het_snps\tspans_segs" > $mergedFile
# Iterate and add the first line
for file in "$outputDir"/facets_gene_output/*.tsv; do
    echo $file
    echo $count
    first_line=$(head -n 1 $file)
    if [[ $first_line == "" ]]; then

        to_write=${file##*/}
        to_write="${to_write//_/	}"
        to_write="${to_write%.tsv}"
        to_write="${to_write}	FACETS Gene Not Found	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA"
        echo "$to_write" >> $mergedFile

    else
        echo "$first_line" >> $mergedFile
    fi

    count=$((count+1))

done