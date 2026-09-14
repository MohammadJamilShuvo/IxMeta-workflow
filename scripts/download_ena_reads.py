#!/usr/bin/env python3
import argparse
import csv
import hashlib
import shutil
import subprocess
import sys
from pathlib import Path


def md5sum(path, block=1024*1024):
    h = hashlib.md5()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(block), b""):
            h.update(chunk)
    return h.hexdigest()


def download(url, dest):
    dest.parent.mkdir(parents=True, exist_ok=True)
    cmd = ["curl", "-L", "--fail", "--retry", "5", "--retry-delay", "5", "-C", "-", "-o", str(dest), url]
    subprocess.run(cmd, check=True)


def main():
    p = argparse.ArgumentParser(description="Download original ENA FASTQs with MD5 validation.")
    p.add_argument("--manifest", required=True)
    p.add_argument("--outdir", required=True)
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--all", action="store_true")
    g.add_argument("--first", type=int)
    p.add_argument("--write-samples")
    args = p.parse_args()

    if not shutil.which("curl"):
        sys.exit("[ERROR] curl is required")

    with open(args.manifest, encoding="utf-8") as fh:
        rows = list(csv.DictReader(fh, delimiter="\t"))
    if args.first:
        rows = rows[:args.first]

    outdir = Path(args.outdir)
    sample_rows = []

    for row in rows:
        run = row["run_accession"]
        layout = row.get("library_layout", "")
        if layout != "PAIRED":
            print(f"[SKIP] {run}: layout={layout}; core workflow expects PAIRED")
            continue
        ftps = [x for x in row.get("fastq_ftp", "").split(";") if x]
        md5s = [x for x in row.get("fastq_md5", "").split(";") if x]
        if len(ftps) < 2:
            print(f"[SKIP] {run}: fewer than two FASTQ URLs")
            continue

        dests = [outdir / f"{run}_1.fastq.gz", outdir / f"{run}_2.fastq.gz"]
        for i, (ftp, dest) in enumerate(zip(ftps[:2], dests)):
            url = ftp if ftp.startswith("http") else "https://" + ftp
            expected = md5s[i] if i < len(md5s) else ""
            if dest.exists() and expected and md5sum(dest) == expected:
                print(f"[OK] existing checksum: {dest}")
                continue
            print(f"[DOWNLOAD] {run} mate {i+1}")
            download(url, dest)
            if expected:
                observed = md5sum(dest)
                if observed != expected:
                    sys.exit(f"[ERROR] MD5 mismatch for {dest}: expected {expected}, observed {observed}")
                print(f"[OK] MD5 verified: {dest}")
        sample_rows.append([run, str(dests[0]), str(dests[1])])

    if args.write_samples:
        pth = Path(args.write_samples)
        pth.parent.mkdir(parents=True, exist_ok=True)
        with pth.open("w", newline="", encoding="utf-8") as fh:
            w = csv.writer(fh, delimiter="\t")
            w.writerow(["sample","r1","r2"])
            w.writerows(sample_rows)
        print(f"[OK] wrote sample sheet: {pth}")

if __name__ == "__main__":
    main()
