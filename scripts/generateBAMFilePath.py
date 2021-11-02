import os
import sys
import pandas as pd



keyFile=sys.argv[1]
#print(keyFile)

bamMirrorPath=sys.argv[2]


sampleID=sys.argv[3]
#print(sampleID)


df=pd.read_csv(keyFile, header=None)

bamID=df[df.iloc[:,0].str.contains(sampleID)].iloc[:,1].values[0]
#print(bamID)

bamFilePath=os.path.join(bamMirrorPath,bamID[0],bamID[1],bamID + ".bam")
print(bamFilePath)
