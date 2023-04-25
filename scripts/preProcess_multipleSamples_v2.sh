#!/bin/bash



source /home/sumans/miniconda2/bin/activate gddP2
#conda activate gddP2

set -euo pipefail

# Sequencing Type - WGS or IMPACT
#seqType="IMPACT"
#seqType="WES"
seqType=$1
shift

i=$1;
shift

bamMirrorPath_impact="/juno/res/dmpcollab/dmpshare/share/irb12_245"
bamMirrorPath_wes="/juno/work/tempo/wes_repo/Results/v1.4.x/cohort_level/MSKWESRP"

#bedName_wes="xgen-exome-research-panel-v2-targets-hg19.bed"
#bedNameImage_wes="xgen-exome-research-panel-v2-targets-hg19.bed"
bedName_wes="xgen-exome-research-panel-v2-targets-hg19-no-chr.bed"
bedNameImage_wes="xgen-exome-research-panel-v2-targets-hg19-no-chr.bed"

if [[ "$seqType" == "IMPACT" ]]; then

#  for i in $(cat $outputManifestPath| tail -n +2 | awk -F "\t" '{print $1"_"$25}'); do

   # For Tumor Sample
          # sampleTypeTumor=$j
      sampleID_Tumor=$(echo "$i" | awk -F'_' '{print $1}')
      tp=$(echo "$i" | awk -F'_' '{print $2}')
      tumor_Purity=$(echo "scale=1 ; $tp / 100"| bc)
      # echo $tumor_Purity

      impactPanel=$(echo "$sampleID_Tumor" | cut -d "-" -f4)

      if [[ "$impactPanel" == "IM7" ]]; then
        bedName_impact="IMPACT505_picard_baits-1.interval_list"
        bedNameImage_impact="IMPACT505_picard_baits.bed"

      elif [[ "$impactPanel" == "IM6" ]]; then
        bedName_impact="IMPACT468_picard_baits.interval_list"
        bedNameImage_impact="IMPACT468_picard_baits.interval_list"

      elif [[ "$impactPanel" == "IM5" ]]; then
        bedName_impact="cv5_picard_baits_withoutHeaders.interval_list"
        bedNameImage_impact="cv5_picard_baits_withoutHeaders.interval_list"

      elif [[ "$impactPanel" == "IM3" ]]; then
        bedName_impact="cv3_hg19_picard_baits_withoutHeaders.interval_list"
        bedNameImage_impact="cv3_hg19_picard_baits_withoutHeaders.interval_list"

      fi

      bamID_Tumor=${sampleID_Tumor}

   # For Normal Paired Sample
      sampleID_Normal=$(python convertT2N.py --sID "$sampleID_Tumor" --aType impact_N)
      bamID_Normal=${sampleID_Normal}

      echo
      echo "Sample=$sampleID_Tumor"
      echo
      date
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

      echo "$cmd"
      echo

      eval "$cmd"
      date
      echo "Done"
      echo
      echo


elif [[ "$seqType" == "WES" ]]; then

  for i in $(cat $outputManifestPath| tail -n +2 | awk '{print $1"_"$3}'); do

    for j in N T; do

      if [[ "$j" == "T" ]]; then
        #echo $i
        sampleType=$j
        sampleID=$(echo $i | awk -F'_' '{print $1}')
        cmoID=$(echo $i | awk -F'_' '{print $2}')
        bamID=$(python convertT2N.py --sID $cmoID --aType WES)

      elif [[  "$j" == "N" ]]; then
        sampleType=$j
        sampleID_T=$(echo $i | awk -F'_' '{print $1}')
        sampleID=$(python convertT2N.py --sID $sampleID_T --aType impact_N)
        cmoID=$(echo $i | awk -F'_' '{print $2}')
        bamID_T=$(python convertT2N.py --sID $cmoID --aType WES)
        bamID=$(python convertT2N.py --sID $bamID_T --aType WES_P --mapFile $mapFile_wes_Path)

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


    done

  done

fi



