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
flagDirName=${flagDirectoryName}_facets_gene
flagDir=${dataDir}/flag/${flagDirName}

mkdir -p "$flagDir" 2>/dev/null

# Manifest doc
subsetFile=$sampleSubset


#################################


logDir=${dataDir}/log/${logDirName}/facets_api_pull
mkdir -p "$logDir" 2>/dev/null

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

echoReportFile=${outputDir}/merged.ECHO_results.csv

mkdir -p "${outputDir}/facets_gene_output" 2>/dev/null


if [ -f "$echoReportFile" ]; then

    # Read each line of file
    while IFS=, read -r sample_id _ gene _; do
        IFS='-' read -ra parts <<< "$sample_id"
        sampleID=""
        for ((i=0; i<4 && i<${#parts[@]}; i++)); do
            sampleID+="${parts[i]}-"
        done
        sampleID=${sampleID%-} 

        
        # Remove NA
        if [[ $sampleID == "NA" ]]; then
            sampleID=""
        fi

        if [[ $gene != "gene" ]]; then
            flag_done="${flagDir}/${sampleID}_${gene}.done"

            if [[ ! -f $flag_done ]]; then

                # Run sample
                if [[ $gene != "gene" ]]; then
                    cmd="bsub \
                        -W ${clusterTime} \
                        -n ${clusterCPUNum} \
                        -R 'rusage[mem=${clusterMemory}]' \
                        -J 'facets_api_pull' \
                        -o '${logDir}/facets_api_pull_${ts}.stdout' \
                        -e '${logDir}/facets_api_pull_${ts}.stderr' \
                        sh submit_one_facets.sh ${sampleID} ${gene}"
                    echo "Submitting ${sampleID} ${gene}"
                    eval $cmd

                fi
            fi      
        fi

    done < "$echoReportFile"
fi


# cmd="bsub \
# -W ${clusterTime} \
# -n ${clusterCPUNum} \
# -R 'rusage[mem=${clusterMemory}]' \
# -J 'facets_api_pull' \
# -o '${logDir}/facets_api_pull_${ts}.stdout' \
# -e '${logDir}/facets_api_pull_${ts}.stderr' \
# python3.8 ./Test_facetsApiPull.py ${sampleListFile} ${echoReportFile} ${sampleReport} ${geneReport} ${dataDir}"


# echo "$cmd"
# eval "$cmd"
# echo

