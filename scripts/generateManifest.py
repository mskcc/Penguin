import os
import sys
import argparse
import pandas as pd


parser = argparse.ArgumentParser()

parser.add_argument('--impactPanel', required=False)

parser.add_argument('--subsetFile', required=False)

parser.add_argument('--sampleManifest', required=True)

parser.add_argument('--outputFile', required=False)

parser.add_argument('--aType', required=True)

parser.add_argument('--sampleIDColumn', required=False)

args = parser.parse_args()

if args.impactPanel is not None:
    regString=args.impactPanel

if args.subsetFile is not None:
    subsetFile=args.subsetFile

if args.sampleIDColumn is not None:
    sampleIDColumn=int(args.sampleIDColumn)

sampleTrackerFilePath=args.sampleManifest
outputManifestPath=args.outputFile
analysisType=int(args.aType)
#print("Test")
#print(type(analysisType))
print(sampleIDColumn)

if analysisType == 1:

    # df = pd.read_excel(sampleTrackerFilePath, engine='openpyxl')
    # df3=df[df.iloc[:,0].str.contains(regString)==True]
    # df3.to_csv(outputManifestPath, sep='\t', index=False)

    df = pd.read_excel(sampleTrackerFilePath, engine='openpyxl')
    df_1=pd.read_excel(subsetFile, engine='openpyxl', header=None)
    listOfIDs=df_1.iloc[:,0].unique().tolist()
    df_filtered=df[df.iloc[:,sampleIDColumn].isin(listOfIDs)]
    # df_filtered_merged=pd.merge(df_filtered, df_1, left_on="DMP Sample ID", right_on="Sample ID")
    df_filtered.to_csv(outputManifestPath, sep='\t', index=False)
    # df_filtered_merged.to_csv(outputManifestPath, sep='\t', index=False)


elif analysisType == 2:

    #print("Test")

    df = pd.read_excel(sampleTrackerFilePath, engine='openpyxl')
    df_1=pd.read_excel(subsetFile, engine='openpyxl')
    listOfIDs=df_1.iloc[:,sampleIDColumn].unique().tolist()
    df_filtered=df[df.iloc[:,0].isin(listOfIDs)]
    df_filtered_merged=pd.merge(df_filtered, df_1, left_on="DMP Sample ID", right_on="Sample ID")
    # df_filtered.to_csv(outputManifestPath, sep='\t', index=False)
    df_filtered_merged.to_csv(outputManifestPath, sep='\t', index=False)
