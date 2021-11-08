
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


import argparse
import os
import sys

#sampleID=sys.argv[1]

# required arg

parser = argparse.ArgumentParser()

parser.add_argument('--sID', required=True)

parser.add_argument('--aType', required=True)

args = parser.parse_args()


sampleID=args.sID

analysisType=args.aType

if analysisType == "impact_N":
    outputID=convertT2N(sampleID)
    print(outputID)

elif analysisType == "WES":
    outputID=convertWgs2Bam(sampleID)
    print(outputID)
