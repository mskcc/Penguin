

#keyFile="/Users/sumans/Projects/Project_BoundlessBio/data/input/key.txt"
keyFile="/juno/res/dmpcollab/dmprequest/12-245/key.txt"

bamMirrorPath="/juno/res/dmpcollab/dmpshare/share/irb12_245"

#sampleID="P-0051445-T01-IM6"
sampleID="P-0066791-T02-IM7"

# python generateBAMFilePath.py $keyFile $bamMirrorPath $sampleID

bamFilePath=`python generateBAMFilePath.py $keyFile $bamMirrorPath $sampleID`

echo $bamFilePath

dataDir=/home/sumans/Projects/Project_BoundlessBio/data

image="mskcc_echo_preprocess.sif"

imagePath=$dataDir/$image
echo $imagePath

mafFile="data_mutations_extended.txt"
mafPath=$dataDir/input/

bamDir=$(dirname $bamFilePath)
bamName=$(basename $bamFilePath)

bedPath=$dataDir/input/beds
bedName="IMPACT505_picard_baits-1.interval_list"
bedNameImage="IMPACT505_picard_baits.bed"

outPath=$dataDir/output
outFile_step1=${sampleID}.cnn
outFile_step2=${sampleID}_historgram.csv

cmd="singularity run \
  --bind ${mafPath}:/home/input/ \
  --bind ${outPath}:/home/output/ \
  ${imagePath} \
  --sample ${sampleID} \
  --maf_file /home/input/${mafFile} \
  --output_file /home/output/${outFile_step2} \
  --step process_vcf"

echo $cmd

#eval $cmd



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


echo
echo $cmd

eval $cmd
