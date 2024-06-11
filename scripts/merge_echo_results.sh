#!/bin/bash

dataDir=/juno/cmo/bergerlab/sumans/Project_BoundlessBio/data
outputDir=${dataDir}/output/output_8
mergedFile=${outputDir}/merged.ECHO_results.csv

count=0

for i in "$outputDir"/*/*/*.csv; do

  echo "$i"
  echo "$count"

  [[ -e "$i" ]] || break

  if [[ "$count" == 0 ]]; 
  then
    cat "$i" > ${mergedFile}
  else
    < "$i" tail -n+2 >> ${mergedFile}
  fi

 count=$((count+1))

done


echo "Total Files Found = $count"
