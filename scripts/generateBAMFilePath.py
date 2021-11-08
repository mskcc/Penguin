import os
import sys
import pandas as pd



keyFile=sys.argv[1]
#print(keyFile)

bamMirrorPath=sys.argv[2]


sampleID=sys.argv[3]
#print(sampleID)

sampleType=sys.argv[4]


df=pd.read_csv(keyFile, header=None)

if sampleType == "T":

    bamID=df[df.iloc[:,0].str.contains(sampleID)].iloc[:,1].values[0]
    #print(bamID)

elif sampleType == "N":

    ID=sampleID.split('-')
    ID[2]='N..'
    ID_N='-'.join(ID)

    bamID=df[df.iloc[:,0].str.contains(ID_N)].iloc[:,1].values[0]
    #print(bamID)

bamFilePath=os.path.join(bamMirrorPath,bamID[0],bamID[1],bamID + ".bam")
print(bamFilePath)
