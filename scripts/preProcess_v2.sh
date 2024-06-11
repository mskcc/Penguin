#!/bin/bash

#source /home/sumans/miniconda2/bin/activate  base && conda activate "gddP2"

source /home/sumans/miniconda2/bin/activate gddP2

set -euo pipefail

module load singularity/3.7.1
module load samtools

bamMirrorPath=$1
echo "BAM Mirror = $bamMirrorPath"
shift

sampleID_Tumor=$1
#sampleID="P-0066791-T02-IM7"
shift

sampleID_Normal=$1
#sampleID="P-0066791-T02-IM7"
shift

bedName=$1
shift

seqType=$1
shift

tumor_Purity=$1
shift

somaticStatus=$1
shift

# refFile=$1
# shift


# keyFile="/juno/res/dmpcollab/dmprequest/12-245/key.txt"
keyFile="/juno/dmp/request/12-245/key.txt"

dataDir=/juno/cmo/bergerlab/sumans/Project_BoundlessBio/data

singularity_cache=$HOME/.singularity/cache

image_echoPreProcessor="boundlessbio-echo-preprocessor-v2.0.4.img"
image_echoCaller="boundlessbio-echo-caller-v2.4.0.img"

imagePath_echoPreProcessor=$singularity_cache/$image_echoPreProcessor
#echo $imagePath_echoPreProcessor
imagePath_echoCaller=$singularity_cache/$image_echoCaller

TOP_LEVEL_DIR=${dataDir}
refFile1="b37.fasta"
refFile2="GRCh37_plus_virus.fa"
# REF_FILE=${TOP_LEVEL_DIR}/input/references/b37.fasta
# REF_FILE=${TOP_LEVEL_DIR}/input/references/GRCh37_plus_virus.fa
# REF_FILE=${TOP_LEVEL_DIR}/input/references/${refFile}
BED_FILE=${TOP_LEVEL_DIR}/input/beds/${bedName}
ANNOTATION_FILE=${TOP_LEVEL_DIR}/input/references/refFlat_withoutPrefix.txt
EXCLUDE_FILE=${TOP_LEVEL_DIR}/input/references/human.hg19.excl.tsv
# bedPath=$dataDir/input/beds

mafFile="data_mutations_extended.txt"
mafPath=/work/access/production/resources/cbioportal/current/msk_solid_heme


TUMOR_SAMPLE_ID=${sampleID_Tumor}
echo "Tumor ID = $TUMOR_SAMPLE_ID"
NORMAL_SAMPLE_ID=${sampleID_Normal}
echo "Normal ID = $NORMAL_SAMPLE_ID"

TUMOR_PURITY=${tumor_Purity}
# echo "Tumor Purity = $TUMOR_PURITY"
GENOME_VERSION=hg19


flagDir=$dataDir/flag/flag_8
OUT_DIR=${TOP_LEVEL_DIR}/output/output_8
outDir_Sample=${OUT_DIR}/${TUMOR_SAMPLE_ID}
outDir_flatReference=${outDir_Sample}/flatReference
outDir_preProcessor=${outDir_Sample}/preProcessor
outDir_echoCaller=${outDir_Sample}/echoCaller
# echo "$outDir_echoCaller"

bedPrefix=$(echo "$bedName" | cut -d"." -f1)
outFile_flatRef_1=${outDir_flatReference}/${bedPrefix}.antitarget.bed
outFile_flatRef_2=${outDir_flatReference}/${bedPrefix}.flat.reference.cnn
outFile_flatRef_3=${outDir_flatReference}/${bedPrefix}.target.bed

mkdir -p "$flagDir" 2>/dev/null

flag_inProcess=$flagDir/${TUMOR_SAMPLE_ID}.running
flag_done=$flagDir/${TUMOR_SAMPLE_ID}.done
flag_fail=$flagDir/${TUMOR_SAMPLE_ID}.fail


