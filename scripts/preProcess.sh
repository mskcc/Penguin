
#!/bin/bash

set -e
set -o pipefail


module load singularity/3.7.1

bamMirrorPath=$1
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


#keyFile="/Users/sumans/Projects/Project_BoundlessBio/data/input/key.txt"
keyFile="/juno/res/dmpcollab/dmprequest/12-245/key.txt"

dataDir=/home/sumans/Projects/Project_BoundlessBio/data

image="mskcc_echo_preprocess.sif"

imagePath=$dataDir/$image
#echo $imagePath

mafFile="data_mutations_extended.txt"
mafPath=$dataDir/input/


flagDir=$dataDir/flags
outPath=$dataDir/output

mkdir -p $flagDir 2>/dev/null
mkdir -p $outPath 2>/dev/null

flag_inProcess=$flagDir/${sampleID}_${seqType}.running
flag_done=$flagDir/${sampleID}_${seqType}.done
flag_fail=$flagDir/${sampleID}_${seqType}.fail

# python generateBAMFilePath.py $keyFile $bamMirrorPath $sampleID

if [[ ! -f $flag_done ]]; then

    rm -rf $flag_inProcess && rm -rf $flag_fail

    bamFilePath=`python3.8 generateBAMFilePath.py $keyFile $bamMirrorPath $sampleID`

    echo "BAM File Path=$bamFilePath"

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
          --sample ${sampleID} \
          --bam_file /home/input/${bamName} \
          --cnn_file /home/output/${outFile_step1} \
          --bed_file ${bedNameImage} \
          --step process_cnvkit"

        echo "Pre-Process Step 1....."
        echo $cmd
        echo

        eval $cmd


        cmd="singularity run \
          --bind ${mafPath}:/home/input/ \
          --bind ${outPath}:/home/output/ \
          ${imagePath} \
          --sample ${sampleID} \
          --maf_file /home/input/${mafFile} \
          --output_file /home/output/${outFile_step2} \
          --step process_vcf"

        echo "Pre-Process Step 2....."
        echo $cmd

        echo

        eval $cmd

        if [ $? -eq 0 ]; then

          rm $flag_inProcess && touch $flag_done

        else
          touch $flag_fail

        fi


    else
      touch $flag_fail

    fi
fi
