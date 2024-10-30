from email.policy import default
from bravado.client import SwaggerClient
from bravado.requests_client import RequestsClient
import sys
import pandas as pd
import json

# Read in token value
tokenFile = sys.argv[1]
# Get the list of samples
fullFileB = sys.argv[2]
# Three outputs
subsetFileB = sys.argv[3]
fullFileA = sys.argv[4]
subsetFileA = sys.argv[5]
defaultPurity = int(sys.argv[6])
exclusionFile = sys.argv[7]


with open(tokenFile, 'r') as file :
    token = file.readline().strip()
    token = token.split(': ')[1]

http_client = RequestsClient()
http_client.set_api_key(
    'cbioportal.mskcc.org', 'Bearer ' + token,
    param_name='Authorization', param_in='header'
)

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

if is_xlsx(fullFileB) :
    manifest = pd.read_excel(fullFileB, engine='openpyxl', header=None, names=['sampleId'])
else :
    manifest = pd.read_csv(fullFileB, sep = '\t', header = None, names=['sampleId'])

'''
Determines if the panel used is useable for this analysis
'''
def isCorrectPanel(row) :
    panelName = row['sampleId'].split('-')[3]
    if panelName == "IM3" or panelName == "IM5" or panelName == "IM6" or panelName == "IM7" or panelName == "IH4" or panelName == "IH3" :
        return True
    return False

# Set up defaults
manifest['TumorPurity'] = defaultPurity
manifest['SomaticStatus'] = 'Unmatched'
manifest['cancerType'] = 'NA'
manifest['cancerTypeDetailed'] = 'NA'
manifest['oncotreeCode'] = 'NA'
manifest['msiScore'] = 'NA'
manifest['msiType'] = 'NA'
manifest['mutationCount'] = 'NA'
manifest['tumorBurdenScore'] = 'NA'
manifest['fractionAltered'] = 'NA'
manifest['sampleType'] = 'NA'

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

# with open('/juno/cmo/bergerlab/sumans/Project_ecDNA/Production/api-docs.json') as f:
#     api_spec = json.load(f)

# cbioportal = SwaggerClient.from_spec(
#     api_spec,  # Local file path
#     http_client=http_client,
#     config={
#         "validate_requests": False,
#         "validate_responses": False,
#         "validate_swagger_spec": False
#     }
# )

# Fill in sample-wise info (Somatic status, tumor purity, cancer type, cancer type detailed)
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
        if data.clinicalAttributeId == "CANCER_TYPE" :
            manifest.loc[sample_dict[data.sampleId], "cancerType"] = data.value
        if data.clinicalAttributeId == "CANCER_TYPE_DETAILED" :
            manifest.loc[sample_dict[data.sampleId], "cancerTypeDetailed"] = data.value
        if data.clinicalAttributeId == "FRACTION_GENOME_ALTERED" :
            manifest.loc[sample_dict[data.sampleId], "fractionAltered"] = data.value
        if data.clinicalAttributeId == "MSI_SCORE" :
            manifest.loc[sample_dict[data.sampleId], "msiScore"] = data.value
        if data.clinicalAttributeId == "MSI_TYPE" :
            manifest.loc[sample_dict[data.sampleId], "msiType"] = data.value
        if data.clinicalAttributeId == "MUTATION_COUNT" :
            manifest.loc[sample_dict[data.sampleId], "mutationCount"] = data.value
        if data.clinicalAttributeId == "FRACTION_GENOME_ALTERED" :
            manifest.loc[sample_dict[data.sampleId], "fractionAltered"] = data.value
        if data.clinicalAttributeId == "ONCOTREE_CODE" :
            manifest.loc[sample_dict[data.sampleId], "oncotreeCode"] = data.value
        if data.clinicalAttributeId == "SAMPLE_TYPE" :
            manifest.loc[sample_dict[data.sampleId], "sampleType"] = data.value
        if data.clinicalAttributeId == "CVR_TMB_SCORE" :
            manifest.loc[sample_dict[data.sampleId], "tumorBurdenScore"] = data.value

