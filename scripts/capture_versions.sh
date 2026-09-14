#!/usr/bin/env bash
set -euo pipefail
CONFIG=${1:?usage: capture_versions.sh <config.yaml>}
OUT="results/08_report/reproducibility"
mkdir -p "$OUT"
cp "$CONFIG" "$OUT/config.used.yaml"
[[ -d .git ]] && git rev-parse HEAD > "$OUT/git_commit.txt" || echo "not-a-git-checkout" > "$OUT/git_commit.txt"
{
  echo -e "tool\tversion"
  for t in snakemake fastp fastqc multiqc bowtie2 samtools kraken2 bracken megahit bcftools mafft iqtree2 Rscript; do
    if command -v "$t" >/dev/null 2>&1; then
      v=$($t --version 2>&1 | head -n 1 || true)
      echo -e "$t\t$v"
    else
      echo -e "$t\tnot-in-current-PATH"
    fi
  done
} > "$OUT/software_versions.tsv"
echo "[OK] reproducibility record: $OUT"
