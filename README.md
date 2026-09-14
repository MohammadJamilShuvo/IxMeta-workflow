# IxMeta Workflow

**Reproducible host-depleted metagenomic profiling and pathogen-genomics workflow for *Ixodes ricinus* sequencing data**

IxMeta is a Snakemake workflow for analysing shotgun/metagenomic sequencing data generated from whole *Ixodes ricinus* ticks. It separates the vector genome from the non-host fraction, profiles bacterial/viral/eukaryotic microbial signals, assembles non-host reads, and performs reference-based genomic characterization of selected candidate pathogens or symbionts.

The workflow is designed around a practical problem in tick metagenomics: most reads from a whole tick can originate from the vector itself, while biologically important microorganisms may be low abundance, phylogenetically close to non-pathogenic endosymbionts, or incompletely represented in reference databases. IxMeta therefore treats broad taxonomic classification as a discovery layer and requires genome-level evidence for stronger organism-level interpretation.

## Scientific scope

IxMeta addresses four linked questions:

1. **How much sequence data are vector-derived versus non-host?**
2. **Which microbial taxa are supported in the non-host fraction?**
3. **Can candidate organisms be reconstructed or supported by genome-wide mapping rather than isolated taxonomic hits?**
4. **How do microbial/pathogen profiles vary among samples and, when metadata are available, across ecological or geographic gradients?**

The workflow is not a clinical diagnostic assay. Its purpose is reproducible research-grade discovery, characterization and comparative analysis.

---

## Reference case study

The included case-study profile uses the public *Ixodes ricinus* metagenomic dataset:

- **NCBI BioProject:** `PRJEB49853`
- **NCBI BioProject ID:** `918049`
- **Title:** *Metagenomic profiling of the viral and bacterial communities in Ixodes ricinus from Portugal*
- **Public data:** 15 SRA experiments, approximately 44 Gbases in total
- **Study objective reported by NCBI:** characterization of viral communities in *I. ricinus* ticks from Portugal, including development of PCR targets for selected bacterial and viral species

IxMeta retrieves the run manifest directly from the public ENA/NCBI-linked archive at run time and downloads the original FASTQ files with checksum verification. No raw sequencing data are stored in this repository.

The host-depletion reference is the current chromosome-level *I. ricinus* assembly:

- **Assembly:** `GCA_964199275.3`
- **BioProject:** `PRJEB67792`
- **Assembly level:** chromosome
- **Chromosomes:** 14

---

## Workflow architecture

<img width="1254" height="1254" alt="workflow_diagram" src="https://github.com/user-attachments/assets/ff808397-5cc9-4e0f-b5ac-48db5db70ef8" />


---

## Main software

| Stage | Tool | Role |
|---|---|---|
| Read preprocessing | `fastp` | adapter removal, quality trimming, read-level QC |
| Independent read QC | `FastQC` | per-library sequence-quality diagnostics |
| Combined QC | `MultiQC` | consolidated run-level QC report |
| Host depletion | `Bowtie2` | map reads to the chromosome-level *I. ricinus* reference |
| Alignment processing | `SAMtools` | sorted/indexed BAMs, mapping statistics, depth |
| Broad classification | `Kraken2` | k-mer-based microbial taxonomic classification |
| Abundance re-estimation | `Bracken` | genus/species abundance estimates from Kraken2 assignments |
| Non-host assembly | `MEGAHIT` | de novo assembly of retained non-host reads |
| Candidate remapping | `Bowtie2` | reference-based evidence for selected organism genomes |
| Variant calling | `BCFtools` | candidate-genome SNP/consensus calling |
| Comparative alignment | `MAFFT` | alignment of recovered consensus with reference sequences |
| Phylogeny | `IQ-TREE2` | maximum-likelihood phylogenetic inference |
| Community analysis | `R`, `vegan` | abundance matrix, alpha diversity and Bray-Curtis ordination |
| Orchestration | `Snakemake` | dependency tracking, reproducible execution and HPC scaling |

Software is isolated in rule-specific Conda environments under `workflow/envs/`.

---

## Repository structure

