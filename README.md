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


### Resources

#### Bams Mirror
```
/juno/res/dmpcollab/dmprequest/12-245/key.txt
/juno/res/dmpcollab/dmprequest/12-245/header.txt
/juno/res/dmpcollab/dmpshare/share/irb12_245/*/*/*bam

```
