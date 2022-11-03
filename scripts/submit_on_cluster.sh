#!/bin/bash

dataDir=/juno/work/bergerm1/bergerlab/sumans/Project_BoundlessBio/data
logDir=${dataDir}/log_v3

mkdir -p $logDir 2>/dev/null

ts=$(date +%Y%m%d%H%M%S)

#seqType="IMPACT"
#impactPanel="IM7"
impactPanel="IM6"
aType=1

# for seqType in IMPACT WES; do
for seqType in IMPACT; do

  cmd="bsub \
      -W 72:00 \
      -n 4 \
      -R 'rusage[mem=64]' \
      -J 'echo.preProcess.${seqType}' \
      -o '${logDir}/echo.preProcess.${seqType}.${ts}.stdout' \
      -e '${logDir}/echo.preProcess.${seqType}.${ts}.stderr' \
      ./preProcess_multipleSamples_v2.sh \
      $seqType \
      $impactPanel \
      $aType"

    echo $cmd
    echo "submitting Job for $seqType"
    echo
    eval $cmd

done
