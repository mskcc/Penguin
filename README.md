# PeNGUIN
Predicting ecDNA Novelties in Genes Using IMPACT NGS Data

A Pipeline to Analyze ecDNA in collaboration with BoundlessBio

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

In ```/example/output```, ```facets_cbioportal_merged.tsv``` is the facets and cBioPortal sample data, which contains annotated data on the inputs.

```merged.ECHO_results.csv``` is for ECHO results; one line for each gene called per sample, and special lines denoting when a sample has no genes called. 

```merged.FACETS_gene_results.tsv``` is the facets annotations for each gene called by ECHO. If the echo results did not have any amplifications, the corresponding line will appear in this document, in the "gene" column. If the gene/sample pair is not in the FACETS database, each column past "gene" will be empty.

### Step 0: Configure Config File

Please first run 

```
cp /juno/cmo/bergerlab/yuk3/Project_ecDNA/references/ /data/input/ -r
```

To get all of the input data.

The default config file is scripts/global_config_bash.rc.
Edit ```projectName``` to the desired project name, and place a list of the sampleIds to run (separated by newlines) in the manifest folder (by default it is ```[dataDir]/input/manifest/[projectName]```). By default this folder does not exist, so you will need to create it. 

You can do this by running

```
mkdir data/input/manifest/[projectName] 2>/dev/null
```

You can see an example sampleId list in ```/example/input```. Edit ```sampleFull``` to this path. All other paths and configurations can be changed for further customization, such as choosing to use the FACETS called tumor purity.

### Step 1: Run the Parallelized ECHO Caller

```
cd scripts
sh generateECHOResults.sh $config_file $list_of_samples 
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

This pipeline offers several visualization notebooks in ```\notebooks``` to jumpstart analysis. 

```echo_visualize.ipynb``` is for general visualizations, analyzing ecDNA prevalence in cancer types, genes that are commonly ecDNA positive, and the effect of ecDNA on clinical factors.

```diagnosis_km_curves.ipynb``` is for creating KM curves using CDSI data. Plot curves for each cancer type and analyze cox models.

```case_study.ipynb``` is for analyzing a single gene in a single cancer. Plot copy number and segment length, cox models / KM curves for the specific gene, and analyze patient timelines.

```treatment.ipynb``` is for analyzing a treatment for a specific gene's amplification and ecDNA positivity. Plot PFS and OS KM curves, and analyze cox models. 

Each notebook has a settings section that the user should edit before each run.

To run the notebooks on Juno, first switch to the analysis environment listed in Dependencies. Run ```jupyter lab``` in the ```\notebooks``` folder. You should get a link like ```http://localhost:[NUM]/lab?token=[TOKEN]``` then in a separate window run ```ssh -N -L [NUM]:localhost:[NUM] [user]@terra```. Copy the link to a browser, and edit settings in each notebook before running.

### Helpful Links

[For cBioPortal API Information](https://docs.cbioportal.org/web-api-and-clients/)

[About Data Access Tokens](https://docs.cbioportal.org/deployment/authorization-and-authentication/authenticating-users-via-tokens/)

[FACETS API](https://github.com/mskcc/facetsAPI)

[About Boundless Bio](https://boundlessbio.com/what-we-do/)

### Troubleshooting

- You can find log files in the log directory, by default ```[dataDir]/log/log_[projectName]```. In the main directory, ```call_submit_on_cluster...``` has information on the call to submit each ECHO job. The ```echoCalls``` folder contains log files for each ECHO call. ```facets_multiple_call...``` has information on the call to submit each FACETS job. the ```facetsCalls``` folder contains log files for each FACETS gene level call. The end of each file is a date timestamp to allow for troubleshooting across multiple different runs.

- To Pull & Build singularity image on HPC:
    ```
    export singularity_cache=$HOME/.singularity/cache

    echo $singularity_cache

    singularity build --docker-login ${singularity_cache}/boundlessbio-echo-preprocessor-release-v2.3.1.img docker://boundlessbio/echo-prep

    singularity build --docker-login ${singularity_cache}/boundlessbio-ecs-v2.0.0.img  docker://boundlessbio/ecs:release-v2.0.0
    ```

- To remove chr Prefix from one of the reference files:

    ```
    sed 's/^chr//' hg19-blacklist.v2.bed > hg19-blacklist.v2_withoutPrefix.bed
    ```