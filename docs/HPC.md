# HPC / SLURM execution

The complete PRJEB49853 dataset is large enough that HPC execution is recommended.

## 1. Keep Conda environments in workspace/project storage

Example:

```bash
mkdir -p /path/to/workspace/conda/envs /path/to/workspace/conda/pkgs
conda config --prepend envs_dirs /path/to/workspace/conda/envs
conda config --prepend pkgs_dirs /path/to/workspace/conda/pkgs
```

## 2. Create controller environment

```bash
conda env create -f workflow/envs/controller.yaml
conda activate ixmeta
```

## 3. Test configuration before submitting jobs

```bash
python scripts/check_inputs.py --config config/run.PRJEB49853.yaml
snakemake -s workflow/Snakefile \
  --configfile config/run.PRJEB49853.yaml \
  --use-conda --dry-run --printshellcmds
```

## 4. SLURM profile

`profiles/slurm/config.yaml` uses the Snakemake SLURM executor plugin. Edit account/partition defaults for the local cluster if required.

Run:

```bash
snakemake \
  -s workflow/Snakefile \
  --configfile config/run.PRJEB49853.yaml \
  --profile profiles/slurm \
  --rerun-incomplete
```

Monitor:

```bash
squeue -u "$USER"
```

Do not run full read mapping, Kraken2 or assembly on a login node.