```text
IxMeta-workflow/
├── README.md
├── LICENSE
├── CITATION.cff
├── CHANGELOG.md
├── config/
│   ├── config.yaml
│   ├── samples.example.tsv
│   └── candidate_references.example.tsv
├── case_study/
│   └── PRJEB49853/
│       ├── README.md
│       └── config.yaml
├── docs/
│   ├── METHODS.md
│   ├── OUTPUTS.md
│   ├── VALIDATION.md
│   ├── DATABASES.md
│   └── HPC.md
├── profiles/
│   └── slurm/config.yaml
├── resources/
│   └── README.md
├── scripts/
│   ├── fetch_bioproject_manifest.py
│   ├── download_ena_reads.py
│   ├── fetch_ixodes_reference.sh
│   ├── check_inputs.py
│   ├── summarize_host_depletion.py
│   ├── summarize_candidate_evidence.py
│   ├── build_bracken_matrix.py
│   ├── community_analysis.R
│   └── capture_versions.sh
├── smoke_test/
│   ├── README.md
│   ├── config.yaml
│   └── make_smoke_data.py
└── workflow/
    ├── Snakefile
    ├── rules/
    │   ├── qc.smk
    │   ├── host.smk
    │   ├── classification.smk
    │   ├── assembly.smk
    │   ├── candidate.smk
    │   └── report.smk
    └── envs/
        ├── qc.yaml
        ├── mapping.yaml
        ├── classification.yaml
        ├── assembly.yaml
        ├── phylogeny.yaml
        └── report.yaml
```

---

## Installation

### 1. Clone

```bash
git clone https://github.com/<USER>/IxMeta-workflow.git
cd IxMeta-workflow
```

### 2. Create the Snakemake controller environment

```bash
conda env create -f workflow/envs/controller.yaml
conda activate ixmeta
```

Check:

```bash
snakemake --version
python --version
```

Snakemake creates the rule-specific Conda environments automatically when `--use-conda` is supplied.

---

## Reproduce the public PRJEB49853 case study

### Step 1. Retrieve the original archive manifest

```bash
python scripts/fetch_bioproject_manifest.py \
  --bioproject PRJEB49853 \
  --output case_study/PRJEB49853/run_manifest.tsv \
  --samples case_study/PRJEB49853/samples.tsv
```

This queries the ENA portal for the run accessions linked to `PRJEB49853`, preserves archive metadata and FASTQ checksums, and writes an IxMeta sample sheet.

### Step 2. Inspect the manifest before downloading

```bash
column -t -s $'\t' case_study/PRJEB49853/run_manifest.tsv | less -S
```

Confirm library layout and total download size.

### Step 3. Download the original FASTQ files

For a first computational benchmark, download a small subset:

```bash
python scripts/download_ena_reads.py \
  --manifest case_study/PRJEB49853/run_manifest.tsv \
  --outdir data/PRJEB49853 \
  --first 3
```

For the complete case study:

```bash
python scripts/download_ena_reads.py \
  --manifest case_study/PRJEB49853/run_manifest.tsv \
  --outdir data/PRJEB49853 \
  --all
```

Downloads are resumable and MD5 checksums are verified against the archive metadata.

If only a subset was downloaded, create a matching subset sample sheet:

```bash
python scripts/download_ena_reads.py \
  --manifest case_study/PRJEB49853/run_manifest.tsv \
  --outdir data/PRJEB49853 \
  --first 3 \
  --write-samples config/samples.PRJEB49853.first3.tsv
```

### Step 4. Download the *I. ricinus* host reference

```bash
bash scripts/fetch_ixodes_reference.sh
```

Expected output:

```text
resources/ixodes_ricinus/GCA_964199275.3.fna
```

### Step 5. Configure the run

For the full case study:

```bash
cp case_study/PRJEB49853/config.yaml config/run.PRJEB49853.yaml
```

Edit only paths that differ on your system.

For a three-run benchmark, set:

```yaml
samples: "config/samples.PRJEB49853.first3.tsv"
```

### Step 6. Validate inputs and configuration

```bash
python scripts/check_inputs.py --config config/run.PRJEB49853.yaml
```

### Step 7. Dry-run

```bash
snakemake \
  --snakefile workflow/Snakefile \
  --configfile config/run.PRJEB49853.yaml \
  --use-conda \
  --cores 8 \
  --dry-run \
  --printshellcmds
```

### Step 8. Run locally/workstation

```bash
snakemake \
  --snakefile workflow/Snakefile \
  --configfile config/run.PRJEB49853.yaml \
  --use-conda \
  --cores 8 \
  --rerun-incomplete \
  --printshellcmds
```

For the complete dataset, HPC execution is recommended; see `docs/HPC.md`.

---

## Taxonomic database

