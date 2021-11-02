

keyFile="/Users/sumans/Projects/Project_BoundlessBio/data/input/key.txt"
#keyFile="/juno/res/dmpcollab/dmprequest/12-245/key.txt"

bamMirrorPath="/juno/res/dmpcollab/dmpshare/share/irb12_245"

#sampleID="P-0051445-T01-IM6"
sampleID="P-0066791-T02-IM7"

# python generateBAMFilePath.py $keyFile $bamMirrorPath $sampleID

bamFilePath=`python generateBAMFilePath.py $keyFile $bamMirrorPath $sampleID`

echo $bamFilePath
