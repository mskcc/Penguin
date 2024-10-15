#!/bin/bash
set -euo pipefail

# config file
CONFIG_FILE=$1
CONFIG_FILE=$(readlink -f "$CONFIG_FILE")

source $CONFIG_FILE


dataDir=$dataDirectory
dataDir=$(readlink -f "$dataDir")

outputDir=${mergedOutputDirectory}
mergedFile_1=${outputDir}/merged_ecDNA_results_${suffix_ecDNA_file1}
mergedFile_2=${outputDir}/merged_ecDNA_results_${suffix_ecDNA_file2}
mergedFile_3=${outputDir}/merged_ecDNA_results_${suffix_ecDNA_file3}
echoOutputDir=${echoOutputDirectory}

mkdir -p $outputDir 2>/dev/null

echo "Scanning ${echoFlagDirectory}"
countFail=$(find ${echoFlagDirectory} -type f -name "*.fail" | wc -l)
echo "Number of fail files found: $countFail"
countRunning=$(find ${echoFlagDirectory} -type f -name "*.running" | wc -l)
echo "Number of running files found: $countRunning"
echo

if [ -f "$mergedFile_1" ]; then
  rm $mergedFile_1
fi

count=0

for i in "$echoOutputDir"/*/*/*_${suffix_ecDNA_file1}; do

  [[ -e "$i" ]] || { echo "File $i not found, skipping."; continue; }

  if [[ "$count" == 0 ]]; 
  then
    cat "$i" > ${mergedFile_1}
  else
    < "$i" tail -n+2 >> ${mergedFile_1}
  fi

 count=$((count+1))

done

echo "Total Files Found (filtered by p_ecDNA) = $count"
echo "The Merged File with ecDNA results (filtered by p_ecDNA) = $mergedFile_1"
echo


if [ -f "$mergedFile_2" ]; then
  rm $mergedFile_2
fi

count=0

for i in "$echoOutputDir"/*/*/*_${suffix_ecDNA_file2}; do

  [[ -e "$i" ]] || { echo "File $i not found, skipping."; continue; }

  if [[ "$count" == 0 ]]; 
  then
    cat "$i" > ${mergedFile_2}
  else
    < "$i" tail -n+2 >> ${mergedFile_2}
  fi

 count=$((count+1))

done

echo "Total Files Found (filtered by p_ecDNA & filtered by IMPACT gene list) = $count"
echo "The Merged File with ecDNA results (filtered by p_ecDNA & filtered by IMPACT gene list) = $mergedFile_2"
echo



if [ -f "$mergedFile_3" ]; then
  rm $mergedFile_3
fi

count=0

for i in "$echoOutputDir"/*/*/*_${suffix_ecDNA_file3}; do

  [[ -e "$i" ]] || { echo "File $i not found, skipping."; continue; }

  if [[ "$count" == 0 ]]; 
  then
    cat "$i" > ${mergedFile_3}
  else
    < "$i" tail -n+2 >> ${mergedFile_3}
  fi

 count=$((count+1))

done

echo "Total Files Found (filtered by p_ecDNA & NOT present in IMPACT gene list) = $count"
echo "The Merged File with ecDNA results (filtered by p_ecDNA & NOT present in IMPACT gene list) = $mergedFile_3"
echo