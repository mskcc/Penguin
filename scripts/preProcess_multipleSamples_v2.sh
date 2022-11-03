#!/bin/bash

set -e
set -o pipefail

source /home/sumans/miniconda2/bin/activate gddP2
#conda activate gddP2


# Sequencing Type - WGS or IMPACT
#seqType="IMPACT"
#seqType="WES"
seqType=$1
shift


#impactPanel="IM7"
impactPanel=$1
shift

aType=$1;
shift

#echo $aType

# sampleTrackerFile="Data-2021-11-4.xlsx"
sampleTrackerFile="MET-bbi-cases.xlsx"
mapFile_wes="MSKWESRP.pairing.tsv"
#subsetFile="amp-with-exome-468.xlsx"
subsetFile="ListofIDs_19N.xlsx"


# Column number of Sample ID inside manifest file. If the column number is 2, the index will be 1
sampleIDColumn=0
tumorPurityColumn=8

dataDir=/juno/work/bergerm1/bergerlab/sumans/Project_BoundlessBio/data

inputDir=${dataDir}/input
manifestDir=${inputDir}/manifest/BB_MET_Nov2022
sampleTrackerFilePath=${manifestDir}/${sampleTrackerFile}
mapFile_wes_Path=${manifestDir}/${mapFile_wes}
subsetFilePath=${manifestDir}/${subsetFile}

outputManifest="sampleManifest_${impactPanel}_${aType}.txt"
outputManifestPath=${manifestDir}/${outputManifest}

if [[ ! -f $outputManifest ]] && [[ "$aType" == 1 ]]; then
    # cmd="python3.8 generateManifest.py --impactPanel $impactPanel --sampleManifest $sampleTrackerFilePath --outputFile $outputManifestPath --aType $aType"

    cmd="python3.8 generateManifest.py --impactPanel $impactPanel --sampleManifest $sampleTrackerFilePath --outputFile $outputManifestPath --subsetFile $subsetFilePath --aType $aType --sampleIDColumn $sampleIDColumn"
    echo $cmd
    eval $cmd


elif [[ ! -f $outputManifest ]] && [[ "$aType" == 2 ]]; then
    cmd="python3.8 generateManifest.py --impactPanel $impactPanel --sampleManifest $sampleTrackerFilePath --outputFile $outputManifestPath --subsetFile $subsetFilePath --aType $aType --sampleIDColumn $sampleIDColumn"
    echo $cmd
    eval $cmd

fi


bamMirrorPath_impact="/juno/res/dmpcollab/dmpshare/share/irb12_245"
bamMirrorPath_wes="/juno/work/tempo/wes_repo/Results/v1.4.x/cohort_level/MSKWESRP"

if [[ "$impactPanel" == "IM7" ]]; then
  bedName_impact="IMPACT505_picard_baits-1.interval_list"
  bedNameImage_impact="IMPACT505_picard_baits.bed"

elif [[ "$impactPanel" == "IM6" ]]; then
  bedName_impact="IMPACT468_picard_baits.interval_list"
  bedNameImage_impact="IMPACT468_picard_baits.interval_list"

fi


#bedName_wes="xgen-exome-research-panel-v2-targets-hg19.bed"
#bedNameImage_wes="xgen-exome-research-panel-v2-targets-hg19.bed"
bedName_wes="xgen-exome-research-panel-v2-targets-hg19-no-chr.bed"
bedNameImage_wes="xgen-exome-research-panel-v2-targets-hg19-no-chr.bed"

count=0;

if [[ "$seqType" == "IMPACT" ]]; then

#  for i in $(cat $outputManifestPath| tail -n +2 | awk -F "\t" '{print $1"_"$25}'); do

 for i in $(cat $outputManifestPath| tail -n +2 | awk -F "\t" -v sampleIDColumn=`expr $sampleIDColumn + 1` -v tumorPurityColumn=`expr $tumorPurityColumn + 1` '{print $sampleIDColumn"_"$tumorPurityColumn}'); do



   # For Tumor Sample
          # sampleTypeTumor=$j
      sampleID_Tumor=$(echo $i | awk -F'_' '{print $1}')
      tp=$(echo $i | awk -F'_' '{print $2}')
      echo $tp
      # tp_fraction=$(( tp / 100.00 ))
      # echo $tp_fraction
      # tumor_Purity=$(printf "%.2f \n" $tp_fraction)
      tumor_Purity=$(echo "scale=1 ; $tp / 100"| bc)

      echo $tumor_Purity


      bamID_Tumor=${sampleID_Tumor}

   # For Normal Paired Sample
      sampleID_Normal=`python convertT2N.py --sID $sampleID_Tumor --aType impact_N`
      bamID_Normal=${sampleID_Normal}

      echo "Sample=$sampleID_Tumor"
      cmd="sh preProcess_v2.sh \
            $bamMirrorPath_impact \
            $sampleID_Tumor \
            $sampleID_Normal \
            $bedName_impact \
            $bedNameImage_impact \
            $seqType \
            $bamID_Tumor \
            $bamID_Normal \
            $tumor_Purity"

      echo $cmd
      echo

      eval $cmd
      echo "Done"
      echo
      echo

      count=$((count+1))


  done

elif [[ "$seqType" == "WES" ]]; then

  for i in $(cat $outputManifestPath| tail -n +2 | awk '{print $1"_"$3}'); do

    for j in N T; do

      if [[ "$j" == "T" ]]; then
        #echo $i
        sampleType=$j
        sampleID=$(echo $i | awk -F'_' '{print $1}')
        cmoID=$(echo $i | awk -F'_' '{print $2}')
        bamID=`python convertT2N.py --sID $cmoID --aType WES`

      elif [[  "$j" == "N" ]]; then
        sampleType=$j
        sampleID_T=$(echo $i | awk -F'_' '{print $1}')
        sampleID=`python convertT2N.py --sID $sampleID_T --aType impact_N`
        cmoID=$(echo $i | awk -F'_' '{print $2}')
        bamID_T=`python convertT2N.py --sID $cmoID --aType WES`
        bamID=`python convertT2N.py --sID $bamID_T --aType WES_P --mapFile $mapFile_wes_Path`

      fi

      echo "Sample=$sampleID"
      cmd="sh preProcess_v2.sh \
            $bamMirrorPath_wes \
            $sampleID \
            $bedName_wes \
            $bedNameImage_wes \
            $seqType \
            $sampleType \
            $bamID"

      echo $cmd
      echo
      #echo "hello"

      eval ${cmd}


      echo "Done"
      echo
      echo

      count=$((count+1))

    done

  done

fi


echo "Total Samples Found = $count"
  #statements
