#!/usr/bin/env python3
import argparse, csv, os, sys
from pathlib import Path
try:
    import yaml
except ImportError:
    sys.exit("[ERROR] PyYAML is required in the controller environment")

p=argparse.ArgumentParser()
p.add_argument("--config", required=True)
a=p.parse_args()
cfg=yaml.safe_load(open(a.config, encoding="utf-8"))
errors=[]
for key in ["project","samples","references","output_dir"]:
    if key not in cfg: errors.append(f"missing config key: {key}")
samples=Path(cfg.get("samples", ""))
if not samples.exists(): errors.append(f"sample sheet does not exist: {samples}")
host=Path(cfg.get("references",{}).get("host_fasta", ""))
if not host.exists(): errors.append(f"host FASTA does not exist: {host}")
if samples.exists():
    with samples.open(encoding="utf-8") as fh:
        rows=list(csv.DictReader(fh, delimiter="\t"))
    if not rows: errors.append("sample sheet has no records")
    for r in rows:
        for col in ["sample","r1","r2"]:
            if not r.get(col): errors.append(f"missing {col} for row {r}")
        for col in ["r1","r2"]:
            if r.get(col) and not Path(r[col]).exists(): errors.append(f"missing read file: {r[col]}")
if cfg.get("classification",{}).get("enabled"):
    db=Path(cfg["classification"].get("kraken_db", ""))
    if not db.exists(): errors.append(f"Kraken2 database not found: {db}")
if cfg.get("candidate_analysis",{}).get("enabled"):
    c=Path(cfg["candidate_analysis"].get("candidates", ""))
    if not c.exists(): errors.append(f"candidate manifest not found: {c}")
if errors:
    print("[FAILED] input/config validation")
    for e in errors: print(" -", e.strip())
    sys.exit(1)
print("[OK] configuration and input paths validated")