# Fill in patient-wise info
all_impact_patient = cbioportal.Clinical_Data.getAllClinicalDataInStudyUsingGET(studyId = "mskimpact", clinicalDataType = 'PATIENT').result()

manifest['patientId'] = manifest['sampleId'].apply(lambda x: x.split('-', 2)[0] + '-' + x.split('-', 2)[1])
manifest['12_245_partA'] = 'NA'
manifest['osStatus'] = 'NA'
manifest['osMonths'] = 'NA'
manifest['deIDAge'] = 'NA'
manifest['stageHighest'] = 'NA'


patient_dict = {}
for idx, row in manifest.iterrows() :
    if row['patientId'] in patient_dict :
        patient_dict[row['patientId']] += ',' + str(idx)
    else :
        patient_dict[row['patientId']] = str(idx)


for data in all_impact_patient :
    if data.patientId in patient_dict :
        if data.clinicalAttributeId == "PARTA_CONSENTED_12_245" :
            for idx in patient_dict[data.patientId].split(',') :
                idx = int(idx)
                manifest.loc[idx, "12_245_partA"] = data.value
        elif data.clinicalAttributeId == "OS_MONTHS" :
            for idx in patient_dict[data.patientId].split(',') :
                idx = int(idx)
                manifest.loc[idx, "osMonths"] = data.value
        elif data.clinicalAttributeId == "OS_STATUS" :
            for idx in patient_dict[data.patientId].split(',') :
                idx = int(idx)
                manifest.loc[idx, "osStatus"] = data.value.split(':')[1]
        elif data.clinicalAttributeId == "STAGE_HIGHEST_RECORDED" :
            for idx in patient_dict[data.patientId].split(',') :
                idx = int(idx)
                manifest.loc[idx, "stageHighest"] = data.value
        elif data.clinicalAttributeId == "CURRENT_AGE_DEID" :
            for idx in patient_dict[data.patientId].split(',') :
                idx = int(idx)
                manifest.loc[idx, "deIDAge"] = data.value
        
subsetManifest = manifest

exclusion_df = pd.DataFrame(columns = ['sampleId', 'reason'])

# Remove samples which are not the correct impact panels
for idx, row in subsetManifest.iterrows() :
    if not isCorrectPanel(row) :
        print(f"Dropping {row['sampleId']}, Panel Incorrect")
        new_row = {'sampleId' : row['sampleId'], 'reason' : "Incorrect_Panel"}
        new_df = pd.DataFrame([new_row])
        exclusion_df = pd.concat([new_df, exclusion_df], ignore_index = True)

mask = subsetManifest.apply(isCorrectPanel, axis = 1)
subsetManifest = subsetManifest[mask]

# Remove part A non consented
for idx, row in subsetManifest.iterrows() :
    if row['12_245_partA'] == "NO" :
        print(f"Dropping {row['sampleId']}, 12-245 Non Consent")
        new_row = {'sampleId' : row['sampleId'], 'reason' : "Incorrect_Panel"}
        new_df = pd.DataFrame([new_row])
        exclusion_df = pd.concat([new_df, exclusion_df], ignore_index = True)
subsetManifest = subsetManifest[subsetManifest['12_245_partA'] != 'NO']

# Export files
if fullFileA.endswith('.xlsx') :
    manifest.to_excel(fullFileA, index = False, header = False)
else :
    manifest.to_csv(fullFileA, sep = '\t', index = False, header = True)

if subsetFileA.endswith('.xlsx') :
    subsetManifest.to_excel(subsetFileA, index = False, header = False)
else :
    subsetManifest.to_csv(subsetFileA, sep = '\t', index = False, header = True)    
    
samples = subsetManifest['sampleId']
if subsetFileB.endswith('.xlsx') :
    samples.to_excel(subsetFileB, index = False, header = False)
else :
    samples.to_csv(subsetFileB, sep = '\t', index = False, header = False)    

exclusion_df.to_csv(exclusionFile, sep = '\t', index = False)