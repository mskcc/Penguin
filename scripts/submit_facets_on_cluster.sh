#!/bin/bash

dataDir=/juno/cmo/bergerlab/sumans/Project_BoundlessBio/data

logDir=${dataDir}/log/log_8/facets_api_pull
# logDir=${dataDir}/log/log.Legacy/log_BB_EchoCaller_SteveMaron_HER2_Dec2023/facets_api_pull

inputDir=${dataDir}/input
manifestDir=${inputDir}/manifest/BB_EchoCaller_GE_Matteo_May2024
sampleListFile=${manifestDir}/FileB_export_ecDNATracker_records_240524135232.txt

outputDir=${dataDir}/output/output_8
# outputDir=${dataDir}/output/output.Legacy/output_BB_EchoCaller_SteveMaron_HER2_Dec2023

echoReportFile=${outputDir}/merged.ECHO_results.csv

sampleReport="${outputDir}/sample_report_facets.txt"
geneReport="${outputDir}/gene_report_facets.txt"

mkdir -p $logDir 2>/dev/null

ts=$(date +%Y%m%d%H%M%S)



cmd="bsub \
-W 96:00 \
-n 4 \
-R 'rusage[mem=64]' \
-J 'facets_api_pull' \
-o '${logDir}/facets_api_pull_${ts}.stdout' \
-e '${logDir}/facets_api_pull_${ts}.stderr' \
python3.8 ./Test_facetsApiPull.py ${sampleListFile} ${echoReportFile} ${sampleReport} ${geneReport}"


echo "$cmd"
eval "$cmd"
echo

