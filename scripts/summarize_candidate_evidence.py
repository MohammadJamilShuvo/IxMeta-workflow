#!/usr/bin/env python3
import argparse, subprocess
from pathlib import Path

p=argparse.ArgumentParser()
p.add_argument("--depth", required=True)
p.add_argument("--fai", required=True)
p.add_argument("--bam", required=True)
p.add_argument("--min-depth", type=int, default=3)
p.add_argument("--output", required=True)
p.add_argument("--sample", required=True)
p.add_argument("--candidate", required=True)
a=p.parse_args()
length=sum(int(x.split("\t")[1]) for x in Path(a.fai).read_text().splitlines() if x.strip())
covered1=coveredn=depthsum=0
with open(a.depth) as fh:
    for line in fh:
        if not line.strip(): continue
        d=int(line.rstrip().split("\t")[2]); depthsum+=d
        covered1 += d >= 1
        coveredn += d >= a.min_depth
mapped=int(subprocess.check_output(["samtools","view","-c","-F","4",a.bam], text=True).strip())
mean=depthsum/length if length else 0
with open(a.output,"w") as h:
    h.write("sample\tcandidate\treference_bp\tmapped_reads\tmean_depth\tbreadth_1x\tbreadth_min_depth\tmin_depth_threshold\n")
    h.write(f"{a.sample}\t{a.candidate}\t{length}\t{mapped}\t{mean:.6f}\t{covered1/length:.6f}\t{coveredn/length:.6f}\t{a.min_depth}\n")
