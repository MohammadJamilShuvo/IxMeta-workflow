#!/usr/bin/env bash
set -euo pipefail
ACC="GCA_964199275.3"
OUTDIR="resources/ixodes_ricinus"
ZIP="${OUTDIR}/${ACC}.zip"
OUTFA="${OUTDIR}/${ACC}.fna"
mkdir -p "$OUTDIR"

if ! command -v datasets >/dev/null 2>&1; then
  echo "[ERROR] NCBI datasets CLI is required. Install with: conda install -c conda-forge -c bioconda ncbi-datasets-cli" >&2
  exit 1
fi

if [[ -s "$OUTFA" ]]; then
  echo "[OK] reference already exists: $OUTFA"
  exit 0
fi

echo "[INFO] downloading $ACC"
datasets download genome accession "$ACC" --include genome --filename "$ZIP"
TMP=$(mktemp -d)
unzip -q "$ZIP" -d "$TMP"
FA=$(find "$TMP" -type f -name '*genomic.fna' | head -n 1)
if [[ -z "${FA:-}" ]]; then
  echo "[ERROR] genomic FASTA not found in NCBI datasets archive" >&2
  exit 1
fi
cp "$FA" "$OUTFA"
rm -rf "$TMP" "$ZIP"
echo "[OK] host reference: $OUTFA"
