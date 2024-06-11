# ecDNA-Echo
Pipeline to Analyze ecDNA in collaboration with BoundlessBio

## Version 2

### Building Echo-Preprocessor Image

#### Singularity

```
export singularity_cache=$HOME/.singularity/cache

echo $singularity_cache

singularity build --docker-login  ${singularity_cache}/boundlessbio-echo-preprocessor-v2.0.4.img docker://boundlessbio/echo-preprocessor:release-v2.0.4
```

### Running Preprocessor manually

```
sh preProcess_multipleSamples_v2.sh IMPACT IM6 2

nohup sh preProcess_multipleSamples_v2.sh IMPACT IM6 2 &

sh preProcess_v2.sh /juno/res/dmpcollab/dmpshare/share/irb12_245 P-0034080-T01-IM6 P-0034080-N01-IM6 IMPACT468_picard_baits.interval_list IMPACT468_picard_baits.interval_list IMPACT P-0034080-T01-IM6 P-0034080-N01-IM6

python3.8 generateBAMFilePath.py /juno/res/dmpcollab/dmpreque
st/12-245/key.txt /juno/res/dmpcollab/dmpshare/share/irb12_245 P-0034080-T01-IM6 T

rm -rf output_3

rm -rf flags_3

```

### Housekeeping Commands

```
for i in $(ls echo.preProcess.P-0*stdout); do echo $i; cat $i | tail -n 50 | head -n 6; done

bjobs
bjobs -l 39777158
bkill -r $jobID

#For removing headers inside the BED file
cat cv3_hg19_picard_baits.interval_list | awk '{if ($1 !~ /^@/) {print $0}}' > cv3_hg19_picard_baits_withoutHeaders.interval_list

#Killing all the running jobs on LSF
bjobs | awk '{print $1}' | tail -n +2 | xargs -I {} bkill {}

# interrogating the intermediate files from ECHO
cat P-0063489-T01-IM7-P-0063489-N01-IM7.cns_adjusted.gene.tsv |awk '{ if ($10 > 10) print $0 }'

cat P-0063489-T01-IM7-P-0063489-N01-IM7.gene.tsv | awk '{ if ($6 > 10) print $0 }'

cat P-0063489-T01-IM7-P-0063489-N01-IM7.unadjusted.gene.tsv | awk '{ if ($5 > 2) print $0



```


## Version 1

### List of Samples

#### For Comptability Test

* P-0066791-T02-IM7
* P-0058060-T02-IM7




### Bash Commands

#### Manipulate MAF file

```
# Print the fields for a line in a row-wise manner
head -n 3 data_mutations_extended.txt | tail -n 1 | awk -F'\t' '{for (i=1; i<NF; i++) {print i "\t" $i}}'


# Print the header names for the MAF file
head -n 2 data_mutations_extended.txt | tail -n 1 | awk -F'\t' '{for (i=1; i<NF; i++) {print i "\t" $i}}'

# Check for Samples that belong to IM7
head -n 20 data_mutations_extended.txt | awk -F'\t' '{if ($17~/IM7/){print $17 "\t" NR}}'
```

#### Running Echo Container

##### Docker

```
docker run \
-v "/Users/sumans/Projects/Project_BoundlessBio/data/input/beds/IMPACT505_picard_baits-1.interval_list:/home/bed/IMPACT505_picard_baits.bed" \
-v /Users/sumans/Projects/Project_BoundlessBio/data/input/bams/:/home/input/ \
-v /Users/sumans/Projects/Project_BoundlessBio/data/output/:/home/output/ \
-a stdout \
-a stderr \
boundlessbio/mskcc:echo_preprocess \
--sample "UH524913-T" \
--bam_file "/home/input/UH524913-T.bam" \
--cnn_file "/home/output/UH524913-T.cnn" \
--bed_file IMPACT505_picard_baits.bed \
--step process_cnvkit


```

```
docker run \
-v /Users/sumans/Projects/Project_BoundlessBio/data/input/:/home/input/ \
-v /Users/sumans/Projects/Project_BoundlessBio/data/output/:/home/output/ \
-a stdout \
-a stderr \
boundlessbio/mskcc:echo_preprocess \
--sample "P-0066791-T02-IM7" \
--maf_file /home/input/data_mutations_extended.txt \
--output_file /home/output/my_sample_histogram.csv \
--step process_vcf

```
##### Singularity
```
singularity pull --docker-login --dir ~/Projects/Project_BoundlessBio/data/  docker://boundlessbio/mskcc:echo_preprocess
```

```
singularity run \
  --bind /home/sumans/Projects/Project_BoundlessBio/data/input/:/home/input/ \
  --bind /home/sumans/Projects/Project_BoundlessBio/data/output/:/home/output/ \
  ${imagePath} \
  --sample ”P-0066791-T02-IM7” \
  --maf_file /home/input/data_mutations_extended.txt \
  --output_file /home/output/my_sample_histogram.csv \
  --step process_vcf

  ```
#### Installing and Sharing on the Google Cloud Bucket
##### Installation
```
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-363.0.0-linux-x86_64.tar.gz

tar -xf google-cloud-sdk-363.0.0-linux-x86_64.tar.gz

./google-cloud-sdk/install.sh

./google-cloud-sdk/bin/gcloud init

```
##### Data upload

```
./google-cloud-sdk/bin/gsutil  ls gs://bbi-mskcc
./google-cloud-sdk/bin/gsutil cp ./Projects/Project_BoundlessBio/data/output/P-0061521-* gs://bbi-mskcc
```



#### Submitting to Cluster
```
bsub -W 20:00 -n 8 -R 'rusage[mem=15]' -J 'echo.all' -o 'merge.all.out' -e 'merge.all.err' ./preProcess_multipleSamples.sh
```





### Resources

#### Bams Mirror
```
/juno/res/dmpcollab/dmprequest/12-245/key.txt
/juno/res/dmpcollab/dmprequest/12-245/header.txt
/juno/res/dmpcollab/dmpshare/share/irb12_245/*/*/*bam

```

#### Reference Data Files

```
/juno/work/ci/resources/genomes/GRCh37/fasta/b37.fasta
```
