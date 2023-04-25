#!/bin/bash

#source /home/sumans/miniconda2/bin/activate  base && conda activate "gddP2"

source /home/sumans/miniconda2/bin/activate gddP2

set -euo pipefail

module load singularity/3.7.1

bamMirrorPath=$1
echo "$bamMirrorPath"
shift

sampleID_Tumor=$1
#sampleID="P-0066791-T02-IM7"
shift

sampleID_Normal=$1
#sampleID="P-0066791-T02-IM7"
shift

bedName=$1
shift

bedNameImage=$1
shift

seqType=$1
shift

bamID_Tumor=$1
shift

bamID_Normal=$1
shift

tumor_Purity=$1
shift

# keyFile="/juno/work/bergerm1/bergerlab/sumans/Project_BoundlessBio/data/input/manifest/key.txt"
keyFile="/juno/res/dmpcollab/dmprequest/12-245/key.txt"

dataDir=/juno/work/bergerm1/bergerlab/sumans/Project_BoundlessBio/data

singularity_cache=$HOME/.singularity/cache

# image="echo-preprocessor:release-v2.0.4"
image_echoPreProcessor="boundlessbio-echo-preprocessor-v2.0.4.img"
image_echoCaller="boundlessbio-echo-caller-v2.4.0.img"

imagePath_echoPreProcessor=$singularity_cache/$image_echoPreProcessor
#echo $imagePath_echoPreProcessor
imagePath_echoCaller=$singularity_cache/$image_echoCaller

TOP_LEVEL_DIR=${dataDir}
OUT_DIR=${TOP_LEVEL_DIR}/output_4
REF_FILE=${TOP_LEVEL_DIR}/input/references/b37.fasta
BED_FILE=${TOP_LEVEL_DIR}/input/beds/${bedName}
ANNOTATION_FILE=${TOP_LEVEL_DIR}/input/references/refFlat_withoutPrefix.txt
EXCLUDE_FILE=${TOP_LEVEL_DIR}/input/references/human.hg19.excl.tsv

TUMOR_SAMPLE_ID=${sampleID_Tumor}
echo "$TUMOR_SAMPLE_ID"
NORMAL_SAMPLE_ID=${sampleID_Normal}
echo "$NORMAL_SAMPLE_ID"
# TUMOR_BAM=${TOP_LEVEL_DIR}</path/to/tumor.bam>
# NORMAL_BAM=${TOP_LEVEL_DIR}</path/to/normal_sample.bam>

TUMOR_PURITY=${tumor_Purity}
echo "$TUMOR_PURITY"
GENOME_VERSION=hg19
# If somatic small variants are available in maf format
# MAF_FILE=${TOP_LEVEL_DIR}</path/to/somatic_SNV_indel.maf>
# If using a pregenerated reference from echo preprocessor
# REFERENCE_CNN=${TOP_LEVEL_DIR}</path/to/reference.cnn>
# If using a matched normal


# keyFile="/home/sumans/Projects/Project_BoundlessBio/data/input/manifest/key.txt"
# # keyFile="/juno/res/dmpcollab/dmprequest/12-245/key.txt"
# echo $keyFile

# dataDir=/home/sumans/Projects/Project_BoundlessBio/data

# image="mskcc_echo_preprocess.sif"
#
# imagePath=$dataDir/$image
#echo $imagePath

flagDir=$dataDir/flags_3
outDir_Sample=${OUT_DIR}/${TUMOR_SAMPLE_ID}
outDir_flatReference=${outDir_Sample}/flatReference
outDir_preProcessor=${outDir_Sample}/preProcessor
outDir_echoCaller=${outDir_Sample}/echoCaller

mkdir -p $flagDir 2>/dev/null
mkdir -p "$outDir_Sample" 2>/dev/null
mkdir -p "$outDir_flatReference" 2>/dev/null
mkdir -p "$outDir_preProcessor" 2>/dev/null
mkdir -p "$outDir_echoCaller" 2>/dev/null
# mkdir -p $OUT_DIR 2>/dev/null

flag_inProcess=$flagDir/${TUMOR_SAMPLE_ID}_${seqType}.running
flag_done=$flagDir/${TUMOR_SAMPLE_ID}_${seqType}.done
flag_fail=$flagDir/${TUMOR_SAMPLE_ID}_${seqType}.fail

# python generateBAMFilePath.py $keyFile $bamMirrorPath $sampleID

