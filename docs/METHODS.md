# Methods implemented by IxMeta

## 1. Read preprocessing

Paired-end reads are processed with fastp. The rule records JSON/HTML reports and retains filtered pairs. FastQC is run on the filtered reads and MultiQC aggregates QC metrics across the project.

## 2. Host depletion

Filtered reads are aligned to the chromosome-level *Ixodes ricinus* reference GCA_964199275.3 with Bowtie2. Properly unmapped read pairs are written as the non-host fraction. The host-aligned BAM is retained and indexed instead of discarded. Host-depletion summaries report total reads, mapped reads, mapping rate and retained non-host pairs.

## 3. Taxonomic discovery

When enabled, Kraken2 classifies non-host reads against a user-specified, versioned database. Bracken re-estimates abundance at the configured taxonomic level. Database identity and build date must be reported as part of the method.

Classification is treated as discovery evidence because database incompleteness and similarity between pathogens/endosymbionts can produce ambiguous assignments.

## 4. De novo non-host assembly

MEGAHIT assembles the paired non-host fraction per sample. Contigs below the configured minimum length are excluded by MEGAHIT. Assembly output allows candidate evidence to be inspected independently of read-level taxonomic classification.

## 5. Candidate genome confirmation

For each candidate listed in the candidate manifest, non-host reads are mapped to a curated reference. IxMeta calculates:

- mapped read count;
- reference breadth at >=1x and >=configured minimum depth;
- mean depth;
- filtered SNP calls;
- consensus sequence.

Genome-wide breadth is central to interpretation: a small number of reads mapping only to conserved loci is not equivalent to broad reference support.

## 6. Optional phylogenetic placement

When a comparative FASTA is supplied, the candidate consensus is combined with comparative sequences, aligned with MAFFT and analysed with IQ-TREE2. Interpretation requires adequate consensus coverage and appropriate comparative references.

## 7. Community analysis

Bracken species/genus estimates are merged into a sample-by-taxon matrix. R/vegan generates relative abundances, taxon prevalence, Shannon diversity, Bray-Curtis dissimilarity and PCoA coordinates. These matrices can be joined to external ecological metadata for study-specific modelling.
