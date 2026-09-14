HOST = config["references"]["host_fasta"]
IDX = f"{OUT}/02_host_depletion/index/ixodes"

rule host_index:
    input: HOST
    output: done=f"{OUT}/02_host_depletion/index/ixodes.index.done"
    conda: "../envs/mapping.yaml"
    shell:
        """mkdir -p {OUT}/02_host_depletion/index; \
        bowtie2-build {input} {IDX}; \
        touch {output.done}"""

rule host_depletion:
    input:
        idx=rules.host_index.output.done,
        r1=f"{OUT}/01_qc/trimmed/{{sample}}_R1.fastq.gz",
        r2=f"{OUT}/01_qc/trimmed/{{sample}}_R2.fastq.gz"
    output:
        bam=f"{OUT}/02_host_depletion/host_bam/{{sample}}.host.bam",
        bai=f"{OUT}/02_host_depletion/host_bam/{{sample}}.host.bam.bai",
        r1=f"{OUT}/02_host_depletion/nonhost/{{sample}}_R1.fastq.gz",
        r2=f"{OUT}/02_host_depletion/nonhost/{{sample}}_R2.fastq.gz",
        log=f"{OUT}/02_host_depletion/logs/{{sample}}.bowtie2.log",
        flag=f"{OUT}/02_host_depletion/host_bam/{{sample}}.flagstat.txt"
    threads: config["threads"]["host_mapping"]
    conda: "../envs/mapping.yaml"
    params:
        preset=config["host_depletion"]["bowtie2_preset"],
        prefix=lambda w: f"{OUT}/02_host_depletion/nonhost/{w.sample}_R%.fastq.gz"
    shell:
        """mkdir -p {OUT}/02_host_depletion/host_bam {OUT}/02_host_depletion/nonhost {OUT}/02_host_depletion/logs; \
        bowtie2 {params.preset} -x {IDX} -1 {input.r1} -2 {input.r2} -p {threads} \
          --un-conc-gz '{params.prefix}' 2> {output.log} | \
          samtools sort -@ {threads} -o {output.bam}; \
        samtools index {output.bam}; \
        samtools flagstat -@ {threads} {output.bam} > {output.flag}"""

rule host_summary:
    input:
        expand(f"{OUT}/02_host_depletion/logs/{{sample}}.bowtie2.log", sample=SAMPLES)
    output:
        f"{OUT}/02_host_depletion/host_depletion_summary.tsv"
    shell:
        "python scripts/summarize_host_depletion.py --logs {input} --output {output}"
