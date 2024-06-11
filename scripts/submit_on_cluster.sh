#!/bin/bash


# dataDir=/rtsess01/compute/juno/cmo/juno/work/bergerm1/bergerlab/sumans/Project_BoundlessBio/data
dataDir=/juno/cmo/bergerlab/sumans/Project_BoundlessBio/data
inputDir=${dataDir}/input
manifestDir=${inputDir}/manifest/BB_EchoCaller_GE_Matteo_May2024
logDir=${dataDir}/log/log_8

mkdir -p $logDir 2>/dev/null


ts=$(date +%Y%m%d%H%M%S)

aType=1

sampleTrackerFile="FileA_export_ecDNATracker_records_240524135226.xlsx"
subsetFile="FileB_export_ecDNATracker_records_240524135232.xlsx"
# mapFile_wes="MSKWESRP.pairing.tsv"

# Column number of Sample ID inside manifest file. If the column number is 2, the index will be 1
sampleIDColumn=0
tumorPurityColumn=1
somaticStatusColumn=2

sampleTrackerFilePath=${manifestDir}/${sampleTrackerFile}
subsetFilePath=${manifestDir}/${subsetFile}
# mapFile_wes_Path=${manifestDir}/${mapFile_wes}

outputManifest="sampleManifest_${ts}_${aType}.txt"
outputManifestPath=${manifestDir}/${outputManifest}


if [[ ! -f $outputManifest ]] && [[ "$aType" == 1 ]]; then
    # cmd="python3.8 generateManifest.py --impactPanel $impactPanel --sampleManifest $sampleTrackerFilePath --outputFile $outputManifestPath --aType $aType"

    cmd="python3.8 generateManifest.py --sampleManifest $sampleTrackerFilePath --outputFile $outputManifestPath --subsetFile $subsetFilePath --aType $aType --sampleIDColumn $sampleIDColumn"
    echo "$cmd"
    eval "$cmd"
    echo


elif [[ ! -f $outputManifest ]] && [[ "$aType" == 2 ]]; then
    cmd="python3.8 generateManifest.py --impactPanel $impactPanel --sampleManifest $sampleTrackerFilePath --outputFile $outputManifestPath --subsetFile $subsetFilePath --aType $aType --sampleIDColumn $sampleIDColumn"
    echo "$cmd"
    eval "$cmd"

fi

count=0;

# for seqType in IMPACT WES; do
for seqType in IMPACT; do

  if [[ "$seqType" == "IMPACT" ]]; then

    for i in $(cat "$outputManifestPath" | awk -F "\t" -v sampleIDColumn=$(expr $sampleIDColumn + 1) -v tumorPurityColumn=$(expr $tumorPurityColumn + 1) -v somaticStatusColumn=$(expr $somaticStatusColumn + 1) '{print $sampleIDColumn"_"$tumorPurityColumn"_"$somaticStatusColumn}'); do

      sampleID_Tumor=$(echo "$i" | awk -F'_' '{print $1}')

      cmd="bsub \
      -W 72:00 \
      -n 4 \
      -R 'rusage[mem=64]' \
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

        # exit 1
      
    done

  fi

done


echo "Total Samples Found = $count"
