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

# Analysis type
aType=$aType

# Manifest doc
sampleTrackerFile=$sampleTracker
subsetFile=$sampleSubset
facetsPurity=$useFacetsPurity

# Column numbers
sampleIDColumn=$sampleIDColumn
tumorPurityColumn=$tumorPurityColumn
somaticStatusColumn=$somaticStatusColumn

# Cluster stats
clusterCPUNum=$clusterCPUNum
clusterMemory=$clusterMemory
clusterTime=$clusterTime
if [[ $clusterTime != *:* ]]; then
    clusterTime="${clusterTime}:00"
fi

################################

# child directory paths
inputDir=${dataDir}/input
manifestDir=${inputDir}/manifest/${manifestDirName}
logDir=${dataDir}/log/${logDirName}
mkdir -p $logDir 2>/dev/null

sampleTrackerFilePath=${manifestDir}/${sampleTrackerFile}
subsetFilePath=${manifestDir}/${subsetFile}
outputManifest="sampleManifest_${ts}_${aType}.txt"
outputManifestPath=${manifestDir}/${outputManifest}

# If using facets purity change
if [[ $facetsPurity == True ]]; then

    if [[ $subsetFile == *.xlsx ]]; then
        echo "Converting Sample List to txt"
        txt_name="${subsetFile%.xlsx}.txt"
        xlsx2csv "${manifestDir}/${subsetFile}" | sed '/^""$/d' > "${manifestDir}/${txt_name}"
        subsetFile=$txt_name
        subsetFilePath=${manifestDir}/${subsetFile}

    fi

    echo "Using facets purity"
    echo "New File location: ${manifestDir}/${sampleTrackerFile}.facets.tsv"
    newManifest="${sampleTrackerFilePath}.facets.tsv"
    cmd="python3.8 generateFacetsManifest.py --sampleManifest $sampleTrackerFilePath --subsetFile $subsetFilePath --outputFile $newManifest --sampleIDColumn $sampleIDColumn --samplePurityColumn $tumorPurityColumn --dataDirectory $dataDir"
    echo "$cmd"
    eval "$cmd"
    echo

    sampleTrackerPath=$newManifest
fi

ts=$(date +%Y%m%d%H%M%S)

if [[ ! -f $outputManifest ]] && [[ "$aType" == 1 ]]; then
    cmd="python3.8 generateManifest_v2.py --sampleManifest $sampleTrackerFilePath --outputFile $outputManifestPath --subsetFile $subsetFilePath --aType $aType --sampleIDColumn $sampleIDColumn"
    echo "$cmd"
    eval "$cmd"
    echo


elif [[ ! -f $outputManifest ]] && [[ "$aType" == 2 ]]; then
    cmd="python3.8 generateManifest_v2.py --impactPanel $impactPanel --sampleManifest $sampleTrackerFilePath --outputFile $outputManifestPath --subsetFile $subsetFilePath --aType $aType --sampleIDColumn $sampleIDColumn"
    echo "$cmd"
    eval "$cmd"

fi

# Counts the number of jobs
count=0;

# TODO: remove this for? since we are only doing impact rn
for seqType in IMPACT; do

  if [[ "$seqType" == "IMPACT" ]]; then

    for i in $(cat "$outputManifestPath" | awk -F "\t" -v sampleIDColumn=$(expr $sampleIDColumn + 1) -v tumorPurityColumn=$(expr $tumorPurityColumn + 1) -v somaticStatusColumn=$(expr $somaticStatusColumn + 1) '{print $sampleIDColumn"_"$tumorPurityColumn"_"$somaticStatusColumn}'); do

      sampleID_Tumor=$(echo "$i" | awk -F'_' '{print $1}')

      cmd="bsub \
      -W ${clusterTime} \
      -n ${clusterCPUNum} \
      -R 'rusage[mem=${clusterMemory}]' \
      -J 'echo.${sampleID_Tumor}' \
      -o '${logDir}/${sampleID_Tumor}.${ts}.stdout' \
      -e '${logDir}/${sampleID_Tumor}.${ts}.stderr' \
      ./preProcess_multipleSamples_v2.sh \
      $seqType \
      $i"

        echo "Sample=$sampleID_Tumor"
        echo "$cmd"
        echo "submitting Job for Sample=$sampleID_Tumor"
        eval "$cmd"
        echo

        count=$((count+1))
      
    done

  fi

done


echo "Total Samples Found = $count"
