#!/bin/bash

CONFIG_FILE=$1
shift
source $CONFIG_FILE

listOfSamples=$1
shift

mkdir -p $echoLogDirectory 2>/dev/null

clusterCPUNum=$clusterCPUNum
clusterMemory=$clusterMemory
clusterTime=$clusterTime

if [[ $clusterTime != *:* ]]; then
    clusterTime="${clusterTime}:00"
fi

ts=$(date +%Y%m%d%H%M%S)

cmd="bsub \
    -W ${clusterTime} \
    -n ${clusterCPUNum} \
    -R 'rusage[mem=${clusterMemory}]' \
    -J 'call_submit_on_cluster' \
    -o '${logDirectory}/call_submit_on_cluster.${ts}.stdout' \
    -e '${logDirectory}/call_submit_on_cluster.${ts}.stderr' \
    sh submit_on_cluster.sh $CONFIG_FILE $listOfSamples"
echo "$cmd"
eval $cmd