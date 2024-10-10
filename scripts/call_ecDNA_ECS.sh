#!/bin/bash

# Set up config file
CONFIG_FILE=$1
shift
CONFIG_FILE=$(readlink -f "$CONFIG_FILE")

source $CONFIG_FILE

outputDir=$echoOutputDirectory
outputDir=$(readlink -f "$outputDir")

flagDir=$echoFlagDirectory

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

BED_FILE=$1
shift

seqType=$1
shift

tumor_Purity=$1
shift

somaticStatus=$1
shift

normalSample_pon=$1
shift

# refFile=$1
# shift


# keyFile="/juno/res/dmpcollab/dmprequest/12-245/key.txt"
# keyFile=$keyFile

dataDir=$dataDirectory
dataDir=$(readlink -f "$dataDir")

# singularity_cache=$singularity_cache

# image_echoPreProcessor="boundlessbio-echo-preprocessor-v2.0.4.img"
# image_echoCaller="boundlessbio-echo-caller-v2.4.0.img"

# imagePath_echoPreProcessor=$imagePath_echoPreProcessor
# imagePath_echoCaller=$imagePath_echoCaller

TOP_LEVEL_DIR=${dataDir}
# refFile1=$refFile1
# refFile2=$refFile2
# REF_FILE=${TOP_LEVEL_DIR}/input/references/b37.fasta
# REF_FILE=${TOP_LEVEL_DIR}/input/references/GRCh37_plus_virus.fa
# REF_FILE=${TOP_LEVEL_DIR}/input/references/${refFile}
inputDirectory=$(readlink -f "$inputDirectory")
# BED_FILE=${bedFolder}/${bedName}
# ANNOTATION_FILE=$ANNOTATION_FILE
# EXCLUDE_FILE=$EXCLUDE_FILE
# ENCODE_EXCLUDE_FILE=$ENCODE_EXCLUDE_FILE
# bedPath=$dataDir/input/beds

# mafFile=$mafFile
# mafPath=$mafPath


TUMOR_SAMPLE_ID=${sampleID_Tumor}
echo "Tumor ID = $TUMOR_SAMPLE_ID"
NORMAL_SAMPLE_ID=${sampleID_Normal}
echo "Normal ID = $NORMAL_SAMPLE_ID"

TUMOR_PURITY=${tumor_Purity}
echo "Tumor Purity = $TUMOR_PURITY"
GENOME_VERSION=$GENOME_VERSION


OUT_DIR=${outputDir}
OUT_DIR=$(readlink -f "$OUT_DIR")
outDir_Sample=${OUT_DIR}/${TUMOR_SAMPLE_ID}
outDir_flatReference=${outDir_Sample}/flatReference
outDir_preProcessor=${outDir_Sample}/preProcessor
outDir_echoCaller=${outDir_Sample}/echoCaller
# echo "$outDir_echoCaller"

