# PRJEB49853 case study

This profile reproduces IxMeta on the public *Ixodes ricinus* sequencing project **PRJEB49853** (NCBI BioProject ID **918049**), titled:

> Metagenomic profiling of the viral and bacterial communities in Ixodes ricinus from Portugal.

NCBI reports 15 SRA experiments and approximately 44 Gbases of public sequence data. The study objective is characterization of viral communities in Portuguese *I. ricinus* ticks and development of PCR targets for selected bacterial/viral species.

## Data provenance

The repository does not redistribute the reads. `scripts/fetch_bioproject_manifest.py` queries the ENA archive for the run-level records linked to `PRJEB49853`. `scripts/download_ena_reads.py` then downloads the original FASTQ files and validates their MD5 checksums.

## Recommended benchmark sequence

1. Fetch the complete run manifest.
2. Download three runs and complete the pipeline end to end.
3. Review host fraction, non-host yield, classification evidence and assembly behaviour.
4. Fix database/reference provenance.
5. Scale to all runs.
6. Select candidates for genomic confirmation based on reproducible evidence, not classifier abundance alone.

## Commands

```bash
python scripts/fetch_bioproject_manifest.py \
  --bioproject PRJEB49853 \
  --output case_study/PRJEB49853/run_manifest.tsv \
  --samples case_study/PRJEB49853/samples.tsv
```

Three-run benchmark:

```bash
python scripts/download_ena_reads.py \
  --manifest case_study/PRJEB49853/run_manifest.tsv \
  --outdir data/PRJEB49853 \
  --first 3 \
  --write-samples config/samples.PRJEB49853.first3.tsv
```

Complete dataset:

```bash
python scripts/download_ena_reads.py \
  --manifest case_study/PRJEB49853/run_manifest.tsv \
  --outdir data/PRJEB49853 \
  --all \
  --write-samples config/samples.PRJEB49853.full.tsv
```
