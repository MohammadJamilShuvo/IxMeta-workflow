#!/usr/bin/env python3
import argparse, csv
from pathlib import Path
from collections import defaultdict

p=argparse.ArgumentParser()
p.add_argument("--inputs", nargs="+", required=True)
p.add_argument("--counts", required=True)
p.add_argument("--relative", required=True)
p.add_argument("--prevalence", required=True)
a=p.parse_args()
data=defaultdict(dict); taxa=set(); samples=[]
for f in a.inputs:
    sample=Path(f).name.split(".")[0]; samples.append(sample)
    with open(f, encoding="utf-8") as h:
        r=csv.DictReader(h, delimiter="\t")
        for row in r:
            name=row.get("name") or row.get("taxonomy_name")
            est=row.get("new_est_reads") or row.get("fraction_total_reads") or "0"
            if name:
                try: val=float(est)
                except: val=0
                data[sample][name]=val; taxa.add(name)
taxa=sorted(taxa)
for path, relative in [(a.counts,False),(a.relative,True)]:
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    with open(path,"w",newline="") as h:
        w=csv.writer(h, delimiter="\t"); w.writerow(["sample"]+taxa)
        for s in samples:
            vals=[data[s].get(t,0.0) for t in taxa]; total=sum(vals)
            if relative and total>0: vals=[v/total for v in vals]
            w.writerow([s]+[f"{v:.8g}" for v in vals])
with open(a.prevalence,"w",newline="") as h:
    w=csv.writer(h, delimiter="\t"); w.writerow(["taxon","samples_detected","prevalence"])
    for t in taxa:
        n=sum(data[s].get(t,0)>0 for s in samples)
        w.writerow([t,n,f"{n/len(samples):.6f}"])
