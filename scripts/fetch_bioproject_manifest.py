#!/usr/bin/env python3
import argparse
import csv
import sys
import urllib.parse
import urllib.request
from pathlib import Path

FIELDS = [
    "study_accession","sample_accession","experiment_accession","run_accession",
    "scientific_name","sample_title","library_strategy","library_source",
    "library_selection","library_layout","instrument_platform","instrument_model",
    "fastq_ftp","fastq_md5","fastq_bytes"
]

def main():
    p = argparse.ArgumentParser(description="Fetch ENA run manifest for an NCBI/ENA BioProject accession.")
    p.add_argument("--bioproject", required=True)
    p.add_argument("--output", required=True)
    p.add_argument("--samples", required=True)
    args = p.parse_args()

    params = {
        "accession": args.bioproject,
        "result": "read_run",
        "fields": ",".join(FIELDS),
        "format": "tsv",
        "download": "true",
    }
    url = "https://www.ebi.ac.uk/ena/portal/api/filereport?" + urllib.parse.urlencode(params)
    try:
        with urllib.request.urlopen(url, timeout=90) as r:
            text = r.read().decode("utf-8")
    except Exception as e:
        sys.exit(f"[ERROR] ENA query failed: {e}\nURL: {url}")

    lines = [x for x in text.splitlines() if x.strip()]
    if len(lines) < 2:
        sys.exit(f"[ERROR] No run records returned for {args.bioproject}")

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text + ("\n" if not text.endswith("\n") else ""), encoding="utf-8")

    rows = list(csv.DictReader(lines, delimiter="\t"))
    bad_layout = sorted({r["library_layout"] for r in rows if r["library_layout"] != "PAIRED"})
    if bad_layout:
        print(f"[WARN] Non-PAIRED layouts returned: {bad_layout}. Main IxMeta workflow expects paired-end reads.")

    samples = Path(args.samples)
    samples.parent.mkdir(parents=True, exist_ok=True)
    with samples.open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh, delimiter="\t")
        w.writerow(["sample","r1","r2"])
        for r in rows:
            run = r["run_accession"]
            ftp = [x for x in r.get("fastq_ftp", "").split(";") if x]
            if len(ftp) >= 2:
                w.writerow([run, f"data/{args.bioproject}/{run}_1.fastq.gz", f"data/{args.bioproject}/{run}_2.fastq.gz"])

    total_bytes = 0
    for r in rows:
        for x in r.get("fastq_bytes", "").split(";"):
            if x.isdigit():
                total_bytes += int(x)
    print(f"[OK] {len(rows)} run records written to {out}")
    print(f"[OK] paired-end sample sheet written to {samples}")
    print(f"[INFO] reported FASTQ size: {total_bytes/1e9:.2f} GB")

if __name__ == "__main__":
    main()
