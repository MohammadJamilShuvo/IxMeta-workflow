#!/usr/bin/env python3
import argparse, re
from pathlib import Path

p=argparse.ArgumentParser()
p.add_argument("--logs", nargs="+", required=True)
p.add_argument("--output", required=True)
a=p.parse_args()
rows=[]
for f in a.logs:
    text=Path(f).read_text(errors="replace")
    sample=Path(f).name.split(".")[0]
    m_total=re.search(r"([0-9,]+) reads; of these:", text)
    m_rate=re.search(r"([0-9.]+)% overall alignment rate", text)
    total=int(m_total.group(1).replace(",","")) if m_total else -1
    rate=float(m_rate.group(1)) if m_rate else float("nan")
    rows.append((sample,total,rate,100-rate if rate==rate else float("nan")))
out=Path(a.output); out.parent.mkdir(parents=True, exist_ok=True)
with out.open("w") as h:
    h.write("sample\ttotal_pairs\thost_alignment_percent\tnonhost_percent_estimate\n")
    for r in rows: h.write(f"{r[0]}\t{r[1]}\t{r[2]:.4f}\t{r[3]:.4f}\n")
