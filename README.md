# ecDNA-Echo
Pipeline to Analyze ecDNA in collaboration with BoundlessBio

### Dependencies

The environment yml file for the scripts may be found in ```/envs/echo.yml```
The environment yml file for the analysis notebooks may be found in ```/envs/ecDNA_analysis.yml```

You can get all the dependencies for the scripts with 

```
conda env create --name ecDNA --file=envs/echo.yml
conda activate ecDNA
pip install git+https://github.com/mskcc/facetsAPI#facetsAPI
```

You can get all the dependencies for analysis with 

```
conda env create --name ecDNA_analysis --file=envs/ecDNA_analysis.yml
conda activate ecDNA_analysis
```

Note: You may need to ask for permission to get facetsAPI access. Please visit https://github.com/mskcc/facetsAPI and contact Adam Price if you need access.

### Examples

You can see example inputs and outputs in ```/example```.

In ```/example/output```, ```facets_cbioportal_merged.tsv``` is the facets and cBioPortal sample data, ```merged.ECHO_results.csv``` are for the ECHO caller, and ```merged.FACETS_gene_results.tsv``` are facets results for the ECHO called genes.

### Step 0: Configure Config File

Please first run 

```cp /juno/cmo/bergerlab/yuk3/Project_ecDNA/references/ /data/input/ -r```

To get all of the input data.

The default config file is scripts/global_config_bash.rc.
Edit ```projectName``` to the desired project name, and place a list of the sampleIds to run (separated by newlines) in the manifest folder (by default it is ```[dataDir]/input/manifest/[projectName]```). You can see an example list in ```/example/input```. Edit ```sampleFull``` to this path. All other paths and configurations can be changed for further customization, such as choosing to use the FACETS called tumor purity.

### Step 1: Run the Parallelized ECHO Caller

```
cd scripts
sh generateECHOResults.sh ../global_config_bash.rc
```

### Step 2: Merge ECHO Results

Please ensure that all jobs have concluded. You can check statuses in ```[dataDir]/flag/flag_[projectName]/echoCalls```. Ensure that no samples are still running.

```
sh merge_echo_results.sh ../global_config_bash.rc
```

### Step 3 (Optional, for FACETS Report): Run the Parallelized FACETS Caller

```
sh submit_facets_on_cluster.sh ../global_config_bash.rc
```

### Step 4 (Optional, for FACETS REport): Merge FACETS Results

Please ensure that all jobs have concluded. You can check statuses in ```[dataDir]/flag/flag_[projectName]/facetsCalls```.

```
sh merge_facets_results.sh ../global_config_bash.rc
```

### Results

The results can be found in the ```mergedOutputDirectory``` folder within the config file. This folder contains ECHO, FACETS, and pre-processing merged files.

### Visualization Notebooks

This pipeline offers several visualization notebooks in ```\notebooks``` to jumpstart analysis. ```echo_visualize.ipynb``` is for general visualizations, while ```case_study.ipynb``` is for analyzing a single gene in a single cancer. Some plots require external data, or for the FACETS gene level (steps 3 & 4) to have been run.

To run the notebooks on Juno, first switch to the analysis environment listed in Dependencies. Run ```jupyter lab``` in the desired folder, then in a separate window run ```ssh -N -L localhost:8888:localhost:8888 [user]@terra```. Copy the link in the first notebook into a browser.