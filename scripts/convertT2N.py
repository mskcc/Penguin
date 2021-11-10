import os
import sys
import pandas as pd
#sampleID="P-0060192-T01-IM7"


def convertT2N(sampleID):

    ID=sampleID.split('-')

    ID[2]='N01'

    ID_N='-'.join(ID)

    return(ID_N)


def convertWgs2Bam(sampleID):

    ID=sampleID.split('-')
    BAMID="s_"+'_'.join(ID)
    return(BAMID)

def findWESPair(sampleID, mapFile):

    pairFile=mapFile
    dfPair=pd.read_csv(pairFile, sep='\t', skiprows=2)
    BAMID=dfPair[dfPair.iloc[:,0].str.contains(sampleID)].iloc[:,1].values[0]
    return(BAMID)


import argparse
import os
import sys

#sampleID=sys.argv[1]

# required arg

parser = argparse.ArgumentParser()

parser.add_argument('--sID', required=True)

parser.add_argument('--aType', required=True)

parser.add_argument('--mapFile', required=False)

args = parser.parse_args()


sampleID=args.sID

analysisType=args.aType

if args.mapFile is not None:
    mapFile=args.mapFile

if analysisType == "impact_N":
    outputID=convertT2N(sampleID)
    print(outputID)

elif analysisType == "WES":
    outputID=convertWgs2Bam(sampleID)
    print(outputID)

elif analysisType == "WES_P":
    outputID=findWESPair(sampleID, mapFile)
    print(outputID)