bedPrefix=$(basename "$BED_FILE" .bed)
outFile_flatRef_1=${outDir_flatReference}/ECS_${bedPrefix}.large.antitarget.bed
outFile_flatRef_2=${outDir_flatReference}/ECS_${bedPrefix}_pon_large.reference.cnn
outFile_flatRef_3=${outDir_flatReference}/ECS_${bedPrefix}.large.target.bed

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

        cmd="python3.8 generateBAMFilePath.py \"$keyFile\" \"$bamMirrorPath\" \"$TUMOR_SAMPLE_ID\" T"
        if ! bamFilePath_T=$(eval $cmd); then
          echo "BAM file not found"
          rm "$flag_inProcess" && touch "$flag_fail"
          exit 1
        fi
        echo "Tumor Sample BAM File = ${bamFilePath_T}"

        if [[ "$somaticStatus" == "Matched" ]]; then
          cmd="python3.8 generateBAMFilePath.py \"$keyFile\" \"$bamMirrorPath\" \"$NORMAL_SAMPLE_ID\" N"
        else
          cmd="python3.8 generateBAMFilePath.py \"$keyFile\" \"$bamMirrorPath\" \"$normalSample_pon\" N"
        fi

        if ! bamFilePath_N=$(eval $cmd); then
          echo "BAM file not found"
          rm "$flag_inProcess" && touch "$flag_fail"
          exit 1
        else
          echo "Normal Sample BAM File = ${bamFilePath_N}"
        fi
        

    fi

    if [[ -f ${bamFilePath_T} ]]; then
        echo "BAM File Paths exists for Tumor Sample....."
        bamDir_T=$(dirname "$bamFilePath_T")
        BAMHeaderCount=$(samtools view -H "$bamFilePath_T"| grep '^@SQ' | wc -l)

        # This is a failure point
        if [ $? -gt 0 ]; then
            echo "samtools command failed with exit status $?"
            rm "$flag_inProcess" && touch "$flag_fail"
            exit 1
        fi
        
        if [[ $BAMHeaderCount -gt 85 ]]; then
          REF_FILE_T=${referenceDirectory}/${refFile2}
          echo "Header Count inside Tumor BAM File=$BAMHeaderCount"
          echo "Tumor BAM file aligned with b37 + virus Reference ....."
          echo "Reference File for Tumor Sample = $REF_FILE_T"
          
        else 
          REF_FILE_T=${referenceDirectory}/${refFile1}
          echo "Header Count inside Tumor BAM File=$BAMHeaderCount"
          echo "Tumor BAM file aligned with b37 ....."
          echo "Reference File for Tumor Sample = $REF_FILE_T"
        fi
         
    else
        echo "Tumor BAM file not found"
        rm "$flag_inProcess" && touch "$flag_fail"
        exit 1
        # bamName_T=$(basename "$bamFilePath_T")
    fi

    if [[ -f ${bamFilePath_N} ]]; then
        echo "BAM File Paths exists for Normal Sample....."
        bamDir_N=$(dirname "$bamFilePath_N")
        BAMHeaderCount=$(samtools view -H "$bamFilePath_N"| grep '^@SQ' | wc -l)

        # This is a failure point
        if [ $? -gt 0 ]; then
            echo "samtools command failed with exit status $?"
            rm "$flag_inProcess" && touch "$flag_fail"
            exit 1
        fi
        
        if [[ $BAMHeaderCount -gt 85 ]]; then
          REF_FILE_N=${referenceDirectory}/${refFile2}
          echo "Header Count inside Normal BAM File=$BAMHeaderCount"
          echo "Normal BAM file aligned with b37 + virus Reference ....."
          echo "Reference File for Normal Sample = $REF_FILE_N"
          
        else 
          REF_FILE_N=${referenceDirectory}/${refFile1}
          echo "Header Count inside Normal BAM File=$BAMHeaderCount"
          echo "Normal BAM file aligned with b37 ....."
          echo "Reference File for Normal Sample = $REF_FILE_N"
        fi
         
    else
        echo "Normal BAM file not found"
        rm "$flag_inProcess" && touch "$flag_fail"
        exit 1
        # bamName_T=$(basename "$bamFilePath_T")
    fi

    # if [[ "$somaticStatus" == "Matched" ]] && [[ -f ${bamFilePath_N} ]]; then
    #     echo "BAM File Paths exists for Normal Sample....."
    #     bamDir_N=$(dirname "$bamFilePath_N")
    #     # bamName_N=$(basename "$bamFilePath_N")
    
    # elif [[ "$somaticStatus" == "Matched" ]]; then
    #     echo "Normal BAM file not found"
    #     rm "$flag_inProcess" && touch "$flag_fail"
    #     exit 1
    # fi

    if [[ "$somaticStatus" == "Matched" ]]; then

        PON_BAMS_LIST=$bamFilePath_N

    elif [[ "$somaticStatus" == "Unmatched" ]]; then

        PON_BAMS_LIST=$bamFilePath_N

    fi

    if [[ ! -f ${outFile_flatRef_1} ]] || [[ ! -f ${outFile_flatRef_2} ]] || [[ ! -f ${outFile_flatRef_3} ]]; then

      cmd="singularity run \
        --bind ${TOP_LEVEL_DIR}:${TOP_LEVEL_DIR},${bamDir_N}:${bamDir_N},${referenceDirectory}:${referenceDirectory} \
        ${imagePath_echoPreProcessor} \
        reference \
        --out_dir ${outDir_flatReference} \
        --ref_fasta ${REF_FILE_N} \
        --target_bed ${BED_FILE} \
        --annot_file ${ANNOTATION_FILE} \
        --pon ${PON_BAMS_LIST} \
        --mode ecs \
        --exclude_bed ${ENCODE_EXCLUDE_FILE}
        "

      echo
      echo "Running Step 1: ECHO Pre-Processor - Create Reference Panel of Normals (pon)....."
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
    


  cmd="singularity run \
    --bind ${TOP_LEVEL_DIR}:${TOP_LEVEL_DIR},${bamDir_T}:${bamDir_T},${outDir_flatReference}:${outDir_flatReference},${mafPath}:${mafPath},${referenceDirectory}:${referenceDirectory} \
    ${imagePath_echoPreProcessor} \
    preprocessor \
    --out_dir ${outDir_preProcessor} \
    --ref_fasta ${REF_FILE_T} \
    --ref_genome ${GENOME_VERSION} \
    --target_bed ${BED_FILE} \
    --annot_file ${ANNOTATION_FILE} \
    --exclude ${EXCLUDE_FILE} \
    --tumor_bam ${bamFilePath_T} \
    --tumor_sample_id ${TUMOR_SAMPLE_ID} \
    --reference_cnn ${outFile_flatRef_2}"

  echo
  echo "Running Step 2: ECHO Pre-Processor - Run ECHO preprocessor with Reference ....."
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


  cmd="singularity run \
    --bind ${TOP_LEVEL_DIR}:${TOP_LEVEL_DIR},${outDir_preProcessor}:${outDir_preProcessor},${outDir_echoCaller}:${outDir_echoCaller},${referenceDirectory}:${referenceDirectory} \
    ${imagePath_echoCaller} \
    --inputs ${outDir_preProcessor} \
    --sample_id ${TUMOR_SAMPLE_ID} \
    --target_bed ${BED_FILE} \
    --output_folder ${outDir_echoCaller} \
    --ref_genome ${GENOME_VERSION}"

  echo
  echo "Running Step 3:  Run ECHO (ECS) caller ....."
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
