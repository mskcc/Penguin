#!/bin/bash

dataDir=/home/sumans/Projects/Project_BoundlessBio/data
logDir=${dataDir}/log

mkdir -p $logDir 2>/dev/null

ts=$(date +%Y%m%d%H%M%S)

#seqType="IMPACT"
#impactPanel="IM7"
impactPanel="IM6"
aType=2

for seqType in IMPACT WES; do

  cmd="bsub \
      -W 20:00 \
      -n 4 \
      -R 'rusage[mem=15]' \
      -J 'echo.preProcess.${seqType}' \
      -o '${logDir}/echo.preProcess.${seqType}.${ts}.stdout' \
      -e '${logDir}/echo.preProcess.${seqType}.${ts}.stderr' \
      ./preProcess_multipleSamples.sh \
      $seqType \
      $impactPanel \
      $aType"

    echo $cmd
    echo "submitting Job for $seqType"
    echo
    eval $cmd

done
