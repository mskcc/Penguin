
set -euo pipefail
# config file
CONFIG_FILE=$1
source $CONFIG_FILE
shift

echoReportFile=$1
shift

################################
# set up using the config file #
################################

# Directories
dataDir=$dataDirectory
inputDir=$inputDirectory
manifestDir=$manifestDirectory
logDir=$facetsLogDirectory
outputDir=$facetsOutputDirectory
flagDir=$facetsFlagDirectory

mkdir -p "$flagDir" 2>/dev/null
mkdir -p "$logDir" 2>/dev/null
mkdir -p "$outputDir" 2>/dev/null

# echoReportFile=${mergedOutputDirectory}/merged.ECHO_results.csv

ts=$(date +%Y%m%d%H%M%S)

if [[ $clusterTime != *:* ]]; then
    clusterTime="${clusterTime}:00"
fi

# Initialize a flag to indicate the first line
first_line=true

# Read each line of file
while IFS=$'\t', read -r sample_id gene _; do
    # Skip the header line
    if $first_line; then
        first_line=false
        continue
    fi
    # IFS='-' read -ra parts <<< "$sample_id"
    # sampleID=""
    sampleID="$sample_id"
    # for ((i=0; i<4 && i<${#parts[@]}; i++)); do
    #     sampleID+="${parts[i]}-"
    # done
    # sampleID=${sampleID%-} 

    
    # Remove NA
    if [[ $sampleID == "NA" ]]; then
        sampleID=""
    fi

    echo "Sample ID: $sampleID, Gene: $gene"

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
                    -o '${logDir}/facets_api_pull_${sampleID}_${gene}_${ts}.stdout' \
                    -e '${logDir}/facets_api_pull_${sampleID}_${gene}_${ts}.stderr' \
                    sh submit_one_facets.sh ${CONFIG_FILE} ${sampleID} ${gene}"
                echo "$cmd"
                eval $cmd

            fi
        fi      
    fi

done < "$echoReportFile"