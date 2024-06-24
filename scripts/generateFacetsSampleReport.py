'''
This script generates a FACETS sample report
'''

import os
import sys
import argparse
import pandas as pd
import math



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

# FileB, list of genes
parser.add_argument('--subsetFile', required=True)
# output 
parser.add_argument('--outputFile', required=True)
# data directory
parser.add_argument('--dataDirectory', required=True)


args = parser.parse_args()

FileB = args.subsetFile
outFile = args.outputFile
dataDir = args.dataDirectory


###################
# Generate Facets #
###################

from facetsAPI import *

clinical_sample_file= dataDir + "/input/data_clinical_sample.oncokb.txt"
facets_dir="/work/ccs/shared/resources/impact/facets/all/"

prepared_metadata = FacetsMeta(clinical_sample_file, facets_dir, "purity")
prepared_metadata.setSingleRunPerSample(True,True)
prepared_metadata.selectSamplesFromFile(FileB)

prepared_metadata.buildFacetsMeta()
test_dataset = FacetsDataset(prepared_metadata)
test_dataset.buildFacetsDataset()

# Write a report
test_dataset.writeReport(outFile)