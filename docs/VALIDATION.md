# Validation framework

IxMeta separates workflow validation from biological validation.

## A. Functional smoke test

A deterministic synthetic paired-end dataset contains vector-like and microbial-like fragments. The smoke test verifies:

- fastp/FastQC execution;
- host-reference indexing;
- host/non-host separation;
- assembly;
- report generation.

It does not demonstrate diagnostic accuracy.

## B. Public archive benchmark

The PRJEB49853 case study tests the workflow on real whole-tick metagenomic libraries. Review:

- raw and retained read counts;
- host alignment fraction;
- non-host yield;
- classifier support;
- assembly size and contiguity;
- consistency across samples.

## C. Candidate-level genomic evidence

A candidate should not be promoted from "classifier detection" to "genome-supported detection" without evaluating:

1. number of mapped reads;
2. breadth of reference coverage;
3. depth distribution;
4. whether coverage is concentrated in conserved/repetitive loci;
5. contig support;
6. variant plausibility;
7. phylogenetic placement where applicable;
8. possibility of a closely related endosymbiont/non-pathogenic lineage.

## D. Biological validation

Depending on the organism and intended claim, publication-grade validation may require independent PCR/RT-PCR, qPCR, Sanger sequencing, replicate-library evidence or culture/isolation. Metagenomic nucleic-acid detection alone does not establish vector competence, viability or pathogenicity.
