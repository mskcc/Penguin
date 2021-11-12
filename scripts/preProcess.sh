
#!/bin/bash

#source /home/sumans/miniconda2/bin/activate  base && conda activate "gddP2"


#conda list

set -e
set -o pipefail


source /home/sumans/miniconda2/bin/activate gddP2


module load singularity/3.7.1

bamMirrorPath=$1
echo $bamMirrorPath
shift

sampleID=$1
#sampleID="P-0066791-T02-IM7"
shift

bedName=$1
shift

bedNameImage=$1
shift

seqType=$1
shift

sampleType=$1
shift

bamID=$1
shift

#keyFile="/Users/sumans/Projects/Project_BoundlessBio/data/input/key.txt"
keyFile="/juno/res/dmpcollab/dmprequest/12-245/key.txt"

dataDir=/home/sumans/Projects/Project_BoundlessBio/data

image="mskcc_echo_preprocess.sif"

imagePath=$dataDir/$image
echo $imagePath


flagDir=$dataDir/flags_2
outPath=$dataDir/output_2

mkdir -p $flagDir 2>/dev/null
mkdir -p $outPath 2>/dev/null

flag_inProcess=$flagDir/${sampleID}_${seqType}.running
flag_done=$flagDir/${sampleID}_${seqType}.done
flag_fail=$flagDir/${sampleID}_${seqType}.fail

# python generateBAMFilePath.py $keyFile $bamMirrorPath $sampleID

if [[ ! -f $flag_done ]]; then

    rm -rf $flag_inProcess && rm -rf $flag_fail

    if [[ "$seqType" == "IMPACT" ]]; then
      bamFilePath=`python3.8 generateBAMFilePath.py $keyFile $bamMirrorPath $sampleID $sampleType`
      echo "BAM File Path=$bamFilePath"

      mafFile="data_mutations_extended.txt"
      mafPath=$dataDir/input/

      sampleID_MAF=${bamID}

    elif [[ "$seqType" == "WES" ]]; then
      bamFilePath=${bamMirrorPath}/bams/${bamID}/${bamID}.bam
      echo "BAM File Path=$bamFilePath"

      if [[ "$sampleType" == "T" ]]; then

        a1=${bamMirrorPath}/somatic
        a2=$(find ${a1} -maxdepth 1  -name ${bamID}* -print)
        a3=$(basename ${a2})
        mafFile=${a3}.somatic.final.maf
        mafPath=${a2}/combined_mutations/

      fi

      sampleID_MAF=${bamID}

    fi


    if [[ -f $bamFilePath ]]; then

        touch $flag_inProcess

        echo "BAM File Path exists....."
        echo

        bamDir=$(dirname $bamFilePath)
        bamName=$(basename $bamFilePath)

        bedPath=$dataDir/input/beds
        # bedName="IMPACT505_picard_baits-1.interval_list"
        # bedNameImage="IMPACT505_picard_baits.bed"

        outPath=$dataDir/output
        outFile_step1=${sampleID}_${seqType}.cnn
        outFile_step2=${sampleID}_${seqType}_historgram.csv



        cmd="singularity run \
          --bind ${bedPath}/${bedName}:/home/bed/${bedNameImage} \
          --bind ${bamDir}:/home/input/ \
          --bind ${outPath}:/home/output/ \
          ${imagePath} \
          --sample ${sampleID_MAF} \
          --bam_file /home/input/${bamName} \
          --cnn_file /home/output/${outFile_step1} \
          --bed_file ${bedNameImage} \
          --step process_cnvkit"

        echo "Pre-Process Step 1....."
        echo $cmd
        echo

        eval $cmd

        if [[ "$sampleType" == "T" ]]; then

            cmd="singularity run \
              --bind ${mafPath}:/home/input/ \
              --bind ${outPath}:/home/output/ \
              ${imagePath} \
              --sample ${sampleID_MAF} \
              --maf_file /home/input/${mafFile} \
              --output_file /home/output/${outFile_step2} \
              --step process_vcf"

            echo "Pre-Process Step 2....."
            echo $cmd

            echo

            eval $cmd
        fi

        if [ $? -eq 0 ]; then

          rm $flag_inProcess && touch $flag_done

        else
          touch $flag_fail

        fi


    else
      touch $flag_fail

    fi
fi
