# ecDNA-Echo
Pipeline to Analyze ecDNA in collaboration with BoundlessBio

## Version 2

### Dependencies

Please make sure to have the following installed in your environment:

'''
facetsapi
bravado
xlsx2csv
samtools
pandas
matplotlib.pyplot
numpy
'''

### Step 1: Configure Config File

The default config file is scripts/global_config_bash.rc.
Edit projectName to the desired project name, the dataDir to the desired data directory, and place a list of the sampleIds to run (separated by newlines) in the manifest folder (by default it is '''[dataDir]/input/manifest/[projectName]'''). Edit the subset file to this path. All other paths and configurations can be changed for further customization, such as choosing to use the FACETS called tumor purity.

### Step 2: Run the Parallelized ECHO Caller

'''
cd scripts
sh submit_on_cluster.sh ./global_config_bash.rc
'''

### Step 3: Merge ECHO Results

Please ensure that all jobs have concluded. You can check statuses in '''[dataDir]/flag/flag_[projectName]/echoCalls'''. Samples may fail if the BAM was not found or was not in the keyFile.

'''
sh merge_echo_results.sh ./global_config_bash.rc
'''

### Step 4 (Optional, for FACETS Report): Run the Parallelized FACETS Caller

'''
sh submit_facets_on_cluster.sh ./global_config_bash.rc
'''

### Step 5 (Optiona, for FACETS REport): Merge FACETS Results

Please ensure that all jobs have concluded. You can check statuses in '''[dataDir]/flag/flag_[projectName]/facetsCalls'''.

'''
sh merge_facets_results.sh ./global_config_bash.rc
'''