# Output interpretation

## `results/01_qc/`
- filtered paired reads
- fastp HTML/JSON
- FastQC reports
- MultiQC report

## `results/02_host_depletion/`
- host-aligned sorted/indexed BAMs
- non-host paired FASTQ files
- Bowtie2 logs
- SAMtools flagstat files
- project host-depletion summary

## `results/03_classification/`
- Kraken2 read assignments and reports
- Bracken abundance tables
- merged abundance matrices

## `results/04_assembly/`
- MEGAHIT contigs per sample
- assembly logs

## `results/05_candidates/`
For each sample x candidate:
- BAM/BAI
- depth table
- breadth/depth evidence summary
- filtered VCF
- consensus FASTA

## `results/06_phylogeny/`
- comparative alignment
- IQ-TREE files and maximum-likelihood tree

## `results/07_community/`
- count matrix
- relative-abundance matrix
- prevalence table
- Shannon diversity
- Bray-Curtis distance matrix
- PCoA coordinates/plot

## `results/08_report/`
- exact config/sample snapshots
- software versions
- Git commit
- run summary
