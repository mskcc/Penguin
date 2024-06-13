'''
This script takes in a FileA manifest document and changes the purity
from pathological to facets called tumor purity for a subset in FileB
'''

import os
import sys
import argparse
import pandas as pd
import math

# TODO: allow for analysisType 2
# Right now only for aType 1

'''
Checks if file is an xlsx file
'''
def is_xlsx(file) :
    with open(file, 'rb') as f :
        try : 
            magic_number = f.read(4) # finds magic number if it exists
            return magic_number == b'\x50\x4B\x03\x04'
        except :
            return False

###################
# Parse arguments #
###################

parser = argparse.ArgumentParser()
# FileA to change
parser.add_argument('--sampleManifest', required=True)
# Path to the output FileA
parser.add_argument('--outputFile', required=True)
# Path to FileB. Assumes it is not an xlsx
parser.add_argument('--subsetFile', required=True)
# ID Column
parser.add_argument('--sampleIDColumn', required=True)
# Purity Column
parser.add_argument('--samplePurityColumn', required=True)
# Data directory
parser.add_argument('--dataDirectory', required=True)

args = parser.parse_args()

FileA = args.sampleManifest
FileB = args.subsetFile
IDCol = int(args.sampleIDColumn)
PurityCol = int(args.samplePurityColumn)
outFile = args.outputFile
dataDir = args.dataDirectory

###################
# Generate Facets #
###################

from facetsAPI import *

clinical_sample_file= dataDir + "/input/data_clinical_sample.oncokb.txt"
facets_dir="/work/ccs/shared/resources/impact/facets/all/"
dummyReport = "./facets_report.to_delete"

prepared_metadata = FacetsMeta(clinical_sample_file, facets_dir, "purity")
prepared_metadata.setSingleRunPerSample(True,True)
prepared_metadata.selectSamplesFromFile(FileB)

prepared_metadata.buildFacetsMeta()
test_dataset = FacetsDataset(prepared_metadata)
test_dataset.buildFacetsDataset()

# Write a report to delete later
test_dataset.writeReport(dummyReport)

##################
# Convert Purity #
##################

facets_df = pd.read_csv(dummyReport, sep = '\t', index_col = False)

# get FileA into a dataframe
if is_xlsx(FileA) :
    print("FileA is xlsx")
    fileA_df = pd.read_excel(FileA, engine='openpyxl', header = None)
else :
    print("FileA is tsv")
    fileA_df = pd.read_csv(FileA, sep = '\t', header = None)

# Get the subset of fileA
subset_fileA_df = fileA_df[fileA_df.iloc[:, IDCol].isin(facets_df['ID'])]

# Convert purity
facets_df['Facets Purity'] = (facets_df['Facets Purity'] * 100).apply(lambda x: math.ceil(x)).astype(int)

# Ensure the correct ordering
if len(subset_fileA_df) != len(facets_df) :
    print("FileB not a subset of FileA")
    sys.exit(1)
subset_fileA_df = subset_fileA_df.sort_values(by = subset_fileA_df.columns[IDCol], ascending = True)
facets_df = facets_df.sort_values(by = 'ID', ascending = True)

# Replace purity
subset_fileA_df.iloc[:, PurityCol] = facets_df['Facets Purity'].values

# Export
subset_fileA_df.to_csv(outFile, sep='\t', index = False, header = False)