if [[ ! -f $flag_done ]]; then

    rm -rf "$flag_inProcess" && rm -rf "$flag_fail" && rm -rf "$outDir_Sample"

    if [[ "$seqType" == "IMPACT" ]]; then

        bamFilePath_T=$(python3.8 generateBAMFilePath.py $keyFile "$bamMirrorPath" "$TUMOR_SAMPLE_ID" T)
        bamFilePath_N=$(python3.8 generateBAMFilePath.py $keyFile "$bamMirrorPath" "$NORMAL_SAMPLE_ID" N)
        echo "T BAM File Path=${bamFilePath_T}"
        echo "N BAM File Path=${bamFilePath_N}"

        mafFile="data_mutations_extended.txt"
        mafPath=$dataDir/input

    fi

    if [[ -f ${bamFilePath_T} ]] && [[ -f ${bamFilePath_N} ]]; then

        touch "$flag_inProcess"

        echo "BAM File Paths exists for both T & N....."
        echo

        bamDir_T=$(dirname "$bamFilePath_T")
        bamName_T=$(basename "$bamFilePath_T")

        bamDir_N=$(dirname "$bamFilePath_N")
        bamName_N=$(basename "$bamFilePath_N")

        bedPath=$dataDir/input/beds
        # bedName="IMPACT505_picard_baits-1.interval_list"
        # bedNameImage="IMPACT505_picard_baits.bed"

        bedPrefix=$(echo "$bedName" | cut -d"." -f1)
        outFile_flatRef_1=${outDir_flatReference}/${bedPrefix}.antitarget.bed
        outFile_flatRef_2=${outDir_flatReference}/${bedPrefix}.flat.reference.cnn
        outFile_flatRef_3=${outDir_flatReference}/${bedPrefix}.target.bed

      if [[ ! -f ${outFile_flatRef_1} ]] || [[ ! -f ${outFile_flatRef_2} ]] || [[ ! -f ${outFile_flatRef_3} ]]; then

        cmd="singularity run \
          --bind ${TOP_LEVEL_DIR}:${TOP_LEVEL_DIR} \
          ${imagePath_echoPreProcessor} \
          --out_dir ${outDir_flatReference} \
          --ref_fasta ${REF_FILE} \
          --target_bed ${BED_FILE} \
          --annot_file ${ANNOTATION_FILE} \
          reference"

        echo "Running Echo Pre-Processor: Step 1....."
        echo "$cmd"
        echo

        # eval "$cmd"

        if ! eval "$cmd" ; then
          echo "Step 1 failed"
        fi


      fi

      cmd="singularity run \
        --bind ${TOP_LEVEL_DIR}:${TOP_LEVEL_DIR},${bamDir_T}:${bamDir_T},${bamDir_N}:${bamDir_N} \
        ${imagePath_echoPreProcessor} \
        --out_dir ${outDir_preProcessor} \
        --ref_fasta ${REF_FILE} \
        --ref_genome ${GENOME_VERSION} \
        --target_bed ${BED_FILE} \
        --annot_file ${ANNOTATION_FILE} \
        --exclude ${EXCLUDE_FILE} \
        --tumor_bam ${bamFilePath_T} \
        --normal_bam ${bamFilePath_N} \
        --tumor_sample_id ${TUMOR_SAMPLE_ID} \
        --normal_sample_id ${NORMAL_SAMPLE_ID} \
        --purity ${TUMOR_PURITY} \
        --maf_file ${mafPath}/${mafFile} \
        preprocess"

      echo "Running Echo Pre-Processor: Step 2....."
      echo "$cmd"
      echo
      # eval $cmd

      if ! eval "$cmd" ; then
        echo "Step 2 failed"
      fi


      cmd="singularity run \
      --bind ${outDir_preProcessor}:${outDir_preProcessor},${outDir_echoCaller}:${outDir_echoCaller} \
      ${imagePath_echoCaller} \
      --input_folder ${outDir_preProcessor} \
      --output_folder ${outDir_echoCaller} \
      --ref_genome ${GENOME_VERSION} \
      call"

      echo "Running Echo Caller: Step 3....."
      echo "$cmd"
      echo
      # eval "$cmd"

      if eval "$cmd" ; then
        rm "$flag_inProcess" && touch "$flag_done"
      else
        touch "$flag_fail"
      fi

    else
      touch "$flag_fail"

    fi
fi