if [[ ! -f $flag_done ]]; then

    rm -rf "$flag_inProcess" && \
    rm -rf "$flag_fail" && \
    rm -rf "$outDir_Sample" && \
    mkdir -p "$outDir_flatReference" 2>/dev/null && \
    mkdir -p "$outDir_preProcessor" 2>/dev/null && \
    mkdir -p "$outDir_echoCaller" 2>/dev/null &&
    touch "$flag_inProcess"

    

    if [[ "$seqType" == "IMPACT" ]]; then

        bamFilePath_T=$(python3.8 generateBAMFilePath.py $keyFile "$bamMirrorPath" "$TUMOR_SAMPLE_ID" T)
        echo "Tumor Sample BAM File = ${bamFilePath_T}"

        if [[ "$somaticStatus" == "Matched" ]]; then
          bamFilePath_N=$(python3.8 generateBAMFilePath.py $keyFile "$bamMirrorPath" "$NORMAL_SAMPLE_ID" N)
          echo "Normal Sample BAM File = ${bamFilePath_N}"
        fi

    fi

    if [[ -f ${bamFilePath_T} ]]; then
        echo "BAM File Paths exists for Tumor Sample....."
        bamDir_T=$(dirname "$bamFilePath_T")
        BAMHeaderCount=$(samtools view -H "$bamFilePath_T"| grep '^@SQ' | wc -l)
        if [[ $BAMHeaderCount -gt 85 ]]; then
          REF_FILE=${TOP_LEVEL_DIR}/input/references/${refFile2}
          echo "Header Count inside BAM File=$BAMHeaderCount"
          echo "BAM file aligned with b37 + virus Reference ....."
          echo "Reference File = $REF_FILE"
        else 
          REF_FILE=${TOP_LEVEL_DIR}/input/references/${refFile1}
          echo "Header Count inside BAM File=$BAMHeaderCount"
          echo "BAM file aligned with b37 ....."
          echo "Reference File = $REF_FILE"
        fi
         

        # bamName_T=$(basename "$bamFilePath_T")
    fi

    if [[ "$somaticStatus" == "Matched" ]] && [[ -f ${bamFilePath_N} ]]; then
        echo "BAM File Paths exists for Normal Sample....."
        bamDir_N=$(dirname "$bamFilePath_N")
        # bamName_N=$(basename "$bamFilePath_N")

    fi


    if [[ "$somaticStatus" == "Unmatched" ]]; then

      if [[ ! -f ${outFile_flatRef_1} ]] || [[ ! -f ${outFile_flatRef_2} ]] || [[ ! -f ${outFile_flatRef_3} ]]; then

        cmd="singularity run \
          --bind ${TOP_LEVEL_DIR}:${TOP_LEVEL_DIR} \
          ${imagePath_echoPreProcessor} \
          --out_dir ${outDir_flatReference} \
          --ref_fasta ${REF_FILE} \
          --target_bed ${BED_FILE} \
          --annot_file ${ANNOTATION_FILE} \
          reference"

        echo
        echo "Running Step 1: ECHO Pre-Processor - Create Flat Reference ....."
        echo "$cmd"
        echo

        if ! eval "$cmd" ; then
          echo "Step 1 Failed"
          rm "$flag_inProcess" && touch "$flag_fail"
          exit
        else
          echo "Step 1 Done"
        fi
      fi
    fi


    if [[ "$somaticStatus" == "Matched" ]]; then

      cmd="singularity run \
        --bind ${TOP_LEVEL_DIR}:${TOP_LEVEL_DIR},${bamDir_T}:${bamDir_T},${bamDir_N}:${bamDir_N},${mafPath}:${mafPath} \
        ${imagePath_echoPreProcessor}\
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

      echo
      echo "Running Step 2: ECHO Pre-Processor - Tumor Normal Mode ....."
      echo "$cmd"
      echo
      # eval $cmd

      if ! eval "$cmd" ; then
        echo "Step 2 Failed"
        rm "$flag_inProcess" && touch "$flag_fail"
        exit
      else
        echo "Step 2 Done"
      fi
    
    elif [[ "$somaticStatus" == "Unmatched" ]]; then

      cmd="singularity run \
        --bind ${TOP_LEVEL_DIR}:${TOP_LEVEL_DIR},${bamDir_T}:${bamDir_T},${outDir_flatReference}:${outDir_flatReference},${mafPath}:${mafPath} \
        ${imagePath_echoPreProcessor} \
        --out_dir ${outDir_preProcessor} \
        --ref_fasta ${REF_FILE} \
        --ref_genome ${GENOME_VERSION} \
        --target_bed ${BED_FILE} \
        --annot_file ${ANNOTATION_FILE} \
        --exclude ${EXCLUDE_FILE} \
        --tumor_bam ${bamFilePath_T} \
        --tumor_sample_id ${TUMOR_SAMPLE_ID} \
        --reference_cnn ${outFile_flatRef_2} \
        --purity ${TUMOR_PURITY} \
        --maf_file ${mafPath}/${mafFile} \
        preprocess"

      echo
      echo "Running Step 2: ECHO Pre-Processor - Tumor Only Mode ....."
      echo "$cmd"
      echo
      # eval $cmd

      if ! eval "$cmd" ; then
        echo "Step 2 Failed"
        rm "$flag_inProcess" && touch "$flag_fail"
        exit
      else
        echo "Step 2 Done"
      fi

    fi


  cmd="singularity run \
    --bind ${outDir_preProcessor}:${outDir_preProcessor},${outDir_echoCaller}:${outDir_echoCaller} \
    ${imagePath_echoCaller} \
    call \
    --input_folder ${outDir_preProcessor} \
    --output_folder ${outDir_echoCaller} \
    --ref_genome ${GENOME_VERSION}"

  echo
  echo "Running Step 3: ECHO Caller ....."
  echo "$cmd"
  echo

  if ! eval "$cmd" ; then
    echo "Step 3 Failed"
    rm "$flag_inProcess" && touch "$flag_fail"

  else
    echo "Step 3 Done"
    rm "$flag_inProcess" && touch "$flag_done"
  fi

  echo
  echo "All Done"
  
fi
