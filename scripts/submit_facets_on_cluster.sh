#!/bin/bash

# config file
CONFIG_FILE=$1
source $CONFIG_FILE
export CONFIG_FILE

################################
# set up using the config file #
################################

# Directories
dataDir=$dataDirectory
manifestDirName=$manifestDirectoryName
logDirName=$logDirectoryName
outDirName=$outputDirectoryName

# Manifest doc
subsetFile=$sampleSubset

# Cluster stats
clusterCPUNum=$clusterCPUNum
clusterMemory=$clusterMemory
clusterTime=$clusterTime
if [[ $clusterTime != *:* ]]; then
    clusterTime="${clusterTime}:00"
fi

#################################


logDir=${dataDir}/log/${logDirName}/facets_api_pull
# logDir=${dataDir}/log/log.Legacy/log_BB_EchoCaller_SteveMaron_HER2_Dec2023/facets_api_pull

inputDir=${dataDir}/input
manifestDir=${inputDir}/manifest/${manifestDirName}

# Convert to txt if necessary
if [[ $subsetFile == *.xlsx ]]; then
    echo "Converting Sample List to txt"
    txt_name="${subsetFile%.xlsx}.txt"
    xlsx2csv "${manifestDir}/${subsetFile}" | sed '/^""$/d' > "${manifestDir}/${txt_name}"
    subsetFile=$txt_name
fi

sampleListFile=${manifestDir}/${subsetFile}

outputDir=${dataDir}/output/${outDirName}
# outputDir=${dataDir}/output/output.Legacy/output_BB_EchoCaller_SteveMaron_HER2_Dec2023

echoReportFile=${outputDir}/merged.ECHO_results.csv

sampleReport="${outputDir}/sample_report_facets.txt"
geneReport="${outputDir}/gene_report_facets.txt"

mkdir -p $logDir 2>/dev/null

ts=$(date +%Y%m%d%H%M%S)





cmd="bsub \
-W ${clusterTime} \
-n ${clusterCPUNum} \
-R 'rusage[mem=${clusterMemory}]' \
-J 'facets_api_pull' \
-o '${logDir}/facets_api_pull_${ts}.stdout' \
-e '${logDir}/facets_api_pull_${ts}.stderr' \
python3.8 ./Test_facetsApiPull.py ${sampleListFile} ${echoReportFile} ${sampleReport} ${geneReport} ${dataDir}"


echo "$cmd"
eval "$cmd"
echo

