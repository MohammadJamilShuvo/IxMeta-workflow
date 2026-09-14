#!/usr/bin/env python3
import gzip, random
from pathlib import Path
random.seed(42)
out=Path("smoke_test/data"); out.mkdir(parents=True, exist_ok=True)
def seq(n): return ''.join(random.choice('ACGT') for _ in range(n))
host=seq(12000); micro1=seq(5000); micro2=seq(4000)
Path("smoke_test/host.fa").write_text(">synthetic_host\n"+host+"\n")
reads=[]
for i in range(1200):
    source=host if i<800 else (micro1 if i<1000 else micro2)
    start=random.randrange(0,len(source)-320)
    frag=source[start:start+300]
    reads.append((f"smoke_{i}",frag[:150],frag[-150:][::-1].translate(str.maketrans('ACGT','TGCA'))))
with gzip.open(out/"SMOKE_R1.fastq.gz","wt") as r1, gzip.open(out/"SMOKE_R2.fastq.gz","wt") as r2:
    for name,a,b in reads:
        r1.write(f"@{name}/1\n{a}\n+\n{'I'*len(a)}\n")
        r2.write(f"@{name}/2\n{b}\n+\n{'I'*len(b)}\n")
Path("smoke_test/samples.tsv").write_text("sample\tr1\tr2\nSMOKE\tsmoke_test/data/SMOKE_R1.fastq.gz\tsmoke_test/data/SMOKE_R2.fastq.gz\n")
print("[OK] smoke-test data generated")
