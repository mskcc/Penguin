#!/bin/bash

dataDir=/juno/work/bergerm1/bergerlab/sumans/Project_BoundlessBio/data
inputDir=${dataDir}/input
manifestDir=${inputDir}/manifest/BB_MET_Nov2022
logDir=${dataDir}/log_v5

mkdir -p $logDir 2>/dev/null

ts=$(date +%Y%m%d%H%M%S)

#seqType="IMPACT"
#impactPanel="IM7"
# impactPanel="IM6"
aType=1

# sampleTrackerFile="Data-2021-11-4.xlsx"
sampleTrackerFile="allFISHSamples.xlsx"
mapFile_wes="MSKWESRP.pairing.tsv"
#subsetFile="amp-with-exome-468.xlsx"
subsetFile="ListofIDs_8N.xlsx"

# Column number of Sample ID inside manifest file. If the column number is 2, the index will be 1
sampleIDColumn=0
tumorPurityColumn=8

sampleTrackerFilePath=${manifestDir}/${sampleTrackerFile}
mapFile_wes_Path=${manifestDir}/${mapFile_wes}
subsetFilePath=${manifestDir}/${subsetFile}

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

    for i in $(cat "$outputManifestPath"| tail -n +2 | awk -F "\t" -v sampleIDColumn=$(expr $sampleIDColumn + 1) -v tumorPurityColumn=$(expr $tumorPurityColumn + 1) '{print $sampleIDColumn"_"$tumorPurityColumn}'); do

      sampleID_Tumor=$(echo "$i" | awk -F'_' '{print $1}')

      cmd="bsub \
          -W 72:00 \
          -n 4 \
          -R 'rusage[mem=64]' \
          -J 'echo.preProcess.${sampleID_Tumor}' \
          -o '${logDir}/echo.preProcess.${sampleID_Tumor}.${ts}.stdout' \
          -e '${logDir}/echo.preProcess.${sampleID_Tumor}.${ts}.stderr' \
          ./preProcess_multipleSamples_v2.sh \
          $seqType \
          $i"

        echo "Sample=$sampleID_Tumor"
        echo "$cmd"
        echo "submitting Job for Sample=$sampleID_Tumor"
        echo
        eval "$cmd"

        count=$((count+1))
      
      done

    fi

done


echo "Total Samples Found = $count"
