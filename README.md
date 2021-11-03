# ecDNA-Echo
Pipeline to Analyze ecDNA in collaboration with BoundlessBio



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


### Resources

#### Bams Mirror
```
/juno/res/dmpcollab/dmprequest/12-245/key.txt
/juno/res/dmpcollab/dmprequest/12-245/header.txt
/juno/res/dmpcollab/dmpshare/share/irb12_245/*/*/*bam

```
