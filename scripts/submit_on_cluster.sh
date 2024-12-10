#!/bin/bash
set -euo pipefail

# config file
CONFIG_FILE=$1
shift
listOfSamples=$1
shift

CONFIG_FILE=$(readlink -f "$CONFIG_FILE")

source $CONFIG_FILE

################################
# set up using the config file #
################################

# Directories
dataDir=$dataDirectory
dataDir=$(readlink -f "$dataDir")
manifestDir=$manifestDirectory
inputDir=$inputDirectory
flagDir=$echoFlagDirectory

mkdir -p $sampleFacetsDirectory 2>/dev/null
mkdir -p $mergedOutputDirectory 2>/dev/null
mkdir -p $manifestDirectory 2>/dev/null
mkdir -p "$flagDir" 2>/dev/null


# Manifest doc
sampleTrackerFile=$sampleInfoSubset
sampleTrackerFull=$sampleInfoFull
sampleSubset=$sampleSubset
sampleFull=$sampleFull
facetsPurity=$useFacetsPurity
defaultPurity=$defaultPurity
exclusionFile=$exclusionFile_cbioportal

# Cluster stats
clusterCPUNum=$clusterCPUNum
clusterMemory=$clusterMemory
clusterTime=$clusterTime
if [[ $clusterTime != *:* ]]; then
    clusterTime="${clusterTime}:00"
fi

# Sample facets location
sampleReportFacetsName="${sampleFacetsDirectory}/sample_report_facets.txt"
sampleReportFacetsNameFull="${sampleFacetsDirectory}/sample_report_facets_full.txt"

################################

ts=$(date +%Y%m%d%H%M%S)

# Making a copy of List of Samples inside Manifest Directory
cmd="cp -f ${listOfSamples} ${sampleFull} 2>/dev/null"
echo "$cmd"
eval $cmd
echo

echo "Creating Manifest..."
cmd="python3.8 ./cBioPortalApiPull.py $dataAccessToken $sampleFull $sampleSubset $sampleTrackerFull $sampleTrackerFile $defaultPurity $exclusionFile"
echo "$cmd"
eval $cmd
echo

# child directory paths
outputManifest="sampleManifest_${ts}_${aType}.txt"
outputManifestPath=${manifestDir}/${outputManifest}

if [[ $sampleSubset == *.xlsx ]]; then
    echo "Converting Sample List to txt"
    txt_name="${sampleSubset%.xlsx}.txt"
    xlsx2csv "${sampleSubset}" | sed '/^""$/d' > "${txt_name}"
    sampleSubset=$txt_name

fi

# Create facets sample document
mergedOutputFull=${mergedOutputDirectory}/facets_cbioportal_merged_full.tsv
mergedOutput=${mergedOutputDirectory}/facets_cbioportal_merged.tsv

echo "Creating facets sample"
cmd="python3.8 generateFacetsSampleReport.py --fullFile $sampleFull --subsetFile $sampleSubset --outputFile $sampleReportFacetsName --outputFileFull $sampleReportFacetsNameFull --dataDirectory $dataDir --fullInfo $sampleInfoFull --subsetInfo $sampleInfoSubset --mergedOutputFull $mergedOutputFull --mergedOutput $mergedOutput"
echo "$cmd"
eval "$cmd"
echo

# If using facets purity change 
if [[ $facetsPurity == True ]]; then
    echo "Using facets purity"
    echo "New File location: ${sampleTrackerFile}.facets.tsv"
    newManifest="${sampleTrackerFile}.facets.tsv"
    cmd="python3.8 generateFacetsManifest.py --sampleManifest $sampleTrackerFile --subsetFile $sampleSubset --outputFile $newManifest --facetsReport $sampleReportFacetsName --sampleIDColumn $sampleIDColumn --samplePurityColumn $tumorPurityColumn --defaultPurity $defaultPurity"
    echo "$cmd"
    eval "$cmd"
    echo

    sampleTrackerFile=$newManifest
fi

if [[ ! -f $outputManifest ]]; then
    cmd="python3.8 generateManifest_v2.py --sampleManifest $sampleTrackerFile --outputFile $outputManifestPath --subsetFile $sampleSubset --aType $aType --sampleIDColumn $sampleIDColumn"
    echo "$cmd"
    eval "$cmd"
    echo

fi

# Counts the number of jobs
count=0;
count_called=0
count_skipped=0

mkdir -p $echoLogDirectory 2>/dev/null
for i in $(cat "$outputManifestPath" | awk -F "\t" -v sampleIDColumn=$(expr $sampleIDColumn + 1) -v tumorPurityColumn=$(expr $tumorPurityColumn + 1) -v somaticStatusColumn=$(expr $somaticStatusColumn + 1) '{print $sampleIDColumn"_"$tumorPurityColumn"_"$somaticStatusColumn}'); do

    sampleID_Tumor=$(echo "$i" | awk -F'_' '{print $1}')

    flag_inProcess=$flagDir/${sampleID_Tumor}.running
    flag_done=$flagDir/${sampleID_Tumor}.done
    flag_fail=$flagDir/${sampleID_Tumor}.fail

    cmd="bsub \
    -W ${clusterTime} \
    -n ${clusterCPUNum} \
    -R 'rusage[mem=${clusterMemory}]' \
    -J 'echo.${sampleID_Tumor}' \
    -o '${echoLogDirectory}/${sampleID_Tumor}.${ts}.stdout' \
    -e '${echoLogDirectory}/${sampleID_Tumor}.${ts}.stderr' \
    ./preProcess_multipleSamples_v2.sh ${CONFIG_FILE} \
    $seqType \
    $i"


    if [[ ! -f $flag_done ]]; then
        echo "Sample=$sampleID_Tumor"
        echo "$cmd"
        echo "submitting Job for Sample=$sampleID_Tumor"
        eval "$cmd"
        echo
        count_called=$((count_called+1))
    else
        echo "Sample=$sampleID_Tumor"
        echo "Done Flag Found. Sample's results already exist"
        echo "Skipping.."
        echo
        count_skipped=$((count_skipped+1))       
    fi

    count=$((count+1))
  
done


echo "Total Samples Found = $count"
echo "Total Samples Called = $count_called"
echo "Total Samples Skipped = $count_skipped"