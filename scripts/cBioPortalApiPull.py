from email.policy import default
from bravado.client import SwaggerClient
from bravado.requests_client import RequestsClient
import sys
import pandas as pd

# Read in token value
tokenFile = sys.argv[1]

with open(tokenFile, 'r') as file :
    token = file.readline().strip()
    token = token.split(': ')[1]

http_client = RequestsClient()
http_client.set_api_key(
    'cbioportal.mskcc.org', 'Bearer ' + token,
    param_name='Authorization', param_in='header'
)

# Get the list of samples
fileB = sys.argv[2]

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

if is_xlsx(fileB) :
    manifest = pd.read_excel(fileB, engine='openpyxl', header=None, names=['sampleId'])
else :
    manifest = pd.read_csv(fileB, sep = '\t', header = None, names=['sampleId'])

def isCorrectPanel(row) :
    panelName = row['sampleId'].split('-')[3]
    if panelName == "IM3" or panelName == "IM5" or panelName == "IM6" or panelName == "IM7" :
        return True
    return False

# Remove samples which are not the correct impact panels
for idx, row in manifest.iterrows() :
    if not isCorrectPanel(row) :
        print(f"Dropping {row['sampleId']}, Panel Incorrect")
mask = manifest.apply(isCorrectPanel, axis = 1)
manifest = manifest[mask]

# Set up defaults
defaultPurity = int(sys.argv[4])
manifest['TumorPurity'] = defaultPurity
manifest['SomaticStatus'] = 'Unmatched'

# Set up a dictionary
sample_dict = {}
for idx, row in manifest.iterrows() :
    sample_dict[row['sampleId']] = idx

# Set up cbioportal
cbioportal = SwaggerClient.from_url('https://cbioportal.mskcc.org/api/v2/api-docs',
                                    http_client=http_client,
                                    config={"validate_requests":False,
                                            "validate_responses":False,
                                            "validate_swagger_spec": False}
)

all_impact = cbioportal.Clinical_Data.getAllClinicalDataInStudyUsingGET(studyId = "mskimpact").result()

for data in all_impact :
    if data.sampleId in sample_dict :
        if data.clinicalAttributeId == "SOMATIC_STATUS" :
            manifest.loc[sample_dict[data.sampleId], "SomaticStatus"] = data.value
        if data.clinicalAttributeId == "TUMOR_PURITY" :
            try :
                manifest.loc[sample_dict[data.sampleId], "TumorPurity"] = int(data.value)
            except :
                manifest.loc[sample_dict[data.sampleId], "SomaticStatus"] = defaultPurity
        
# Export
outFile = sys.argv[3]
if outFile.endswith('.xlsx') :
    manifest.to_excel(outFile, index = False, header = False)
else :
    manifest.to_csv(outFile, sep = '\t', index = False, header = False)