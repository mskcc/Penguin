

# Sequencing Type - WGS or IMPACT
#seqType="IMPACT"
seqType="WES"

impactPanel="IM7"
sampleTrackerFile="Data-2021-11-4.xlsx"

dataDir=/home/sumans/Projects/Project_BoundlessBio/data

inputDir=${dataDir}/input
sampleTrackerFilePath=${inputDir}/${sampleTrackerFile}

outputManifest="sampleManifest_${impactPanel}.txt"
outputManifestPath=${inputDir}/${outputManifest}


python3.8 generateManifest.py $impactPanel $sampleTrackerFilePath $outputManifestPath


bamMirrorPath_impact="/juno/res/dmpcollab/dmpshare/share/irb12_245"
bamMirrorPath_wes="/juno/work/tempo/wes_repo/Results/v1.4.x/cohort_level/MSKWESRP"

bedName_impact="IMPACT505_picard_baits-1.interval_list"
bedNameImage_impact="IMPACT505_picard_baits.bed"

#bedName_wes="xgen-exome-research-panel-v2-targets-hg19.bed"
#bedNameImage_wes="xgen-exome-research-panel-v2-targets-hg19.bed"
bedName_wes="xgen-exome-research-panel-v2-targets-hg19-no-chr.bed"
bedNameImage_wes="xgen-exome-research-panel-v2-targets-hg19-no-chr.bed"

count=0;

if [[ "$seqType" == "IMPACT" ]]; then

 for i in $(cat $outputManifestPath| tail -n +2 | awk '{print $1}'); do

   for j in N T; do


   # For Tumor Sample
      if [[ "$j" == "T" ]]; then
          sampleType=$j
          sampleID=$i
          bamID=${sampleID}

   # For Normal Paired Sample
      elif [[  "$j" == "N" ]]; then
          sampleType=$j
          sampleID=`python convertT2N.py --sID $i --aType impact_N`
          bamID=${sampleID}
      fi

      echo "Sample=$sampleID"
      cmd="sh preProcess.sh \
            $bamMirrorPath_impact \
            $sampleID \
            $bedName_impact \
            $bedNameImage_impact \
            $seqType \
            $sampleType \
            $bamID"

      echo $cmd
      echo

      eval $cmd
      echo "Done"
      echo
      echo

      count=$((count+1))

    done

  done

elif [[ "$seqType" == "WES" ]]; then

  for i in $(cat $outputManifestPath| tail -n +2 | awk '{print $1"_"$3}'); do

    echo $i
    sampleType="T"
    sampleID=$(echo $i | awk -F'_' '{print $1}')
    cmoID=$(echo $i | awk -F'_' '{print $2}')
    bamID=`python convertT2N.py --sID $cmoID --aType WES`

    echo "Sample=$sampleID"
    cmd="sh ./preProcess.sh \
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

fi


echo "Total Samples Found = $count"
  #statements