IxMeta does not bundle a Kraken2 database because database identity and build date are part of the scientific method. Configure an existing Kraken2/Bracken database in `config.yaml`:

```yaml
classification:
  enabled: true
  kraken_db: "/path/to/k2_pluspf_database"
  bracken_level: "S"
  read_length: 150
```

For a publication-grade run, record:

- database name,
- build date,
- source URL,
- taxonomy snapshot,
- database checksum or immutable identifier when available.

See `docs/DATABASES.md`.

---

## Candidate-genome characterization

Broad classification is not treated as final pathogen evidence. Organisms selected for genomic confirmation are supplied in a TSV:

```text
candidate_id    reference_fasta    comparative_fasta
rickettsia_helvetica    resources/candidates/r_helvetica.fa    resources/candidates/rickettsia_refs.fa
borrelia_miyamotoi      resources/candidates/b_miyamotoi.fa    resources/candidates/borrelia_refs.fa
```

Set:

```yaml
candidate_analysis:
  enabled: true
  candidates: "config/candidate_references.tsv"
  min_mapq: 20
  min_baseq: 20
  min_depth: 3
```

For each candidate and sample IxMeta reports:

- mapped read pairs,
- mean depth,
- breadth of reference covered at ≥1× and ≥3×,
- filtered variants,
- consensus sequence,
- optional phylogenetic placement when a comparative FASTA is supplied.

These metrics distinguish a genome-wide signal from isolated matches to conserved or repetitive regions.

---

## Community-level outputs

When classification is enabled, Bracken outputs are converted into a sample × taxon matrix. IxMeta then produces:

- raw estimated read counts,
- relative abundance matrix,
- Shannon diversity per sample,
- Bray-Curtis distance matrix,
- PCoA ordination coordinates and figure,
- taxon prevalence table.

These outputs are suitable for later integration with ecological metadata such as habitat, forest structure, microclimate, host community or sampling region. Ecological association models are deliberately not hard-coded because the design matrix depends on the study.

---

## Output hierarchy

```text
results/
├── 01_qc/
├── 02_host_depletion/
├── 03_classification/
├── 04_assembly/
├── 05_candidates/
├── 06_phylogeny/
├── 07_community/
└── 08_report/
```

See `docs/OUTPUTS.md` for file-level interpretation.

---

## Validation strategy

IxMeta uses three validation layers:

1. **Functional smoke test** — fixed synthetic host + microbial reads verify rule connectivity and expected host depletion.
2. **Archive-data benchmark** — original PRJEB49853 reads verify behaviour on real *I. ricinus* metagenomic libraries.
3. **Organism-level evidence** — candidate calls are evaluated using mapping breadth/depth, assembly support, variants and phylogenetic placement rather than classifier output alone.

A publishable interpretation should additionally include biological validation where required (for example targeted PCR/RT-PCR, qPCR, Sanger sequencing or independent library evidence).

See `docs/VALIDATION.md`.

---

## Scientific contribution

IxMeta does not replace established tools. Its contribution is the reproducible connection of vector-host subtraction, metagenomic discovery, de novo assembly, candidate genome confirmation and cross-sample ecological summaries in one auditable workflow.

The design is particularly useful for *I. ricinus* because a chromosome-level vector reference is now available, allowing host-derived reads to be separated explicitly rather than treated as an undefined background. The retained host-mapped BAMs also remain available for future vector-genomic analyses when coverage and sampling design permit.

---

## Reproducibility record

Every run can archive the exact configuration, sample sheet, Git commit and software versions:

```bash
bash scripts/capture_versions.sh config/run.PRJEB49853.yaml
```

The report bundle is written under:

```text
results/08_report/reproducibility/
```

For a manuscript analysis, archive the repository release and configuration with a DOI-enabled repository such as Zenodo.

---

## Current scope and limitations

- IxMeta currently assumes paired-end short-read input for the main workflow.
- Kraken2/Bracken results depend on the configured database and are discovery evidence.
- Detection of nucleic acid does not establish vector competence, viability, virulence or human pathogenicity.
- Closely related endosymbionts and pathogens require targeted genomic/experimental validation.
- Candidate phylogenies are only meaningful when comparative references are taxonomically appropriate and sequence coverage is sufficient.
- Vector population-genomic analysis of the host-mapped read fraction is outside the current core workflow, although the required BAMs are retained.

---

## Citation

A formal workflow citation will be added with the first archived release. Until then, cite this repository and the public source datasets used in the analysis.

## License

MIT License.
