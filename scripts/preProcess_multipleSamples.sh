

# Sequencing Type - WGS or IMPACT
seqType="IMPACT"


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

count=0;

if [[ "$seqType" == "IMPACT" ]]; then

 for i in $(cat $outputManifestPath| tail -n +2 | awk '{print $1}'); do

   # For Tumor Sample

    sampleID=$i

    echo "Sample=$sampleID"
    cmd="sh preProcess.sh \
          $bamMirrorPath_impact \
          $sampleID \
          $bedName_impact \
          $bedNameImage_impact \
          $seqType"

    echo $cmd
    echo

    eval $cmd
    echo "Done"
    echo
    echo

    count=$((count+1))

    # For Normal Paired Sample

    sampleID=`python convertT2N.py $i`

    echo "Sample=$sampleID"
    cmd="sh preProcess.sh \
          $bamMirrorPath_impact \
          $sampleID \
          $bedName_impact \
          $bedNameImage_impact \
          $seqType"

    echo $cmd
    echo

    eval $cmd
    echo "Done"
    echo
    echo

    count=$((count+1))



  done

elif [[ "$seqType" == "WGS" ]]; then

   echo "Nothing to do yet"

fi


echo "Total Samples Found = $count"
  #statements
