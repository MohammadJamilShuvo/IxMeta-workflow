def cand_ref(w): return CAND_REFS[w.candidate]
def cand_comp(w): return CAND_COMP.get(w.candidate, "")
def idxprefix(w): return f"{OUT}/05_candidates/index/{w.candidate}"

rule candidate_index:
    input: cand_ref
    output: done=f"{OUT}/05_candidates/index/{{candidate}}.index.done"
    conda: "../envs/mapping.yaml"
    params: idxprefix
    shell:
        """mkdir -p {OUT}/05_candidates/index; \
        bowtie2-build {input} {params}; \
        touch {output.done}"""

rule candidate_map:
    input:
        idx=rules.candidate_index.output.done,
        r1=f"{OUT}/02_host_depletion/nonhost/{{sample}}_R1.fastq.gz",
        r2=f"{OUT}/02_host_depletion/nonhost/{{sample}}_R2.fastq.gz"
    output:
        bam=f"{OUT}/05_candidates/{{sample}}/{{candidate}}/mapped.bam",
        bai=f"{OUT}/05_candidates/{{sample}}/{{candidate}}/mapped.bam.bai",
        flag=f"{OUT}/05_candidates/{{sample}}/{{candidate}}/flagstat.txt"
    threads: config["threads"]["candidate_mapping"]
    conda: "../envs/mapping.yaml"
    params:
        idx=idxprefix,
        mapq=config["candidate_analysis"]["min_mapq"]
    shell:
        """mkdir -p $(dirname {output.bam}); \
        bowtie2 --very-sensitive -x {params.idx} -1 {input.r1} -2 {input.r2} -p {threads} | \
        samtools view -b -q {params.mapq} - | samtools sort -@ {threads} -o {output.bam}; \
        samtools index {output.bam}; \
        samtools flagstat {output.bam} > {output.flag}"""

rule candidate_depth:
    input:
        bam=f"{OUT}/05_candidates/{{sample}}/{{candidate}}/mapped.bam",
        bai=f"{OUT}/05_candidates/{{sample}}/{{candidate}}/mapped.bam.bai",
        ref=cand_ref
    output:
        depth=f"{OUT}/05_candidates/{{sample}}/{{candidate}}/depth.tsv",
        fai=f"{OUT}/05_candidates/{{sample}}/{{candidate}}/reference.fa.fai",
        mask=f"{OUT}/05_candidates/{{sample}}/{{candidate}}/low_coverage.bed",
        evidence=f"{OUT}/05_candidates/{{sample}}/{{candidate}}/evidence.tsv"
    conda: "../envs/mapping.yaml"
    params:
        mindepth=config["candidate_analysis"]["min_depth"]
    shell:
        """cp {input.ref} $(dirname {output.fai})/reference.fa; \
        samtools faidx $(dirname {output.fai})/reference.fa; \
        samtools depth -aa {input.bam} > {output.depth}; \
        awk -v md={params.mindepth} '$3 < md {{print $1"\t"$2-1"\t"$2}}' {output.depth} > {output.mask}; \
        python scripts/summarize_candidate_evidence.py --depth {output.depth} --fai {output.fai} \
          --bam {input.bam} --min-depth {params.mindepth} --sample {wildcards.sample} \
          --candidate {wildcards.candidate} --output {output.evidence}"""

rule candidate_variants:
    input:
        bam=f"{OUT}/05_candidates/{{sample}}/{{candidate}}/mapped.bam",
        ref=cand_ref
    output:
        vcf=f"{OUT}/05_candidates/{{sample}}/{{candidate}}/variants.filtered.vcf.gz",
        csi=f"{OUT}/05_candidates/{{sample}}/{{candidate}}/variants.filtered.vcf.gz.csi"
    threads: config["threads"]["variant_calling"]
    conda: "../envs/mapping.yaml"
    params:
        bq=config["candidate_analysis"]["min_baseq"],
        q=config["candidate_analysis"]["min_variant_qual"]
    shell:
        """bcftools mpileup -Ou -f {input.ref} -Q {params.bq} {input.bam} | \
        bcftools call -mv -Ou | bcftools filter -i 'QUAL>={params.q}' -Oz -o {output.vcf}; \
        bcftools index {output.vcf}"""

rule candidate_consensus:
    input:
        vcf=f"{OUT}/05_candidates/{{sample}}/{{candidate}}/variants.filtered.vcf.gz",
        ref=cand_ref,
        mask=f"{OUT}/05_candidates/{{sample}}/{{candidate}}/low_coverage.bed"
    output:
        f"{OUT}/05_candidates/{{sample}}/{{candidate}}/consensus.fa"
    conda: "../envs/mapping.yaml"
    shell:
        """tmp=$(mktemp); \
        bcftools consensus -f {input.ref} {input.vcf} > $tmp; \
        bedtools maskfasta -fi $tmp -bed {input.mask} -fo {output}; \
        rm -f $tmp"""

rule candidate_phylogeny:
    input:
        consensus=f"{OUT}/05_candidates/{{sample}}/{{candidate}}/consensus.fa",
        comparative=cand_comp
    output:
        alignment=f"{OUT}/06_phylogeny/{{sample}}/{{candidate}}/alignment.fa",
        tree=f"{OUT}/06_phylogeny/{{sample}}/{{candidate}}/iqtree.treefile"
    threads: config["threads"]["phylogeny"]
    conda: "../envs/phylogeny.yaml"
    params:
        prefix=lambda w: f"{OUT}/06_phylogeny/{w.sample}/{w.candidate}/iqtree"
    run:
        if not input.comparative or not Path(str(input.comparative)).exists():
            Path(output.alignment).parent.mkdir(parents=True, exist_ok=True)
            Path(output.alignment).write_text("# comparative FASTA not supplied\n")
            Path(output.tree).write_text("# phylogeny not run\n")
        else:
            shell("mkdir -p $(dirname {output.alignment}); cat {input.comparative} {input.consensus} | mafft --auto - > {output.alignment}; iqtree2 -s {output.alignment} -m MFP -B 1000 -T {threads} --prefix {params.prefix} >/dev/null 2>&1; cp {params.prefix}.treefile {output.tree}")
