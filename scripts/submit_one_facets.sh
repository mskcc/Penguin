#!/bin/bash

# This script submits one job on the cluster for facets gene

if [[ -z ${CONFIG_FILE} ]]; then 
    echo "Config file not found. Run submit_facets_on_cluster.sh instead"
    exit 1
fi

source $CONFIG_FILE

# Directories
dataDir=$dataDirectory
outDirName=$outputDirectoryName
flagDirName=${flagDirectoryName}_facets_gene
logDirName=$logDirectoryName
logDir=${dataDir}/log/${logDirName}/facets_api_pull
flagDir=${dataDir}/flag/${flagDirName}


# Cluster stats
clusterCPUNum=$clusterCPUNum
clusterMemory=$clusterMemory
clusterTime=$clusterTime
if [[ $clusterTime != *:* ]]; then
    clusterTime="${clusterTime}:00"
fi

sampleID=$1
echo "Sample ID: $sampleID"
shift

gene=$1
echo "Gene: $gene"
shift

ts=$(date +%Y%m%d%H%M%S)
outputDir=${dataDir}/output/${outDirName}
outFile="$outputDir/facets_gene_output/${sampleID}_${gene}.tsv"
rm -rf outFile
# Edit flags
flag_done="${flagDir}/${sampleID}_${gene}.done"
flag_inProcess="${flagDir}/${sampleID}_${gene}.running"
flag_fail="${flagDir}/${sampleID}_${gene}.fail"

rm -rf "$flag_inProcess" && \
rm -rf "$flag_fail" && \
rm -rf "$outFile" &&
touch "$flag_inProcess"

cmd="python3.8 ./facetsApiPull_v2.py ${sampleID} ${gene} ${dataDir} ${outFile}"

echo "$cmd"
if ! eval "$cmd" ; then
    # Command failed
    echo "${sampleID} ${gene} Failed"
    rm "$flag_inProcess" && touch "$flag_fail"
else 
    rm "$flag_inProcess" && touch "$flag_done"
fi
